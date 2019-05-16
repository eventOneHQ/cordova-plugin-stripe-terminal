import StripeTerminal
import Foundation

@objc(CDVStripeTerminal) class CDVStripeTerminal: CDVPlugin, DiscoveryDelegate, ReaderDisplayDelegate {
    private var readers: [Any] = []
    private var readerObjs: [Reader] = []
    private var inputOptionsList: [String] = []
    private var inputPrompts: [String] = []
    private var discoverCancleable: Cancelable?
    
    override init() {
        print("init CDVStripeTerminal")
        super.init()
    }
    
    @objc(setTokenProvider:)
    func setTokenProvider(command: CDVInvokedUrlCommand) {
        
        print("Cordova Stripe Terminal!!!")
        
        var pluginResult = CDVPluginResult(
            status: CDVCommandStatus_ERROR
        )
        
        let apiUrl = command.arguments[0] as? String ?? ""
        
        let apiClient = APIClient(apiUrl: apiUrl)
        
        Terminal.setTokenProvider(apiClient)
        
        pluginResult = CDVPluginResult(
            status: CDVCommandStatus_OK
        )
        
        self.commandDelegate!.send(
            pluginResult,
            callbackId: command.callbackId
        )
    }
    
    @objc(discoverReaders:)
    func discoverReaders(command: CDVInvokedUrlCommand) {
        // currently hardcoded into sim mode
        let config = DiscoveryConfiguration(
            deviceType: .chipper2X,
            discoveryMethod: .bluetoothScan,
            simulated: false
        )
        
        
        self.discoverCancleable = Terminal.shared.discoverReaders(
            config,
            delegate: self,
            completion: { error in
                print(error as Any)
                
                let pluginResult = CDVPluginResult(
                    status: CDVCommandStatus_ERROR,
                    messageAs: error?.localizedDescription
                )
                self.commandDelegate!.send(
                    pluginResult,
                    callbackId: command.callbackId
                )
        }
        )
        
        let pluginResult = CDVPluginResult(
            status: CDVCommandStatus_OK
        )
        self.commandDelegate!.send(
            pluginResult,
            callbackId: command.callbackId
        )
    }
    
    @objc(getReaders:)
    func getReaders(command: CDVInvokedUrlCommand) {
        let pluginResult = CDVPluginResult(
            status: CDVCommandStatus_OK,
            messageAs: self.readers
        )
        
        self.commandDelegate!.send(
            pluginResult,
            callbackId: command.callbackId
        )
    }
    func terminal(_ terminal: Terminal, didUpdateDiscoveredReaders readers: [Reader]) {
        print(readers as [Any])
        
        var items = [Any]()
        
        // convert Reader to a plain object
        for reader in readers {
            items.append([
                "serialNumber": reader.serialNumber,
                "batteryLevel": reader.batteryLevel as Any,
                // "deviceType": reader.deviceType as Any,
                "deviceSoftwareVersion": reader.deviceSoftwareVersion as Any
                ])
        }
        
        self.readers = items
        self.readerObjs = readers
    }
    
    @objc(getInputOptions:)
    func getInputOptions(command: CDVInvokedUrlCommand) {
        let pluginResult = CDVPluginResult(
            status: CDVCommandStatus_OK,
            messageAs: self.inputOptionsList
        )
        
        self.commandDelegate!.send(
            pluginResult,
            callbackId: command.callbackId
        )
    }
    func terminal(_ terminal: Terminal, didRequestReaderInput inputOptions: ReaderInputOptions = []) {
        let inputOptionsString = Terminal.stringFromReaderInputOptions(inputOptions)

        print("inputOptionsString \(inputOptionsString)")
        
//        self.inputOptionsList.append(inputOptionsString)
    }
    
    
    @objc(getInputPromts:)
    func getInputPromts(command: CDVInvokedUrlCommand) {
        let pluginResult = CDVPluginResult(
            status: CDVCommandStatus_OK,
            messageAs: self.inputPrompts
        )
        
        self.commandDelegate!.send(
            pluginResult,
            callbackId: command.callbackId
        )
    }
    func terminal(_ terminal: Terminal, didRequestReaderDisplayMessage inputPrompt: ReaderDisplayMessage) {
        let inputPromptString = Terminal.stringFromReaderDisplayMessage(inputPrompt)

        print("inputPromptString \(inputPromptString)")
        
//        self.inputPrompts.append(inputPromptString)
    }
    
    @objc(connectReader:)
    func connectReader(command: CDVInvokedUrlCommand) {
        var pluginResult = CDVPluginResult(
            status: CDVCommandStatus_ERROR
        )
        
        let serialNumber = command.arguments[0] as? String ?? ""
        let selectReader = self.readerObjs.first(where: { $0.serialNumber == serialNumber })
        
        let selectedReader = selectReader as! Reader
        
        Terminal.shared.connectReader(selectedReader, completion: { reader, error in
            if let reader = reader {
                print("Successfully connected to reader: \(reader.serialNumber)")
                
                pluginResult = CDVPluginResult(
                    status: CDVCommandStatus_OK,
                    messageAs: "Successfully connected to reader: \(reader.serialNumber)"
                )
                
                self.commandDelegate!.send(
                    pluginResult,
                    callbackId: command.callbackId
                )
            }
            else if let error = error {
                print("errorConnect: \(error.localizedDescription)")
                
                pluginResult = CDVPluginResult(
                    status: CDVCommandStatus_ERROR,
                    messageAs: error.localizedDescription
                )
                
                self.commandDelegate!.send(
                    pluginResult,
                    callbackId: command.callbackId
                )
            }
        })
    }
    
    @objc(collectPayment:)
    func collectPayment(command: CDVInvokedUrlCommand) {
        var pluginResult = CDVPluginResult(
            status: CDVCommandStatus_ERROR
        )
        
        let clientSecret = command.arguments[0] as? String ?? ""
        print(clientSecret)
        
        // get the payment intent
        let paymentIntent = Terminal.shared.retrievePaymentIntent(clientSecret: clientSecret) { paymentIntent, error in
            if let paymentIntent = paymentIntent {
                print("retrievePaymentIntent")
                // collect a payment method
                let cancelable = Terminal.shared.collectPaymentMethod(paymentIntent, delegate: self) { paymentIntent, error in
                    if let paymentIntent = paymentIntent {
                        print("collectPaymentMethod \(paymentIntent)")
                        // process the payment
                        Terminal.shared.processPayment(paymentIntent) { paymentIntent, error in
                            if let paymentIntent = paymentIntent {
                                print("processPayment")
                                let pluginResult = CDVPluginResult(
                                    status: CDVCommandStatus_OK,
                                    messageAs: paymentIntent.stripeId
                                )
                                self.commandDelegate!.send(
                                    pluginResult,
                                    callbackId: command.callbackId
                                )
                            }
                            else if let error = error {
                                pluginResult = CDVPluginResult(
                                    status: CDVCommandStatus_ERROR,
                                    messageAs: error.localizedDescription
                                )
                                self.commandDelegate!.send(
                                    pluginResult,
                                    callbackId: command.callbackId
                                )
                            }
                        }
                    }
                    else if let error = error {
                        pluginResult = CDVPluginResult(
                            status: CDVCommandStatus_ERROR,
                            messageAs: error.localizedDescription
                        )
                        self.commandDelegate!.send(
                            pluginResult,
                            callbackId: command.callbackId
                        )
                    }
                }
            }
            else if let error = error {
                pluginResult = CDVPluginResult(
                    status: CDVCommandStatus_ERROR,
                    messageAs: error.localizedDescription
                )
                self.commandDelegate!.send(
                    pluginResult,
                    callbackId: command.callbackId
                )
            }
        }
    }
}
