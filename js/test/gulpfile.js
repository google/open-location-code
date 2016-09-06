var gulp = require('gulp');
var qunit = require('gulp-qunit');

gulp.task('test', function() {
  return gulp.src('./test.html').pipe(qunit());
});

gulp.task('default', ['test']);
