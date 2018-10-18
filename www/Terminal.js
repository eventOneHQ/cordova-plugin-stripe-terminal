var exec = require('cordova/exec')
var noop = function () {}

/**
 * @namespace cordova.plugins
 */

/**
 * @exports terminal
 */
module.exports = {
  /**
   * Initialize Stripe Terminal
   * @param key {string} Secret key
   * @param [success] {Function} Success callback
   * @param [error] {Function} Error callback
   */
  init: function (key, success, error) {
    success = success || noop
    error = error || noop
    exec(success, error, 'CordovaStripeTerminal', 'init', [key])
  }
}
