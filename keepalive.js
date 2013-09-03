var http = require('http'); //importing http
var options = {
  host: 'snowbase.herokuapp.com',
  port: 80,
  path: '/'
};
http.get(options, function(res) {
  res.on('data', function(chunk) {
    console.log('requested ' + options.host)
  });
}).on('error', function(err) {
  console.log("Error: " + err.message);
});