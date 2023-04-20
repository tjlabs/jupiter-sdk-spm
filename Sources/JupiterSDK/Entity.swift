import Foundation

struct UserInfo: Codable {
    var user_id: String
    var device_model: String
    var os_version: Int
}

struct SectorInfo: Codable {
    var sector_id: Int
}

struct SectorInfoResult: Codable {
    var building_level: [[String]]
}
 
struct CardList: Codable {
    var sectors: [CardInfo]
}

struct CardInfo: Codable {
    var sector_id: Int
    var sector_name: String
    var description: String
    var card_color: String
    var dead_reckoning: String
    var service_request: String
    var building_level: [[String]]
}

public struct Attitude: Equatable {
    public var Roll: Double = 0
    public var Pitch: Double = 0
    public var Yaw: Double = 0
}

public struct StepResult: Equatable {
    public var count: Double = 0
    public var heading: Double = 0
    public var pressure: Double = 0
    public var stepLength: Double = 0
    public var isLooking: Bool = true
}

public struct UnitDistance: Equatable {
    public var index: Int = 0
    public var length: Double = 0
    public var velocity: Double = 0
    public var isIndexChanged: Bool = false
}


public struct TimestampDouble: Equatable {
    public var timestamp: Double = 0
    public var valuestamp: Double = 0
}


public struct StepLengthWithTimestamp: Equatable {
    public var timestamp: Double = 0
    public var stepLength: Double = 0

}

public struct SensorAxisValue: Equatable {
    public var x: Double = 0
    public var y: Double = 0
    public var z: Double = 0
    
    public var norm: Double = 0
}

public struct DistanceInfo: Equatable {
    public var index: Int = 0
    public var length: Double = 0
    public var time: Double = 0
    public var isIndexChanged: Bool = true
}

public struct KalmanOutput: Equatable {
    public var x: Double = 0
    public var y: Double = 0
    public var heading: Double = 0
    
    public func toString() -> String {
        return "{x : \(x), y : \(y), search_direction : \(heading)}"
    }
}

public struct UnitDRInfo {
    public var index: Int = 0
    public var length: Double = 0
    public var heading: Double = 0
    public var velocity: Double = 0
    public var lookingFlag: Bool = false
    public var isIndexChanged: Bool = false
    public var autoMode: Int = 0
    
    public func toString() -> String {
        return "{index : \(index), length : \(length), heading : \(heading), velocity : \(velocity), lookingFlag : \(lookingFlag), isStepDetected : \(isIndexChanged), autoMode : \(autoMode)}"
    }
}

public struct ServiceResult {
    public var isIndexChanged: Bool = false
    
    public var indexTx: Int = 0
    public var indexRx: Int = 0
    public var length: Double = 0
    public var velocity: Double = 0
    public var heading: Double = 0
    public var scc: Double = 0
    public var phase: String = ""
    public var bias: Int = 0
    public var isConverged: Bool = false
    public var mode: String = ""
    
    public var level: String = ""
    public var building: String = ""
}

// ------------------------------------------------- //
// -------------------- Network -------------------- //
// ------------------------------------------------- //
struct ReceivedForce: Encodable {
    var user_id: String
    var mobile_time: Int
    var ble: [String: Double]
    var pressure: Double
}

struct UserVelocity: Encodable {
    var user_id: String
    var mobile_time: Int
    var index: Int
    var length: Double
    var heading: Double
    var looking: Bool
}

struct RssiBias: Encodable {
    var os_version: Int
    var device_model: String
    var rssi_scale: Double
    var rssi_bias: Int
}

// Sector Detection
public struct SectorDetectionResult: Codable {
    public var mobile_time: Int
    public var sector_name: String
    public var calculated_time: Double
    
    public init() {
        self.mobile_time = 0
        self.sector_name = ""
        self.calculated_time = 0
    }
}

// Building Detection
public struct BuildingDetectionResult: Codable {
    public var mobile_time: Int
    public var building_name: String
    public var calculated_time: Double
    
    public init() {
        self.mobile_time = 0
        self.building_name = ""
        self.calculated_time = 0
    }
}

// Coarse Level Detection
struct CoarseLevelDetection: Encodable {
    var user_id: String
    var mobile_time: Int
}

public struct CoarseLevelDetectionResult: Codable {
    public var mobile_time: Int
    public var sector_name: String
    public var building_name: String
    public var level_name: String
    public var calculated_time: Double
    
    public init() {
        self.mobile_time = 0
        self.sector_name = ""
        self.building_name = ""
        self.level_name = ""
        self.calculated_time = 0
    }
}

// Fine Level Detection
public struct FineLevelDetectionResult: Codable {
    public var mobile_time: Int
    public var building_name: String
    public var level_name: String
    public var scc: Double
    public var scr: Double
    public var calculated_time: Double
    
    public init() {
        self.mobile_time = 0
        self.building_name = ""
        self.level_name = ""
        self.scc = 0
        self.scr = 0
        self.calculated_time = 0
    }
}


// Coarse Location Estimation
struct CoarseLocationEstimation: Encodable {
    var user_id: String
    var mobile_time: Int
    var sector_id: Int
}

public struct CoarseLocationEstimationResult: Codable {
    public var mobile_time: Int
    public var building_name: String
    public var level_name: String
    public var scc: Double
    public var scr: Double
    public var x: Int
    public var y: Int
    public var calculated_time: Double
    
    public init() {
        self.mobile_time = 0
        self.building_name = ""
        self.level_name = ""
        self.scc = 0
        self.scr = 0
        self.x = 0
        self.y = 0
        self.calculated_time = 0
    }
}


// Fine Location Tracking
struct FineLocationTracking: Encodable {
    var user_id: String
    var mobile_time: Int
    var sector_id: Int
    var building_name: String
    var level_name: String
    var spot_id: Int
    var phase: Int
    var rss_compensation_list: [Int]
    var sc_compensation_list: [Double]
}

public struct FineLocationTrackingFromServer: Codable {
    public var mobile_time: Int
    public var building_name: String
    public var level_name: String
    public var scc: Double
    public var x: Double
    public var y: Double
    public var absolute_heading: Double
    public var phase: Int
    public var calculated_time: Double
    public var index: Int
    public var rss_compensation: Int
    public var sc_compensation: Double
    
    public init() {
        self.mobile_time = 0
        self.building_name = ""
        self.level_name = ""
        self.scc = 0
        self.x = 0
        self.y = 0
        self.absolute_heading = 0
        self.phase = 0
        self.calculated_time = 0
        self.index = 0
        self.rss_compensation = 0
        self.sc_compensation = 0
    }
}

public struct FineLocationTrackingResult: Codable {
    public var mobile_time: Int
    public var building_name: String
    public var level_name: String
    public var scc: Double
    public var x: Double
    public var y: Double
    public var absolute_heading: Double
    public var phase: Int
    public var calculated_time: Double
    public var index: Int
    public var velocity: Double
    public var mode: String
    public var ble_only_position: Bool
    
    public init() {
        self.mobile_time = 0
        self.building_name = ""
        self.level_name = ""
        self.scc = 0
        self.x = 0
        self.y = 0
        self.absolute_heading = 0
        self.phase = 0
        self.calculated_time = 0
        self.index = 0
        self.velocity = 0
        self.mode = ""
        self.ble_only_position = false
    }
}

// On Spot Recognition
struct OnSpotRecognition: Encodable {
    var user_id: String
    var mobile_time: Int
    var rss_compensation: Int
}

public struct OnSpotRecognitionResult: Codable {
    public var mobile_time: Int
    public var building_name: String
    public var level_name: String
    public var linked_level_name: String
    public var spot_id: Int
    public var spot_distance: Double

    public init() {
        self.mobile_time = 0
        self.building_name = ""
        self.level_name = ""
        self.linked_level_name = ""
        self.spot_id = 0
        self.spot_distance = 0
    }
}

// On Spot Authorizationds
struct OnSpotAuthorization: Encodable {
    var user_id: String
    var mobile_time: Int
}


public struct OnSpotAuthorizationResult: Codable {
    public var spots: [Spot]
    
    public init() {
        self.spots = []
    }
}

public struct Spot: Codable {
    public var mobile_time: Int
    public var sector_name: String
    public var building_name: String
    public var level_name: String
    public var spot_id: Int
    public var spot_number: Int
    public var spot_name: String
    public var spot_feature_id: Int
    public var spot_x: Int
    public var spot_y: Int
    public var ccs: Double
    
    public init() {
        self.mobile_time = 0
        self.sector_name = ""
        self.building_name = ""
        self.level_name = ""
        self.spot_id = 0
        self.spot_number = 0
        self.spot_name = ""
        self.spot_feature_id = 0
        self.spot_x = 0
        self.spot_y = 0
        self.ccs = 0
    }
}

// Geo
public struct JupiterGeo: Encodable {
    var sector_id: Int
    var building_name: String
    var level_name: String
}

public struct JupiterGeoResult: Codable {
    var geofences: [[Double]]
    var entrance_area: [[Double]]
    
    public init() {
        self.geofences = [[]]
        self.entrance_area = [[]]
    }
}

// Bias
public struct JupiterBiasGet: Encodable {
    var device_model: String
    var os_version: Int
    var sector_id: Int
}

public struct JupiterDeviceBiasGet: Encodable {
    var device_model: String
    var sector_id: Int
}


public struct JupiterBiasResult: Codable {
    public var rss_compensations: [rss_compensation]
    
    public init() {
        self.rss_compensations = []
    }
}

public struct rss_compensation: Codable {
    public var os_version: Int
    public var rss_compensation: Int
    public var scale_factor: Double
    
    public init() {
        self.os_version = 0
        self.rss_compensation = 0
        self.scale_factor = 1.0
    }
}

public struct JupiterBiasPost: Encodable {
    var device_model: String
    var os_version: Int
    var sector_id: Int
    var rss_compensation: Int
}


// Recent
struct RecentResult: Encodable {
    var user_id: String
    var mobile_time: Int
}

public func decodeOSA(json: String) -> OnSpotAuthorizationResult {
    let result = OnSpotAuthorizationResult.init()
    let decoder = JSONDecoder()
    let jsonString = json

    if let data = jsonString.data(using: .utf8), let decoded = try? decoder.decode(OnSpotAuthorizationResult.self, from: data) {
        return decoded
    }

    return result
}

public func decodeOSR(json: String) -> OnSpotRecognitionResult {
    let result = OnSpotRecognitionResult.init()
    let decoder = JSONDecoder()
    let jsonString = json

    if let data = jsonString.data(using: .utf8), let decoded = try? decoder.decode(OnSpotRecognitionResult.self, from: data) {
        return decoded
    }

    return result
}

public func decodeGEO(json: String) -> JupiterGeoResult {
    let result = JupiterGeoResult.init()
    let decoder = JSONDecoder()
    let jsonString = json

    if let data = jsonString.data(using: .utf8), let decoded = try? decoder.decode(JupiterGeoResult.self, from: data) {
        return decoded
    }

    return result
}

public func decodeRC(json: String) -> JupiterBiasResult {
    let result = JupiterBiasResult.init()
    let decoder = JSONDecoder()
    let jsonString = json

    if let data = jsonString.data(using: .utf8), let decoded = try? decoder.decode(JupiterBiasResult.self, from: data) {
        return decoded
    }

    return result
}


public func CLDtoSD(json: String) -> String {
    let decoder = JSONDecoder()
    let jsonString = json
    if let data = jsonString.data(using: .utf8), let decoded = try? decoder.decode(CoarseLevelDetectionResult.self, from: data) {
        var result = SectorDetectionResult()
        result.mobile_time = decoded.mobile_time
        result.sector_name = decoded.sector_name
        result.calculated_time = decoded.calculated_time
        
        if (result.sector_name != "") {
            let encodedData = try! JSONEncoder().encode(result)
            if let encodedResult: String = String(data: encodedData, encoding: .utf8) {
                return encodedResult
            } else {
                return "Fail"
            }
        }
    }
    return "Fail"
}

public func CLDtoBD(json: String) -> String {
    let decoder = JSONDecoder()

    let jsonString = json

    if let data = jsonString.data(using: .utf8), let decoded = try? decoder.decode(CoarseLevelDetectionResult.self, from: data) {
        var result = BuildingDetectionResult()
        result.mobile_time = decoded.mobile_time
        result.building_name = decoded.building_name
        result.calculated_time = decoded.calculated_time
        
        if (result.building_name != "") {
            let encodedData = try! JSONEncoder().encode(result)
            if let encodedResult: String = String(data: encodedData, encoding: .utf8) {
                return encodedResult
            } else {
                return "Fail"
            }
        }
    }
    return "Fail"
}

public func CLEtoFLD(json: String) -> String {
    let decoder = JSONDecoder()

    let jsonString = json

    if let data = jsonString.data(using: .utf8), let decoded = try? decoder.decode(CoarseLocationEstimationResult.self, from: data) {
        var result = FineLevelDetectionResult()
        
        result.mobile_time = decoded.mobile_time
        result.building_name = decoded.building_name
        result.level_name = decoded.level_name
        result.scc = decoded.scc
        result.scr = decoded.scr
        result.calculated_time = decoded.calculated_time
        
        if (result.building_name != "" && result.level_name != "") {
            let encodedData = try! JSONEncoder().encode(result)
            if let encodedResult: String = String(data: encodedData, encoding: .utf8) {
                return encodedResult
            } else {
                return "Fail"
            }
        }
    }
    return "Fail"
}
