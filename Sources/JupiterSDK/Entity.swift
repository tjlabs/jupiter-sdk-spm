import Foundation

struct UserInfo: Codable {
    var user_id: String
    var device_model: String
    var os_version: Int
}

struct UserLogin: Codable {
    var user_id: String
    var device_model: String
    var os_version: Int
    var sdk_version: String
}

struct SectorInfo: Codable {
    var sector_id: Int
}

struct SectorInfoResult: Codable {
    var building_level: [[String]]
    var entrance_wards: [String]
    var entrance_scales: [[Double]]
}

struct Info: Codable {
    var sector_id: Int
    var operating_system: String
}

public struct InfoResult: Codable {
    var building_level: [[String]]
    var entrances: [Entrance]
    var standard_rss_list: [Int]
    
    init() {
        self.building_level = [[]]
        self.entrances = []
        self.standard_rss_list = []
    }
}

struct Entrance: Codable {
    var entrance_number: Int
    var outermost_ward_id: String
    var entrance_scale: Double
    var entrance_rss: [String: Int]
    
    init() {
        self.entrance_number = 0
        self.outermost_ward_id = ""
        self.entrance_scale = 0
        self.entrance_rss = [String: Int]()
    }
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

public struct TrajectoryInfo {
    public var index: Int = 0
    public var length: Double = 0
    public var heading: Double = 0
    public var velocity: Double = 0
    public var lookingFlag: Bool = false
    public var isIndexChanged: Bool = false
    public var numChannels: Int = 0
    public var scc: Double = 0
    public var userBuilding: String = ""
    public var userLevel: String = ""
    public var userX: Double = 0
    public var userY: Double = 0
    public var userHeading: Double = 0
    public var userPmSuccess: Bool = false
    public var userTuHeading: Double = 0
}

public struct MatchedTraj {
    public var isSuccess: Bool = false
    public var xyd: [Double] = []
    public var minTrajectory: [[Double]] = [[]]
    public var minTrajectoryOriginal: [[Double]] = [[]]
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
    public var mode: String = ""
    public var isPmSuccess: Bool = false
    
    public var level: String = ""
    public var building: String = ""
    
    public var userTrajectory: [[Double]] = [[0, 0]]
    public var trajectoryStartCoord: [Double] = [0, 0]
    public var searchArea: [[Double]] = [[0, 0]]
    public var searchType: Int = 0
    
    public var trajectoryPm: [[Double]] = [[0, 0]]
    public var trajectoryOg: [[Double]] = [[0, 0]]
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
    var normalization_scale: Double
    var device_min_rss: Int
    var standard_min_rss: Int
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
    var search_direction_list: [Int]
    var normalization_scale: Double
    var device_min_rss: Int
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
    var level_name_list: [String]
    var phase: Int
    var search_range: [Int]
    var search_direction_list: [Int]
    var normalization_scale: Double
    var device_min_rss: Int
    var sc_compensation_list: [Double]
    var tail_index: Int
}

public struct FineLocationTrackingListFromServer: Codable {
    public var flt_outputs: [FineLocationTrackingFromServer]
    
    public init() {
        self.flt_outputs = []
    }
}

public struct FineLocationTrackingFromServer: Codable {
    public var mobile_time: Int
    public var building_name: String
    public var level_name: String
    public var scc: Double
    public var x: Double
    public var y: Double
    public var absolute_heading: Double
    public var calculated_time: Double
    public var index: Int
    public var sc_compensation: Double
    public var search_direction: Int
    public var cumulative_length: Double
    public var channel_condition: Bool
    
    public init() {
        self.mobile_time = 0
        self.building_name = ""
        self.level_name = ""
        self.scc = 0
        self.x = 0
        self.y = 0
        self.absolute_heading = 0
        self.calculated_time = 0
        self.index = 0
        self.sc_compensation = 0
        self.search_direction = 0
        self.cumulative_length = 0
        self.channel_condition = false
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
    public var isIndoor: Bool
    public var validity: Bool
    public var validity_flag: Int
    
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
        self.isIndoor = false
        self.validity = false
        self.validity_flag = 0
    }
}

// On Spot Recognition
struct OnSpotRecognition: Encodable {
    var user_id: String
    var mobile_time: Int
    var normalization_scale: Double
    var device_min_rss: Int
    var standard_min_rss: Int
}

public struct OnSpotRecognitionResult: Codable {
    public var mobile_time: Int
    public var building_name: String
    public var level_name: String
    public var linked_level_name: String
    public var spot_id: Int
    public var spot_distance: Double
    public var spot_range: [Int]
    public var spot_direction_down: [Int]
    public var spot_direction_up: [Int]

    public init() {
        self.mobile_time = 0
        self.building_name = ""
        self.level_name = ""
        self.linked_level_name = ""
        self.spot_id = 0
        self.spot_distance = 0
        self.spot_range = []
        self.spot_direction_down = []
        self.spot_direction_up = []
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

struct JupiterMock: Encodable {
    var user_id: String
    var mobile_time: Int
    var sector_id: Int
}

public struct JupiterMockResult: Codable {
    public var FLT: FineLocationTrackingFromServer
    public var OSA: OnSpotAuthorizationResult

    public init() {
        self.FLT = FineLocationTrackingFromServer.init()
        self.OSA = OnSpotAuthorizationResult.init()
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
    var entrance_matching_area: [[Double]]
    var level_change_area: [[Double]]
    
    public init() {
        self.geofences = [[]]
        self.entrance_area = [[]]
        self.entrance_matching_area = [[]]
        self.level_change_area = [[]]
    }
}

// Bias
public struct JupiterParamGet: Encodable {
    var device_model: String
    var os_version: Int
    var sector_id: Int
}

public struct JupiterDeviceParamGet: Encodable {
    var device_model: String
    var sector_id: Int
}


public struct JupiterParamResult: Codable {
    public var rss_compensations: [rss_compensation]
    
    public init() {
        self.rss_compensations = []
    }
}

public struct rss_compensation: Codable {
    public var os_version: Int
    public var rss_compensation: Int
    public var scale_factor: Double
    public var normalization_scale: Double
    
    public init() {
        self.os_version = 0
        self.rss_compensation = 0
        self.scale_factor = 1.0
        self.normalization_scale = 1.0
    }
}

public struct JupiterBiasPost: Encodable {
    var device_model: String
    var os_version: Int
    var sector_id: Int
    var rss_compensation: Int
}

public struct JupiterParamPost: Encodable {
    var device_model: String
    var os_version: Int
    var sector_id: Int
    var normalization_scale: Double
}

// Traj
public struct JupiterTraj: Encodable {
    var sector_id: Int
}

public struct JupiterTrajResult: Codable {
    var trajectory_length: Int
    var trajectory_diagonal: Int
    
    public init() {
        self.trajectory_length = 0
        self.trajectory_diagonal = 0
    }
}

// Debug
public struct MobileDebug: Encodable {
    var sector_id: Int
}

public struct MobileDebugResult: Codable {
    public var sector_debug: Bool
    
    public init() {
        self.sector_debug = false
    }
}

public struct MobileResult: Encodable {
    public var user_id: String
    public var mobile_time: Int
    public var sector_id: Int
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
    public var ble_only_position: Bool
    public var normalization_scale: Double
    public var device_min_rss: Int
    public var sc_compensation: Double
    public var is_indoor: Bool
}

public struct MobileReport: Encodable {
    public var user_id: String
    public var mobile_time: Int
    public var report: Int
}

// Recent
struct RecentResult: Encodable {
    var user_id: String
    var mobile_time: Int
}

public struct RecentResultFromServer: Codable {
    public var mobile_time: Int
    public var building_name: String
    public var level_name: String
    public var scc: Double
    public var x: Double
    public var y: Double
    public var absolute_heading: Double
    public var calculated_time: Double
    public var index: Int
    public var rss_compensation: Int
    public var sc_compensation: Double
    public var cumulative_length: Double
    public var channel_condition: Bool
    
    public init() {
        self.mobile_time = 0
        self.building_name = ""
        self.level_name = ""
        self.scc = 0
        self.x = 0
        self.y = 0
        self.absolute_heading = 0
        self.calculated_time = 0
        self.index = 0
        self.rss_compensation = 0
        self.sc_compensation = 0
        self.cumulative_length = 0
        self.channel_condition = false
    }
}

public struct JupiterToDisplay {
    var x: Double = 0
    var y: Double = 0
    var heading: Double = 0
    var building: String = ""
    var level: String = ""
    var isIndoor: Bool = false
}
