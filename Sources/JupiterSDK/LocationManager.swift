import CoreLocation

public class LocationManager: NSObject, CLLocationManagerDelegate {
    public var locationManager = CLLocationManager()
    public var magHeading: Double = 0

    public override init() {
        super.init()
        locationManager.delegate = self
        locationManager.startUpdatingHeading()
    }

    public func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        let magneticHeading = newHeading.magneticHeading
        self.magHeading = magneticHeading
    }
    
    public func getMagHeading() -> Double {
        return self.magHeading
    }
}
