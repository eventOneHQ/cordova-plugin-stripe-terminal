var exec = require('cordova/exec')
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
   * @param tokenProvider {string} Token provider function
   * @param [success] {Function} Success callback
   * @param [error] {Function} Error callback
   */
  initTerminal: function (url, success, error) {
    success = success || noop
    error = error || noop

    exec(success, error, 'CordovaTerminal', 'initTerminal', [
      url
    ])
  }
}
