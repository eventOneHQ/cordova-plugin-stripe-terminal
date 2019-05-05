import StripeTerminal

@objc(CDVStripeTerminal) class CDVStripeTerminal: CDVPlugin, DiscoveryDelegate {

    private let config: DiscoveryConfiguration
    private var readers: [Reader] = []
    
    init(discoveryConfig: DiscoveryConfiguration) {
        self.config = discoveryConfig
        super.init()
    }

    @objc(setTokenProvider:)
    func setTokenProvider(command: CDVInvokedUrlCommand) {

        print("Cordova Stripe Terminal!!!")

        var pluginResult = CDVPluginResult(
            status: CDVCommandStatus_ERROR
        )

        print(command as Any)

        let apiUrl = command.arguments[0] as? String ?? ""

        print(apiUrl)
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
            simulated: true
        )

        
        let cancleable = Terminal.shared.discoverReaders(
            config, 
            delegate: self, 
            completion: { error in
                print(error as Any)

                let errTxt = error as! String
                
                let pluginResult = CDVPluginResult(
                    status: CDVCommandStatus_ERROR,
                    messageAs: errTxt
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
        print(readers as Any)

        self.readers = readers
    }
}
