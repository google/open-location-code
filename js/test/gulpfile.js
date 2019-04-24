var gulp = require('gulp');
var phantom = require('node-qunit-phantomjs');

function test(callback) {
  phantom('./test.html', {}, (result) => {
    // Called with 0 for successful test completion, 1 for failure(s).
    if (result === 0) {
      callback();
    } else {
      callback(new Error('tests failed'));
    }
  });
}

exports.test = test;
