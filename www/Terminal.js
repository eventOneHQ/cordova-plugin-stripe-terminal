var exec = require('cordova/exec')
var channel = require('corodva/channel')

var noop = function (data) {
  console.log(data)
}

/**
 * @namespace cordova.plugins
 */

/**
 * @exports terminal
 */
module.exports = {
  /**
   * Initialize Stripe Terminal
   * @param url {string} API URL to get the token
   * @param [success] {Function} Success callback
   * @param [error] {Function} Error callback
   */
  setTokenProvider: function (url, success, error) {
    success = success || noop
    error = error || noop

    exec(success, error, 'StripeTerminal', 'setTokenProvider', [url])
  },

  getReaders: function (success, error) {
    success = success || noop
    error = error || noop

    exec(success, error, 'StripeTerminal', 'getReaders', [])
  },

  discoverReaders: function (success, error) {
    success = success || noop
    error = error || noop

    exec(
      function () {
        this.getReaders(success, error)
      },
      error,
      'StripeTerminal',
      'discoverReaders',
      []
    )
  }
}
