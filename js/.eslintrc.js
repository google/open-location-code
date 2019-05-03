module.exports = {
  "env": {
      "browser": true,
      "es6": true
  },
  "extends": "google",
  "globals": {
      "Atomics": "readonly",
      "SharedArrayBuffer": "readonly"
  },
  "parserOptions": {
      "ecmaVersion": 2018
  },
  "rules": {
    // Rules are based on the Google styleguide with the following overrides.
    "max-len": [2, {
      code: 100,
      tabWidth: 2,
      ignoreUrls: true,
    }],
    "no-var": 0,
  }
};
