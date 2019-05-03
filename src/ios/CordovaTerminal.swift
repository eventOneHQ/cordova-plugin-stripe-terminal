@objc(CordovaTerminal) class CordovaTerminal : CDVPlugin {
    func initTerminal(command: CDVInvokedUrlCommand) {
        var pluginResult = CDVPluginResult(
            status: CDVCommandStatus_ERROR
        )

        print(pluginResult)
        let apiUrl = command.arguments[0] as? String ?? ""

        print(apiUrl)
        var apiClient = APIClient(apiUrl)

        Terminal.setTokenProvider(apiClient)
    }
}