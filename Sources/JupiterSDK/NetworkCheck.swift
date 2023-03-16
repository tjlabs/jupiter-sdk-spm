import SystemConfiguration

class NetworkCheck {
    
    static let shared = NetworkCheck()
    private let reachability = SCNetworkReachabilityCreateWithName(nil, "NetworkCheck")
    
    private init() {}
    
    func isConnectedToInternet() -> Bool {
        var flags = SCNetworkReachabilityFlags()
        SCNetworkReachabilityGetFlags(self.reachability!, &flags)
        let isReachable = flags.contains(.reachable)
        let needsConnection = flags.contains(.connectionRequired)
        return (isReachable && !needsConnection)
    }
}
