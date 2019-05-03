module.exports = function(config) {
  config.set({
    browsers: ['ChromeHeadless'],
    frameworks: [
      'jasmine-jquery',
      'jasmine',
    ],
    plugins: [
      'karma-chrome-launcher',
      'karma-jasmine',
      'karma-jasmine-jquery',
    ],
    files: [
      '../src/openlocationcode.js',
      'jasmine-tests.js',
      { pattern: '*.json', included: false, served: true}
    ]
  });
};
