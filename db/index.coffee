mongoose = require 'mongoose'
_ = require 'underscore'

SnowDaySchema = new mongoose.Schema
	resortName: String
	resortId: String
	snowDate: Date
	snowBase: Number
	snowDateString: Number
	precipitation: Number
	seasonSnow: Number
	seasonDay: Number
	generated: type: Boolean, default: false

ResortSchema = new mongoose.Schema
	name: String
	state: String

SnowDay = mongoose.model 'SnowDay', SnowDaySchema
exports.SnowDay = SnowDay

Resort = mongoose.model 'Resort', ResortSchema
exports.Resort = Resort

#Declare outside of function scope
_resortMap = {}
populateResortMap = (callback)->
	_resortMap = {}
	SnowDay.find (err, results) ->
		_.each results, (result) ->
			try
				resortName = result.resortName
				date = new Date(result.snowDate)
				season = undefined

				#delete day if it's Feb 29 so we don't have non-matching days btwn seasons
				if result.snowDateString.toString().slice(4,8) == '0229'
					result.remove(err) ->
						if !err then console.log 'removed snow day on feb 29'
				#Start season in November (month 10)
				else if date.getMonth() > 9
					season = date.getFullYear() + '-' + (date.getFullYear() + 1).toString()
				#end season in april (month 3)
				else if date.getMonth() < 4
					season = (date.getFullYear() - 1) + '-' + date.getFullYear().toString()
				else
					result.remove(err) ->
						if !err then console.log 'removed snow day outside of season bounds'
				if season
					if !_resortMap[resortName]
						_resortMap[resortName] = {}
					if !_resortMap[resortName][season]
						_resortMap[resortName][season] = {}	
					_resortMap[resortName][season][result.snowDateString] = result
			catch error
				console.log result
				# console.log typeof result.snowDate
				console.log error
		console.log 'populateResortMap: calling callback'
		callback()

removeDuplicates = (callback) ->
	#the _id: null specifies that we don't want to group by anything, and then we are specifying that we want to return the snowDateString, with the aggregation function "$addToSet", which returns one unique value for each dateString. $project selects which fields to return
	# SnowDay.aggregate {$group: {_id: null, snowDateString: {$addToSet: "$snowDateString"}}}, {$project: {_id: 0, snowDateString: 1}}, (err, res) ->
	# 	if callback then callback res
	SnowDay.aggregate {$group: {_id: "$snowDateString", count: {$sum: 1}}}, {$project: {_id: 0, snowDateString: "$_id", count: 1}}, (err, results) ->
		duplicates = _.filter results, (result) ->
			result.count > 1
		if callback then callback duplicates

exports.removeDuplicates = removeDuplicates

_dateArray1 = []
_dateArray2 = []
populateDateArray = () ->
	_dateArray1 = []
	_dateArray2 = []
	for i in [1..30]
		_dateArray1.push 1100 + i
	for i in [1..31]
		_dateArray1.push 1200 + i
	for i in [1..31]
		_dateArray2.push 100 + i
	for i in [1..28]
		_dateArray2.push 200 + i
	for i in [1..31]
		_dateArray2.push 300 + i
	for i in [1..30]
		_dateArray2.push 400 + i

getDateArray = (startYear) ->
	result = []
	_.each _dateArray1, (date) ->
		result.push startYear * 10000 + date
	_.each _dateArray2, (date) ->
		result.push (startYear + 1) * 10000 + date
	result

_normalizeRunning = false
normalizeSnowData = (callback) ->
	padSeason = true
	if _normalizeRunning then return
	_normalizeRunning = true
	populateDateArray()
	populateResortMap () ->
		console.log 'done with populateResortMap, starting callback'
										
		_.each _resortMap, (resortData, resortName) =>
			Resort.findOne name: resortName, (err, results) =>
				resortId = results._id
				_.each resortData, (seasonData, seasonName) =>
					#sort snowDays by their date string so we know we have sequential data
					sortedSeasonData = _.sortBy seasonData, (day) -> day.snowDateString

					#set the first day string so we know where to begin interpolating data
					firstDayString = sortedSeasonData[0].snowDateString
					lastDayString = sortedSeasonData[sortedSeasonData.length - 1].snowDateString
					console.log lastDayString
					previousDayString = firstDayString

					dateArray = getDateArray parseInt seasonName.slice(0,4)
					
					# console.log dateArray
					missingDays = []
					missingDates = []
					seasonDay = 0
					_.each dateArray, (dateString) =>
						seasonDay += 1
						#check for document with the given dateString
						if !seasonData[dateString]
							#if we've gone to the end of the available data for the season then just create new docs holding the base constant
							if dateString > lastDayString || dateString < firstDayString
								if padSeason
									str = dateString.toString()
									date = new Date str.slice(0,4), parseInt(str.slice(4,6)) - 1, str.slice(6,8)
									newDay = new SnowDay
										resortName: resortName
										resortId: resortId
										snowDate: date
										snowBase: 0#if dateString > lastDayString then seasonData[lastDayString].snowBase else seasonData[firstDayString].snowBase
										snowDateString: dateString
										precipitation: 0
										seasonDay: seasonDay
										seasonSnow: if dateString > lastDayString then seasonData[lastDayString].seasonSnow else 0
										generated: true
									console.log 'saving new snow day before or after season %s', newDay.snowDateString
									newDay.save (err) ->
										if err
											console.log 'error saving new snow day before or after season'
										else
											console.log 'saved new snow day before or after season'
							else
								#day is missing, so push to missing date array to keep running tally
								missingDays.push seasonDay
								missingDates.push dateString
						else
							#add a seasonDay attribute
							seasonData[dateString].seasonDay = seasonDay
							seasonData[dateString].save()

							#check if we have a queue of missing days, and then fill out the dates in between
							if missingDates.length > 0
								baseDiff = seasonData[dateString].snowBase - seasonData[previousDayString].snowBase
								seasonSnowDiff = seasonData[dateString].seasonSnow - seasonData[previousDayString].seasonSnow
								if seasonSnowDiff < 0 then seasonSnowDiff = 0
								incrementalBaseDiff = baseDiff / (missingDates.length + 1)
								incrementalSeasonSnowDiff = seasonSnowDiff / (missingDates.length + 1)
								j = 0
								_.each missingDates, (missingDate) ->
									j += 1
									str = missingDate.toString()
									date = new Date str.slice(0,4), parseInt(str.slice(4,6)) - 1, str.slice(6,8)
									newDay = new SnowDay
										resortName: resortName
										resortId: resortId
										snowDate: date
										snowBase: seasonData[previousDayString].snowBase + (j * incrementalBaseDiff)
										snowDateString: missingDate
										seasonDay: missingDays[j-1]
										precipitation: incrementalSeasonSnowDiff
										seasonSnow: seasonData[previousDayString].seasonSnow + (j * incrementalSeasonSnowDiff)
										generated: true
									console.log 'saving new snow day during season %s', newDay.snowDateString
									newDay.save (err) ->
										if err
											console.log 'error saving new snow day during season'
										else
											console.log 'saved new snow day during season'

								#reset missingDays array
								missingDays = []
								missingDates = []


							#Populate the previousDayString so we can know where the start point is for the interpolation
							previousDayString = dateString
		console.log 'snow Data normalized'
		callback _resortMap
		_normalizeRunning = false
	
exports.normalizeSnowData = normalizeSnowData

