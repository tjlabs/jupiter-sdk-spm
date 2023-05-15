import Foundation
import CoreMotion

public class ServiceManager: Observation {
    var sdkVersion: String = "1.11.32"
    
    func tracking(input: FineLocationTrackingResult, isPast: Bool) {
        for observer in observers {
            let result = input
            if (result.x != 0 && result.y != 0 && result.building_name != "" && result.level_name != "") {
                observer.update(result: result)
                
                if (self.isSaveFlag) {
                    let rsCompensation = self.rssiBias
                    let scCompensation = self.scCompensation
                    
                    let data = MobileResult(user_id: self.user_id, mobile_time: result.mobile_time, sector_id: self.sector_id, building_name: result.building_name, level_name: result.level_name, scc: result.scc, x: result.x, y: result.y, absolute_heading: result.absolute_heading, phase: result.phase, calculated_time: result.calculated_time, index: result.index, velocity: result.velocity, ble_only_position: result.ble_only_position, rss_compensation: rsCompensation, sc_compensation: scCompensation)
                    inputMobileResult.append(data)
                    if ((inputMobileResult.count-1) >= MR_INPUT_NUM) {
                        inputMobileResult.remove(at: 0)
                        NetworkManager.shared.postMobileResult(url: MR_URL, input: inputMobileResult, completion: { [self] statusCode, returnedStrig in
                            if (statusCode != 200) {
                                let localTime = getLocalTimeString()
                                let log: String = localTime + " , (Jupiter) Error : Fail to send mobile result"
                                print(log)
                            }
                        })
                        inputMobileResult = [MobileResult(user_id: "", mobile_time: 0, sector_id: 0, building_name: "", level_name: "", scc: 0, x: 0, y: 0, absolute_heading: 0, phase: 0, calculated_time: 0, index: 0, velocity: 0, ble_only_position: false, rss_compensation: 0, sc_compensation: 0)]
                    }
                }
            }
        }
    }
    
    func reporting(input: Int) {
        for observer in observers {
            observer.report(flag: input)
        }
    }
    
    public var isSaveFlag: Bool = false
    var inputMobileResult: [MobileResult] = [MobileResult(user_id: "", mobile_time: 0, sector_id: 0, building_name: "", level_name: "", scc: 0, x: 0, y: 0, absolute_heading: 0, phase: 0, calculated_time: 0, index: 0, velocity: 0, ble_only_position: false, rss_compensation: 0, sc_compensation: 0)]
    let MR_INPUT_NUM = 20
    
    // 1 ~ 2 : Release  //  0 : Test
    var serverType: Int = 2
    var region: String = "Korea"
    
    let G: Double = 9.81
    
    var user_id: String = ""
    var sector_id: Int = 0
    var sectorIdOrigin: Int = 0
    var service: String = ""
    var mode: String = ""
    var runMode: String = ""
    
    var deviceModel: String = "Unknown"
    var os: String = "Unknown"
    var osVersion: Int = 0
    
    var PathPoint = [String: [[Double]]]()
    var PathMagScale = [String: [Double]]()
    var PathHeading = [String: [String]]()
    var LoadPathPoint = [String: Bool]()
    
    var AbnormalArea = [String: [[Double]]]()
    var EntranceArea = [String: [[Double]]]()
    var PathMatchingArea = [String: [[Double]]]()
    public var isLoadEnd = [String: [Bool]]()
    var isBackground: Bool = false
    
    // ----- Sensor & BLE ----- //
    var sensorData = SensorData()
    public var collectData = CollectData()
    
    let magField = CMMagneticField()
    let motionManager = CMMotionManager()
    let motionAltimeter = CMAltimeter()
    var bleManager = BLECentralManager()
    // ------------------------ //
    
    
    // ----- Spatial Force ----- //
    var magX: Double = 0
    var magY: Double = 0
    var magZ: Double = 0
    var pressure: Double = 0
    var RFD_INPUT_NUM: Int = 7
    // --------------------- //
    
    
    // ----- Mobile Force ----- //
    var mobilePastTime: Int = 0
    var accX: Double = 0
    var accY: Double = 0
    var accZ: Double = 0
    
    var gyroRawX: Double = 0
    var gyroRawY: Double = 0
    var gyroRawZ: Double = 0
    
    var gyroX: Double = 0
    var gyroY: Double = 0
    var gyroZ: Double = 0
    
    var userAccX: Double = 0
    var userAccY: Double = 0
    var userAccZ: Double = 0
    
    var gravX: Double = 0
    var gravY: Double = 0
    var gravZ: Double = 0
    
    var pitch: Double  = 0
    var roll: Double = 0
    var yaw: Double = 0
    
    var UVD_INPUT_NUM: Int = 3
    var VALUE_INPUT_NUM: Int = 5
    var INIT_INPUT_NUM: Int = 3
    // ------------------------ //
    
    
    // ----- Timer ----- //
    var backgroundUpTimer: DispatchSourceTimer?
    var backgroundUvTimer: DispatchSourceTimer?
    var backgroundTaskIdentifier: UIBackgroundTaskIdentifier?
    
    var receivedForceTimer: DispatchSourceTimer?
    var RFD_INTERVAL: TimeInterval = 1/2 // second
    var BLE_VALID_TIME: Double = 1000
    var bleTrimed = [String: [[Double]]]()
    var bleAvg = [String: Double]()
    
    var userVelocityTimer: DispatchSourceTimer?
    var UVD_INTERVAL: TimeInterval = 1/40 // second
    var pastUvdTime: Int = 0
    
    var requestTimer: DispatchSourceTimer?
    var RQ_INTERVAL: TimeInterval = 2 // second
    
    var updateTimer: DispatchSourceTimer?
    var UPDATE_INTERVAL: TimeInterval = 1/5 // second
    
    var osrTimer: DispatchSourceTimer?
    var OSR_INTERVAL: TimeInterval = 2
    var phase2Count: Int = 0
    var isEnterPhase2: Bool = false
    var SCC_FOR_PHASE4: Double = 0.65
    
    let SENSOR_INTERVAL: TimeInterval = 1/100
    var abnormalMagCount: Int = 0
    var magNormQueue = [Double]()
    var isVenusMode: Bool = false
    let ABNORMAL_MAG_THRESHOLD: Double = 2000
    let ABNORMAL_COUNT = 500
    var collectTimer: Timer?
    // ------------------ //
    
    
    // ----- Network ----- //
    var inputReceivedForce: [ReceivedForce] = [ReceivedForce(user_id: "", mobile_time: 0, ble: [:], pressure: 0)]
    var inputUserVelocity: [UserVelocity] = [UserVelocity(user_id: "", mobile_time: 0, index: 0, length: 0, heading: 0, looking: true)]
    var isStartOSA: Bool = false
    // ------------------- //
    
    
    // ----- Fine Location Tracking ----- //
    var bleData: [String: [[Double]]]?
    var unitDRInfo = UnitDRInfo()
    var unitDrInfoIndex: Int = 0
    var unitDRGenerator = UnitDRGenerator()
    var userTrajectory = TrajectoryInfo()
    var userTrajectoryInfo: [TrajectoryInfo] = []
    var phase2Trajectory: [TrajectoryInfo] = []
    var USER_TRAJECTORY_LENGTH_ORIGIN: Double = 60
    var USER_TRAJECTORY_LENGTH: Double = 60
    var USER_TRAJECTORY_DIAGONAL: Double = 200
    var NUM_STRAIGHT_INDEX = 10
    var preTailHeading: Double = 0
    var preTuMmHeading: Double = 0
    
    var unitDistane: Double = 0
    var isStartFlag: Bool = false
    var isStartComplete: Bool = false
    
    var preOutputMobileTime: Int = 0
    var preUnitHeading: Double = 0
    
    public var displayOutput = ServiceResult()
    
    var networkCount: Int = 0
    var isNetworkConnectReported: Bool = false
    var nowTime: Int = 0
    var RECENT_THRESHOLD: Int = 10000 // 2200
    var INDEX_THRESHOLD: Int = 11
    let VALID_BL_CHANGE_TIME = 7000
    
    let DEFAULT_SPOT_DISTANCE: Double = 80
    var lastOsrId: Int = 0
    var buildingLevelChangedTime: Int = 0
    var travelingOsrDistance: Double = 0
    var isDetermineSpot: Bool = false
    
    var isGetFirstResponse: Bool = false
    var indexAfterResponse: Int = 0
    var isPossibleEstBias: Bool = false
    
    var rssiBiasArray: [Int] = [2, 0, 4]
    var rssiBias: Int = 0
    var rssiScale: Double = 1.0
    var isBiasConverged: Bool = false
    var sccBadCount: Int = 0
    var scCompensationArray: [Double] = [0.8, 1.0, 1.2]
    var scCompensation: Double = 1.0
    var scCompensationBadCount: Int = 0
    
    let SCC_THRESHOLD: Double = 0.75
    let SCC_MAX: Double = 0.8
    let BIAS_RANGE_MAX: Int = 10
    let BIAS_RANGE_MIN: Int = -3
    var sccGoodBiasArray = [Int]()
    var biasRequestTime: Int = 0
    var isBiasRequested: Bool = false
    
    var scRequestTime: Int = 0
    var isScRequested: Bool = false
    
    let MINIMUN_INDEX_FOR_BIAS: Int = 30
    let GOOD_BIAS_ARRAY_SIZE: Int = 30
    // --------------------------------- //
    
    
    // ----------- Kalman Filter ------------ //
    var phase: Int = 0
    var indexCurrent: Int = 0
    var indexPast: Int = 0
    
    var indexSend: Int = 0
    var indexReceived: Int = 0
    
    var timeUpdateFlag: Bool = false
    var measurementUpdateFlag: Bool = false
    var isPhaseBreak: Bool = false
    var isNeedTrajInit: Bool = false
    var indexAfterTrajInit: Int = 0
    
    var kalmanP: Double = 1
    var kalmanQ: Double = 0.3
    var kalmanR: Double = 0.5
    var kalmanK: Double = 1
    
    var updateHeading: Double = 0
    var headingKalmanP: Double = 0.5
    var headingKalmanQ: Double = 0.5
    var headingKalmanR: Double = 1
    var headingKalmanK: Double = 1
    
    var pastKalmanP: Double = 1
    var pastKalmanQ: Double = 0.3
    var pastKalmanR: Double = 0.5
    var pastKalmanK: Double = 1
    
    var pastHeadingKalmanP: Double = 0.5
    var pastHeadingKalmanQ: Double = 0.5
    var pastHeadingKalmanR: Double = 1
    var pastHeadingKalmanK: Double = 1
    // ------------------------------------- //
    
    
    var timeUpdatePosition = KalmanOutput()
    var measurementPosition = KalmanOutput()
    
    var timeUpdateOutput = FineLocationTrackingFromServer()
    var measurementOutput = FineLocationTrackingFromServer()
    
    var headingBeforePm: Double = 0
    var currentBuilding: String = ""
    var currentLevel: String = "0F"
    var currentSpot: Int = 0
    
    var buildingBuffer = [String]()
    var levelBuffer = [String]()
    
    var isMapMatching: Bool = false
    var isLoadingPp: Bool = false
    
    var isActiveService: Bool = true
    var isActiveRF: Bool = true
    var isEmptyRF: Bool = false
    var isAnswered: Bool = false
    var isActiveKf: Bool = false
    var isStop: Bool = true
    var isSufficientRfd: Bool = false
    var isBleOff: Bool = false
    
    var timeBleOff: Double = 0
    var timeActiveRF: Double = 0
    var timeActiveUV: Double = 0
    var timeEmptyRF: Double = 0
    var timeRequest: Double = 0
    var timePhaseChange: Double = 0
    var timeSleepRF: Double = 0
    var timeSleepUV: Double = 0
    let STOP_THRESHOLD: Double = 2
    let SLEEP_THRESHOLD: Double = 600
    let SLEEP_THRESHOLD_RF: Double = 6
    let BLE_OFF_THRESHOLD: Double = 4
    
    var lastTrackingTime: Int = 0
    var lastResult = FineLocationTrackingResult()
    
    var SQUARE_RANGE: Double = 10
    let SQUARE_RANGE_SMALL: Double = 10
    let SQUARE_RANGE_LARGE: Double = 20
    
    let HEADING_RANGE: Double = 50
    var pastMatchingResult: [Double] = [0, 0, 0, 0]
    
    let UVD_BUFFER_SIZE = 10
    var uvdIndexBuffer = [Int]()
    var tuResultBuffer = [[Double]]()
    var currentTuResult = FineLocationTrackingResult()
    var pastTuResult = FineLocationTrackingResult()
    var headingBuffer = [Double]()
    var isNeedHeadingCorrection: Bool = false
    let HEADING_BUFFER_SIZE: Int = 10
    
    public var serverResult: [Double] = [0, 0, 0]
    public var timeUpdateResult: [Double] = [0, 0, 0]
    
    let TU_SCALE_VALUE = 0.9
    
    // Output
    var outputResult = FineLocationTrackingResult()
    var resultToReturn = FineLocationTrackingResult()
    var flagPast: Bool = false
    var lastOutputTime: Int = 0
    var pastOutputTime: Int = 0
    var isIndoor: Bool = false
    var timeForInit: Double = 31
    public var TIME_INIT_THRESHOLD: Double = 30
    
    public override init() {
        super.init()
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd-HH-mm-ss"
        dateFormatter.locale = Locale(identifier:"ko_KR")
        let nowDate = Date()
        let localTime = dateFormatter.string(from: nowDate)
        
        deviceModel = UIDevice.modelName
        os = UIDevice.current.systemVersion
        let arr = os.components(separatedBy: ".")
        osVersion = Int(arr[0]) ?? 0
        
        print(localTime + " , (Jupiter) Device Model : \(deviceModel)")
        print(localTime + " , (Jupiter) OS : \(osVersion)")
    }
    
    public func initService() -> (Bool, String) {
        let localTime = getLocalTimeString()
        let log: String = localTime + " , (Jupiter) Success : Service Initalization"
        
        var isSuccess: Bool = true
        var message: String = log
        
        // Init Sensors
        let initSensors = initialzeSensors()
        if (!initSensors.0) {
            isSuccess = initSensors.0
            message = initSensors.1
            
            return (isSuccess, message)
        }
        
        // Init Bluetooth
        let initBle = startBLE()
        if (!initBle.0) {
            isSuccess = initBle.0
            message = initBle.1
            
            return (isSuccess, message)
        }
        
        if (self.service == "FLT") {
            unitDRInfo = UnitDRInfo()
            unitDRGenerator.setMode(mode: mode)
            userTrajectory = TrajectoryInfo()
            
            if (mode == "auto") {
                self.runMode = "dr"
            } else if (mode == "pdr") {
                self.runMode = "pdr"
            } else if (mode == "dr") {
                self.runMode = "dr"
            } else {
                isSuccess = false
                message = localTime + " , (Jupiter) Error : Invalid Service Mode"
                return (isSuccess, message)
            }
            setModeParam(mode: self.runMode, phase: self.phase)
        }
        
        notificationCenterAddOberver()
        return (isSuccess, message)
    }
    
    public func changeRegion(regionName: String) {
        setRegion(regionName: regionName)
        setServerUrl(server: self.serverType)
    }
    
    public func setMinimumTimeForIndoorReport(time: Double) {
        self.TIME_INIT_THRESHOLD = time
        self.timeForInit = time + 1
    }
    
    public func startService(id: String, sector_id: Int, service: String, mode: String, completion: @escaping (Bool, String) -> Void) {
        let localTime = getLocalTimeString()
        let log: String = localTime + " , (Jupiter) Success : Service Initalization"
        
        var isSuccess: Bool = true
        var message: String = log
        
        self.sectorIdOrigin = sector_id
        self.sector_id = sector_id
        
        self.user_id = id
        self.service = service
        self.mode = mode
        
        var countBuildingLevel: Int = 0
        
        var interval: Double = 1/2
        var numInput = 6
        
        // Check Save Flag
        let debugInput = MobileDebug(sector_id: sector_id)
        NetworkManager.shared.postMobileDebug(url: DEBUG_URL, input: debugInput, completion: { [self] statusCode, returnedString in
            if (statusCode == 200) {
                let result = decodeMobileDebug(json: returnedString)
                setSaveFlag(flag: result.sector_debug)
            }
        })
        
        switch(service) {
        case "SD":
            numInput = 3
            interval = 1/2
        case "BD":
            numInput = 3
            interval = 1/2
        case "CLD":
            numInput = 3
            interval = 1/2
        case "FLD":
            numInput = 3
            interval = 1/2
        case "CLE":
            numInput = 6
            interval = 1/2
        case "FLT":
            numInput = 6
            interval = 1/5
        case "OSA":
            numInput = 3
            interval = 1/2
        default:
            let log: String = getLocalTimeString() + " , (Jupiter) Error : Invalid Service Name"
            message = log
            
            completion(false, message)
        }
        
        self.RFD_INPUT_NUM = numInput
        self.RFD_INTERVAL = interval
        
        if (self.isStartFlag) {
            isSuccess = false
            message = getLocalTimeString() + " , (Jupiter) Error : Please stop another service"
            
            completion(isSuccess, message)
        } else {
            self.isStartFlag = true
            let initService = self.initService()
            if (!initService.0) {
                isSuccess = initService.0
                message = initService.1
                self.isStartFlag = false
                completion(isSuccess, message)
            }
        }
        
        setServerUrl(server: self.serverType)
        
        if (self.user_id.isEmpty || self.user_id.contains(" ")) {
            isSuccess = false
            
            let log: String = getLocalTimeString() + " , (Jupiter) Error : User ID(input = \(self.user_id)) cannot be empty or contain space"
            message = log
            self.isStartFlag = false
            completion(isSuccess, message)
        } else {
            // Login Success
            let userInfo = UserInfo(user_id: self.user_id, device_model: deviceModel, os_version: osVersion)
            postUser(url: USER_URL, input: userInfo, completion: { [self] statusCode, returnedString in
                if (statusCode == 200) {
                    let log: String = getLocalTimeString() + " , (Jupiter) Success : User Login"
                    print(log)
                    
                    let sectorInfo = SectorInfo(sector_id: sector_id)
                    postSector(url: SECTOR_URL, input: sectorInfo, completion: { [self] statusCode, returnedString in
                        if (statusCode == 200) {
                            let buildingLevelInfo = jsonToSectorInfoResult(json: returnedString)
                            let buildings_n_levels: [[String]] = buildingLevelInfo.building_level
                            
                            var infoBuilding = [String]()
                            var infoLevel = [String:[String]]()
                            for building in 0..<buildings_n_levels.count {
                                let buildingName: String = buildings_n_levels[building][0]
                                let levelName: String = buildings_n_levels[building][1]
                                
                                // Building
                                if !(infoBuilding.contains(buildingName)) {
                                    infoBuilding.append(buildingName)
                                }
                                
                                // Level
                                if let value = infoLevel[buildingName] {
                                    var levels:[String] = value
                                    levels.append(levelName)
                                    infoLevel[buildingName] = levels
                                } else {
                                    let levels:[String] = [levelName]
                                    infoLevel[buildingName] = levels
                                }
                            }
                            
                            let countAll = countAllValuesInDictionary(infoLevel)
                            
                            self.isMapMatching = true
                            // Key-Value Saved
                            for i in 0..<infoBuilding.count {
                                let buildingName = infoBuilding[i]
                                let levelList = infoLevel[buildingName]
                                for j in 0..<levelList!.count {
                                    let levelName = levelList![j]
                                    let key: String = "\(buildingName)_\(levelName)"
                                    self.LoadPathPoint[key] = true
                                    
                                    let url = self.getPpUrl(server: self.serverType, key: key)
                                    let urlComponents = URLComponents(string: url)
                                    let requestURL = URLRequest(url: (urlComponents?.url)!)
                                    let dataTask = URLSession.shared.dataTask(with: requestURL, completionHandler: { (data, response, error) in
                                        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 500
                                        
                                        if (statusCode == 200) {
                                            if let responseData = data {
                                                if let utf8Text = String(data: responseData, encoding: .utf8) {
                                                    ( self.PathPoint[key], self.PathMagScale[key], self.PathHeading[key] ) = self.parseRoad(data: utf8Text)
                                                    self.isLoadEnd[key] = [true, true]
                                                    
//                                                    print("PathPoint \(key) = \(self.PathPoint[key])")
//                                                    print("PathMagScale \(key) = \(self.PathMagScale[key])")
//                                                    print("PathHeading \(key) = \(self.PathHeading[key])")
                                                    let log: String = getLocalTimeString() + " , (Jupiter) Success : Load \(buildingName) \(levelName) Path-Point"
                                                    print(log)
                                                }
                                            }
                                        } else {
                                            self.isLoadEnd[key] = [true, false]
                                            
                                            let log: String = getLocalTimeString() + " , (Jupiter) Warnings : Load \(buildingName) \(levelName) Path-Point"
                                            print(log)
                                        }
                                    })
                                    dataTask.resume()
                                }
                                
                                for j in 0..<levelList!.count {
                                    let levelName = levelList![j]
                                    let input = JupiterGeo(sector_id: self.sector_id, building_name: buildingName, level_name: levelName)
                                    NetworkManager.shared.postGEO(url: GEO_URL, input: input, completion: { [self] statusCode, returnedString, buildingGeo, levelGeo in
                                        if (statusCode >= 200 && statusCode <= 300) {
                                            let result = decodeGeo(json: returnedString)
                                            let key: String = "\(buildingGeo)_\(levelGeo)"
                                            self.AbnormalArea[key] = result.geofences
                                            self.EntranceArea[key] = result.entrance_area
                                            
                                            countBuildingLevel += 1
                                            
                                            if (countBuildingLevel == countAll) {
                                                if (bleManager.bluetoothReady) {
                                                    // Load Trajectory Info
                                                    let inputGetTraj = JupiterTraj(sector_id: sector_id)
                                                    NetworkManager.shared.postTraj(url: TRAJ_URL, input: inputGetTraj, completion: { [self] statusCode, returnedString in
                                                        if (statusCode == 200) {
                                                            let resultTraj = decodeTraj(json: returnedString)
                                                            self.USER_TRAJECTORY_LENGTH_ORIGIN = Double(resultTraj.trajectory_length + 10)
                                                            self.USER_TRAJECTORY_LENGTH = Double(resultTraj.trajectory_length + 10)
                                                            self.USER_TRAJECTORY_DIAGONAL = Double(resultTraj.trajectory_diagonal)
                                                            
                                                            self.NUM_STRAIGHT_INDEX = Int(ceil(self.USER_TRAJECTORY_LENGTH/6))
                                                            print(getLocalTimeString() + " , (Jupiter) Trajectory Info Load : \(self.USER_TRAJECTORY_LENGTH) // \(self.USER_TRAJECTORY_DIAGONAL) // \(self.NUM_STRAIGHT_INDEX)")
                                                            
                                                            // Load Bias
                                                            let inputGetBias = JupiterBiasGet(device_model: self.deviceModel, os_version: self.osVersion, sector_id: self.sector_id)
                                                            NetworkManager.shared.getJupiterBias(url: RC_URL, input: inputGetBias, completion: { [self] statusCode, returnedString in
                                                                let loadedBias = self.loadRssiBias(sector_id: self.sector_id)
                                                                if (statusCode == 200) {
                                                                    let result = decodeRC(json: returnedString)
                                                                    if (result.rss_compensations.isEmpty) {
                                                                        let inputGetDeviceBias = JupiterDeviceBiasGet(device_model: self.deviceModel, sector_id: self.sector_id)
                                                                        NetworkManager.shared.getJupiterDeviceBias(url: RC_URL, input: inputGetDeviceBias, completion: { [self] statusCode, returnedString in
                                                                            if (statusCode == 200) {
                                                                                let result = decodeRC(json: returnedString)
                                                                                if (result.rss_compensations.isEmpty) {
                                                                                    // Need Bias Estimation
                                                                                    self.rssiBias = loadedBias.0
                                                                                    self.sccGoodBiasArray = loadedBias.1
                                                                                    self.isBiasConverged = loadedBias.2
                                                                                    displayOutput.bias = self.rssiBias
                                                                                    displayOutput.isConverged = self.isBiasConverged
                                                                                    
                                                                                    let biasArray = self.makeRssiBiasArray(bias: loadedBias.0)
                                                                                    self.rssiBiasArray = biasArray
                                                                                    self.isStartComplete = true
                                                                                    
                                                                                    self.startTimer()
                                                                                    
                                                                                    print(localTime + " , (Jupiter) Need Bias Estimation // bias = \(self.rssiBias) , array = \(self.sccGoodBiasArray)")
                                                                                    let log: String = localTime + " , (Jupiter) Success : Service Initalization"
                                                                                    message = log
                                                                                    
                                                                                    completion(true, message)
                                                                                } else {
                                                                                    // Success Load Bias without OS
                                                                                    if let closest = findClosestStructure(to: self.osVersion, in: result.rss_compensations) {
                                                                                        let biasFromServer: rss_compensation = closest
                                                                                        
                                                                                        self.rssiScale = biasFromServer.scale_factor
                                                                                        bleManager.setRssiScale(scale: self.rssiScale)
                                                                                        
                                                                                        if (loadedBias.2) {
                                                                                            self.rssiBias = loadedBias.0
                                                                                            self.sccGoodBiasArray = loadedBias.1
                                                                                            self.isBiasConverged = true
                                                                                            print(localTime + " , (Jupiter) Bias Load (Device // Cache) : \(loadedBias.0)")
                                                                                        } else {
                                                                                            self.rssiBias = biasFromServer.rss_compensation
                                                                                            self.sccGoodBiasArray = loadedBias.1
                                                                                            self.isBiasConverged = false
                                                                                            print(localTime + " , (Jupiter) Bias Load (Device) : \(biasFromServer.rss_compensation)")
                                                                                        }
                                                                                        
                                                                                        displayOutput.bias = self.rssiBias
                                                                                        displayOutput.isConverged = self.isBiasConverged
                                                                                        
                                                                                        let biasArray = self.makeRssiBiasArray(bias: self.rssiBias)
                                                                                        self.rssiBiasArray = biasArray
                                                                                        self.isStartComplete = true
                                                                                        self.startTimer()
                                                                                        
                                                                                        let log: String = localTime + " , (Jupiter) Success : Service Initalization"
                                                                                        message = log
                                                                                        completion(true, message)
                                                                                    } else {
                                                                                        self.rssiBias = loadedBias.0
                                                                                        self.sccGoodBiasArray = loadedBias.1
                                                                                        self.isBiasConverged = loadedBias.2
                                                                                        displayOutput.bias = self.rssiBias
                                                                                        displayOutput.isConverged = self.isBiasConverged
                                                                                        
                                                                                        let biasArray = self.makeRssiBiasArray(bias: loadedBias.0)
                                                                                        self.rssiBiasArray = biasArray
                                                                                        self.isStartComplete = true
                                                                                        self.startTimer()
                                                                                        
                                                                                        let log: String = localTime + " , (Jupiter) Success : Service Initalization"
                                                                                        message = log
                                                                                        completion(true, message)
                                                                                    }
                                                                                }
                                                                            } else {
                                                                                let log: String = getLocalTimeString() + " , (Jupiter) Error : Bias Load (Device)"
                                                                                message = log
                                                                                
                                                                                isSuccess = false
                                                                                self.stopTimer()
                                                                                self.isStartFlag = false
                                                                                NotificationCenter.default.removeObserver(self)
                                                                                completion(isSuccess, message)
                                                                            }
                                                                        })
                                                                    } else {
                                                                        // Succes Load Bias
                                                                        let biasFromServer: rss_compensation = result.rss_compensations[0]
                                                                        
                                                                        self.rssiScale = biasFromServer.scale_factor
                                                                        bleManager.setRssiScale(scale: self.rssiScale)
                                                                        
                                                                        if (loadedBias.2) {
                                                                            self.rssiBias = loadedBias.0
                                                                            self.sccGoodBiasArray = loadedBias.1
                                                                            print(getLocalTimeString() + " , (Jupiter) Bias Load (Device & OS // Cache) : \(loadedBias.0)")
                                                                        } else {
                                                                            self.rssiBias = biasFromServer.rss_compensation
                                                                            self.sccGoodBiasArray = loadedBias.1
                                                                            print(getLocalTimeString() + " , (Jupiter) Bias Load (Device & OS) : \(biasFromServer.rss_compensation)")
                                                                        }
                                                                        self.isBiasConverged = true
                                                                        
                                                                        displayOutput.bias = self.rssiBias
                                                                        displayOutput.isConverged = self.isBiasConverged
                                                                        
                                                                        let biasArray = self.makeRssiBiasArray(bias: self.rssiBias)
                                                                        self.rssiBiasArray = biasArray
                                                                        self.isStartComplete = true
                                                                        self.startTimer()
                                                                        
                                                                        let log: String = localTime + " , (Jupiter) Success : Service Initalization"
                                                                        message = log
                                                                        completion(true, message)
                                                                    }
                                                                } else {
                                                                    let log: String = getLocalTimeString() + " , (Jupiter) Error : Load Bias"
                                                                    message = log
                                                                    
                                                                    isSuccess = false
                                                                    self.stopTimer()
                                                                    self.isStartFlag = false
                                                                    NotificationCenter.default.removeObserver(self)
                                                                    completion(isSuccess, message)
                                                                }
                                                            })
                                                        } else {
                                                            let log: String = getLocalTimeString() + " , (Jupiter) Error : Load Trajectory Info"
                                                            message = log
                                                            
                                                            isSuccess = false
                                                            self.stopTimer()
                                                            self.isStartFlag = false
                                                            NotificationCenter.default.removeObserver(self)
                                                            completion(isSuccess, message)
                                                        }
                                                    })
                                                } else {
                                                    let log: String = getLocalTimeString() + " , (Jupiter) Error : Bluetooth is not enabled"
                                                    message = log
                                                    self.stopTimer()
                                                    self.isStartFlag = false
                                                    NotificationCenter.default.removeObserver(self)
                                                    completion(false, message)
                                                }
                                            }
                                        } else {
                                            isSuccess = false
                                            self.stopTimer()
                                            if (!NetworkCheck.shared.isConnectedToInternet()) {
                                                isSuccess = false
                                                let log: String = getLocalTimeString() + " , (Jupiter) Error : Network is not connected"
                                                message = log
                                                self.isStartFlag = false
                                                NotificationCenter.default.removeObserver(self)
                                                completion(isSuccess, message)
                                            } else {
                                                let log: String = getLocalTimeString() + " , (Jupiter) Error : Load Abnormal Area"
                                                message = log
                                                self.isStartFlag = false
                                                NotificationCenter.default.removeObserver(self)
                                                completion(isSuccess, message)
                                            }
                                        }
                                    })
                                    
                                    let keyPathMatching: String = "\(buildingName)_\(levelName)"
                                    self.PathMatchingArea[keyPathMatching] = self.loadPathMatchingArea(buildingName: buildingName, levelName: levelName)
                                }
                            }
                        } else {
                            isSuccess = false
                            self.stopTimer()
                            if (!NetworkCheck.shared.isConnectedToInternet()) {
                                isSuccess = false
                                let log: String = getLocalTimeString() + " , (Jupiter) Error : Network is not connected"
                                message = log
                                self.isStartFlag = false
                                NotificationCenter.default.removeObserver(self)
                                completion(isSuccess, message)
                            } else {
                                let log: String = getLocalTimeString() + " , (Jupiter) Error : Load Building & Level Information"
                                message = log
                                self.isStartFlag = false
                                NotificationCenter.default.removeObserver(self)
                                completion(isSuccess, message)
                            }
                        }
                    })
                } else {
                    isSuccess = false
                    
                    self.stopTimer()
                    if (!NetworkCheck.shared.isConnectedToInternet()) {
                        isSuccess = false
                        let log: String = getLocalTimeString() + " , (Jupiter) Error : Network is not connected"
                        message = log
                        self.isStartFlag = false
                        NotificationCenter.default.removeObserver(self)
                        completion(isSuccess, message)
                    } else {
                        let log: String = getLocalTimeString() + " , (Jupiter) Error : User Login"
                        message = log
                        self.isStartFlag = false
                        NotificationCenter.default.removeObserver(self)
                        completion(isSuccess, message)
                    }
                }
            })
        }
    }
    
    func findClosestStructure(to myOsVersion: Int, in array: [rss_compensation]) -> rss_compensation? {
        guard let first = array.first else {
            return nil
        }
        var closest = first
        var closestDistance = closest.os_version - myOsVersion
        for d in array {
            let distance = d.os_version - myOsVersion
            if abs(distance) < abs(closestDistance) {
                closest = d
                closestDistance = distance
            }
        }
        return closest
    }
    
    public func setSaveFlag(flag: Bool) {
        self.isSaveFlag = flag
        print(getLocalTimeString() + " , (Jupiter) Set Save Flag : \(self.isSaveFlag)")
    }
    
    
    public func setServerUrl(server: Int) {
        switch (server) {
        case 0:
            SERVER_TYPE = "-t"
        case 1:
            SERVER_TYPE = ""
        case 2:
            SERVER_TYPE = "-2"
        default:
            SERVER_TYPE = ""
        }
        
        BASE_URL = CALC_URL + SERVER_TYPE + REGION + "/"
        setBaseURL(url: BASE_URL)
    }
    
    func getPpUrl(server: Int, key: String) -> String {
        var url = "https://storage.googleapis.com/\(IMAGE_URL)/ios/pp/\(self.sectorIdOrigin)/\(key).csv"
        
        switch (server) {
        case 0:
            url = "https://storage.googleapis.com/\(IMAGE_URL)/ios/pp-test/\(self.sectorIdOrigin)/\(key).csv"
        case 1:
            url = "https://storage.googleapis.com/\(IMAGE_URL)/ios/pp/\(self.sectorIdOrigin)/\(key).csv"
        case 2:
            url = "https://storage.googleapis.com/\(IMAGE_URL)/ios/pp-2/\(self.sectorIdOrigin)/\(key).csv"
        default:
            url = "https://storage.googleapis.com/\(IMAGE_URL)/ios/pp/\(self.sectorIdOrigin)/\(key).csv"
        }
        
        return url
    }
    
    public func stopService() -> (Bool, String) {
        let localTime: String = getLocalTimeString()
        var message: String = localTime + " , (Jupiter) Success : Stop Service"
        
        if (self.isStartComplete) {
            NotificationCenter.default.removeObserver(self)
            
            self.stopTimer()
            self.stopBLE()
            
            if (self.service == "FLT") {
                unitDRInfo = UnitDRInfo()
                userTrajectory = TrajectoryInfo()
                saveRssiBias(bias: self.rssiBias, biasArray: self.sccGoodBiasArray, isConverged: self.isBiasConverged, sector_id: self.sector_id)
            }
            
            self.initVariables()
            self.isStartFlag = false
            self.isStartComplete = false
            displayOutput.phase = String(0)
            self.isMapMatching = false
            
            return (true, message)
        } else {
            message = localTime + " , (Jupiter) Fail : After the service has fully started, it can be stop "
            return (false, message)
        }
    }
    
    public func enterBackground() {
        if (!self.isBackground) {
            let localTime = getLocalTimeString()
            
            self.isBackground = true
            self.bleManager.stopScan()
            self.stopTimer()
            backgroundTaskIdentifier = .invalid
            backgroundTaskIdentifier = UIApplication.shared.beginBackgroundTask(withName: "BackgroundOutputTimer") {
                UIApplication.shared.endBackgroundTask(self.backgroundTaskIdentifier!)
                self.backgroundTaskIdentifier = .invalid
            }
            
            self.backgroundUpTimer = DispatchSource.makeTimerSource(queue: DispatchQueue.global())
            self.backgroundUpTimer!.schedule(deadline: .now(), repeating: UPDATE_INTERVAL)
            self.backgroundUpTimer!.setEventHandler(handler: self.outputTimerUpdate)
            self.backgroundUpTimer!.resume()
            
            self.backgroundUvTimer = DispatchSource.makeTimerSource(queue: DispatchQueue.global())
            self.backgroundUvTimer!.schedule(deadline: .now(), repeating: UVD_INTERVAL)
            self.backgroundUvTimer!.setEventHandler(handler: self.userVelocityTimerUpdate)
            self.backgroundUvTimer!.resume()
            
            self.bleTrimed = [String: [[Double]]]()
            self.bleAvg = [String: Double]()
            self.reporting(input: BACKGROUND_FLAG)
        }
    }
    
    public func enterForeground() {
        if (self.isBackground) {
            let localTime = getLocalTimeString()
            self.isBackground = false
            self.bleManager.startScan(option: .Foreground)
            
            if backgroundTaskIdentifier != .invalid {
                UIApplication.shared.endBackgroundTask(backgroundTaskIdentifier!)
                backgroundTaskIdentifier = .invalid
            }
            self.backgroundUpTimer?.cancel()
            self.backgroundUpTimer = nil
            
            self.backgroundUvTimer?.cancel()
            self.backgroundUvTimer = nil
            
            self.startTimer()
            self.reporting(input: FOREGROUND_FLAG)
        }
    }
    
    private func initVariables() {
        self.timeForInit = 0
        
        self.inputReceivedForce = [ReceivedForce(user_id: user_id, mobile_time: 0, ble: [:], pressure: 0)]
        self.inputUserVelocity = [UserVelocity(user_id: user_id, mobile_time: 0, index: 0, length: 0, heading: 0, looking: true)]
        self.indexAfterResponse = 0
        self.lastOsrId = 0
        self.phase = 0
        
        self.isGetFirstResponse = false
        
        self.isActiveKf = false
        self.updateHeading = 0
        self.timeUpdateFlag = false
        self.measurementUpdateFlag = false
        self.timeUpdatePosition = KalmanOutput()
        self.measurementPosition = KalmanOutput()
        
        self.timeUpdateOutput = FineLocationTrackingFromServer()
        self.measurementOutput = FineLocationTrackingFromServer()
    }
    
    func notificationCenterAddOberver() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.onDidReceiveNotification), name: .didEnterBackground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.onDidReceiveNotification), name: .didBecomeActive, object: nil)
    }
    
    public func initCollect() {
        unitDRGenerator.setMode(mode: "pdr")
        
        initialzeSensors()
        startBLE()
        startCollectTimer()
    }
    
    public func startCollect() {
        isStartFlag = true
    }
    
    public func stopCollect() {
        stopCollectTimer()
        stopBLE()
        
        isStartFlag = false
    }
    
    public func getResult(completion: @escaping (Int, String) -> Void) {
        let currentTime: Int = getCurrentTimeInMilliseconds()
        
        switch(self.service) {
        case "SD":
            let input = CoarseLevelDetection(user_id: self.user_id, mobile_time: currentTime)
            NetworkManager.shared.postCLD(url: CLD_URL, input: input, completion: { statusCode, returnedString in
                let sdString = CLDtoSD(json: returnedString)
                completion(statusCode, sdString)
            })
        case "BD":
            let input = CoarseLevelDetection(user_id: self.user_id, mobile_time: currentTime)
            NetworkManager.shared.postCLD(url: CLD_URL, input: input, completion: { statusCode, returnedString in
                let bdString = CLDtoBD(json: returnedString)
                completion(statusCode, bdString)
            })
        case "CLD":
            let input = CoarseLevelDetection(user_id: self.user_id, mobile_time: currentTime)
            NetworkManager.shared.postCLD(url: CLD_URL, input: input, completion: { statusCode, returnedString in
                completion(statusCode, returnedString)
            })
        case "FLD":
            let input = CoarseLocationEstimation(user_id: self.user_id, mobile_time: currentTime, sector_id: self.sector_id, search_direction_list: [0, 90, 180, 270])
            NetworkManager.shared.postCLE(url: CLE_URL, input: input, completion: { statusCode, returnedString in
                let fldString = CLEtoFLD(json: returnedString)
                completion(statusCode, fldString)
            })
        case "CLE":
            let input = CoarseLocationEstimation(user_id: self.user_id, mobile_time: currentTime, sector_id: self.sector_id, search_direction_list: [0, 90, 180, 270])
            NetworkManager.shared.postCLE(url: CLE_URL, input: input, completion: { statusCode, returnedString in
                completion(statusCode, returnedString)
            })
        case "OSA":
            let input = OnSpotAuthorization(user_id: self.user_id, mobile_time: currentTime)
            NetworkManager.shared.postOSA(url: OSA_URL, input: input, completion: { statusCode, returnedString in
                completion(statusCode, returnedString)
            })
        default:
            completion(500, "(Jupiter) Error : Invalid Service Name")
        }
    }
    
    public func getSpotResult(completion: @escaping (Int, String) -> Void) {
        let currentTime: Int = getCurrentTimeInMilliseconds()
        
        if (self.user_id != "") {
            let input = OnSpotAuthorization(user_id: self.user_id, mobile_time: currentTime)
            NetworkManager.shared.postOSA(url: OSA_URL, input: input, completion: { statusCode, returnedString in
                completion(statusCode, returnedString)
            })
        } else {
            completion(500, " , (Jupiter) Error : Invalid User ID")
        }
    }
    
    public func getRecentResult(id: String, completion: @escaping (Int, String) -> Void) {
        let currentTime: Int = getCurrentTimeInMilliseconds()
        let input = RecentResult(user_id: id, mobile_time: currentTime)
        NetworkManager.shared.postRecent(url: RECENT_URL, input: input, completion: { statusCode, returnedString in
            completion(statusCode, returnedString)
        })
    }
    
    internal func initialzeSensors() -> (Bool, String) {
        var isSuccess: Bool = false
        var message: String = ""
        
        var sensorActive: Int = 0
        if motionManager.isAccelerometerAvailable {
            sensorActive += 1
            motionManager.accelerometerUpdateInterval = SENSOR_INTERVAL
            motionManager.startAccelerometerUpdates(to: .main) { [self] (data, error) in
                if let accX = data?.acceleration.x {
                    self.accX = -accX
                    sensorData.acc[0] = -accX*G
                    collectData.acc[0] = -accX*G
                }
                if let accY = data?.acceleration.y {
                    self.accY = -accY
                    sensorData.acc[1] = -accY*G
                    collectData.acc[1] = -accY*G
                }
                if let accZ = data?.acceleration.z {
                    self.accZ = -accZ
                    sensorData.acc[2] = -accZ*G
                    collectData.acc[2] = -accZ*G
                }
            }
        } else {
            let localTime: String = getLocalTimeString()
            let log: String = localTime + " , (Jupiter) Error : Fail to initialize accelerometer"
            print(log)
        }
        
        if motionManager.isGyroAvailable {
            sensorActive += 1
            motionManager.gyroUpdateInterval = SENSOR_INTERVAL
            motionManager.startGyroUpdates(to: .main) { [self] (data, error) in
                if let gyroX = data?.rotationRate.x {
                    self.gyroRawX = gyroX
                }
                if let gyroY = data?.rotationRate.y {
                    self.gyroRawY = gyroY
                }
                if let gyroZ = data?.rotationRate.z {
                    self.gyroRawZ = gyroZ
                }
            }
        } else {
            let localTime: String = getLocalTimeString()
            let log: String = localTime + " , (Jupiter) Error : Fail to initialize gyroscope"
            print(log)
        }
        
        
        if motionManager.isMagnetometerAvailable {
            sensorActive += 1
            // Uncalibrated
            motionManager.magnetometerUpdateInterval = SENSOR_INTERVAL
            motionManager.startMagnetometerUpdates(to: .main) { [self] (data, error) in
                if let magX = data?.magneticField.x {
                    self.magX = magX
                    sensorData.mag[0] = magX
                    collectData.mag[0] = magX
                }
                if let magY = data?.magneticField.y {
                    self.magY = magY
                    sensorData.mag[1] = magY
                    collectData.mag[1] = magY
                }
                if let magZ = data?.magneticField.z {
                    self.magZ = magZ
                    sensorData.mag[2] = magZ
                    collectData.mag[2] = magZ
                }
                let norm = sqrt(self.magX*self.magX + self.magY*self.magY + self.magZ*self.magZ)
                if (norm > ABNORMAL_MAG_THRESHOLD || norm == 0) {
                    self.abnormalMagCount += 1
                } else {
                    self.abnormalMagCount = 0
                }
                
                if (self.abnormalMagCount >= ABNORMAL_COUNT) {
                    self.abnormalMagCount = ABNORMAL_COUNT
                    if (!self.isVenusMode && self.runMode == "dr") {
                        self.isVenusMode = true
                        self.phase = 1
                        self.isPossibleEstBias = false
                        self.rssiBias = 0
                        
                        self.isActiveKf = false
                        self.timeUpdateFlag = false
                        self.measurementUpdateFlag = false
                        self.timeUpdatePosition = KalmanOutput()
                        self.measurementPosition = KalmanOutput()
                        
                        self.timeUpdateOutput = FineLocationTrackingFromServer()
                        self.measurementOutput = FineLocationTrackingFromServer()
                        self.reporting(input: VENUS_FLAG)
                    }
                } else {
                    if (self.isVenusMode) {
                        self.isVenusMode = false
                        self.reporting(input: JUPITER_FLAG)
                    }
                }
            }
        } else {
            let localTime: String = getLocalTimeString()
            let log: String = localTime + " , (Jupiter) Error : Fail to initialize magnetometer\n"
            print(log)
        }
        
        if CMAltimeter.isRelativeAltitudeAvailable() {
            sensorActive += 1
            motionAltimeter.startRelativeAltitudeUpdates(to: .main) { [self] (data, error) in
                if let pressure = data?.pressure {
                    let pressure_: Double = Double(pressure)*10
                    self.pressure = pressure_
                    sensorData.pressure[0] = pressure_
                    collectData.pressure[0] = pressure_
                }
            }
        } else {
            let localTime: String = getLocalTimeString()
            let log: String = localTime + " , (Jupiter) Error : Fail to initialize pressure sensor"
            print(log)
        }
        
        if motionManager.isDeviceMotionAvailable {
            sensorActive += 1
            motionManager.deviceMotionUpdateInterval = SENSOR_INTERVAL
            motionManager.startDeviceMotionUpdates(to: .main) { [self] (motion, error) in
                if let m = motion {
                    self.userAccX = -m.userAcceleration.x
                    self.userAccY = -m.userAcceleration.y
                    self.userAccZ = -m.userAcceleration.z
                    
                    self.gravX = m.gravity.x
                    self.gravY = m.gravity.y
                    self.gravZ = m.gravity.z
                    
                    self.roll = m.attitude.roll
                    self.pitch = m.attitude.pitch
                    self.yaw = m.attitude.yaw
                    
                    // Calibrated Gyro
                    sensorData.gyro[0] = m.rotationRate.x
                    sensorData.gyro[1] = m.rotationRate.y
                    sensorData.gyro[2] = m.rotationRate.z
                    
                    collectData.gyro[0] = m.rotationRate.x
                    collectData.gyro[1] = m.rotationRate.y
                    collectData.gyro[2] = m.rotationRate.z
                    
                    sensorData.userAcc[0] = -m.userAcceleration.x*G
                    sensorData.userAcc[1] = -m.userAcceleration.y*G
                    sensorData.userAcc[2] = -m.userAcceleration.z*G
                    
                    collectData.userAcc[0] = -m.userAcceleration.x*G
                    collectData.userAcc[1] = -m.userAcceleration.y*G
                    collectData.userAcc[2] = -m.userAcceleration.z*G
                    
                    sensorData.att[0] = m.attitude.roll
                    sensorData.att[1] = m.attitude.pitch
                    sensorData.att[2] = m.attitude.yaw
                    
                    collectData.att[0] = m.attitude.roll
                    collectData.att[1] = m.attitude.pitch
                    collectData.att[2] = m.attitude.yaw
                    
                    sensorData.rotationMatrix[0][0] = m.attitude.rotationMatrix.m11
                    sensorData.rotationMatrix[0][1] = m.attitude.rotationMatrix.m12
                    sensorData.rotationMatrix[0][2] = m.attitude.rotationMatrix.m13
                    
                    sensorData.rotationMatrix[1][0] = m.attitude.rotationMatrix.m21
                    sensorData.rotationMatrix[1][1] = m.attitude.rotationMatrix.m22
                    sensorData.rotationMatrix[1][2] = m.attitude.rotationMatrix.m23
                    
                    sensorData.rotationMatrix[2][0] = m.attitude.rotationMatrix.m31
                    sensorData.rotationMatrix[2][1] = m.attitude.rotationMatrix.m32
                    sensorData.rotationMatrix[2][2] = m.attitude.rotationMatrix.m33
                    
                    collectData.rotationMatrix[0][0] = m.attitude.rotationMatrix.m11
                    collectData.rotationMatrix[0][1] = m.attitude.rotationMatrix.m12
                    collectData.rotationMatrix[0][2] = m.attitude.rotationMatrix.m13
                    
                    collectData.rotationMatrix[1][0] = m.attitude.rotationMatrix.m21
                    collectData.rotationMatrix[1][1] = m.attitude.rotationMatrix.m22
                    collectData.rotationMatrix[1][2] = m.attitude.rotationMatrix.m23
                    
                    collectData.rotationMatrix[2][0] = m.attitude.rotationMatrix.m31
                    collectData.rotationMatrix[2][1] = m.attitude.rotationMatrix.m32
                    collectData.rotationMatrix[2][2] = m.attitude.rotationMatrix.m33
                    
                    collectData.quaternion[0] = m.attitude.quaternion.x
                    collectData.quaternion[1] = m.attitude.quaternion.y
                    collectData.quaternion[2] = m.attitude.quaternion.z
                    collectData.quaternion[3] = m.attitude.quaternion.w
                }
            }
        } else {
            let localTime: String = getLocalTimeString()
            let log: String = localTime + " , (Jupiter) Error : Fail to initialize motion sensor"
            print(log)
        }
        
        let localTime: String = getLocalTimeString()
        if (sensorActive >= 5) {
            let log: String = localTime + " , (Jupiter) Success : Sensor Initialization"
            
            isSuccess = true
            message = log
        } else {
            let log: String = localTime + " , (Jupiter) Error : Sensor is not available"
            
            isSuccess = false
            message = log
        }
        
        return (isSuccess, message)
    }
    
    func startBLE() -> (Bool, String) {
        let localTime: String = getLocalTimeString()
        
        let isSuccess: Bool = true
        let message: String = localTime + " , (Jupiter) Success : Bluetooth Initialization"
        
        bleManager.setValidTime(mode: self.runMode)
        bleManager.startScan(option: .Foreground)
        
        return (isSuccess, message)
    }
    
    
    func stopBLE() {
        bleManager.stopScan()
    }
    
    func startTimer() {
        if (self.requestTimer == nil) {
            let queueRFD = DispatchQueue(label: Bundle.main.bundleIdentifier! + ".receivedForceTimer")
            self.receivedForceTimer = DispatchSource.makeTimerSource(queue: queueRFD)
            self.receivedForceTimer!.schedule(deadline: .now(), repeating: RFD_INTERVAL)
            self.receivedForceTimer!.setEventHandler(handler: self.receivedForceTimerUpdate)
            self.receivedForceTimer!.resume()
        }
        
        if (self.userVelocityTimer == nil) {
            let queueUVD = DispatchQueue(label: Bundle.main.bundleIdentifier! + ".userVelocityTimer")
            self.userVelocityTimer = DispatchSource.makeTimerSource(queue: queueUVD)
            self.userVelocityTimer!.schedule(deadline: .now(), repeating: UVD_INTERVAL)
            self.userVelocityTimer!.setEventHandler(handler: self.userVelocityTimerUpdate)
            self.userVelocityTimer!.resume()
        }
        
        
        if (self.requestTimer == nil) {
            let queueRQ = DispatchQueue(label: Bundle.main.bundleIdentifier! + ".requestTimer")
            self.requestTimer = DispatchSource.makeTimerSource(queue: queueRQ)
            self.requestTimer!.schedule(deadline: .now(), repeating: RQ_INTERVAL)
            self.requestTimer!.setEventHandler(handler: self.requestTimerUpdate)
            self.requestTimer!.resume()
        }
        
        
        if (self.updateTimer == nil) {
            let queueUP = DispatchQueue(label: Bundle.main.bundleIdentifier! + ".updateTimer")
            self.updateTimer = DispatchSource.makeTimerSource(queue: queueUP)
            self.updateTimer!.schedule(deadline: .now(), repeating: UPDATE_INTERVAL)
            self.updateTimer!.setEventHandler(handler: self.outputTimerUpdate)
            self.updateTimer!.resume()
        }
        
        
        if (self.osrTimer == nil) {
            let queueOSR = DispatchQueue(label: Bundle.main.bundleIdentifier! + ".osrTimer")
            self.osrTimer = DispatchSource.makeTimerSource(queue: queueOSR)
            self.osrTimer!.schedule(deadline: .now(), repeating: OSR_INTERVAL)
            self.osrTimer!.setEventHandler(handler: self.osrTimerUpdate)
            self.osrTimer!.resume()
        }
    }
    
    func stopTimer() {
        self.receivedForceTimer?.cancel()
        self.userVelocityTimer?.cancel()
        self.osrTimer?.cancel()
        self.requestTimer?.cancel()
        self.updateTimer?.cancel()
        
        self.receivedForceTimer = nil
        self.userVelocityTimer = nil
        self.osrTimer = nil
        self.requestTimer = nil
        self.updateTimer = nil
    }
    
    func enterSleepMode() {
        let localTime: String = getLocalTimeString()
        print(localTime + " , (Jupiter) Enter Sleep Mode")
        self.updateTimer?.cancel()
        self.updateTimer = nil
    }
    
    func wakeUpFromSleepMode() {
        if (self.service == "FLT") {
            if (self.updateTimer == nil && !self.isBackground) {
                let queue = DispatchQueue(label: Bundle.main.bundleIdentifier! + ".updateTimer")
                self.updateTimer = DispatchSource.makeTimerSource(queue: queue)
                self.updateTimer!.schedule(deadline: .now(), repeating: UPDATE_INTERVAL)
                self.updateTimer!.setEventHandler(handler: self.outputTimerUpdate)
                self.updateTimer!.resume()
            }
        }
    }
    
    func startCollectTimer() {
        if (self.collectTimer == nil) {
            self.collectTimer = Timer.scheduledTimer(timeInterval: UVD_INTERVAL, target: self, selector: #selector(self.collectTimerUpdate), userInfo: nil, repeats: true)
            RunLoop.current.add(self.collectTimer!, forMode: .common)
        }
    }
    
    func stopCollectTimer() {
        if (collectTimer != nil) {
            collectTimer!.invalidate()
            collectTimer = nil
        }
    }
    
    @objc func outputTimerUpdate() {
        if (self.isActiveService) {
            let currentTime = getCurrentTimeInMilliseconds()
            
            var resultToReturn = self.resultToReturn
            resultToReturn.mobile_time = currentTime
            resultToReturn.ble_only_position = self.isVenusMode
            resultToReturn.isIndoor = self.isIndoor
            
            self.tracking(input: resultToReturn, isPast: self.flagPast)
            self.lastOutputTime = currentTime
        }
    }
    
    func makeOutputResult(input: FineLocationTrackingResult, isPast: Bool, runMode: String, isVenusMode: Bool) -> FineLocationTrackingResult {
        var result = input
        if (result.x != 0 && result.y != 0 && result.building_name != "" && result.level_name != "") {
            result.index = self.unitDrInfoIndex
            result.absolute_heading = compensateHeading(heading: result.absolute_heading, mode: runMode)
            result.mode = runMode
            
            displayOutput.phase = String(result.phase)
            displayOutput.mode = runMode
            displayOutput.scc = result.scc
            
            let buildingName: String = result.building_name
            let levelName: String = self.removeLevelDirectionString(levelName: result.level_name)
            
            // Map Matching
            if (self.isMapMatching) {
                var mapMatchingMode: String = runMode
                if (isVenusMode) {
                    mapMatchingMode = "pdr"
                }
                self.headingBeforePm = result.absolute_heading
                let correctResult = pathMatching(building: buildingName, level: levelName, x: result.x, y: result.y, heading: result.absolute_heading, tuXY: [0,0], mode: mapMatchingMode, isPast: isPast, HEADING_RANGE: self.HEADING_RANGE)
                
                if (correctResult.isSuccess) {
                    displayOutput.isPmSuccess = true
                    result.x = correctResult.xyh[0]
                    result.y = correctResult.xyh[1]
                    result.absolute_heading = correctResult.xyh[2]
                } else {
                    displayOutput.isPmSuccess = false
                    let localTime: String = getLocalTimeString()
                    
                    let key: String = "\(buildingName)_\(levelName)"
                    
                    var isLoadPathPoint: Bool = true
                    if let isLoad: Bool = self.LoadPathPoint[key] { isLoadPathPoint = isLoad }
                    if let mainRoad: [[Double]] = self.PathPoint[key] {
                        self.LoadPathPoint[key] = true
                    } else {
                        if (isLoadPathPoint) {
                            self.LoadPathPoint[key] = false
                            let url = self.getPpUrl(server: self.serverType, key: key)
                            
                            let urlComponents = URLComponents(string: url)
                            let requestURL = URLRequest(url: (urlComponents?.url)!)
                            let dataTask = URLSession.shared.dataTask(with: requestURL, completionHandler: { (data, response, error) in
                                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 500
                                if (statusCode == 200) {
                                    if let responseData = data {
                                        if let utf8Text = String(data: responseData, encoding: .utf8) {
                                            ( self.PathPoint[key], self.PathMagScale[key], self.PathHeading[key] ) = self.parseRoad(data: utf8Text)
                                            self.LoadPathPoint[key] = true
                                            let log: String = localTime + " , (Jupiter) Success : Load \(buildingName) \(levelName) Path-Point (when PP was empty)"
                                            print(log)
                                        }
                                    }
                                } else {
                                    let log: String = localTime + " , (Jupiter) Warnings : Load \(buildingName) \(levelName) Path-Point (When Pp was empty)"
                                    print(log)
                                }
                            })
                            dataTask.resume()
                        }
                    }
                    
                    if (self.isActiveKf) {
                        result = self.lastResult
                    } else {
                        let correctResult = pathMatching(building: result.building_name, level: result.level_name, x: result.x, y: result.y, heading: result.absolute_heading, tuXY: [0,0], mode: "pdr", isPast: isPast, HEADING_RANGE: self.HEADING_RANGE)
                        if (correctResult.isSuccess) {
                            result.x = correctResult.xyh[0]
                            result.y = correctResult.xyh[1]
                            result.absolute_heading = correctResult.xyh[2]
                        } else {
                            result.x = 0
                            result.y = 0
                        }
                    }
                }
            }
            
            result.level_name = removeLevelDirectionString(levelName: result.level_name)
            result.velocity = round(result.velocity*100)/100
            if (isVenusMode) {
                result.phase = 1
            }
            self.lastResult = result
            
            displayOutput.heading = result.absolute_heading
            displayOutput.building = result.building_name
            displayOutput.level = result.level_name
        }
        
        return result
    }
    
    @objc func receivedForceTimerUpdate() {
        let localTime: String = getLocalTimeString()
        if (!bleManager.bluetoothReady) {
            self.timeBleOff += RFD_INTERVAL
            if (self.timeBleOff >= BLE_OFF_THRESHOLD) {
                if (!self.isBleOff) {
                    self.isBleOff = true
                    self.timeBleOff = 0
                    self.reporting(input: BLE_OFF_FLAG)
                }
            }
        }
        
        bleManager.setValidTime(mode: self.runMode)
        self.setValidTime(mode: self.runMode)
        let validTime = self.BLE_VALID_TIME
        let currentTime = getCurrentTimeInMilliseconds() - (Int(validTime)/2)
        let bleDictionary: [String: [[Double]]]? = bleManager.bleDictionary
        if let bleData = bleDictionary {
            self.bleTrimed = trimBleData(bleInput: bleData, nowTime: getCurrentTimeInMillisecondsDouble(), validTime: validTime)
            self.bleAvg = avgBleData(bleDictionary: self.bleTrimed)
//            let bleAvg = ["TJ-00CB-0000031A-0000":-76.0]
            
            if (!self.bleAvg.isEmpty) {
                self.timeBleOff = 0
                self.timeActiveRF = 0
                self.timeSleepRF = 0
                self.timeEmptyRF = 0
                
                self.isActiveRF = true
                self.isEmptyRF = false
                self.isBleOff = false
                self.isActiveService = true
                
                self.wakeUpFromSleepMode()
                if (self.isActiveService) {
                    let data = ReceivedForce(user_id: self.user_id, mobile_time: currentTime, ble: self.bleAvg, pressure: self.pressure)
                    
                    inputReceivedForce.append(data)
                    if ((inputReceivedForce.count-1) >= RFD_INPUT_NUM) {
                        inputReceivedForce.remove(at: 0)
                        NetworkManager.shared.postReceivedForce(url: RF_URL, input: inputReceivedForce, completion: { [self] statusCode, returnedStrig in
                            if (statusCode != 200) {
                                let localTime = getLocalTimeString()
                                let log: String = localTime + " , (Jupiter) Error : \(statusCode) " + returnedStrig
                                print(log)
                                
                                if (statusCode == 406) {
                                    self.reporting(input: RFD_FLAG)
                                }
                            }
                        })
                        inputReceivedForce = [ReceivedForce(user_id: "", mobile_time: 0, ble: [:], pressure: 0)]
                    }
                }
            } else {
                self.timeActiveRF += RFD_INTERVAL
                if (self.timeActiveRF >= SLEEP_THRESHOLD_RF) {
                    self.isActiveRF = false
                    // Here
                    if (self.isIndoor && self.isGetFirstResponse) {
                        if (!self.isBleOff) {
                            let lastResult = self.resultToReturn
                            let isInPathMatchingArea = self.checkInPathMatchingArea(x: lastResult.x, y: lastResult.y, building: lastResult.building_name, level: lastResult.level_name)
                            
                            if (lastResult.building_name != "" && lastResult.level_name == "B0") {
                                self.initVariables()
                                self.isIndoor = false
                                self.reporting(input: OUTDOOR_FLAG)
                            } else if (isInPathMatchingArea.0) {
                                self.initVariables()
                                self.isIndoor = false
                                self.reporting(input: OUTDOOR_FLAG)
                            } else {
                                if (self.timeActiveRF >= SLEEP_THRESHOLD_RF*3) {
                                    self.initVariables()
                                    self.isIndoor = false
                                    self.reporting(input: OUTDOOR_FLAG)
                                }
                            }
                        }
                    }
                }
                
                self.timeSleepRF += RFD_INTERVAL
                if (self.timeSleepRF >= SLEEP_THRESHOLD) {
                    self.isActiveService = false
                    self.timeSleepRF = 0
                    
                    self.enterSleepMode()
                }
            }
        } else {
            let log: String = localTime + " , (Jupiter) Warnings : Fail to get recent ble"
            print(log)
        }
        
        if (!self.isIndoor) {
            self.timeForInit += RFD_INTERVAL
        }
    }
    
    func checkBleChannelNum(bleDict: [String: Double]) -> Int {
        var numChannels: Int = 0
        
        for key in bleDict.keys {
            let bleId: String = key
            let bleRssi: Double = bleDict[key] ?? -100.0
            
            if (bleRssi > -95.0) {
                numChannels += 1
            }
        }
        
        return numChannels
    }
    
    func checkSufficientRfd(userTrajectory: [TrajectoryInfo]) -> Bool {
        if (!userTrajectory.isEmpty) {
            var countOneChannel: Int = 0
            var numAllChannels: Int = 0
            
            let trajectoryLength: Int = userTrajectory.count
            for i in 0..<trajectoryLength {
                let numChannels = userTrajectory[i].numChannels
                numAllChannels += numChannels
                if (numChannels <= 1) {
                    countOneChannel += 1
                }
            }
            
            let ratioOneChannel: Double = Double(countOneChannel)/Double(trajectoryLength)
            if (ratioOneChannel >= 0.5) {
                return false
            }
            
            let ratio: Double = Double(numAllChannels)/Double(trajectoryLength)
            if (ratio >= 2.0) {
                return true
            } else {
                return false
            }
        } else {
            return false
        }
    }
    
    
    @objc func userVelocityTimerUpdate() {
        let currentTime = getCurrentTimeInMilliseconds()
        let localTime = getLocalTimeString()
        // UV Control
        setModeParam(mode: self.runMode, phase: self.phase)
        
        if (self.service == "FLT") {
            unitDRInfo = unitDRGenerator.generateDRInfo(sensorData: sensorData)
        }
        
        var backgroundScale: Double = 1.0
        if (self.isBackground) {
            let diffTime = currentTime - self.pastUvdTime
            backgroundScale = Double(diffTime)/(1000/SAMPLE_HZ)
        }
        self.pastUvdTime = currentTime
        
        if (unitDRInfo.isIndexChanged) {
            self.headingBuffer.append(unitDRInfo.heading)
            self.isNeedHeadingCorrection = self.checkHeadingCorrection(buffer: self.headingBuffer)
            
            self.wakeUpFromSleepMode()
            self.timeActiveUV = 0
            self.timeSleepUV = 0
            
            self.isStop = false
            self.isActiveService = true
            
            displayOutput.isIndexChanged = unitDRInfo.isIndexChanged
            displayOutput.indexTx = unitDRInfo.index
            displayOutput.length = unitDRInfo.length
            displayOutput.velocity = unitDRInfo.velocity * 3.6
            
            if (self.isBackground) {
                unitDRInfo.length = unitDRInfo.length*backgroundScale
            }
            self.unitDrInfoIndex = unitDRInfo.index
            
            if (self.mode == "auto") {
                let autoMode = unitDRInfo.autoMode
                if (autoMode == 0) {
                    self.runMode = "pdr"
                    self.sector_id = self.sectorIdOrigin - 1
                    self.kalmanR = 0.5
                } else {
                    self.runMode = "dr"
                    self.sector_id = self.sectorIdOrigin
                    self.kalmanR = 1
                }
                setModeParam(mode: self.runMode, phase: self.phase)
            }
            
            let data = UserVelocity(user_id: self.user_id, mobile_time: currentTime, index: unitDRInfo.index, length: unitDRInfo.length, heading: unitDRInfo.heading, looking: unitDRInfo.lookingFlag)
            timeUpdateOutput.index = unitDRInfo.index
            
            // Kalman Filter
            let diffHeading = unitDRInfo.heading - preUnitHeading
            let curUnitDRLength = unitDRInfo.length
            
            if (self.isActiveService) {
                if (self.isGetFirstResponse && self.runMode == "dr") {
                    let lastResult = self.lastResult
                    if (lastResult.building_name != "" && lastResult.level_name != "") {
                        self.travelingOsrDistance += unitDRInfo.length
                    }
                }
                
                if (self.isGetFirstResponse && !self.isPossibleEstBias) {
                    if (self.isIndoor) {
                        self.indexAfterResponse += 1
                        if (self.indexAfterResponse >= MINIMUN_INDEX_FOR_BIAS) {
                            self.isPossibleEstBias = true
                        }
                    }
                }
                
                // Make User Trajectory Buffer
                let numChannels = checkBleChannelNum(bleDict: self.bleAvg)
                makeTrajectoryInfo(unitDRInfo: self.unitDRInfo, resultToReturn: self.resultToReturn, tuHeading: self.updateHeading, isPmSuccess: self.displayOutput.isPmSuccess, bleChannels: numChannels)
                
                inputUserVelocity.append(data)
                // Time Update
                if (self.isActiveKf) {
                    if (self.timeUpdateFlag) {
                        let tuOutput = timeUpdate(length: curUnitDRLength, diffHeading: diffHeading, mobileTime: currentTime, isNeedHeadingCorrection: isNeedHeadingCorrection, runMode: self.runMode)
                        var tuResult = fromServerToResult(fromServer: tuOutput, velocity: displayOutput.velocity)
                        
                        self.timeUpdateResult[0] = tuResult.x
                        self.timeUpdateResult[1] = tuResult.y
                        self.timeUpdateResult[2] = tuResult.absolute_heading
                        
                        self.uvdIndexBuffer.append(unitDRInfo.index)
                        self.tuResultBuffer.append([tuResult.x, tuResult.y, tuResult.absolute_heading])
                        
                        if (self.uvdIndexBuffer.count > UVD_BUFFER_SIZE) {
                            self.uvdIndexBuffer.remove(at: 0)
                            self.tuResultBuffer.remove(at: 0)
                        }
                        
                        self.currentTuResult = tuResult
                        
                        let trackingTime = getCurrentTimeInMilliseconds()
                        tuResult.mobile_time = trackingTime
                        self.outputResult = tuResult
                        self.flagPast = false
                        
                        self.resultToReturn = self.makeOutputResult(input: self.outputResult, isPast: self.flagPast, runMode: self.runMode, isVenusMode: self.isVenusMode)
                    }
                }
                preUnitHeading = unitDRInfo.heading
                
                // Put UV
                if ((inputUserVelocity.count-1) >= UVD_INPUT_NUM) {
                    inputUserVelocity.remove(at: 0)
                    NetworkManager.shared.postUserVelocity(url: UV_URL, input: inputUserVelocity, completion: { [self] statusCode, returnedString in
                        if (statusCode == 200) {
                            self.pastTuResult = self.currentTuResult
                            self.indexSend = Int(returnedString) ?? 0
                            self.isAnswered = true
                        } else {
                            let localTime: String = getLocalTimeString()
                            let log: String = localTime + " , (Jupiter) Error : \(statusCode) " + returnedString
                            print(log)
                            
                            if (statusCode == 406) {
                                self.reporting(input: UVD_FLAG)
                            }
                        }
                    })
                    inputUserVelocity = [UserVelocity(user_id: user_id, mobile_time: 0, index: 0, length: 0, heading: 0, looking: true)]
                }
                
                // Phase 4 Request
                if (self.isAnswered && (self.phase == 4)) {
                    self.isAnswered = false
                    
                    let phase4Trajectory = self.userTrajectoryInfo
                    let searchInfo = makeSearchAreaAndDirection(userTrajectory: phase4Trajectory, phase: self.phase)
                    if (!self.isBackground && searchInfo.3 != 0) {
                        processPhase4(currentTime: currentTime, localTime: localTime, userTrajectory: phase4Trajectory, searchInfo: searchInfo)
                    }
                }
            }
        } else {
            // UV가 발생하지 않음
            self.timeActiveUV += UVD_INTERVAL
            if (self.timeActiveUV >= STOP_THRESHOLD && self.isGetFirstResponse) {
                if (self.isVenusMode) {
                    self.isStop = false
                } else {
                    self.isStop = true
                }
                self.timeActiveUV = 0
                displayOutput.velocity = 0
            }
            
            self.timeSleepUV += UVD_INTERVAL
            if (self.timeSleepUV >= SLEEP_THRESHOLD) {
                self.isActiveService = false
                self.timeSleepUV = 0
                
                self.enterSleepMode()
            }
        }
    }
    
    func accumulateLengthAndRemoveOldest(isDetermineSpot: Bool, LENGTH_CONDITION: Double) {
        if (isDetermineSpot) {
            var tailIndex = 1
            if (!self.phase2Trajectory.isEmpty) {
                tailIndex = self.phase2Trajectory[0].index
            }
            let inputTrajectory = getTrajectoryFromIndex(from: self.userTrajectoryInfo, index: tailIndex)
            self.userTrajectoryInfo = inputTrajectory
            
            self.isDetermineSpot = false
        }
        
        var accumulatedLength = 0.0
        for userTrajectory in self.userTrajectoryInfo {
            accumulatedLength += userTrajectory.length
        }
        
        if accumulatedLength > USER_TRAJECTORY_LENGTH {
            self.userTrajectoryInfo.removeFirst()
        }
    }
    
    func makeTrajectoryInfo(unitDRInfo: UnitDRInfo, resultToReturn: FineLocationTrackingResult, tuHeading: Double, isPmSuccess: Bool, bleChannels: Int) {
        if (resultToReturn.x != 0 && resultToReturn.y != 0) {
            if (self.isNeedTrajInit) {
                self.userTrajectoryInfo = [TrajectoryInfo]()
                self.isNeedTrajInit = false
            } else if (!self.isGetFirstResponse && (self.timeForInit < TIME_INIT_THRESHOLD)) {
                self.userTrajectoryInfo = [TrajectoryInfo]()
            } else {
                self.userTrajectory.index = unitDRInfo.index
                self.userTrajectory.length = unitDRInfo.length
                self.userTrajectory.heading = unitDRInfo.heading
                self.userTrajectory.velocity = unitDRInfo.velocity
                self.userTrajectory.lookingFlag = unitDRInfo.lookingFlag
                self.userTrajectory.isIndexChanged = unitDRInfo.isIndexChanged
                self.userTrajectory.numChannels = bleChannels
                self.userTrajectory.scc = resultToReturn.scc
                self.userTrajectory.userBuilding = resultToReturn.building_name
                self.userTrajectory.userLevel = resultToReturn.level_name
                self.userTrajectory.userX = resultToReturn.x
                self.userTrajectory.userY = resultToReturn.y
                self.userTrajectory.userHeading = resultToReturn.absolute_heading
                self.userTrajectory.userTuHeading = tuHeading
                self.userTrajectory.userPmSuccess = isPmSuccess
                
                self.userTrajectoryInfo.append(self.userTrajectory)
                self.accumulateLengthAndRemoveOldest(isDetermineSpot: self.isDetermineSpot, LENGTH_CONDITION: USER_TRAJECTORY_LENGTH)
            }
        }
    }
    
    func getTrajectoryFromIndex(from userTrajectory: [TrajectoryInfo], index: Int) -> [TrajectoryInfo] {
        var result: [TrajectoryInfo] = []
        
        let currentTrajectory = userTrajectory
        var closestIndex = 0
        var startIndex = currentTrajectory.count-15
        for i in 0..<currentTrajectory.count {
            let currentIndex = currentTrajectory[i].index
            let diffIndex = abs(currentIndex - index)
            let compareIndex = abs(closestIndex - index)
            
            if (diffIndex < compareIndex) {
                closestIndex = currentIndex
                startIndex = i
            }
        }
        
        for i in startIndex..<currentTrajectory.count {
            result.append(currentTrajectory[i])
        }
        
        return result
    }
    
    func getTrajectoryFromLast(from userTrajectory: [TrajectoryInfo], N: Int) -> [TrajectoryInfo] {
        var accumulatedLength = 0.0
        for unitTraj in userTrajectory {
            accumulatedLength += unitTraj.length
        }
        
        let size = userTrajectory.count
        guard size >= N else {
            return userTrajectory
        }
        
        let startIndex = size - N
        let endIndex = size
        
        var result: [TrajectoryInfo] = []
        for i in startIndex..<endIndex {
            result.append(userTrajectory[i])
        }

        return result
    }
    
    func cutTrajectoryFromLast(from userTrajectory: [TrajectoryInfo], userLength: Double, cutLength: Double) -> [TrajectoryInfo] {
        let trajLength = userLength
        
        if (trajLength < cutLength) {
            return userTrajectory
        } else {
            var cutIndex = 0
            
            var accumulatedLength: Double = 0
            for i in (0..<userTrajectory.count).reversed() {
                accumulatedLength += userTrajectory[i].length
                
                if (accumulatedLength > cutLength) {
                    cutIndex = i
                    break
                }
            }
            
            let startIndex = userTrajectory.count - cutIndex
            let endIndex = userTrajectory.count

            var result: [TrajectoryInfo] = []
            for i in startIndex..<endIndex {
                result.append(userTrajectory[i])
            }
            
            return result
        }
    }
    
    func makeSearchAreaAndDirection(userTrajectory: [TrajectoryInfo], phase: Int) -> ([Int], [Int], Int, Int) {
        var resultRange: [Int] = []
        var resultDirection: [Int] = [0, 90, 180, 270]
        var tailIndex = 1
        var searchType = 0
        
        if (!userTrajectory.isEmpty) {
            var uvHeading = [Double]()
            for value in userTrajectory {
                uvHeading.append(compensateHeading(heading: value.heading, mode: "dr"))
            }
            
            var accumulatedLength = 0.0
            for unitTraj in userTrajectory {
                accumulatedLength += unitTraj.length
            }
            
            if (accumulatedLength < USER_TRAJECTORY_LENGTH*0.7) {
                let userBuilding = userTrajectory[userTrajectory.count-1].userBuilding
                let userLevel = userTrajectory[userTrajectory.count-1].userLevel
                let userX = userTrajectory[userTrajectory.count-1].userX
                let userY = userTrajectory[userTrajectory.count-1].userY
                let userH = userTrajectory[userTrajectory.count-1].userHeading
                
                var RANGE = USER_TRAJECTORY_LENGTH*1.2
                if (phase == 2) {
                    RANGE = accumulatedLength*1.5
                }
                
                // Search Area
                let areaMinMax: [Double] = [userX - RANGE, userY - RANGE, userX + RANGE, userY + RANGE]
                let searchArea = getSearchCoordinates(areaMinMax: areaMinMax, interval: 1.0)
                
                let headInfo = userTrajectory[userTrajectory.count-1]
                let headInfoHeading = headInfo.userTuHeading
                var xyFromHead: [Double] = [headInfo.userX, headInfo.userY]
                
                var headingCorrectionFromServer: Double = headInfo.userHeading - uvHeading[uvHeading.count-1]
                var headingCorrectionForHead: Double = 0
                if (!self.isActiveKf) {
                    headingCorrectionForHead = 0
                } else {
                    headingCorrectionForHead = headInfoHeading - headInfo.userHeading
                }
                
                var headingFromHead = [Double] (repeating: 0, count: uvHeading.count)
                for i in 0..<uvHeading.count {
                    headingFromHead[i] = compensateHeading(heading: (uvHeading[i] + headingCorrectionForHead) - 180 + headingCorrectionFromServer, mode: "dr")
                }
                
                var trajectoryFromHead = [[Double]]()
                trajectoryFromHead.append(xyFromHead)
                for i in (1..<userTrajectory.count).reversed() {
                    let headAngle = headingFromHead[i]
                    xyFromHead[0] = xyFromHead[0] + userTrajectory[i].length*cos(headAngle*D2R)
                    xyFromHead[1] = xyFromHead[1] + userTrajectory[i].length*sin(headAngle*D2R)
                    trajectoryFromHead.append(xyFromHead)
                }
                
                let headingStart = compensateHeading(heading: headingFromHead[headingFromHead.count-1]-180, mode: "dr")
                let headingEnd = compensateHeading(heading: headingFromHead[0]-180, mode: "dr")
                
                // Search Direction
                let ppHeadings = getPathMatchingHeadings(building: userBuilding, level: userLevel, x: userX, y: userY, heading: userH, RANGE: RANGE)
                var searchHeadings: [Double] = []
                for i in 0..<ppHeadings.count {
                    searchHeadings.append(compensateHeading(heading: ppHeadings[i]-10, mode: "dr"))
                    searchHeadings.append(compensateHeading(heading: ppHeadings[i], mode: "dr"))
                    searchHeadings.append(compensateHeading(heading: ppHeadings[i]+10, mode: "dr"))
                }
                
                resultRange = areaMinMax.map { Int($0) }
                resultDirection = searchHeadings.map { Int($0) }
                tailIndex = userTrajectory[0].index
                
                displayOutput.trajectoryStartCoord = [headInfo.userX, headInfo.userY]
                displayOutput.userTrajectory = trajectoryFromHead
                displayOutput.searchArea = searchArea
                displayOutput.searchType = -2
                searchType = -2
            } else {
                // User Long
                if (phase <= 1) {
                    let userBuilding = userTrajectory[userTrajectory.count-1].userBuilding
                    let userLevel = userTrajectory[userTrajectory.count-1].userLevel
                    let userX = userTrajectory[userTrajectory.count-1].userX
                    let userY = userTrajectory[userTrajectory.count-1].userY
                    let userH = userTrajectory[userTrajectory.count-1].userHeading
                    let RANGE = USER_TRAJECTORY_LENGTH*1.5
                    
                    // Search Area
                    let areaMinMax: [Double] = [userX - RANGE, userY - RANGE, userX + RANGE, userY + RANGE]
                    let searchArea = getSearchCoordinates(areaMinMax: areaMinMax, interval: 1.0)
                    
                    let headInfo = userTrajectory[userTrajectory.count-1]
                    var xyFromHead: [Double] = [headInfo.userX, headInfo.userY]
                    let headingCorrectionForHead: Double = headInfo.userHeading - uvHeading[uvHeading.count-1]
                    var headingCorrectionFromServer: Double = headInfo.userHeading - uvHeading[uvHeading.count-1]
                    
                    var headingFromHead = [Double] (repeating: 0, count: uvHeading.count)
                    for i in 0..<uvHeading.count {
                        headingFromHead[i] = (uvHeading[i] + headingCorrectionForHead) - 180 + headingCorrectionFromServer
                    }
                    
                    var trajectoryFromHead = [[Double]]()
                    trajectoryFromHead.append(xyFromHead)
                    for i in (1..<userTrajectory.count).reversed() {
                        let headAngle = headingFromHead[i]
                        xyFromHead[0] = xyFromHead[0] + userTrajectory[i].length*cos(headAngle*D2R)
                        xyFromHead[1] = xyFromHead[1] + userTrajectory[i].length*sin(headAngle*D2R)
                        trajectoryFromHead.append(xyFromHead)
                    }
                    let headingStart = compensateHeading(heading: headingFromHead[headingFromHead.count-1]-180, mode: "dr")
                    let headingEnd = compensateHeading(heading: headingFromHead[0]-180, mode: "dr")
                    let diffHeading = abs(headingStart - headingEnd)
                    
                    // Search Direction
                    let ppHeadings = getPathMatchingHeadings(building: userBuilding, level: userLevel, x: userX, y: userY, heading: userH, RANGE: RANGE)
                    var searchHeadings: [Double] = []
                    for i in 0..<ppHeadings.count {
                        searchHeadings.append(compensateHeading(heading: ppHeadings[i]-10-diffHeading, mode: "dr"))
                        searchHeadings.append(compensateHeading(heading: ppHeadings[i]-diffHeading, mode: "dr"))
                        searchHeadings.append(compensateHeading(heading: ppHeadings[i]+10-diffHeading, mode: "dr"))
                    }
                    
                    resultRange = areaMinMax.map { Int($0) }
                    resultDirection = searchHeadings.map { Int($0) }
                    tailIndex = userTrajectory[0].index
                    
                    displayOutput.trajectoryStartCoord = [headInfo.userX, headInfo.userY]
                    displayOutput.userTrajectory = trajectoryFromHead
                    displayOutput.searchArea = searchArea
                    displayOutput.searchType = -1
                    searchType = 0
                } else {
                    // Phase > 1
                    let headInfo = userTrajectory[userTrajectory.count-1]
                    let headInfoHeading = headInfo.userTuHeading
                    
                    let tailInfo = userTrajectory[0]
                    let tailInfoHeading = tailInfo.userTuHeading
                    
                    let isStraight = isTrajectoryStraight(for: uvHeading, size: uvHeading.count)
                    
                    if (isStraight == 1) {
                        // All Straight
                        var recentScc: Double = headInfo.scc
                        var xyFromHead: [Double] = [headInfo.userX, headInfo.userY]
                        
                        var headingCorrectionForHead: Double = 0
                        var headingCorrectionFromServer: Double = headInfo.userHeading - uvHeading[uvHeading.count-1]
                        if (!self.isActiveKf) {
                            headingCorrectionForHead = 0
                        } else {
                            headingCorrectionForHead = headInfoHeading - headInfo.userHeading
                        }
                        
                        
                        var headingFromHead = [Double] (repeating: 0, count: uvHeading.count)
                        for i in 0..<uvHeading.count {
                            headingFromHead[i] = compensateHeading(heading: (uvHeading[i] + headingCorrectionForHead) - 180 + headingCorrectionFromServer, mode: "dr")
                        }
                        
                        // Head 기준 back propagation
                        var trajectoryFromHead = [[Double]]()
                        trajectoryFromHead.append(xyFromHead)
                        for i in (1..<userTrajectory.count).reversed() {
                            let headAngle = headingFromHead[i]
                            xyFromHead[0] = xyFromHead[0] + userTrajectory[i].length*cos(headAngle*D2R)
                            xyFromHead[1] = xyFromHead[1] + userTrajectory[i].length*sin(headAngle*D2R)
                            trajectoryFromHead.append(xyFromHead)
                        }
                        
                        var xyMinMax: [Double] = getMinMaxValues(for: trajectoryFromHead)

                        let headingStart = compensateHeading(heading: headingFromHead[headingFromHead.count-1]-180, mode: "dr")
                        let headingEnd = compensateHeading(heading: headingFromHead[0]-180, mode: "dr")
                        let diffHeading = abs(90 - abs(headingStart - headingEnd))
                        
                        let areaMinMax: [Double] = getSearchAreaMinMax(xyMinMax: xyMinMax, heading: [headingStart, headingEnd], recentScc: recentScc, searchType: isStraight)
                        let searchArea = getSearchCoordinates(areaMinMax: areaMinMax, interval: 1.0)
                        
                        var searchHeadings: [Double] = []
                        
                        if (diffHeading < 90) {
                            if (diffHeading > 5) {
                                searchHeadings.append(headingEnd-diffHeading)
                                searchHeadings.append(headingEnd)
                                searchHeadings.append(headingEnd+diffHeading)
                            } else {
                                searchHeadings.append(headingEnd)
                            }
                        } else {
                            searchHeadings.append(headingEnd-5)
                            searchHeadings.append(headingEnd)
                            searchHeadings.append(headingEnd+5)
                        }
                        
                        for i in 0..<searchHeadings.count {
                            searchHeadings[i] = compensateHeading(heading: searchHeadings[i], mode: "dr")
                        }
                        
                        resultRange = areaMinMax.map { Int($0) }
                        resultDirection = searchHeadings.map { Int($0) }
                        tailIndex = userTrajectory[0].index
                        
                        displayOutput.trajectoryStartCoord = [headInfo.userX, headInfo.userY]
                        displayOutput.userTrajectory = trajectoryFromHead
                        displayOutput.searchArea = searchArea
                        displayOutput.searchType = isStraight
                        searchType = isStraight
                    } else if (isStraight == 2) {
                        // Head Straight
                        var recentScc: Double = headInfo.scc
                        var xyFromHead: [Double] = [headInfo.userX, headInfo.userY]
                        
                        var headingCorrectionForHead: Double = 0
                        var headingCorrectionFromServer: Double = headInfo.userHeading - uvHeading[uvHeading.count-1]
                        if (!self.isActiveKf) {
                            headingCorrectionForHead = 0
                        } else {
                            headingCorrectionForHead = headInfoHeading - headInfo.userHeading
                        }
                        
                        var headingFromHead = [Double] (repeating: 0, count: uvHeading.count)
                        for i in 0..<uvHeading.count {
                            headingFromHead[i] = (uvHeading[i] + headingCorrectionForHead) - 180 + headingCorrectionFromServer
                        }
                        
                        // Head 기준 back propagation
                        var trajectoryFromHead = [[Double]]()
                        trajectoryFromHead.append(xyFromHead)
                        for i in (1..<userTrajectory.count).reversed() {
                            let headAngle = headingFromHead[i]
                            xyFromHead[0] = xyFromHead[0] + userTrajectory[i].length*cos(headAngle*D2R)
                            xyFromHead[1] = xyFromHead[1] + userTrajectory[i].length*sin(headAngle*D2R)
                            trajectoryFromHead.append(xyFromHead)
                        }
                        
                        var xyMinMax: [Double] = getMinMaxValues(for: trajectoryFromHead)
                        
                        let headingStart = compensateHeading(heading: headingFromHead[headingFromHead.count-1]-180, mode: "dr")
                        let headingEnd = compensateHeading(heading: headingFromHead[0]-180, mode: "dr")
                        let diffHeading = abs(90 - abs(headingStart - headingEnd))
                        
                        let areaMinMax: [Double] = getSearchAreaMinMax(xyMinMax: xyMinMax, heading: [headingStart, headingEnd], recentScc: recentScc, searchType: isStraight)
                        let searchArea = getSearchCoordinates(areaMinMax: areaMinMax, interval: 1.0)
                        
                        var searchHeadings: [Double] = []
                        
                        if (diffHeading < 90) {
                            if (diffHeading > 5) {
                                searchHeadings.append(headingEnd-diffHeading)
                                searchHeadings.append(headingEnd)
                                searchHeadings.append(headingEnd+diffHeading)
                            } else {
                                searchHeadings.append(headingEnd)
                            }
                        } else {
                            searchHeadings.append(headingEnd-10)
                            searchHeadings.append(headingEnd)
                            searchHeadings.append(headingEnd+10)
                        }
                        
                        
                        for i in 0..<searchHeadings.count {
                            searchHeadings[i] = compensateHeading(heading: searchHeadings[i], mode: "dr")
                        }
                        
                        resultRange = areaMinMax.map { Int($0) }
                        resultDirection = searchHeadings.map { Int($0) }
                        tailIndex = userTrajectory[0].index
                        
                        displayOutput.trajectoryStartCoord = [headInfo.userX, headInfo.userY]
                        displayOutput.userTrajectory = trajectoryFromHead
                        displayOutput.searchArea = searchArea
                        displayOutput.searchType = isStraight
                        searchType = isStraight
                    } else if (isStraight == 3) {
                        // Tail Straight
                        var recentScc: Double = headInfo.scc
                        var xyFromTail: [Double] = [tailInfo.userX, tailInfo.userY]
                        
                        var headingCorrectionForTail: Double = 0
                        var headingCorrectionFromServer: Double = tailInfo.userHeading - uvHeading[0]
                        if (!self.isActiveKf) {
                            headingCorrectionForTail = tailInfoHeading - uvHeading[0]
                        }
                        
                        var headingFromTail = [Double] (repeating: 0, count: uvHeading.count)
                        for i in 0..<uvHeading.count {
                            headingFromTail[i] = uvHeading[i] + headingCorrectionForTail + headingCorrectionFromServer
                        }
                        
                        var trajectoryFromTail = [[Double]]()
                        
                        trajectoryFromTail.append(xyFromTail)
                        for i in 1..<userTrajectory.count {
                            let tailAngle = headingFromTail[i]
                            xyFromTail[0] = xyFromTail[0] + userTrajectory[i].length*cos(tailAngle*D2R)
                            xyFromTail[1] = xyFromTail[1] + userTrajectory[i].length*sin(tailAngle*D2R)
                            trajectoryFromTail.append(xyFromTail)
                        }
                        
                        var xyMinMax: [Double] = getMinMaxValues(for: trajectoryFromTail)
                        
                        let headingStart = compensateHeading(heading: headingFromTail[headingFromTail.count-1], mode: "dr")
                        let headingEnd = compensateHeading(heading: headingFromTail[0], mode: "dr")
                        let diffHeading = abs(90 - abs(headingStart - headingEnd))
                        
                        let diffX = xyMinMax[2] - xyMinMax[0]
                        let diffY = xyMinMax[3] - xyMinMax[1]
                        
                        var areaMinMax: [Double] = getSearchAreaMinMax(xyMinMax: xyMinMax, heading: [headingStart, headingEnd], recentScc: recentScc, searchType: isStraight)
                        if (!self.isActiveKf) {
                            areaMinMax[0] = areaMinMax[0] - USER_TRAJECTORY_LENGTH/2
                            areaMinMax[1] = areaMinMax[1] - USER_TRAJECTORY_LENGTH/2
                            areaMinMax[2] = areaMinMax[2] + USER_TRAJECTORY_LENGTH/2
                            areaMinMax[3] = areaMinMax[3] + USER_TRAJECTORY_LENGTH/2
                        }
                        let searchArea = getSearchCoordinates(areaMinMax: areaMinMax, interval: 1.0)
                        
                        var searchHeadings: [Double] = []
                        
                        if (!self.isActiveKf) {
                            // Search Direction
                            let userBuilding = userTrajectory[userTrajectory.count-1].userBuilding
                            let userLevel = userTrajectory[userTrajectory.count-1].userLevel
                            let userX = userTrajectory[userTrajectory.count-1].userX
                            let userY = userTrajectory[userTrajectory.count-1].userY
                            let userH = userTrajectory[userTrajectory.count-1].userHeading
                            let RANGE = USER_TRAJECTORY_LENGTH*1.5
                            
                            let ppHeadings = getPathMatchingHeadings(building: userBuilding, level: userLevel, x: userX, y: userY, heading: userH, RANGE: RANGE)
                            for i in 0..<ppHeadings.count {
                                searchHeadings.append(compensateHeading(heading: ppHeadings[i]-10-diffHeading, mode: "dr"))
                                searchHeadings.append(compensateHeading(heading: ppHeadings[i]-diffHeading, mode: "dr"))
                                searchHeadings.append(compensateHeading(heading: ppHeadings[i]+10-diffHeading, mode: "dr"))
                            }
                        } else {
                            if (diffHeading < 90) {
                                if (diffHeading > 5) {
                                    searchHeadings.append(headingEnd-diffHeading)
                                    searchHeadings.append(headingEnd)
                                    searchHeadings.append(headingEnd+diffHeading)
                                } else {
                                    searchHeadings.append(headingEnd)
                                }
                            } else {
                                searchHeadings.append(headingEnd-10)
                                searchHeadings.append(headingEnd)
                                searchHeadings.append(headingEnd+10)
                            }
                        }
                        
                        
                        for i in 0..<searchHeadings.count {
                            searchHeadings[i] = compensateHeading(heading: searchHeadings[i], mode: "dr")
                        }
                        
                        resultRange = areaMinMax.map { Int($0) }
                        resultDirection = searchHeadings.map { Int($0) }
                        tailIndex = userTrajectory[0].index
                        
                        displayOutput.trajectoryStartCoord = [tailInfo.userX, tailInfo.userY]
                        displayOutput.userTrajectory = trajectoryFromTail
                        displayOutput.searchArea = searchArea
                        displayOutput.searchType = isStraight
                        
                        let diffX_ = trajectoryFromTail[trajectoryFromTail.count-1][0] - headInfo.userX
                        let diffY_ = trajectoryFromTail[trajectoryFromTail.count-1][1] - headInfo.userY
                        let diffXY_ = sqrt(diffX_*diffX_ + diffY_*diffY_)
                        
                        if (self.isActiveKf && diffXY_ <= 30) {
                            searchType = isStraight
                        } else if (diffXY_ > 30) {
                            searchType = 0
                        } else {
                            searchType = isStraight
                        }
                    } else {
                        // Turn
                        var accumulatedLength = 0.0
                        for unitTrajectory in userTrajectory {
                            accumulatedLength += unitTrajectory.length
                        }
                        
                        if (accumulatedLength >= USER_TRAJECTORY_LENGTH-10 && USER_TRAJECTORY_LENGTH >= 30) {
                            tailIndex = userTrajectory[10].index
                        } else {
                            tailIndex = userTrajectory[0].index
                        }
                        
                        let turnTrajectory = getTrajectoryFromIndex(from: self.userTrajectoryInfo, index: tailIndex)
                        
                        var turnUvHeading = [Double]()
                        for value in turnTrajectory {
                            turnUvHeading.append(compensateHeading(heading: value.heading, mode: "dr"))
                        }
                        
                        let userBuilding = turnTrajectory[turnTrajectory.count-1].userBuilding
                        let userLevel = turnTrajectory[turnTrajectory.count-1].userLevel
                        let userX = turnTrajectory[turnTrajectory.count-1].userX
                        let userY = turnTrajectory[turnTrajectory.count-1].userY
                        let userH = turnTrajectory[turnTrajectory.count-1].userHeading
                        let RANGE = Double(turnTrajectory.count)*1.2
                        
                        // Search Area
                        let areaMinMax: [Double] = [userX - RANGE, userY - RANGE, userX + RANGE, userY + RANGE]
                        let searchArea = getSearchCoordinates(areaMinMax: areaMinMax, interval: 1.0)
                        
                        var recentScc: Double = headInfo.scc
                        
                        // From Head
                        let turnHeadInfo = turnTrajectory[turnTrajectory.count-1]
                        let headInfoHeading = turnHeadInfo.userTuHeading
                        
                        var xyFromHead: [Double] = [turnHeadInfo.userX, turnHeadInfo.userY]
                        
                        var headingCorrectionForHead: Double = 0
                        let headingCorrectionFromServerH: Double = turnHeadInfo.userHeading - turnUvHeading[turnUvHeading.count-1]
                        if (!self.isActiveKf) {
                            headingCorrectionForHead = 0
                        } else {
                            headingCorrectionForHead = headInfoHeading - turnHeadInfo.userHeading
                        }
                        
                        
                        var headingFromHead = [Double] (repeating: 0, count: turnUvHeading.count)
                        for i in 0..<turnUvHeading.count {
                            headingFromHead[i] = (turnUvHeading[i] + headingCorrectionForHead) - 180 + headingCorrectionFromServerH
                        }
                        
                        var trajectoryFromHead = [[Double]]()
                        trajectoryFromHead.append(xyFromHead)
                        for i in (1..<turnTrajectory.count).reversed() {
                            let headAngle = headingFromHead[i]
                            xyFromHead[0] = xyFromHead[0] + turnTrajectory[i].length*cos(headAngle*D2R)
                            xyFromHead[1] = xyFromHead[1] + turnTrajectory[i].length*sin(headAngle*D2R)
                            trajectoryFromHead.append(xyFromHead)
                        }
                        
                        // From Tail
                        let tailInfo = turnTrajectory[0]
                        let tailInfoHeading = tailInfo.userTuHeading
                        
                        var xyFromTail: [Double] = [tailInfo.userX, tailInfo.userY]
                        var headingCorrectionForTail: Double = 0
                        var headingCorrectionFromServerT: Double = tailInfo.userHeading - uvHeading[0]
                        if (!self.isActiveKf) {
                            headingCorrectionForTail = tailInfoHeading - uvHeading[0]
                        }
                        
                        var headingFromTail = [Double] (repeating: 0, count: turnUvHeading.count)
                        for i in 0..<turnUvHeading.count {
                            headingFromTail[i] = turnUvHeading[i] + headingCorrectionForTail + headingCorrectionFromServerT
                        }
                        var trajectoryFromTail = [[Double]]()
                        
                        trajectoryFromTail.append(xyFromTail)
                        for i in 1..<turnTrajectory.count {
                            let tailAngle = headingFromTail[i]
                            xyFromTail[0] = xyFromTail[0] + turnTrajectory[i].length*cos(tailAngle*D2R)
                            xyFromTail[1] = xyFromTail[1] + turnTrajectory[i].length*sin(tailAngle*D2R)
                            trajectoryFromTail.append(xyFromTail)
                        }
                        
                        // Search Direction
                        let tailHeadingFromHead = compensateHeading(heading: headingFromHead[0]-180, mode: "dr")
                        let taiHeadingFromTail = compensateHeading(heading: headingFromTail[0], mode: "dr")
                        
                        var searchHeadings: [Double] = []
                        searchHeadings.append(tailHeadingFromHead-10)
                        searchHeadings.append(tailHeadingFromHead)
                        searchHeadings.append(tailHeadingFromHead+10)
                        searchHeadings.append(taiHeadingFromTail-10)
                        searchHeadings.append(taiHeadingFromTail)
                        searchHeadings.append(taiHeadingFromTail+10)
                        
                        resultRange = areaMinMax.map { Int($0) }
                        resultDirection = searchHeadings.map { Int($0) }
                        
                        displayOutput.trajectoryStartCoord = [headInfo.userX, headInfo.userY]
                        displayOutput.userTrajectory = trajectoryFromHead
                        displayOutput.searchArea = searchArea
                        displayOutput.searchType = 0
                        searchType = isStraight
                    }
                }
            }
            
            if (resultRange.isEmpty) {
                let userX = userTrajectory[userTrajectory.count-1].userX
                let userY = userTrajectory[userTrajectory.count-1].userY
                let userH = userTrajectory[userTrajectory.count-1].userHeading
                let RANGE = USER_TRAJECTORY_LENGTH*1.2
                let areaMinMax = [userX - RANGE, userY - RANGE, userX + RANGE, userY + RANGE]
                resultRange = areaMinMax.map { Int($0) }
            }
        }
        
        if (resultDirection.isEmpty) {
            resultDirection = [0, 90, 180, 270]
        }
        
        
        return (resultRange, resultDirection, tailIndex, searchType)
    }
    
    func removeOppositeHeading(_ arrayA: [Double], subtractConstant c: Double) -> [Double] {
        let arrayB = arrayA.map { abs($0 - c) }
        let indicesToRemove = arrayB.indices.filter { arrayB[$0] > 140 }
        let newArray = arrayA.enumerated().filter { !indicesToRemove.contains($0.offset) }.map { $0.element }
        return newArray
    }
    
    func isTrajectoryStraight(for array: [Double], size: Int) -> Int {
        if (size < NUM_STRAIGHT_INDEX) {
            return 0
        }
        
        // All Straight
        let circularStandardDeviationAll = circularStandardDeviation(for: array)
        
        if (circularStandardDeviationAll <= 10.0) {
            return 1
        }
        
        // Head Straight
        let lastTenValues = Array(array[(size-NUM_STRAIGHT_INDEX)..<size])
        let circularStandardDeviationHead = circularStandardDeviation(for: lastTenValues)
        
        if (circularStandardDeviationHead <= 10.0) {
            return 2
        }
        
        // Tail Straight
        let firstTenValues = Array(array[0..<NUM_STRAIGHT_INDEX])
        let circularStandardDeviationTail = circularStandardDeviation(for: firstTenValues)
        
        if (circularStandardDeviationTail <= 10.0) {
            return 3
        }
        
        return 0
    }
    
    func getSearchAreaMinMax(xyMinMax: [Double], heading: [Double], recentScc: Double, searchType: Int) -> [Double] {
        var areaMinMax: [Double] = []
        
        var xMin = xyMinMax[0]
        var yMin = xyMinMax[1]
        var xMax = xyMinMax[2]
        var yMax = xyMinMax[3]
        
        let SEARCH_LENGTH: Double = USER_TRAJECTORY_LENGTH*(0.3)

        let headingStart = heading[0]
        let headingEnd = heading[1]

        let startCos = cos(headingStart*D2R)
        let startSin = sin(headingStart*D2R)

        let endCos = cos(headingEnd*D2R)
        let endSin = sin(headingEnd*D2R)
        
        if (searchType == 3) {
            // Tail Straight
            if (startCos > 0) {
                xMin = xMin - SEARCH_LENGTH*startCos
                xMax = xMax + SEARCH_LENGTH*startCos
            } else {
                xMin = xMin + SEARCH_LENGTH*startCos
                xMax = xMax - SEARCH_LENGTH*startCos
            }

            if (startSin > 0) {
                yMin = yMin - SEARCH_LENGTH*startSin
                yMax = yMax + SEARCH_LENGTH*startSin
            } else {
                yMin = yMin + SEARCH_LENGTH*startSin
                yMax = yMax - SEARCH_LENGTH*startSin
            }

            if (endCos > 0) {
                xMin = xMin - 1.2*SEARCH_LENGTH*endCos
                xMax = xMax + 1.2*SEARCH_LENGTH*endCos
            } else {
                xMin = xMin + 1.2*SEARCH_LENGTH*endCos
                xMax = xMax - 1.2*SEARCH_LENGTH*endCos
            }

            if (endSin > 0) {
                yMin = yMin - 1.2*SEARCH_LENGTH*endSin
                yMax = yMax + 1.2*SEARCH_LENGTH*endSin
            } else {
                yMin = yMin + 1.2*SEARCH_LENGTH*endSin
                yMax = yMax - 1.2*SEARCH_LENGTH*endSin
            }
        } else {
            // All & Head Straight
            if (startCos > 0) {
                xMin = xMin - 1.2*SEARCH_LENGTH*startCos
                xMax = xMax + 1.2*SEARCH_LENGTH*startCos
            } else {
                xMin = xMin + 1.2*SEARCH_LENGTH*startCos
                xMax = xMax - 1.2*SEARCH_LENGTH*startCos
            }

            if (startSin > 0) {
                yMin = yMin - 1.2*SEARCH_LENGTH*startSin
                yMax = yMax + 1.2*SEARCH_LENGTH*startSin
            } else {
                yMin = yMin + 1.2*SEARCH_LENGTH*startSin
                yMax = yMax - 1.2*SEARCH_LENGTH*startSin
            }

            if (endCos > 0) {
                xMin = xMin - SEARCH_LENGTH*endCos
                xMax = xMax + SEARCH_LENGTH*endCos
            } else {
                xMin = xMin + SEARCH_LENGTH*endCos
                xMax = xMax - SEARCH_LENGTH*endCos
            }

            if (endSin > 0) {
                yMin = yMin - SEARCH_LENGTH*endSin
                yMax = yMax + SEARCH_LENGTH*endSin
            } else {
                yMin = yMin + SEARCH_LENGTH*endSin
                yMax = yMax - SEARCH_LENGTH*endSin
            }
        }
        
        // 직선인 경우
        if (abs(xMin - xMax) < 5.0) {
            xMin = xMin - USER_TRAJECTORY_LENGTH*0.05
            xMax = xMax + USER_TRAJECTORY_LENGTH*0.05
        }

        if (abs(yMin - yMax) < 5.0) {
            yMin = yMin - USER_TRAJECTORY_LENGTH*0.05
            yMax = yMax + USER_TRAJECTORY_LENGTH*0.05
        }
        
        // U-Turn인 경우
        let diffHeading = compensateHeading(heading: abs(headingStart - headingEnd), mode: "dr")
        if (diffHeading > 150) {
            let diffX = abs(xMax - xMin)
            let diffY = abs(yMax - yMin)
            
            let diffXy = abs(diffX - diffY)*0.25
            
            if (diffX < diffY) {
                xMin = xMin - diffXy
                xMax = xMax + diffXy
            } else {
                yMin = yMin - diffXy
                yMax = yMax + diffXy
            }
        }

        areaMinMax = [xMin, yMin, xMax, yMax]
        
        return areaMinMax
    }

    func getSearchCoordinates(areaMinMax: [Double], interval: Double) -> [[Double]] {
        var coordinates: [[Double]] = []
        
        let xMin = areaMinMax[0]
        let yMin = areaMinMax[1]
        let xMax = areaMinMax[2]
        let yMax = areaMinMax[3]
        
        var x = xMin
            while x <= xMax {
                coordinates.append([x, yMin])
                coordinates.append([x, yMax])
                x += interval
            }
            
            var y = yMin
            while y <= yMax {
                coordinates.append([xMin, y])
                coordinates.append([xMax, y])
                y += interval
            }
        
        return coordinates
    }
    
    @objc func requestTimerUpdate() {
        let currentTime = getCurrentTimeInMilliseconds()
        let localTime = getLocalTimeString()
        
        if (self.isActiveService) {
            if (!self.isStop) {
                if (self.phase == 2) {
                    var tailIndex = 1
                    if (!self.phase2Trajectory.isEmpty) {
                        tailIndex = self.phase2Trajectory[0].index
                    }
                    let inputTrajectory = getTrajectoryFromIndex(from: self.userTrajectoryInfo, index: tailIndex)
                    let searchInfo = makeSearchAreaAndDirection(userTrajectory: inputTrajectory, phase: self.phase)
                    
                    processPhase2(currentTime: currentTime, localTime: localTime, userTrajectory: inputTrajectory, searchInfo: searchInfo)
                } else if (self.phase < 4) {
                    // Phase 1 ~ 3
                    let phase3Trajectory = self.userTrajectoryInfo
                    let searchInfo = makeSearchAreaAndDirection(userTrajectory: phase3Trajectory, phase: self.phase)
                    if (!self.isActiveKf) {
                        processPhase3(currentTime: currentTime, localTime: localTime, userTrajectory: phase3Trajectory, searchInfo: searchInfo)
                    } else {
                        if (searchInfo.3 != 0) {
                            processPhase3(currentTime: currentTime, localTime: localTime, userTrajectory: phase3Trajectory, searchInfo: searchInfo)
                        }
                    }
                }
            } else if (!self.isGetFirstResponse) {
                let phase3Trajectory = self.userTrajectoryInfo
                let searchInfo = makeSearchAreaAndDirection(userTrajectory: phase3Trajectory, phase: self.phase)
                processPhase3(currentTime: currentTime, localTime: localTime, userTrajectory: phase3Trajectory, searchInfo: searchInfo)
            }
        }
    }
    
    private func processPhase2(currentTime: Int, localTime: String, userTrajectory: [TrajectoryInfo], searchInfo: ([Int], [Int], Int, Int)) {
        let localTime = getLocalTimeString()
        
        let input = FineLocationTracking(user_id: self.user_id, mobile_time: currentTime, sector_id: self.sector_id, building_name: self.currentBuilding, level_name: self.currentLevel, spot_id: self.currentSpot, phase: self.phase, search_range: searchInfo.0, search_direction_list: searchInfo.1, rss_compensation_list: [self.rssiBias], sc_compensation_list: [1.0], tail_index: searchInfo.2)
        NetworkManager.shared.postFLT(url: FLT_URL, input: input, isSufficientRfd: self.isSufficientRfd, completion: { [self] statusCode, returnedString, rfdCondition in
            if (statusCode == 200) {
                var result = jsonToResult(json: returnedString)
                if (result.x != 0 && result.y != 0) {
                    if (result.mobile_time > self.preOutputMobileTime) {
                        if (self.isVenusMode) {
                            result.phase = 1
                            result.absolute_heading = 0
                        }
                        
                        let resultHeading = compensateHeading(heading: result.absolute_heading, mode: self.runMode)
                        var resultCorrected = self.pathMatching(building: result.building_name, level: result.level_name, x: result.x, y: result.y, heading: resultHeading, tuXY: [0,0], mode: self.runMode, isPast: false, HEADING_RANGE: self.HEADING_RANGE)
                        resultCorrected.xyh[2] = compensateHeading(heading: resultCorrected.xyh[2], mode: self.runMode)
                        
                        if (result.phase == 2 && result.scc < SCC_FOR_PHASE4) {
                            self.phase2Count += 1
                            if (self.phase2Count > 6) {
                                self.isNeedTrajInit = true
                                self.phase2Count = 0
                                self.phase = 1
                            }
                        } else {
                            if (result.phase == 4) {
                                self.phase2Count = 0
                                self.isEnterPhase2 = true
                            }
                            
                            if (self.currentLevel == "0F") {
                                self.isNeedTrajInit = true
                                self.phase = 1
                            } else {
                                self.phase = result.phase
                            }
                        }
                        
                        self.serverResult[0] = result.x
                        self.serverResult[1] = result.y
                        self.serverResult[2] = result.absolute_heading
                        
                        if (!self.isActiveKf) {
                            self.outputResult.x = resultCorrected.xyh[0]
                            self.outputResult.y = resultCorrected.xyh[1]
                            self.outputResult.absolute_heading = resultCorrected.xyh[2]
                        }
                        
                        self.outputResult.scc = result.scc
                        self.outputResult.phase = result.phase
                        self.resultToReturn = self.makeOutputResult(input: self.outputResult, isPast: self.flagPast, runMode: self.runMode, isVenusMode: self.isVenusMode)
                        self.indexPast = result.index
                    }
                    self.preOutputMobileTime = result.mobile_time
                } else {
                    self.phase = 1
                    self.isNeedTrajInit = true
                }
            } else {
                let log: String = localTime + " , (Jupiter) Error : \(statusCode) Fail to request indoor position in Phase 2"
                print(log)
            }
        })
    }
    
    private func processPhase3(currentTime: Int, localTime: String, userTrajectory: [TrajectoryInfo], searchInfo: ([Int], [Int], Int, Int)) {
        let localTime = getLocalTimeString()
        self.isSufficientRfd = checkSufficientRfd(userTrajectory: userTrajectory)
        
        // Bias Estimation
        var requestBiasArray: [Int] = [self.rssiBias]
        if (self.isBiasConverged) {
            requestBiasArray = [self.rssiBias]
            self.isBiasRequested = false
        } else {
            if (self.isPossibleEstBias) {
                if (self.isBiasRequested) {
                    requestBiasArray = [self.rssiBias]
                } else {
                    if (!self.isActiveKf && self.isSufficientRfd) {
                        requestBiasArray = self.rssiBiasArray
                        self.biasRequestTime = currentTime
                        self.isBiasRequested = true
                    } else if (self.phase > 2 && self.isSufficientRfd) {
                        requestBiasArray = self.rssiBiasArray
                        self.biasRequestTime = currentTime
                        self.isBiasRequested = true
                    } else {
                        requestBiasArray = [self.rssiBias]
                    }
                }
            }
        }
        
        self.phase2Count = 0
        let input = FineLocationTracking(user_id: self.user_id, mobile_time: currentTime, sector_id: self.sector_id, building_name: self.currentBuilding, level_name: self.currentLevel, spot_id: self.currentSpot, phase: self.phase, search_range: searchInfo.0, search_direction_list: searchInfo.1, rss_compensation_list: requestBiasArray, sc_compensation_list: [1.0], tail_index: searchInfo.2)
        
        self.networkCount += 1
        NetworkManager.shared.postFLT(url: FLT_URL, input: input, isSufficientRfd: self.isSufficientRfd, completion: { [self] statusCode, returnedString, rfdCondition in
            self.networkCount = 0
            if (statusCode == 200) {
                let result = jsonToResult(json: returnedString)
                if (result.x != 0 && result.y != 0) {
                    if (self.isBiasRequested) {
                        let biasCheckTime = abs(result.mobile_time - self.biasRequestTime)
                        if (biasCheckTime < 100) {
                            let resultEstRssiBias = estimateRssiBias(sccResult: result.scc, biasResult: result.rss_compensation, biasArray: self.rssiBiasArray)
                            self.rssiBias = result.rss_compensation
                            let newBiasArray: [Int] = resultEstRssiBias.1
                            self.rssiBiasArray = newBiasArray
                            
                            if (resultEstRssiBias.0) {
                                self.sccGoodBiasArray.append(result.rss_compensation)
                                if (self.sccGoodBiasArray.count >= GOOD_BIAS_ARRAY_SIZE) {
                                    let biasAvg = averageBiasArray(biasArray: self.sccGoodBiasArray)
                                    self.sccGoodBiasArray.remove(at: 0)
                                    self.rssiBias = biasAvg.0
                                    self.isBiasConverged = biasAvg.1
                                    if (!biasAvg.1) {
                                        self.sccGoodBiasArray = [Int]()
                                    }
                                    
                                    self.saveRssiBias(bias: self.rssiBias, biasArray: self.sccGoodBiasArray, isConverged: self.isBiasConverged, sector_id: self.sector_id)
                                    if (self.isBiasConverged) {
                                        self.postRssiBias(sector_id: self.sector_id, bias: self.rssiBias)
                                    }
                                }
                            }
                            
                            self.isBiasRequested = false
                            displayOutput.bias = self.rssiBias
                            displayOutput.isConverged = self.isBiasConverged
                        } else if (biasCheckTime > 3000) {
                            self.isBiasRequested = false
                        }
                    }
                    
                    if (result.mobile_time > self.preOutputMobileTime) {
                        if (!self.isGetFirstResponse) {
                            if (!self.isIndoor && (self.timeForInit >= TIME_INIT_THRESHOLD)) {
                                self.isGetFirstResponse = true
                                self.isIndoor = true
                                self.reporting(input: INDOOR_FLAG)
                            }
                        }
                        
                        if (result.phase == 1) {
                            self.isNeedTrajInit = true
                        }
                        
                        displayOutput.indexRx = result.index
                        
                        // Check Bias Re-estimation is needed
                        if (self.isBiasConverged) {
                            if (result.scc < 0.5) {
                                self.sccBadCount += 1
                                if (self.sccBadCount > 5) {
                                    reEstimateRssiBias()
                                    self.sccBadCount = 0
                                }
                            }
                        }
                        
                        var resultCorrected = self.pathMatching(building: result.building_name, level: result.level_name, x: result.x, y: result.y, heading: result.absolute_heading, tuXY: [0,0], mode: self.runMode, isPast: false, HEADING_RANGE: self.HEADING_RANGE)
                        resultCorrected.xyh[2] = compensateHeading(heading: resultCorrected.xyh[2], mode: self.runMode)
                        
                        self.serverResult[0] = resultCorrected.xyh[0]
                        self.serverResult[1] = resultCorrected.xyh[1]
                        self.serverResult[2] = resultCorrected.xyh[2]
                        
                        if (!self.isActiveKf) {
                            if (result.phase == 4) {
                                self.timeUpdatePosition.x = resultCorrected.xyh[0]
                                self.timeUpdatePosition.y = resultCorrected.xyh[1]
                                self.timeUpdatePosition.heading = resultCorrected.xyh[2]
                                
                                self.timeUpdateOutput.x = resultCorrected.xyh[0]
                                self.timeUpdateOutput.y = resultCorrected.xyh[1]
                                self.timeUpdateOutput.absolute_heading = resultCorrected.xyh[2]
                                
                                self.measurementPosition.x = resultCorrected.xyh[0]
                                self.measurementPosition.y = resultCorrected.xyh[1]
                                self.measurementPosition.heading = resultCorrected.xyh[2]
                                
                                self.measurementOutput.x = resultCorrected.xyh[0]
                                self.measurementOutput.y = resultCorrected.xyh[1]
                                self.measurementOutput.absolute_heading = resultCorrected.xyh[2]
                                
                                self.outputResult.x = resultCorrected.xyh[0]
                                self.outputResult.y = resultCorrected.xyh[1]
                                self.outputResult.absolute_heading = resultCorrected.xyh[2]
                                
                                self.resultToReturn = self.makeOutputResult(input: self.outputResult, isPast: self.flagPast, runMode: self.runMode, isVenusMode: self.isVenusMode)
                            }
                            
                            var resultCopy = result
                            
                            let resultLevelName = removeLevelDirectionString(levelName: result.level_name)
                            let currentLevelName = removeLevelDirectionString(levelName: self.currentLevel)
                            
                            let levelArray: [String] = [resultLevelName, currentLevelName]
                            var TIME_CONDITION = VALID_BL_CHANGE_TIME
                            if (levelArray.contains("B0") && levelArray.contains("B2")) {
                                TIME_CONDITION = VALID_BL_CHANGE_TIME*4
                            }
                            
                            if (result.building_name != self.currentBuilding || result.level_name != self.currentLevel) {
                                if ((result.mobile_time - self.buildingLevelChangedTime) > TIME_CONDITION) {
                                    // Building Level 이 바뀐지 10초 이상 지남 -> 서버 결과를 이용해 바뀌어야 한다고 판단
                                    self.currentBuilding = result.building_name
                                    self.currentLevel = result.level_name
                                } else {
                                    resultCopy.building_name = self.currentBuilding
                                    resultCopy.level_name = self.currentLevel
                                }
                            }
                            let finalResult = fromServerToResult(fromServer: resultCopy, velocity: displayOutput.velocity)
                            
                            self.flagPast = false
                            self.outputResult = finalResult
                            
                            self.resultToReturn = self.makeOutputResult(input: self.outputResult, isPast: self.flagPast, runMode: self.runMode, isVenusMode: self.isVenusMode)
                        } else {
                            // Kalman Filter가 동작 중이면서 위치 요청시 input의 phase 가 1~3 인 경우
                            if (result.phase == 4 && resultCorrected.isSuccess) {
                                self.updateAllResult(result: resultCorrected.xyh)
                            } else if (result.phase == 3) {
                                self.updateAllResult(result: resultCorrected.xyh)
                            } else {
                                self.isNeedTrajInit = true
                            }
                            var timUpdateOutputCopy = self.timeUpdateOutput
                            timUpdateOutputCopy.phase = result.phase
                            
                            let resultLevelName = removeLevelDirectionString(levelName: result.level_name)
                            let currentLevelName = removeLevelDirectionString(levelName: self.currentLevel)
                            
                            let levelArray: [String] = [resultLevelName, currentLevelName]
                            var TIME_CONDITION = VALID_BL_CHANGE_TIME
                            if (levelArray.contains("B0") && levelArray.contains("B2")) {
                                TIME_CONDITION = VALID_BL_CHANGE_TIME*4
                            }
                            
                            if (result.building_name != self.currentBuilding || result.level_name != self.currentLevel) {
                                if ((result.mobile_time - self.buildingLevelChangedTime) > TIME_CONDITION) {
                                    // Building Level 이 바뀐지 10초 이상 지남 -> 서버 결과를 이용해 바뀌어야 한다고 판단
                                    self.currentBuilding = result.building_name
                                    self.currentLevel = result.level_name
                                    
                                    timUpdateOutputCopy.building_name = result.building_name
                                    timUpdateOutputCopy.level_name = result.level_name
                                } else {
                                    timUpdateOutputCopy.building_name = self.currentBuilding
                                    timUpdateOutputCopy.level_name = self.currentLevel
                                }
                                timUpdateOutputCopy.mobile_time = result.mobile_time
                            }
                            
                            let updatedResult = fromServerToResult(fromServer: timUpdateOutputCopy, velocity: displayOutput.velocity)
                            self.timeUpdateOutput = timUpdateOutputCopy
                            
                            self.flagPast = false
                            self.outputResult = updatedResult
                            
                            self.resultToReturn = self.makeOutputResult(input: self.outputResult, isPast: self.flagPast, runMode: self.runMode, isVenusMode: self.isVenusMode)
                        }
                        
                        if (self.isVenusMode) {
                            self.phase = 1
                            self.outputResult.phase = 1
                            self.outputResult.absolute_heading = 0
                            
                            self.resultToReturn = self.makeOutputResult(input: self.outputResult, isPast: self.flagPast, runMode: self.runMode, isVenusMode: self.isVenusMode)
                        } else {
                            self.phase = result.phase
                        }
                        self.indexPast = result.index
                    }
                    self.preOutputMobileTime = result.mobile_time
                } else {
                    self.phase = result.phase
                }
            } else {
                let log: String = localTime + " , (Jupiter) Error : \(statusCode) Fail to request indoor position in Phase 3"
                print(log)
            }
        })
    }
    
    private func processPhase4(currentTime: Int, localTime: String, userTrajectory: [TrajectoryInfo], searchInfo: ([Int], [Int], Int, Int)) {
        let localTime = getLocalTimeString()
        self.isSufficientRfd = checkSufficientRfd(userTrajectory: userTrajectory)
        
        self.nowTime = currentTime
        var requestBiasArray: [Int] = [self.rssiBias]
        var requestScArray: [Double] = [self.scCompensation]
        
        if (self.isBiasConverged) {
            requestBiasArray = [self.rssiBias]
            self.isBiasRequested = false
        } else {
            if (self.isPossibleEstBias) {
                if (self.isBiasRequested) {
                    requestBiasArray = [self.rssiBias]
                } else {
                    if (self.isSufficientRfd) {
                        requestBiasArray = self.rssiBiasArray
                        self.biasRequestTime = currentTime
                        self.isBiasRequested = true
                    } else {
                        requestBiasArray = [self.rssiBias]
                    }
                }
            }
        }
        
        
        // 사이즈 검사
        // 3개 -> scCompensation 불가능 -> 여기는 무조건 1개 보냄
        if (requestBiasArray.count == 1) {
            // 1개 -> scCoompenstaion 가능 -> 여기서 판단해서 3개보낼지 하나보낼지
            if (self.isScRequested) {
                requestScArray = [self.scCompensation]
            } else {
                requestScArray = self.scCompensationArray
                self.scRequestTime = currentTime
                self.isScRequested = true
            }
        }
        
        self.sccBadCount = 0
        let input = FineLocationTracking(user_id: self.user_id, mobile_time: currentTime, sector_id: self.sector_id, building_name: self.currentBuilding, level_name: self.currentLevel, spot_id: self.currentSpot, phase: self.phase, search_range: searchInfo.0, search_direction_list: searchInfo.1, rss_compensation_list: requestBiasArray, sc_compensation_list: requestScArray, tail_index: searchInfo.2)
        self.networkCount += 1
        NetworkManager.shared.postFLT(url: FLT_URL, input: input, isSufficientRfd: self.isSufficientRfd, completion: { [self] statusCode, returnedString, rfdCondition in
            self.networkCount = 0
            if (statusCode == 200) {
                let result = jsonToResult(json: returnedString)
                // Bias Compensation
                if (self.isBiasRequested) {
                    let biasCheckTime = abs(result.mobile_time - self.biasRequestTime)
                    if (biasCheckTime < 100) {
                        let resultEstRssiBias = estimateRssiBias(sccResult: result.scc, biasResult: result.rss_compensation, biasArray: self.rssiBiasArray)
                        
                        self.rssiBias = result.rss_compensation
                        let newBiasArray: [Int] = resultEstRssiBias.1
                        self.rssiBiasArray = newBiasArray
                        if (resultEstRssiBias.0) {
                            self.sccGoodBiasArray.append(result.rss_compensation)
                            if (self.sccGoodBiasArray.count >= GOOD_BIAS_ARRAY_SIZE) {
                                let biasAvg = averageBiasArray(biasArray: self.sccGoodBiasArray)
                                self.sccGoodBiasArray.remove(at: 0)
                                self.rssiBias = biasAvg.0
                                self.isBiasConverged = biasAvg.1
                                if (!biasAvg.1) {
                                    self.sccGoodBiasArray = [Int]()
                                }
                                self.saveRssiBias(bias: self.rssiBias, biasArray: self.sccGoodBiasArray, isConverged: self.isBiasConverged, sector_id: self.sector_id)
                                if (self.isBiasConverged) {
                                    self.postRssiBias(sector_id: self.sector_id, bias: self.rssiBias)
                                }
                            }
                        }
                        self.isBiasRequested = false
                        displayOutput.bias = self.rssiBias
                        displayOutput.isConverged = self.isBiasConverged
                    } else if (biasCheckTime > 3000) {
                        self.isBiasRequested = false
                    }
                }
                
                // Sc Compensation
                if (self.isScRequested) {
                    let compensationCheckTime = abs(result.mobile_time - self.scRequestTime)
                    if (compensationCheckTime < 100) {
                        if (result.scc < 0.55) {
                            self.scCompensationBadCount += 1
                        } else {
                            if (result.scc > 0.7) {
                                self.scCompensation = result.sc_compensation
                            }
                            self.scCompensationBadCount = 0
                        }
                        
                        if (self.scCompensationBadCount > 1) {
                            self.scCompensationBadCount = 0
                            let resultEstScCompensation = estimateScCompensation(sccResult: result.scc, scResult: result.sc_compensation, scArray: self.scCompensationArray)
                            self.scCompensationArray = resultEstScCompensation
                            self.isScRequested = false
                        }
                    } else if (compensationCheckTime > 3000) {
                        self.isScRequested = false
                    }
                }
                
                if ((self.nowTime - result.mobile_time) <= RECENT_THRESHOLD) {
                    if ((result.index - self.indexPast) < INDEX_THRESHOLD) {
                        if (result.mobile_time > self.preOutputMobileTime) {
                            if (result.phase == 4) {
                                if (self.isIndoor) {
                                    let outputBuilding = self.outputResult.building_name
                                    let outputLevel = self.outputResult.level_name
                                    let outputPhase = self.outputResult.phase
                                    
                                    self.timeUpdateOutput.building_name = outputBuilding
                                    self.timeUpdateOutput.level_name = outputLevel
                                    self.timeUpdateOutput.phase = outputPhase
                                    
                                    self.measurementOutput.building_name = outputBuilding
                                    self.measurementOutput.level_name = outputLevel
                                    self.measurementOutput.phase = outputPhase
                                    
                                    self.isActiveKf = true
                                    self.timeUpdateFlag = true
                                }
                            }
                            self.phase = result.phase
                            
                            if (self.isActiveKf && result.phase == 4) {
                                if (!(result.x == 0 && result.y == 0)) {
                                    if (self.isPhaseBreak) {
                                        if (self.runMode == "pdr") {
                                            self.kalmanR = 0.5
                                        } else if (self.runMode == "dr") {
                                            self.kalmanR = 0.5
                                        }
                                        self.SQUARE_RANGE = self.SQUARE_RANGE_SMALL
                                        
                                        self.headingKalmanR = 1
                                        self.isPhaseBreak = false
                                    }
                                    
                                    // Measurment Update
                                    let diffIndex = abs(self.indexSend - result.index)
                                    if (measurementUpdateFlag && (diffIndex<UVD_BUFFER_SIZE)) {
                                        displayOutput.indexRx = result.index
                                        
                                        // Measurement Update 하기전에 현재 Time Update 위치를 고려
                                        var resultForMu = result
                                        resultForMu.absolute_heading = compensateHeading(heading: resultForMu.absolute_heading, mode: self.runMode)
                                        let resultCorrected = self.pathMatching(building: resultForMu.building_name, level: resultForMu.level_name, x: resultForMu.x, y: resultForMu.y, heading: resultForMu.absolute_heading, tuXY: [self.pastTuResult.x, self.pastTuResult.y], mode: self.runMode, isPast: false, HEADING_RANGE: self.HEADING_RANGE)
                                        
                                        self.serverResult[0] = resultCorrected.xyh[0]
                                        self.serverResult[1] = resultCorrected.xyh[1]
                                        self.serverResult[2] = resultCorrected.xyh[2]
                                        
                                        let indexBuffer: [Int] = self.uvdIndexBuffer
                                        let tuBuffer: [[Double]] = self.tuResultBuffer
                                        
                                        var currentTuResult = self.currentTuResult
                                        var pastTuResult = self.pastTuResult
                                        
                                        var dx: Double = 0
                                        var dy: Double = 0
                                        var dh: Double = 0
                                        
                                        if (currentTuResult.mobile_time != 0 && pastTuResult.mobile_time != 0) {
                                            if (self.isEnterPhase2) {
                                                dx = currentTuResult.x - pastTuResult.x
                                                dy = currentTuResult.y - pastTuResult.y
                                                currentTuResult.absolute_heading = compensateHeading(heading: currentTuResult.absolute_heading, mode: self.runMode)
                                                pastTuResult.absolute_heading = compensateHeading(heading: pastTuResult.absolute_heading, mode: self.runMode)
                                                
                                                dh = currentTuResult.absolute_heading - pastTuResult.absolute_heading
                                                self.isEnterPhase2 = false
                                            } else {
                                                if let idx = indexBuffer.firstIndex(of: result.index) {
                                                    if ( sqrt((dx*dx) + (dy*dy)) < 15 ) {
                                                        dx = currentTuResult.x - tuBuffer[idx][0]
                                                        dy = currentTuResult.y - tuBuffer[idx][1]
                                                        currentTuResult.absolute_heading = compensateHeading(heading: currentTuResult.absolute_heading, mode: self.runMode)
                                                        let tuBufferHeading = compensateHeading(heading: tuBuffer[idx][2], mode: self.runMode)
                                                        
                                                        dh = currentTuResult.absolute_heading - tuBufferHeading
                                                    } else {
                                                        dx = currentTuResult.x - pastTuResult.x
                                                        dy = currentTuResult.y - pastTuResult.y
                                                        currentTuResult.absolute_heading = compensateHeading(heading: currentTuResult.absolute_heading, mode: self.runMode)
                                                        pastTuResult.absolute_heading = compensateHeading(heading: pastTuResult.absolute_heading, mode: self.runMode)
                                                        
                                                        dh = currentTuResult.absolute_heading - pastTuResult.absolute_heading
                                                    }
                                                } else {
                                                    dx = currentTuResult.x - pastTuResult.x
                                                    dy = currentTuResult.y - pastTuResult.y
                                                    currentTuResult.absolute_heading = compensateHeading(heading: currentTuResult.absolute_heading, mode: self.runMode)
                                                    pastTuResult.absolute_heading = compensateHeading(heading: pastTuResult.absolute_heading, mode: self.runMode)
                                                    
                                                    dh = currentTuResult.absolute_heading - pastTuResult.absolute_heading
                                                }
                                            }
                                            
                                            resultForMu.x = resultCorrected.xyh[0] + dx
                                            resultForMu.y = resultCorrected.xyh[1] + dy
                                            if (self.isNeedHeadingCorrection) {
                                                resultForMu.absolute_heading = resultCorrected.xyh[2] + dh
                                            } else {
                                                resultForMu.absolute_heading = resultForMu.absolute_heading + dh
                                                resultForMu.absolute_heading = self.compensateHeading(heading: resultForMu.absolute_heading, mode: self.runMode)
                                            }
                                        }
                                        
                                        let muOutput = measurementUpdate(timeUpdatePosition: timeUpdatePosition, serverOutputHat: resultForMu, originalResult: resultCorrected.xyh, isNeedHeadingCorrection: self.isNeedHeadingCorrection, mode: self.runMode)
                                        var muResult = fromServerToResult(fromServer: muOutput, velocity: displayOutput.velocity)
                                        muResult.mobile_time = result.mobile_time
                                        
                                        let resultLevelName = removeLevelDirectionString(levelName: result.level_name)
                                        let currentLevelName = removeLevelDirectionString(levelName: self.currentLevel)
                                        
                                        let levelArray: [String] = [resultLevelName, currentLevelName]
                                        var TIME_CONDITION = VALID_BL_CHANGE_TIME
                                        if (levelArray.contains("B0") && levelArray.contains("B2")) {
                                            TIME_CONDITION = VALID_BL_CHANGE_TIME*4
                                        }
                                        
                                        if (result.building_name != self.currentBuilding || result.level_name != self.currentLevel) {
                                            if ((result.mobile_time - self.buildingLevelChangedTime) > TIME_CONDITION) {
                                                // Building Level 이 바뀐지 10초 이상 지남 -> 서버 결과를 이용해 바뀌어야 한다고 판단
                                                self.currentBuilding = result.building_name
                                                self.currentLevel = result.level_name
                                                
                                                muResult.building_name = result.building_name
                                                muResult.level_name = result.level_name
                                            } else {
                                                muResult.building_name = self.currentBuilding
                                                muResult.level_name = self.currentLevel
                                            }
                                        }
                                        
                                        self.flagPast = false
                                        self.outputResult = muResult
                                        self.resultToReturn = self.makeOutputResult(input: self.outputResult, isPast: self.flagPast, runMode: self.runMode, isVenusMode: self.isVenusMode)
                                        timeUpdatePositionInit(serverOutput: muOutput)
                                    }
                                }
                            } else if (self.isActiveKf) {
                                self.SQUARE_RANGE = self.SQUARE_RANGE_LARGE
                                self.kalmanR = 0.01
                                self.headingKalmanR = 0.01
                                self.indexAfterResponse = 0
                                self.isPossibleEstBias = false
                                self.isNeedTrajInit = true
                                self.isPhaseBreak = true
                            }
                        }
                    }
                    self.indexPast = result.index
                }
                self.preOutputMobileTime = result.mobile_time
            } else {
                let log: String = localTime + " , (Jupiter) Error : \(statusCode) Fail to request indoor position in Phase 4"
                print(log)
            }
        })
    }
    
    @objc func osrTimerUpdate() {
        if (self.isGetFirstResponse) {
            let localTime: String = getLocalTimeString()
            let currentTime = getCurrentTimeInMilliseconds()
            let input = OnSpotRecognition(user_id: self.user_id, mobile_time: currentTime, rss_compensation: self.rssiBias)
            NetworkManager.shared.postOSR(url: OSR_URL, input: input, completion: { [self] statusCode, returnedString in
                if (statusCode == 200) {
                    let result = decodeOSR(json: returnedString)
                    if (result.building_name != "" && result.level_name != "") {
                        let isOnSpot = isOnSpotRecognition(result: result, level: self.currentLevel)
                        if (isOnSpot.isOn) {
                            let levelDestination = isOnSpot.levelDestination + isOnSpot.levelDirection
                            determineSpotDetect(result: result, lastSpotId: self.lastOsrId, levelDestination: levelDestination, currentTime: currentTime)
                        }
                    }
                }
            })
            
            // Check Entrance Level
            let isEntrance = self.checkIsEntranceLevel(result: lastResult)
            unitDRGenerator.setIsEntranceLevel(flag: isEntrance)
        } else {
            self.travelingOsrDistance = 0
        }
        
        if (self.networkCount >= 5 && NetworkCheck.shared.isConnectedToInternet()) {
            self.reporting(input: NETWORK_WAITING_FLAG)
        }
        
        if (NetworkCheck.shared.isConnectedToInternet()) {
            self.isNetworkConnectReported = false
        } else {
            self.networkCount = 0
            if (!self.isNetworkConnectReported) {
                self.isNetworkConnectReported = true
                self.reporting(input: NETWORK_CONNECTION_FLAG)
            }
        }
    }
    
    func isOnSpotRecognition(result: OnSpotRecognitionResult, level: String) -> (isOn: Bool, levelDestination: String, levelDirection: String) {
        let localTime = getLocalTimeString()
        var isOn: Bool = false
        let building_name = result.building_name
        let level_name = result.level_name
        let linked_level_name = result.linked_level_name
        
        let levelArray: [String] = [level_name, linked_level_name]
        var levelDestination: String = ""

        if (linked_level_name == "") {
            isOn = false
            return (isOn, levelDestination, "")
        } else {
            if (level_name == linked_level_name) {
                isOn = false
                return (isOn, "", "")
            }
            
            if (self.currentLevel == "") {
                isOn = false
                return (isOn, "", "")
            }
            
            // Normal OSR
            let currentLevel: String = level
            let levelNameCorrected: String = removeLevelDirectionString(levelName: currentLevel)
            for i in 0..<levelArray.count {
                if levelArray[i] != levelNameCorrected {
                    levelDestination = levelArray[i]
                    isOn = true
                }
            }
            
            // Up or Down Direction
            let currentLevelNum: Int = getLevelNumber(levelName: currentLevel)
            let destinationLevelNum: Int = getLevelNumber(levelName: levelDestination)
            let levelDirection: String = checkLevelDirection(currentLevel: currentLevelNum, destinationLevel: destinationLevelNum)
            
            return (isOn, levelDestination, levelDirection)
        }
    }
    
    func determineSpotDetect(result: OnSpotRecognitionResult, lastSpotId: Int, levelDestination: String, currentTime: Int) {
        let localTime = getLocalTimeString()
        var spotDistance = result.spot_distance
        if (spotDistance == 0) {
            spotDistance = DEFAULT_SPOT_DISTANCE
        }
        
        let levelArray: [String] = [result.level_name, result.linked_level_name]
        var TIME_CONDITION = VALID_BL_CHANGE_TIME
        if (levelArray.contains("B0") && levelArray.contains("B2")) {
            TIME_CONDITION = VALID_BL_CHANGE_TIME*4
        }
        
        if (result.spot_id != lastSpotId) {
            // Different Spot Detected
            let resultLevelName: String = removeLevelDirectionString(levelName: levelDestination)
            if (result.building_name != self.currentBuilding || resultLevelName != self.currentLevel) {
                if ((result.mobile_time - self.buildingLevelChangedTime) > TIME_CONDITION) {
                    // Building Level 이 바뀐지 7초 이상 지남 -> 서버 결과를 이용해 바뀌어야 한다고 판단
                    self.currentBuilding = result.building_name
                    self.currentLevel = levelDestination
                    self.timeUpdateOutput.building_name = result.building_name
                    self.timeUpdateOutput.level_name = levelDestination
                    self.measurementOutput.building_name = result.building_name
                    self.measurementOutput.level_name = levelDestination
                    self.outputResult.level_name = levelDestination
                    
                    self.phase2Trajectory = getTrajectoryFromLast(from: self.userTrajectoryInfo, N: 15)
//                    var accumulatedLength = 0.0
//                    for unitTraj in self.userTrajectoryInfo {
//                        accumulatedLength += unitTraj.length
//                    }
//                    let cutLength: Double = USER_TRAJECTORY_LENGTH*0.2
//                    self.phase2Trajectory = cutTrajectoryFromLast(from: self.userTrajectoryInfo, userLength: accumulatedLength, cutLength: cutLength)
                    self.phase = 2
                    self.outputResult.phase = 2
                    self.isDetermineSpot = true
                    
                    self.resultToReturn = self.makeOutputResult(input: self.outputResult, isPast: self.flagPast, runMode: self.runMode, isVenusMode: self.isVenusMode)
                }
            }
            self.currentSpot = result.spot_id
            self.lastOsrId = result.spot_id
            self.travelingOsrDistance = 0
            self.isPossibleEstBias = false
            self.buildingLevelChangedTime = currentTime
            self.preOutputMobileTime = currentTime
        } else {
            // Same Spot Detected
            if (self.travelingOsrDistance >= spotDistance) {
                let resultLevelName: String = removeLevelDirectionString(levelName: levelDestination)
                if (result.building_name != self.currentBuilding || resultLevelName != self.currentLevel) {
                    if ((result.mobile_time - self.buildingLevelChangedTime) > TIME_CONDITION) {
                        // Building Level 이 바뀐지 7초 이상 지남 -> 서버 결과를 이용해 바뀌어야 한다고 판단
                        self.currentBuilding = result.building_name
                        self.currentLevel = levelDestination
                        self.timeUpdateOutput.building_name = result.building_name
                        self.timeUpdateOutput.level_name = levelDestination
                        self.measurementOutput.building_name = result.building_name
                        self.measurementOutput.level_name = levelDestination
                        self.outputResult.level_name = levelDestination
                        
                        self.phase2Trajectory = getTrajectoryFromLast(from: self.userTrajectoryInfo, N: 15)
//                        var accumulatedLength = 0.0
//                        for unitTraj in self.userTrajectoryInfo {
//                            accumulatedLength += unitTraj.length
//                        }
//                        let cutLength: Double = USER_TRAJECTORY_LENGTH*0.2
//                        self.phase2Trajectory = cutTrajectoryFromLast(from: self.userTrajectoryInfo, userLength: accumulatedLength, cutLength: cutLength)
                        self.phase = 2
                        self.outputResult.phase = 2
                        self.isDetermineSpot = true
                        
                        self.resultToReturn = self.makeOutputResult(input: self.outputResult, isPast: self.flagPast, runMode: self.runMode, isVenusMode: self.isVenusMode)
                    }
                }
                self.currentSpot = result.spot_id
                self.lastOsrId = result.spot_id
                self.travelingOsrDistance = 0
                self.isPossibleEstBias = false
                self.buildingLevelChangedTime = currentTime
                self.preOutputMobileTime = currentTime
            }
        }
    }
    
    func getLevelNumber(levelName: String) -> Int {
        let levelNameCorrected: String = removeLevelDirectionString(levelName: levelName)
        if (levelNameCorrected[levelNameCorrected.startIndex] == "B") {
            // 지하
            let levelTemp = levelNameCorrected.substring(from: 1, to: levelNameCorrected.count-1)
            var levelNum = Int(levelTemp) ?? 0
            levelNum = (-1*levelNum)-1
            return levelNum
        } else {
            // 지상
            let levelTemp = levelNameCorrected.substring(from: 0, to: levelNameCorrected.count-2)
            var levelNum = Int(levelTemp) ?? 0
            levelNum = levelNum+1
            return levelNum
        }
    }
    
    func checkLevelDirection(currentLevel: Int, destinationLevel: Int) -> String {
        var levelDirection: String = ""
        let diffLevel: Int = destinationLevel - currentLevel
        if (diffLevel > 0) {
            levelDirection = "_D"
        }
        return levelDirection
    }
    
    func removeLevelDirectionString(levelName: String) -> String {
        var levelToReturn: String = levelName
        if (levelToReturn.contains("_D")) {
            levelToReturn = levelName.replacingOccurrences(of: "_D", with: "")
        }
        return levelToReturn
    }
    
    
    func checkInAbnormalArea(result: FineLocationTrackingResult) -> Double {
        var velocityScaleFactor: Double = 1.0
        
        let lastResult = result
        
        let buildingName = lastResult.building_name
        let levelName = removeLevelDirectionString(levelName: result.level_name)
        
        let key = "\(buildingName)_\(levelName)"
        guard let abnormalArea: [[Double]] = AbnormalArea[key] else {
            return velocityScaleFactor
        }
        
        for i in 0..<abnormalArea.count {
            if (!abnormalArea[i].isEmpty) {
                let xMin = abnormalArea[i][0]
                let yMin = abnormalArea[i][1]
                let xMax = abnormalArea[i][2]
                let yMax = abnormalArea[i][3]
                
                if (lastResult.x >= xMin && lastResult.x <= xMax) {
                    if (lastResult.y >= yMin && lastResult.y <= yMax) {
                        velocityScaleFactor = abnormalArea[i][4]
                        return velocityScaleFactor
                    }
                }
            }
        }
        
        return velocityScaleFactor
    }
    
    func checkIsEntranceLevel(result: FineLocationTrackingResult) -> Bool {
        let lastResult = result
        
        let buildingName = lastResult.building_name
        let levelName = removeLevelDirectionString(levelName: result.level_name)
        
        if (levelName == "B0") {
            return true
        } else {
            let key = "\(buildingName)_\(levelName)"
            guard let entranceArea: [[Double]] = EntranceArea[key] else {
                return false
            }
            
            for i in 0..<entranceArea.count {
                if (!entranceArea[i].isEmpty) {
                    let xMin = entranceArea[i][0]
                    let yMin = entranceArea[i][1]
                    let xMax = entranceArea[i][2]
                    let yMax = entranceArea[i][3]
                    
                    if (lastResult.x >= xMin && lastResult.x <= xMax) {
                        if (lastResult.y >= yMin && lastResult.y <= yMax) {
                            return true
                        }
                    }
                }
                
            }
            return false
        }
    }
    
    func checkInPathMatchingArea(x: Double, y: Double, building: String, level: String) -> (Bool, [Double]) {
        var area = [Double]()
        
        let buildingName = building
        let levelName = removeLevelDirectionString(levelName: level)
        
        let key = "\(buildingName)_\(levelName)"
        guard let pathMatchingArea: [[Double]] = PathMatchingArea[key] else {
            return (false, area)
        }
        
        for i in 0..<pathMatchingArea.count {
            if (!pathMatchingArea[i].isEmpty) {
                let xMin = pathMatchingArea[i][0]
                let yMin = pathMatchingArea[i][1]
                let xMax = pathMatchingArea[i][2]
                let yMax = pathMatchingArea[i][3]
                
                if (x >= xMin && x <= xMax) {
                    if (y >= yMin && y <= yMax) {
                        area = pathMatchingArea[i]
                        return (true, area)
                    }
                }
            }
        }
        
        return (false, area)
    }
    
    func saveRssiBias(bias: Int, biasArray: [Int], isConverged: Bool, sector_id: Int) {
        let currentTime = getCurrentTimeInMilliseconds()
        
        print(getLocalTimeString() + " , (Jupiter) Save Bias : \(bias) // \(biasArray) // \(isConverged)")
        // Time
        do {
            let key: String = "JupiterRssiBiasTime_\(sector_id)"
            UserDefaults.standard.set(currentTime, forKey: key)
        } catch {
            print("(Jupiter) Error : Fail to save RssiBiasTime")
        }
        
        // Converged
        do {
            let key: String = "JupiterRssiBiasConverge_\(sector_id)"
            UserDefaults.standard.set(isConverged, forKey: key)
        } catch {
            print("(Jupiter) Error : Fail to save RssiBiasConverge")
        }
        
        // Bias
        do {
            let key: String = "JupiterRssiBias_\(sector_id)"
            UserDefaults.standard.set(bias, forKey: key)
        } catch {
            print("(Jupiter) Error : Fail to save RssiBias")
        }
        
        do {
            let key: String = "JupiterRssiBiasArray_\(sector_id)"
            UserDefaults.standard.set(biasArray, forKey: key)
        } catch {
            print("(Jupiter) Error : Fail to save RssiBiasArray")
        }
    }
    
    func postRssiBias(sector_id: Int, bias: Int) {
        let localTime = getLocalTimeString()
        
        let input = JupiterBiasPost(device_model: self.deviceModel, os_version: self.osVersion, sector_id: sector_id, rss_compensation: bias)
        NetworkManager.shared.postJupiterBias(url: RCR_URL, input: input, completion: { statusCode, returnedString in
            if (statusCode == 200) {
                print(localTime + " , (Jupiter) Success : Save Rssi Bias \(bias)")
            } else {
                print(localTime + " , (Jupiter) Warnings : Save Rssi Bias ")
            }
        })
    }
    
    func loadRssiBias(sector_id: Int) -> (Int, [Int], Bool) {
        var bias: Int = 2
        var biasArray: [Int] = []
        var isConverged: Bool = false
        
        let currentTime = getCurrentTimeInMilliseconds()
        let keyBiasTime: String = "JupiterRssiBiasTime_\(sector_id)"
        if let biasTime: Int = UserDefaults.standard.object(forKey: keyBiasTime) as? Int {
            if (currentTime - biasTime) > 1000*3600*24*7  {
                print(getLocalTimeString() + " , (Jupiter) Cannot believe old bias (\(currentTime - biasTime))")
                return (bias, biasArray, isConverged)
            }
        }
        
        let keyBiasConverged: String = "JupiterRssiBiasConverge_\(sector_id)"
        if let biasConverged: Bool = UserDefaults.standard.object(forKey: keyBiasConverged) as? Bool {
            isConverged = biasConverged
        }
        
        let keyBias: String = "JupiterRssiBias_\(sector_id)"
        if let loadedRssiBias: Int = UserDefaults.standard.object(forKey: keyBias) as? Int {
            bias = loadedRssiBias
        }
        
        let keyBiasArray: String = "JupiterRssiBiasArray_\(sector_id)"
        if let loadedRssiBiasArray: [Int] = UserDefaults.standard.object(forKey: keyBiasArray) as? [Int] {
            biasArray = loadedRssiBiasArray
        }
        
        return (bias, biasArray, isConverged)
    }
    
    func makeRssiBiasArray(bias: Int) -> [Int] {
        let loadedRssiBias: Int = bias
        let biasRange: Int = 3
        var biasArray: [Int] = [loadedRssiBias, loadedRssiBias-biasRange, loadedRssiBias+biasRange]
        
        if (biasArray[1] <= BIAS_RANGE_MIN) {
            biasArray[1] = BIAS_RANGE_MIN
            biasArray[0] = BIAS_RANGE_MIN + biasRange
            biasArray[2] = BIAS_RANGE_MIN + (2*biasRange)
            if (biasArray[2] > BIAS_RANGE_MAX) {
                biasArray[2] = BIAS_RANGE_MAX
            }
        } else if (biasArray[2] >= BIAS_RANGE_MAX) {
            biasArray[2] = BIAS_RANGE_MAX
            biasArray[0] = BIAS_RANGE_MAX - biasRange
            biasArray[1] = BIAS_RANGE_MAX - (2*biasRange)
        }
        
        return biasArray
    }
    
    func reEstimateRssiBias() {
        print(getLocalTimeString() + " , (Jupiter) Bias is not correct -> Initialization")
        self.isBiasConverged = false
        
        self.rssiBias = 2
        self.rssiBiasArray = [2, 0, 4]
        self.sccGoodBiasArray = [Int]()
    }
    
    func estimateRssiBias(sccResult: Double, biasResult: Int, biasArray: [Int]) -> (Bool, [Int]) {
        var isSccHigh: Bool = false
        var newBiasArray: [Int] = biasArray
        
        let biasStandard = biasResult
        let diffScc: Double = SCC_MAX - sccResult
        
        newBiasArray[0] = biasStandard
        
        var biasRange: Int = 1
        if (diffScc < 0.1) {
            biasRange = 1
        } else if (diffScc < 0.18) {
            biasRange = 2
        } else if (diffScc < 0.25) {
            biasRange = 3
        } else {
            biasRange = 5
        }
        
        if (sccResult < SCC_THRESHOLD) {
            let biasMinus: Int = biasStandard - biasRange
            let biasPlus: Int = biasStandard + biasRange
            
            newBiasArray[1] = biasMinus
            newBiasArray[2] = biasPlus
        } else {
            isSccHigh = true
            
            let biasMinus: Int = biasStandard - 1
            let biasPlus: Int = biasStandard + 1
            
            newBiasArray[1] = biasMinus
            newBiasArray[2] = biasPlus
        }
        
        if (newBiasArray[1] <= BIAS_RANGE_MIN) {
            newBiasArray[1] = BIAS_RANGE_MIN
            newBiasArray[0] = BIAS_RANGE_MIN + biasRange
            newBiasArray[2] = BIAS_RANGE_MIN + (2*biasRange)
            if (newBiasArray[2] > BIAS_RANGE_MAX) {
                newBiasArray[2] = BIAS_RANGE_MAX
            }
        } else if (newBiasArray[2] >= BIAS_RANGE_MAX) {
            newBiasArray[2] = BIAS_RANGE_MAX
            newBiasArray[0] = BIAS_RANGE_MAX - biasRange
            newBiasArray[1] = BIAS_RANGE_MAX - (2*biasRange)
        }
        
        return (isSccHigh, newBiasArray)
    }
    
    func estimateScCompensation(sccResult: Double, scResult: Double, scArray: [Double]) -> [Double] {
        let newBiasArray: [Double] = scArray
        
        return newBiasArray
    }
    
    func averageBiasArray(biasArray: [Int]) -> (Int, Bool) {
        var bias: Int = 0
        var isConverge: Bool = false
        
        let array: [Double] = convertToDoubleArray(intArray: biasArray)
        
        let mean = array.reduce(0, +) / Double(array.count)
        let variance = array.map { pow($0 - mean, 2) }.reduce(0, +) / Double(array.count)
        let stdev = sqrt(variance)
        let validValues = array.filter { abs($0 - mean) <= 1.5 * stdev }
        
        if (validValues.count < 17) {
            let avgDouble: Double = biasArray.average
            
            bias = Int(round(avgDouble))
            isConverge = false
            return (bias, isConverge)
        } else {
            let sum = validValues.reduce(0, +)
            let avgDouble: Double = Double(sum) / Double(validValues.count)
            
            bias = Int(round(avgDouble))
            isConverge = true
            return (bias, isConverge)
        }
    }
    
    func convertToDoubleArray(intArray: [Int]) -> [Double] {
        return intArray.map { Double($0) }
    }
    
    @objc func collectTimerUpdate() {
        let localTime = getLocalTimeString()
        let validTime = self.BLE_VALID_TIME
        let currentTime = getCurrentTimeInMilliseconds()
        let bleDictionary: [String: [[Double]]]? = bleManager.bleDictionary
        if let bleData = bleDictionary {
            let bleTrimed = trimBleData(bleInput: bleData, nowTime: getCurrentTimeInMillisecondsDouble(), validTime: validTime)
            let bleAvg = avgBleData(bleDictionary: bleTrimed)
            let bleRaw = latestBleData(bleDictionary: bleTrimed)
            
            collectData.time = currentTime
            collectData.bleRaw = bleRaw
            collectData.bleAvg = bleAvg
        } else {
            let log: String = localTime + " , (Jupiter) Warnings : Fail to get recent ble"
            print(log)
        }
        
        if (isStartFlag) {
            unitDRInfo = unitDRGenerator.generateDRInfo(sensorData: sensorData)
        }
        
        collectData.isIndexChanged = false
        if (unitDRInfo.isIndexChanged) {
            collectData.isIndexChanged = unitDRInfo.isIndexChanged
            collectData.index = unitDRInfo.index
            collectData.length = unitDRInfo.length
            collectData.heading = unitDRInfo.heading
            collectData.lookingFlag = unitDRInfo.lookingFlag
        }
    }
    
    func getCurrentTimeInMilliseconds() -> Int
    {
        return Int(Date().timeIntervalSince1970 * 1000)
    }
    
    func getCurrentTimeInMillisecondsDouble() -> Double
    {
        return (Date().timeIntervalSince1970 * 1000)
    }
    
    func getLocalTimeString() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd-HH-mm-ss"
        dateFormatter.locale = Locale(identifier:"ko_KR")
        let nowDate = Date()
        let convertNowStr = dateFormatter.string(from: nowDate)
        
        return convertNowStr
    }
    
    public func jsonToResult(json: String) -> FineLocationTrackingFromServer {
        let result = FineLocationTrackingFromServer()
        let decoder = JSONDecoder()
        let jsonString = json
        
        if let data = jsonString.data(using: .utf8), let decoded = try? decoder.decode(FineLocationTrackingFromServer.self, from: data) {
            return decoded
        }
        
        return result
    }
    
    func jsonForTracking(json: String) -> FineLocationTrackingResult {
        let result = FineLocationTrackingResult()
        let decoder = JSONDecoder()
        let jsonString = json
        
        if let data = jsonString.data(using: .utf8), let decoded = try? decoder.decode(FineLocationTrackingResult.self, from: data) {
            return decoded
        }
        
        return result
    }
    
    func fromServerToResult(fromServer: FineLocationTrackingFromServer, velocity: Double) -> FineLocationTrackingResult {
        var result = FineLocationTrackingResult()
        
        result.mobile_time = fromServer.mobile_time
        result.building_name = fromServer.building_name
        result.level_name = fromServer.level_name
        result.scc = fromServer.scc
        result.x = fromServer.x
        result.y = fromServer.y
        result.absolute_heading = fromServer.absolute_heading
        result.phase = fromServer.phase
        result.calculated_time = fromServer.calculated_time
        result.index = fromServer.index
        result.velocity = velocity
        
        return result
    }
    
    private func parseRoad(data: String) -> ( [[Double]], [Double], [String] ) {
        var road = [[Double]]()
        var roadScale = [Double]()
        var roadHeading = [String]()
        
        var roadX = [Double]()
        var roadY = [Double]()
        
        let roadString = data.components(separatedBy: .newlines)
        for i in 0..<roadString.count {
            if (roadString[i] != "") {
                let lineData = roadString[i].components(separatedBy: ",")
                
                roadX.append(Double(lineData[0])!)
                roadY.append(Double(lineData[1])!)
                roadScale.append(Double(lineData[2])!)
                
                var headingArray: String = ""
                if (lineData.count > 3) {
                    for j in 3..<lineData.count {
                        headingArray.append(lineData[j])
                        if (lineData[j] != "") {
                            headingArray.append(",")
                        }
                    }
                }
                roadHeading.append(headingArray)
            }
        }
        road = [roadX, roadY]
        
        return (road, roadScale, roadHeading)
    }
    
    private func loadEntranceArea(buildingName: String, levelName: String) -> [[Double]] {
        var entranceArea = [[Double]]()
        let key: String = "\(buildingName)_\(levelName)"
        if (key == "COEX_B2") {
            entranceArea.append([225, 395, 262, 420])
            entranceArea.append([247, 263, 296, 290])
            entranceArea.append([14, 360, 67, 396])
            entranceArea.append([265, 0, 298, 29])
            entranceArea.append([241, 154, 257, 185])
        } else if (key == "COEX_B3") {
            entranceArea.append([225, 395, 262, 420])
            entranceArea.append([247, 263, 296, 290])
        } else if (key == "COEX_B4") {
            entranceArea.append([225, 395, 262, 420])
            entranceArea.append([247, 263, 296, 290])
        }
        
        return entranceArea
    }
    
    private func loadPathMatchingArea(buildingName: String, levelName: String) -> [[Double]] {
        var pathMatchingArea = [[Double]]()
        let key: String = "\(buildingName)_\(levelName)"
        if (key == "COEX_B2") {
            pathMatchingArea.append([265, 0, 298, 29])
            pathMatchingArea.append([238, 154, 258, 198])
            pathMatchingArea.append([284, 270, 296, 305])
            pathMatchingArea.append([227, 390, 262, 448])
            pathMatchingArea.append([14, 365, 67, 396])
        }
        
        return pathMatchingArea
    }
    
    private func updateAllResult(result: [Double]) {
        self.timeUpdatePosition.x = result[0]
        self.timeUpdatePosition.y = result[1]
        
        self.timeUpdateOutput.x = result[0]
        self.timeUpdateOutput.y = result[1]
        
        self.measurementPosition.x = result[0]
        self.measurementPosition.y = result[1]
        
        self.measurementOutput.x = result[0]
        self.measurementOutput.y = result[1]
        
        self.outputResult.x = result[0]
        self.outputResult.y = result[1]
        
        var accumulatedLength = 0.0
        for userTrajectory in self.userTrajectoryInfo {
            accumulatedLength += userTrajectory.length
        }
        
        if (accumulatedLength > USER_TRAJECTORY_LENGTH*0.5) {
            self.timeUpdatePosition.heading = result[2]
            self.timeUpdateOutput.absolute_heading = result[2]
            self.measurementPosition.heading = result[2]
            self.measurementOutput.absolute_heading = result[2]
            self.outputResult.absolute_heading = result[2]
        }
        self.resultToReturn = self.makeOutputResult(input: self.outputResult, isPast: self.flagPast, runMode: self.runMode, isVenusMode: self.isVenusMode)
    }
    
    public func pathMatching(building: String, level: String, x: Double, y: Double, heading: Double, tuXY: [Double], mode: String, isPast: Bool, HEADING_RANGE: Double) -> (isSuccess: Bool, xyh: [Double]) {
        var isSuccess: Bool = false
        var xyh: [Double] = [x, y, heading]
        let levelCopy: String = self.removeLevelDirectionString(levelName: level)
        let key: String = "\(building)_\(levelCopy)"
        if (isPast) {
            isSuccess = true
            return (isSuccess, xyh)
        }
        
        if (!(building.isEmpty) && !(level.isEmpty)) {
            guard let mainRoad: [[Double]] = self.PathPoint[key] else {
                return (isSuccess, xyh)
            }
            
            guard let mainMagScale: [Double] = self.PathMagScale[key] else {
                return (isSuccess, xyh)
            }
            
            guard let mainHeading: [String] = self.PathHeading[key] else {
                return (isSuccess, xyh)
            }
            
            let pathhMatchingArea = checkInPathMatchingArea(x: x, y: y, building: building, level: level)
            
            // Heading 사용
            var idshArray = [[Double]]()
            var pathArray = [[Double]]()
            var failArray = [[Double]]()
            if (!mainRoad.isEmpty) {
                let roadX = mainRoad[0]
                let roadY = mainRoad[1]
                
                var xMin = x - SQUARE_RANGE
                var xMax = x + SQUARE_RANGE
                var yMin = y - SQUARE_RANGE
                var yMax = y + SQUARE_RANGE
                if (pathhMatchingArea.0) {
                    xMin = pathhMatchingArea.1[0]
                    yMin = pathhMatchingArea.1[1]
                    xMax = pathhMatchingArea.1[2]
                    yMax = pathhMatchingArea.1[3]
                }
                
                for i in 0..<roadX.count {
                    let xPath = roadX[i]
                    let yPath = roadY[i]
                    
                    // XY 범위 안에 있는 값 중에 검사
                    if (xPath >= xMin && xPath <= xMax) {
                        if (yPath >= yMin && yPath <= yMax) {
                            let index = Double(i)
                            let distance = sqrt(pow(x-xPath, 2) + pow(y-yPath, 2))
                            
                            let magScale = mainMagScale[i]
                            var idsh: [Double] = [index, distance, magScale, heading]
                            var path: [Double] = [xPath, yPath, 0, 0]
                            
                            let headingArray = mainHeading[i]
                            var isValidIdh: Bool = true
                            if (!headingArray.isEmpty) {
                                let headingData = headingArray.components(separatedBy: ",")
                                var diffHeading = [Double]()
                                for j in 0..<headingData.count {
                                    if(!headingData[j].isEmpty) {
                                        let mapHeading = Double(headingData[j])!
                                        if (heading > 270 && (mapHeading >= 0 && mapHeading < 90)) {
                                            diffHeading.append(abs(heading - (mapHeading+360)))
                                        } else if (mapHeading > 270 && (heading >= 0 && heading < 90)) {
                                            diffHeading.append(abs(mapHeading - (heading+360)))
                                        } else {
                                            diffHeading.append(abs(heading - mapHeading))
                                        }
                                    }
                                }
                                
                                if (!diffHeading.isEmpty) {
                                    let idxHeading = diffHeading.firstIndex(of: diffHeading.min()!)
                                    let minHeading = Double(headingData[idxHeading!])!
                                    idsh[3] = minHeading
                                    if (mode == "pdr") {
                                        
                                    } else {
                                        if (heading > 270 && (minHeading >= 0 && minHeading < 90)) {
                                            if (abs(heading-360) >= HEADING_RANGE) {
                                                isValidIdh = false
                                            }
                                        } else if (minHeading > 270 && (heading >= 0 && heading < 90)) {
                                            if (abs(minHeading-360) >= HEADING_RANGE) {
                                                isValidIdh = false
                                            }
                                        } else {
                                            if (abs(heading-minHeading) >= HEADING_RANGE) {
                                                isValidIdh = false
                                            }
                                        }
                                    }
                                    path[2] = minHeading
                                    path[3] = 1
                                }
                            }
                            if (isValidIdh) {
                                idshArray.append(idsh)
                                pathArray.append(path)
                            } else {
                                failArray.append(idsh)
                            }
                        }
                    }
                }
                
                if (!idshArray.isEmpty) {
                    let sortedIdsh = idshArray.sorted(by: {$0[1] < $1[1] })
                    var index: Int = 0
                    var correctedHeading: Double = heading
                    var correctedScale = 1.0
                    
                    if (!sortedIdsh.isEmpty) {
                        let minData: [Double] = sortedIdsh[0]
                        index = Int(minData[0])
                        if (mode == "pdr") {
                            correctedHeading = heading
                        } else {
                            correctedScale = minData[2]
                            correctedHeading = minData[3]
                        }
                    }
                    
                    isSuccess = true
                    
                    if (correctedScale < 0.7) {
                        correctedScale = 0.7
                    }
                    
                    unitDRGenerator.setVelocityScaleFactor(scaleFactor: correctedScale)
                    xyh = [roadX[index], roadY[index], correctedHeading]
                }
            }
        }
        return (isSuccess, xyh)
    }
    
    func getPathMatchingHeadings(building: String, level: String, x: Double, y: Double, heading: Double, RANGE: Double) -> [Double] {
        var headings: [Double] = []
        let levelCopy: String = self.removeLevelDirectionString(levelName: level)
        let key: String = "\(building)_\(levelCopy)"
        
        if (!(building.isEmpty) && !(level.isEmpty)) {
            guard let mainRoad: [[Double]] = self.PathPoint[key] else {
                return headings
            }
            
            guard let mainHeading: [String] = self.PathHeading[key] else {
                return headings
            }
            
            if (!mainRoad.isEmpty) {
                let roadX = mainRoad[0]
                let roadY = mainRoad[1]
                
                let xMin = x - RANGE
                let xMax = x + RANGE
                let yMin = y - RANGE
                let yMax = y + RANGE
                
                for i in 0..<roadX.count {
                    let xPath = roadX[i]
                    let yPath = roadY[i]
                    
                    if (xPath >= xMin && xPath <= xMax) {
                        if (yPath >= yMin && yPath <= yMax) {
                            let headingArray = mainHeading[i]
                            if (!headingArray.isEmpty) {
                                let headingData = headingArray.components(separatedBy: ",")
                                for j in 0..<headingData.count {
                                    if (!headingData[j].isEmpty) {
                                        let value = Double(headingData[j])!
                                        if (!headings.contains(value)) {
                                            headings.append(value)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        
        
        return headings
    }
    
    func checkHeadingCorrection(buffer: [Double]) -> Bool {
        if (buffer.count >= HEADING_BUFFER_SIZE) {
            let firstHeading: Double = buffer.first ?? 0.0
            let lastHeading: Double = buffer.last ?? 0.0
            
            self.headingBuffer.removeFirst()
            
            let diffHeading: Double = abs(lastHeading - firstHeading)
            if (diffHeading < 10.0) {
                return true
            } else {
                return false
            }
        } else {
            return false
        }
    }
    
    func postUser(url: String, input: UserInfo, completion: @escaping (Int, String) -> Void) {
        // [http 비동기 방식을 사용해서 http 요청 수행 실시]
        let urlComponents = URLComponents(string: url)
        var requestURL = URLRequest(url: (urlComponents?.url)!)
        
        requestURL.httpMethod = "POST"
        let encodingData = JSONConverter.encodeJson(param: input)
        requestURL.httpBody = encodingData
        requestURL.addValue("application/json", forHTTPHeaderField: "Content-Type")
        requestURL.setValue("\(encodingData)", forHTTPHeaderField: "Content-Length")
        
        let dataTask = URLSession.shared.dataTask(with: requestURL, completionHandler: { (data, response, error) in
            
            // [error가 존재하면 종료]
            guard error == nil else {
                // [콜백 반환]
                completion(500, error?.localizedDescription ?? "Fail")
                return
            }
            
            // [status 코드 체크 실시]
            let successsRange = 200..<300
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, successsRange.contains(statusCode)
            else {
                // [콜백 반환]
                completion(500, (response as? HTTPURLResponse)?.description ?? "Fail")
                return
            }
            
            // [response 데이터 획득]
            let resultCode = (response as? HTTPURLResponse)?.statusCode ?? 500 // [상태 코드]
            let resultLen = data! // [데이터 길이]
            let resultData = String(data: resultLen, encoding: .utf8) ?? "" // [데이터 확인]
            
            // [콜백 반환]
            DispatchQueue.main.async {
                completion(resultCode, resultData)
            }
        })
        
        // [network 통신 실행]
        dataTask.resume()
    }
    
    func postSector(url: String, input: SectorInfo, completion: @escaping (Int, String) -> Void) {
        // [http 비동기 방식을 사용해서 http 요청 수행 실시]
        let urlComponents = URLComponents(string: url)
        var requestURL = URLRequest(url: (urlComponents?.url)!)
        
        requestURL.httpMethod = "POST"
        let encodingData = JSONConverter.encodeJson(param: input)
        requestURL.httpBody = encodingData
        requestURL.addValue("application/json", forHTTPHeaderField: "Content-Type")
        requestURL.setValue("\(encodingData)", forHTTPHeaderField: "Content-Length")
        
        let dataTask = URLSession.shared.dataTask(with: requestURL, completionHandler: { (data, response, error) in
            
            // [error가 존재하면 종료]
            guard error == nil else {
                // [콜백 반환]
                completion(500, error?.localizedDescription ?? "Fail")
                return
            }
            
            // [status 코드 체크 실시]
            let successsRange = 200..<300
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, successsRange.contains(statusCode)
            else {
                // [콜백 반환]
                completion(500, (response as? HTTPURLResponse)?.description ?? "Fail")
                return
            }
            
            // [response 데이터 획득]
            let resultCode = (response as? HTTPURLResponse)?.statusCode ?? 500 // [상태 코드]
            let resultLen = data! // [데이터 길이]
            let resultData = String(data: resultLen, encoding: .utf8) ?? "" // [데이터 확인]
            
            // [콜백 반환]
            DispatchQueue.main.async {
                completion(resultCode, resultData)
            }
        })
        
        // [network 통신 실행]
        dataTask.resume()
    }
    
    func jsonToCardList(json: String) -> CardList {
        let result = CardList(sectors: [])
        let decoder = JSONDecoder()
        
        let jsonString = json
        
        if let data = jsonString.data(using: .utf8), let decoded = try? decoder.decode(CardList.self, from: data) {
            return decoded
        }
        
        return result
    }
    
    func jsonToSectorInfoResult(json: String) -> SectorInfoResult {
        let result = SectorInfoResult(building_level: [[]])
        let decoder = JSONDecoder()
        
        let jsonString = json
        
        if let data = jsonString.data(using: .utf8), let decoded = try? decoder.decode(SectorInfoResult.self, from: data) {
            return decoded
        }
        
        return result
    }
    
    func setModeParam(mode: String, phase: Int) {
        if (mode == "pdr") {
//            self.USER_TRAJECTORY_LENGTH = ceil(self.USER_TRAJECTORY_LENGTH_ORIGIN*(0.6))
            self.USER_TRAJECTORY_LENGTH = self.USER_TRAJECTORY_DIAGONAL
            self.kalmanR = 0.5
            self.INIT_INPUT_NUM = 3
            self.VALUE_INPUT_NUM = 5
            self.SQUARE_RANGE = self.SQUARE_RANGE_SMALL
            
            if (phase == 4) {
                self.UVD_INPUT_NUM = self.VALUE_INPUT_NUM
                self.INDEX_THRESHOLD = 21
            } else {
                self.UVD_INPUT_NUM = self.INIT_INPUT_NUM
                self.INDEX_THRESHOLD = 11
            }
            
        } else if (mode == "dr") {
            self.USER_TRAJECTORY_LENGTH = self.USER_TRAJECTORY_LENGTH_ORIGIN
            self.kalmanR = 3
            self.INIT_INPUT_NUM = 5
            self.VALUE_INPUT_NUM = self.UVD_BUFFER_SIZE
            self.SQUARE_RANGE = self.SQUARE_RANGE_LARGE
            
            if (phase == 4) {
                self.UVD_INPUT_NUM = self.VALUE_INPUT_NUM
                self.INDEX_THRESHOLD = (UVD_INPUT_NUM*2)+1
            } else {
                self.UVD_INPUT_NUM = self.INIT_INPUT_NUM
                self.INDEX_THRESHOLD = UVD_INPUT_NUM+1
            }
        }
    }
    
    func countAllValuesInDictionary(_ dictionary: [String: [String]]) -> Int {
        var count = 0
        for (_, value) in dictionary {
            count += value.count
        }
        return count
    }
    
    // Kalman Filter
    func timeUpdatePositionInit(serverOutput: FineLocationTrackingFromServer) {
        timeUpdateOutput = serverOutput
        if (!measurementUpdateFlag) {
            timeUpdatePosition = KalmanOutput(x: Double(timeUpdateOutput.x), y: Double(timeUpdateOutput.y), heading: timeUpdateOutput.absolute_heading)
            timeUpdateFlag = true
        } else {
            timeUpdatePosition = KalmanOutput(x: measurementPosition.x, y: measurementPosition.y, heading: updateHeading)
        }
    }
    
    func timeUpdate(length: Double, diffHeading: Double, mobileTime: Int, isNeedHeadingCorrection: Bool, runMode: String) -> FineLocationTrackingFromServer {
        updateHeading = timeUpdatePosition.heading + diffHeading
        
        let dx = length*cos(updateHeading*D2R)
        let dy = length*sin(updateHeading*D2R)
        
        timeUpdatePosition.x = timeUpdatePosition.x + dx
        timeUpdatePosition.y = timeUpdatePosition.y + dy
        timeUpdatePosition.heading = updateHeading
        self.preTuMmHeading = compensateHeading(heading: updateHeading, mode: "dr")
        
        var timeUpdateCopy = timeUpdatePosition
        let correctedTuCopy = self.pathMatching(building: timeUpdateOutput.building_name, level: timeUpdateOutput.level_name, x: timeUpdateCopy.x, y: timeUpdateCopy.y, heading: timeUpdateCopy.heading, tuXY: [0,0], mode: "dr", isPast: false, HEADING_RANGE: self.HEADING_RANGE)
        
        if (correctedTuCopy.isSuccess) {
            if (runMode == "pdr") {
                timeUpdateCopy.x = correctedTuCopy.xyh[0]
                timeUpdateCopy.y = correctedTuCopy.xyh[1]
            } else {
                timeUpdateCopy.x = correctedTuCopy.xyh[0]
                timeUpdateCopy.y = correctedTuCopy.xyh[1]
                if (isNeedHeadingCorrection && self.phase < 4) {
                    timeUpdateCopy.heading = correctedTuCopy.xyh[2]
                }
            }
            timeUpdatePosition = timeUpdateCopy
        } else {
            let correctedTuCopy = self.pathMatching(building: timeUpdateOutput.building_name, level: timeUpdateOutput.level_name, x: timeUpdateCopy.x, y: timeUpdateCopy.y, heading: timeUpdateCopy.heading, tuXY: [0,0], mode: "pdr", isPast: false, HEADING_RANGE: self.HEADING_RANGE)
            timeUpdateCopy.x = correctedTuCopy.xyh[0]
            timeUpdateCopy.y = correctedTuCopy.xyh[1]
            timeUpdatePosition = timeUpdateCopy
        }
        
        kalmanP += kalmanQ
        headingKalmanP += headingKalmanQ
        
        timeUpdateOutput.x = timeUpdatePosition.x
        timeUpdateOutput.y = timeUpdatePosition.y
        timeUpdateOutput.absolute_heading = timeUpdatePosition.heading
        timeUpdateOutput.mobile_time = mobileTime
        
        measurementUpdateFlag = true
        
        return timeUpdateOutput
    }
    
    func measurementUpdate(timeUpdatePosition: KalmanOutput, serverOutputHat: FineLocationTrackingFromServer, originalResult: [Double], isNeedHeadingCorrection: Bool, mode: String) -> FineLocationTrackingFromServer {
        var serverOutputHatCopy = serverOutputHat
        serverOutputHatCopy.absolute_heading = compensateHeading(heading: serverOutputHatCopy.absolute_heading, mode: mode)
        
        // ServerOutputHat을 맵매칭
        let serverOutputHatCopyMm = self.pathMatching(building: serverOutputHatCopy.building_name, level: serverOutputHatCopy.level_name, x: serverOutputHatCopy.x, y: serverOutputHatCopy.y, heading: serverOutputHatCopy.absolute_heading, tuXY: [0, 0], mode: mode, isPast: false, HEADING_RANGE: self.HEADING_RANGE)
        
        var serverOutputHatMm: FineLocationTrackingFromServer = serverOutputHatCopy
        var timeUpdateHeadingCopy = compensateHeading(heading: timeUpdatePosition.heading, mode: mode)
        
        if (serverOutputHatCopyMm.isSuccess) {
            serverOutputHatMm.x = serverOutputHatCopyMm.xyh[0]
            serverOutputHatMm.y = serverOutputHatCopyMm.xyh[1]
            if (isNeedHeadingCorrection) {
                serverOutputHatMm.absolute_heading = serverOutputHatCopyMm.xyh[2]
                if (timeUpdateHeadingCopy >= 270 && (serverOutputHatMm.absolute_heading >= 0 && serverOutputHatMm.absolute_heading < 90)) {
                    serverOutputHatMm.absolute_heading = serverOutputHatMm.absolute_heading + 360
                } else if (serverOutputHatMm.absolute_heading >= 270 && (timeUpdateHeadingCopy >= 0 && timeUpdateHeadingCopy < 90)) {
                    timeUpdateHeadingCopy = timeUpdateHeadingCopy + 360
                }
            } else {
                serverOutputHatMm.absolute_heading = serverOutputHatCopy.absolute_heading
            }
        } else {
            serverOutputHatMm.absolute_heading = originalResult[2]
        }
        
        measurementOutput = serverOutputHatMm
        
        kalmanK = kalmanP / (kalmanP + kalmanR)
        headingKalmanK = headingKalmanP / (headingKalmanP + headingKalmanR)
        
        measurementPosition.x = timeUpdatePosition.x + kalmanK * (Double(serverOutputHatMm.x) - timeUpdatePosition.x)
        measurementPosition.y = timeUpdatePosition.y + kalmanK * (Double(serverOutputHatMm.y) - timeUpdatePosition.y)
        updateHeading = timeUpdateHeadingCopy + headingKalmanK * (serverOutputHatMm.absolute_heading - timeUpdateHeadingCopy)
        
        measurementOutput.x = measurementPosition.x
        measurementOutput.y = measurementPosition.y
        kalmanP -= kalmanK * kalmanP
        headingKalmanP -= headingKalmanK * headingKalmanP
        
        let measurementOutputCorrected = self.pathMatching(building: measurementOutput.building_name, level: measurementOutput.level_name, x: measurementOutput.x, y: measurementOutput.y, heading: updateHeading, tuXY: [0,0], mode: mode, isPast: false, HEADING_RANGE: self.HEADING_RANGE)
        
        if (measurementOutputCorrected.isSuccess) {
            let diffX = timeUpdatePosition.x - measurementOutputCorrected.xyh[0]
            let diffY = timeUpdatePosition.y - measurementOutputCorrected.xyh[1]
            let diffXY = sqrt(diffX*diffX + diffY*diffY)
            
            if (diffXY > 30) {
                // Use Server Result
                let measurementOutputCorrected = self.pathMatching(building: measurementOutput.building_name, level: measurementOutput.level_name, x: measurementOutput.x, y: measurementOutput.y, heading: updateHeading, tuXY: [0,0], mode: "pdr", isPast: false, HEADING_RANGE: self.HEADING_RANGE)
                
                // Use Server Result
                self.timeUpdatePosition.x = measurementOutputCorrected.xyh[0]
                self.timeUpdatePosition.y = measurementOutputCorrected.xyh[1]
                self.timeUpdatePosition.heading = measurementOutputCorrected.xyh[2]
                
                measurementOutput.x = measurementOutputCorrected.xyh[0]
                measurementOutput.y = measurementOutputCorrected.xyh[1]
                updateHeading = measurementOutputCorrected.xyh[2]
                
                backKalmanParam()
            } else {
                self.timeUpdatePosition.x = measurementOutputCorrected.xyh[0]
                self.timeUpdatePosition.y = measurementOutputCorrected.xyh[1]
                
                measurementOutput.x = measurementOutputCorrected.xyh[0]
                measurementOutput.y = measurementOutputCorrected.xyh[1]
                
                if (isNeedHeadingCorrection) {
                    self.timeUpdatePosition.heading = measurementOutputCorrected.xyh[2]
                    updateHeading = measurementOutputCorrected.xyh[2]
                } else {
                    if (mode == "pdr") {
                        self.timeUpdatePosition.heading = measurementOutputCorrected.xyh[2]
                        updateHeading = measurementOutputCorrected.xyh[2]
                    } else {
                        self.timeUpdatePosition.heading = timeUpdateHeadingCopy
                        updateHeading = timeUpdateHeadingCopy
                    }
                }
                saveKalmanParam()
            }
        } else {
            let measurementOutputCorrected = self.pathMatching(building: measurementOutput.building_name, level: measurementOutput.level_name, x: measurementOutput.x, y: measurementOutput.y, heading: updateHeading, tuXY: [0,0], mode: "pdr", isPast: false, HEADING_RANGE: self.HEADING_RANGE)
            
            // Use Server Result
            self.timeUpdatePosition.x = measurementOutputCorrected.xyh[0]
            self.timeUpdatePosition.y = measurementOutputCorrected.xyh[1]
            self.timeUpdatePosition.heading = measurementOutputCorrected.xyh[2]
            
            measurementOutput.x = measurementOutputCorrected.xyh[0]
            measurementOutput.y = measurementOutputCorrected.xyh[1]
            updateHeading = measurementOutputCorrected.xyh[2]
            
            backKalmanParam()
        }
        
        return measurementOutput
    }
    
    func saveKalmanParam() {
        self.pastKalmanP = self.kalmanP
        self.pastKalmanQ = self.kalmanQ
        self.pastKalmanR = self.kalmanR
        self.pastKalmanK = self.kalmanK
        
        self.pastHeadingKalmanP = self.headingKalmanP
        self.pastHeadingKalmanQ = self.headingKalmanQ
        self.pastHeadingKalmanR = self.headingKalmanR
        self.pastHeadingKalmanK = self.headingKalmanK
    }
    
    func backKalmanParam() {
        self.kalmanP = self.pastKalmanP
        self.kalmanQ = self.pastKalmanQ
        self.kalmanR = self.pastKalmanR
        self.kalmanK = self.pastKalmanK
        
        self.headingKalmanP = self.pastHeadingKalmanP
        self.headingKalmanQ = self.pastHeadingKalmanQ
        self.headingKalmanR = self.pastHeadingKalmanR
        self.headingKalmanK = self.pastHeadingKalmanK
    }
    
    func compensateHeading(heading: Double, mode: String) -> Double {
        var headingToReturn: Double = heading
        if (mode == "pdr") {
            
        } else {
            if (headingToReturn < 0) {
                headingToReturn = headingToReturn + 360
            }
            headingToReturn = headingToReturn - floor(headingToReturn/360)*360
        }
        
        return headingToReturn
    }
    
    func setValidTime(mode: String) {
        if (mode == "dr") {
            self.BLE_VALID_TIME = 1000
        } else {
            self.BLE_VALID_TIME = 1500
        }
    }
    
    func trimBleData(bleInput: [String: [[Double]]], nowTime: Double, validTime: Double) -> [String: [[Double]]] {
        var trimmedData = [String: [[Double]]]()
        
        for (bleID, bleData) in bleInput {
            let newValue = bleData.filter { data in
                let rssi = data[0]
                let time = data[1]
                
                return (nowTime - time <= validTime) && (rssi >= -100)
            }
            
            if !newValue.isEmpty {
                trimmedData[bleID] = newValue
            }
        }
        
        return trimmedData
    }
    
    
    func avgBleData(bleDictionary: [String: [[Double]]]) -> [String: Double] {
        let digit: Double = pow(10, 2)
        var ble = [String: Double]()
        
        let keys: [String] = Array(bleDictionary.keys)
        for index in 0..<keys.count {
            let bleID: String = keys[index]
            let bleData: [[Double]] = bleDictionary[bleID]!
            let bleCount = bleData.count
            
            var rssiSum: Double = 0
            
            for i in 0..<bleCount {
                let rssi = bleData[i][0]
                rssiSum += rssi
            }
            let rssiFinal: Double = floor(((rssiSum/Double(bleData.count))) * digit) / digit
            
            if ( rssiSum == 0 ) {
                ble.removeValue(forKey: bleID)
            } else {
                ble.updateValue(rssiFinal, forKey: bleID)
            }
        }
        return ble
    }
    
    func latestBleData(bleDictionary: [String: [[Double]]]) -> [String: Double] {
        var ble = [String: Double]()
        
        let keys: [String] = Array(bleDictionary.keys)
        for index in 0..<keys.count {
            let bleID: String = keys[index]
            let bleData: [[Double]] = bleDictionary[bleID]!
            
            let rssiFinal: Double = bleData[bleData.count-1][0]
            
            ble.updateValue(rssiFinal, forKey: bleID)
        }
        return ble
    }
    
    @objc func onDidReceiveNotification(_ notification: Notification) {
        if notification.name == .didEnterBackground {
            self.enterBackground()
        }
        
        if notification.name == .didBecomeActive {
            self.enterForeground()
        }
    }
}
