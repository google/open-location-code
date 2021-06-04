var gulp = require('gulp');
var karma = require('karma');

gulp.task('test', function(done) {
    var server = new karma.Server({
        configFile: __dirname + '/test/karma.config.js',
        singleRun: true
    });

    server.on('run_complete', function (browsers, results) {
        if (results.error || results.failed) {
            done(new Error('There are test failures'));
        }
        else {
            done();
        }
    });

    server.start();
});

const minify = require('gulp-minify');
gulp.task('minify', function(done) {
  gulp.src('src/openlocationcode.js')
    .pipe(minify({
        ext:{
            src:'.js',
            min:'.min.js'
        },
    }))
    .pipe(gulp.dest('src'));
  done();
});
