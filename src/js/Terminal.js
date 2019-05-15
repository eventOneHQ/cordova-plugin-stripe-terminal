const exec = require('cordova/exec')
const PLUGIN_NAME = 'StripeTerminal'

class Terminal {
  /**
   * Initialize Stripe Terminal
   * @param options {Object} Options to initiate Stripe Terminal
   * @return {Terminal} Instance of Stripe Terminal
   */
  constructor (options) {
    this.handlers = {
      readers: [],
      error: []
    }
    this.isInitialized = false
    this.timers = {}
    this.connecting = false

    this.options = options || {}
  }

  /**
   * @private
   */
  log (...args) {
    console.log(PLUGIN_NAME, ...args)
  }

  /**
   * @private
   */
  resolve (results) {
    this.log(results)
  }

  /**
   * @private
   */
  reject (msg) {
    const e = typeof msg === 'string' ? new Error(msg) : msg
    this.emit('error', e)
    console.error(e)
  }

  /**
   * Set token provider
   * @param url {string} API URL to get the token
   */
  setTokenProvider (url) {
    const self = this
    this.log('setTokenProvider')
    return new Promise((resolve, reject) => {
      exec(
        data => {
          resolve(data)
          self.isInitialized = true
        },
        reject,
        PLUGIN_NAME,
        'setTokenProvider',
        [url]
      )
    })
  }

  /**
   * Begins discovering readers matching the given configuration.
   */
  discoverReaders () {
    const self = this
    return new Promise((resolve, reject) => {
      this.log('discoverReaders')
      exec(
        () => {
          // set a timeout so that setTokenProvider is ready
          setTimeout(() => {
            // if discoverReaders has already been called, don't do it again
            if (self.timers['readers']) {
              resolve()
            }

            self.timers['readers'] = setInterval(() => {
              exec(
                readers => {
                  if (readers) {
                    self.emit('readers', readers)
                  }
                },
                self.reject,
                PLUGIN_NAME,
                'getReaders',
                []
              )
            }, 1000)

            resolve()
          }, 100)
        },
        reject,
        PLUGIN_NAME,
        'discoverReaders',
        []
      )
    })
  }

  /**
   * Connect to a reader.
   *
   * @param {string} serialNumber The serial number of the reader that you want to connect to.
   */
  connectReader (serialNumber) {
    return new Promise((resolve, reject) => {
      if (!serialNumber) {
        return reject(new Error('Please specify a serialNumber'))
      }

      const self = this
      if (!self.connecting) {
        self.connecting = true
        self.log('connectReader', serialNumber)

        exec(
          res => {
            self.connecting = false

            clearInterval(self.timers['readers'])
            resolve(res)
          },
          err => {
            self.connecting = false

            clearInterval(self.timers['readers'])
            reject(err)
          },
          PLUGIN_NAME,
          'connectReader',
          [serialNumber]
        )
      } else {
        return reject(new Error('Already connecting...'))
      }
    })
  }

  /**
   * Collect a payment for a PaymentIntent
   *
   * @param {string} clientSecret See Stripe {@link https://stripe.com/docs/api/payment_intents/object#payment_intent_object-client_secret:Payment Intents API reference} for details
   */
  collectPayment (clientSecret) {
    return new Promise((resolve, reject) => {
      if (!clientSecret) {
        return reject(new Error('Please specify a clientSecret'))
      }

      this.log('collectPayment')
      exec(resolve, reject, PLUGIN_NAME, 'collectPayment', [clientSecret])
    })
  }

  /**
   * Listen for an event.
   *
   * The following events are supported:
   *
   *   - readers
   *   - error
   *
   * @param {String} eventName to subscribe to.
   * @param {Function} callback triggered on the event.
   */
  on (eventName, callback) {
    if (!this.handlers.hasOwnProperty(eventName)) {
      this.handlers[eventName] = []
    }
    this.handlers[eventName].push(callback)
  }

  /**
   * Remove event listener.
   *
   * @param {String} eventName to match subscription.
   * @param {Function} handle function associated with event.
   */
  off (eventName, handle) {
    if (this.handlers.hasOwnProperty(eventName)) {
      const handleIndex = this.handlers[eventName].indexOf(handle)
      if (handleIndex >= 0) {
        this.handlers[eventName].splice(handleIndex, 1)
      }
    }
  }

  /**
   * Emit an event.
   *
   * This is intended for internal use only.
   *
   * @param {String} eventName is the event to trigger.
   * @param {*} all arguments are passed to the event listeners.
   * @private
   *
   * @return {Boolean} is true when the event is triggered otherwise false.
   */
  emit (...args) {
    const eventName = args.shift()

    if (!this.handlers.hasOwnProperty(eventName)) {
      return false
    }

    for (let i = 0, length = this.handlers[eventName].length; i < length; i++) {
      const callback = this.handlers[eventName][i]
      if (typeof callback === 'function') {
        callback.apply(undefined, args)
      } else {
        console.log(`event handler: ${eventName} must be a function`)
      }
    }

    return true
  }
}

module.exports = Terminal
