import Foundation
import CoreMotion

public class ServiceManager: Observation {
    
    func tracking(input: FineLocationTrackingResult, isPast: Bool) {
        for observer in observers {
            var result = input
            if (result.x != 0 && result.y != 0 && result.building_name != "" && result.level_name != "") {
                result.absolute_heading = compensateHeading(heading: result.absolute_heading, mode: self.runMode)
                result.mode = self.runMode
                displayOutput.mode = self.runMode
                
                // Map Matching
                if (self.isMapMatching) {
                    let correctResult = correct(building: result.building_name, level: result.level_name, x: result.x, y: result.y, heading: result.absolute_heading, tuXY: [0,0], mode: self.runMode, isPast: isPast, HEADING_RANGE: self.HEADING_RANGE)
                    
                    if (correctResult.isSuccess) {
                        result.x = correctResult.xyh[0]
                        result.y = correctResult.xyh[1]
                        result.absolute_heading = correctResult.xyh[2]
                    } else {
                        if (isActiveKf) {
                            result = self.lastResult
                        } else {
                            let correctResult = correct(building: result.building_name, level: result.level_name, x: result.x, y: result.y, heading: result.absolute_heading, tuXY: [0,0], mode: "pdr", isPast: isPast, HEADING_RANGE: self.HEADING_RANGE)
                            result.x = correctResult.xyh[0]
                            result.y = correctResult.xyh[1]
                            result.absolute_heading = correctResult.xyh[2]
                        }
                    }
                }
                displayOutput.heading = result.absolute_heading

                // Past Result Update
                if (pastResult.isEmpty) {
                    pastResult.append(result.x)
                    pastResult.append(result.y)
                    pastResult.append(result.absolute_heading)
                } else {
                    pastResult[0] = result.x
                    pastResult[1] = result.y
                    pastResult[2] = result.absolute_heading
                }

                var updatedResult = FineLocationTrackingResult()
                let trackingTime = getCurrentTimeInMilliseconds()
                self.lastTrackingTime = trackingTime
                
                updatedResult.mobile_time = trackingTime
                updatedResult.building_name = result.building_name
                updatedResult.level_name = removeLevelDirectionString(levelName: result.level_name)
                updatedResult.scc = result.scc
                updatedResult.x = result.x
                updatedResult.y = result.y
                updatedResult.absolute_heading = result.absolute_heading
                updatedResult.phase = result.phase
                updatedResult.calculated_time = result.calculated_time
                updatedResult.index = result.index
                
                updatedResult.velocity = round(result.velocity*100)/100
                updatedResult.mode = result.mode
                
                displayOutput.building = updatedResult.building_name
                displayOutput.level = updatedResult.level_name
                displayOutput.scc = updatedResult.scc
                displayOutput.phase = String(updatedResult.phase)

                self.lastResult = updatedResult
                
                observer.update(result: updatedResult)
            }
        }
    }
    
    func reporting(input: Int) {
        for observer in observers {
            observer.report(flag: input)
        }
    }
    
    // 0 : Release  //  1 : Test
    var serverType: Int = 0
    // 0 : Android  //  1 : iOS
    var osType: Int = 1
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
    
    var Road = [String: [[Double]]]()
    var RoadHeading = [String: [String]]()
    var AbnormalArea = [String: [[Double]]]()
    
    
    // ----- Sensor & BLE ----- //
    var sensorData = SensorData()
    public var collectData = CollectData()
    
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
    var receivedForceTimer: Timer?
    var RFD_INTERVAL: TimeInterval = 1/2 // second

    var userVelocityTimer: Timer?
    var UVD_INTERVAL: TimeInterval = 1/40 // second

    var requestTimer: Timer?
    var RQ_INTERVAL: TimeInterval = 2 // second

    var updateTimer: Timer?
    var UPDATE_INTERVAL: TimeInterval = 1/5 // second

    var osrTimer: Timer?
    var OSR_INTERVAL: TimeInterval = 2
    
    let SENSOR_INTERVAL: TimeInterval = 1/100
    
    var collectTimer: Timer?
    // ------------------ //
    
    
    // ----- Network ----- //
    var inputReceivedForce: [ReceivedForce] = [ReceivedForce(user_id: "", mobile_time: 0, ble: [:], pressure: 0)]
    var inputUserVelocity: [UserVelocity] = [UserVelocity(user_id: "", mobile_time: 0, index: 0, length: 0, heading: 0, looking: true)]
    var isStartOSA: Bool = false
    // ------------------- //
    
    
    // ----- Fine Location Tracking ----- //
    var unitDRInfo = UnitDRInfo()
    var unitDRGenerator = UnitDRGenerator()
    
    var unitDistane: Double = 0
    var onStartFlag: Bool = false
    
    var preOutputMobileTime: Int = 0
    var preUnitHeading: Double = 0
    
    public var displayOutput = ServiceResult()
    
    var nowTime: Int = 0
    var RECENT_THRESHOLD: Int = 10000 // 2200
    var INDEX_THRESHOLD: Int = 11
    let VALID_BL_CHANGE_TIME = 10000
    let VALID_BL_CHANGE_TIME_SAME_SPOT = 5000
    
    var lastOsrId: Int = 0
    var buildingLevelChangedTime: Int = 0
    var travelingOsrDistance: Double = 0
    var distanceAfterPhase1: Double = 0
    
    var isGetFirstResponse: Bool = false
    var indexAfterResponse: Int = 0
    var isPossibleEstBias: Bool = false
    
    var rssiBiasArray: [Int] = [4, 2, 6]
    var rssiBias: Int = 0
    let SCC_THRESHOLD: Double = 0.75
    let SCC_MAX: Double = 0.8
    let BIAS_RANGE_MAX: Int = 10
    let BIAS_RANGE_MIN: Int = -3
    var sccGoodCount: Int = 0
    var sccGoodBiasArray = [Int]()
    var biasRequestTime: Int = 0
    var isBiasRequested: Bool = false
    let MINIMUN_INDEX_FOR_BIAS: Int = 30
    let GOOD_BIAS_ARRAY_SIZE: Int = 15
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

    var timeUpdatePosition = KalmanOutput()
    var measurementPosition = KalmanOutput()

    var timeUpdateOutput = FineLocationTrackingFromServer()
    var measurementOutput = FineLocationTrackingFromServer()
    
    var pastResult = [Double]()
    var currentBuilding: String = ""
    var currentLevel: String = "0F"
    var currentSpot: Int = 0
    
    var buildingBuffer = [String]()
    var levelBuffer = [String]()
    
    var isMapMatching: Bool = false
    
    var isActiveService: Bool = true
    var isActiveRF: Bool = true
    var isEmptyRF: Bool = false
    var isAnswered: Bool = false
    var isActiveKf: Bool = false
    var isActiveReturn: Bool = true
    var isStop: Bool = true
    var isEntered: Bool = false
    var phase4Count: Int = 0
    
    var timeActiveRF: Double = 0
    var timeActiveUV: Double = 0
    var timeEmptyRF: Double = 0
    var timeRequest: Double = 0
    var timePhaseChange: Double = 0
    var timeSleepRF: Double = 0
    var timeSleepUV: Double = 0
    let STOP_THRESHOLD: Double = 2
    let SLEEP_THRESHOLD: Double = 600 // 10분
    let SLEEP_THRESHOLD_RF: Double = 6 // 6s
    
    var lastTrackingTime: Int = 0
    var lastResult = FineLocationTrackingResult()
    var lastResultBufferUvdChanged = [Any]()
    
    var SQUARE_RANGE: Double = 10
    let SQUARE_RANGE_SMALL: Double = 10
    let SQUARE_RANGE_LARGE: Double = 12
    
    let HEADING_RANGE: Double = 50
    var pastMatchingResult: [Double] = [0, 0, 0, 0]
    var matchingFailCount: Int = 0
    
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
    let SAME_SPOT_DISTANCE: Double = 80

    // Output
    var outputResult = FineLocationTrackingResult()
    var flagPast: Bool = false
    
    public override init() {
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
        
        onStartFlag = false
        if (self.service == "FLT") {
            unitDRInfo = UnitDRInfo()
            unitDRGenerator.setMode(mode: mode)

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
        onStartFlag = true
        
        return (isSuccess, message)
    }
    
    public func changeRegion(regionName: String) {
        setRegion(regionName: regionName)
        settingURL(server: self.serverType, os: self.osType)
    }

    public func startService(id: String, sector_id: Int, service: String, mode: String) -> (Bool, String) {
        NetworkCheck.shared.startMonitoring()
        
        let localTime = getLocalTimeString()
        let log: String = localTime + " , (Jupiter) Success : Service Initalization"
        
        var isSuccess: Bool = true
        var message: String = log
        
        self.sectorIdOrigin = sector_id
        self.sector_id = sector_id
        
        self.user_id = id
        self.service = service
        self.mode = mode
        
        var interval: Double = 1/2
        var numInput = 6
        
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
            let log: String = localTime + " , (Jupiter) Error : Invalid Service Name"
            message = log
            return (isSuccess, message)
        }
        
        self.RFD_INPUT_NUM = numInput
        self.RFD_INTERVAL = interval
        
        if (onStartFlag) {
            isSuccess = false
            message = localTime + " , (Jupiter) Error : Please stop another service"
            
            return (isSuccess, message)
        } else {
            let initService = self.initService()
            if (!initService.0) {
                isSuccess = initService.0
                message = initService.1
                
                return (isSuccess, message)
            }
        }
        
        settingURL(server: self.serverType, os: self.osType)
        
        if (self.user_id.isEmpty || self.user_id.contains(" ")) {
            isSuccess = false
            
            let log: String = localTime + " , (Jupiter) Error : User ID cannot be empty or contain space"
            message = log
            
            return (isSuccess, message)
        } else {
            if (!NetworkCheck.shared.isConnected) {
                isSuccess = false
                let log: String = localTime + " , (Jupiter) Error : Network is not connected"
                message = log
                return (isSuccess, message)
            }
            
            // Login Success
            let userInfo = UserInfo(user_id: self.user_id, device_model: deviceModel, os_version: osVersion)
            postUser(url: USER_URL, input: userInfo, completion: { [self] statusCode, returnedString in
                if (statusCode == 200) {
                    let log: String = localTime + " , (Jupiter) Success : User Login"
                    print(log)
                    self.startTimer()
                } else {
                    let log: String = localTime + " , (Jupiter) Error : User Login"
                    print(log)
                }
            })
            
            let adminInfo = UserInfo(user_id: "tjlabsAdmin", device_model: deviceModel, os_version: osVersion)
            postUser(url: USER_URL, input: adminInfo, completion: { [self] statusCode, returnedString in
                if (statusCode == 200) {
                    let list = jsonToCardList(json: returnedString)
                    let myCard = list.sectors

                    for card in 0..<myCard.count {
                        let cardInfo: CardInfo = myCard[card]
                        let id: Int = cardInfo.sector_id

                        if (id == self.sector_id) {
                            let buildings_n_levels: [[String]] = cardInfo.building_level

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

                            // Key-Value Saved
                            for i in 0..<infoBuilding.count {
                                let buildingName = infoBuilding[i]
                                let levelList = infoLevel[buildingName]
                                for j in 0..<levelList!.count {
                                    let levelName = levelList![j]
                                    let key: String = "\(buildingName)_\(levelName)"

                                    let url = "https://storage.googleapis.com/\(IMAGE_URL)/pp/\(self.sectorIdOrigin)/\(key).csv"
                                    let urlComponents = URLComponents(string: url)
                                    let requestURL = URLRequest(url: (urlComponents?.url)!)
                                    let dataTask = URLSession.shared.dataTask(with: requestURL, completionHandler: { (data, response, error) in
                                        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 500

                                        if (statusCode == 200) {
                                            if let responseData = data {
                                                if let utf8Text = String(data: responseData, encoding: .utf8) {
                                                    ( self.Road[key], self.RoadHeading[key] ) = self.parseRoad(data: utf8Text)
//                                                    self.AbnormalArea[key] = self.loadAbnormalArea(buildingName: buildingName, levelName: levelName)
                                                    self.isMapMatching = true
                                                    
                                                    let log: String = localTime + " , (Jupiter) Success : Load \(buildingName) \(levelName) Path-Point"
                                                    print(log)
                                                }
                                            }
                                        }
                                    })
                                    dataTask.resume()
                                }
                                
                                for j in 0..<levelList!.count {
                                    let levelName = levelList![j]
                                    let input = Geo(sector_id: self.sector_id, building_name: buildingName, level_name: levelName)
                                    NetworkManager.shared.postGEO(url: GEO_URL, input: input, completion: { [self] statusCode, returnedString, buildingGeo, levelGeo in
                                        if (statusCode >= 200 && statusCode <= 300) {
                                            let result = decodeGEO(json: returnedString)
                                            let key: String = "\(buildingGeo)_\(levelGeo)"
                                            self.AbnormalArea[key] = result.geofences
                                        }
                                    })
                                }
                            }
                        }
                    }
                }
            })
            self.loadRssiBias(sector_id: self.sector_id)
            
            return (isSuccess, message)
        }
    }
    
    func settingURL(server: Int, os: Int) {
        // (server) 0 : Release  //  1 : Test
        // (os) 0 : Android  //  1 : iOS
        
        if (server == 0 && os == 0) {
            BASE_URL = RELEASE_URL_A
        } else if (server == 0 && os == 1) {
            BASE_URL = RELEASE_URL_i
        } else if (server == 1 && os == 0) {
            BASE_URL = TEST_URL_A
        } else if (server == 1 && os == 1) {
            BASE_URL = TEST_URL_i
        } else {
            BASE_URL = RELEASE_URL_i
        }
        setBaseURL(url: BASE_URL)
    }
    
    public func stopService() {
        NetworkCheck.shared.stopMonitoring()
        
        let localTime: String = getLocalTimeString()
        
        stopTimer()
        stopBLE()
        
        if (self.service == "FLT") {
            unitDRInfo = UnitDRInfo()
            onStartFlag = false
            saveRssiBias(bias: self.rssiBias, sector_id: self.sector_id)
        }
        
        self.lastResultBufferUvdChanged = [Any]()
        self.indexAfterResponse = 0
        self.lastOsrId = 0
        self.phase4Count = 0
        self.phase = 0
        displayOutput.phase = String(0)
        
        self.currentBuilding = ""
        self.currentLevel = "0F"
        
        self.isGetFirstResponse = false
        self.isActiveReturn = true
        self.isEntered = false
        
        self.isActiveKf = false
        self.timeUpdatePosition = KalmanOutput()
        self.measurementPosition = KalmanOutput()

        self.timeUpdateOutput = FineLocationTrackingFromServer()
        self.measurementOutput = FineLocationTrackingFromServer()
        
        self.isMapMatching = false
        
        let log: String = localTime + " , (Jupiter) Stop Service"
        print(log)
    }
    
    public func initCollect() {
        unitDRGenerator.setMode(mode: "pdr")
        
        initialzeSensors()
        startCollectTimer()
        startBLE()
    }
    
    public func startCollect() {
        onStartFlag = true
    }
    
    public func stopCollect() {
        stopCollectTimer()
        stopBLE()
        
        onStartFlag = false
    }
    
    public func getResult(completion: @escaping (Int, String) -> Void) {
        let currentTime: Int = getCurrentTimeInMilliseconds()
        
        switch(self.service) {
        case "SD":
            let input = CoarseLevelDetection(user_id: self.user_id, mobile_time: currentTime)
            NetworkManager.shared.postCLD(url: CLD_URL, input: input, completion: { statusCode, returnedString in
                let sdString = self.CLDtoSD(json: returnedString)
                completion(statusCode, sdString)
            })
        case "BD":
            let input = CoarseLevelDetection(user_id: self.user_id, mobile_time: currentTime)
            NetworkManager.shared.postCLD(url: CLD_URL, input: input, completion: { statusCode, returnedString in
                let bdString = self.CLDtoBD(json: returnedString)
                completion(statusCode, bdString)
            })
        case "CLD":
            let input = CoarseLevelDetection(user_id: self.user_id, mobile_time: currentTime)
            NetworkManager.shared.postCLD(url: CLD_URL, input: input, completion: { statusCode, returnedString in
                completion(statusCode, returnedString)
            })
        case "FLD":
            let input = CoarseLocationEstimation(user_id: self.user_id, mobile_time: currentTime, sector_id: self.sector_id)
            NetworkManager.shared.postCLE(url: CLE_URL, input: input, completion: { statusCode, returnedString in
                let fldString = self.CLEtoFLD(json: returnedString)
                completion(statusCode, fldString)
            })
        case "CLE":
            let input = CoarseLocationEstimation(user_id: self.user_id, mobile_time: currentTime, sector_id: self.sector_id)
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
            print("getSpotResult : \(input)")
            NetworkManager.shared.postOSA(url: OSA_URL, input: input, completion: { statusCode, returnedString in
                completion(statusCode, returnedString)
            })
        } else {
            completion(500, "(Jupiter) Error : Invalid User ID")
        }
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
        if (receivedForceTimer == nil) {
            receivedForceTimer = Timer.scheduledTimer(timeInterval: RFD_INTERVAL, target: self, selector: #selector(self.receivedForceTimerUpdate), userInfo: nil, repeats: true)
            RunLoop.current.add(receivedForceTimer!, forMode: .common)
        }

        if (userVelocityTimer == nil && self.service == "FLT") {
            userVelocityTimer = Timer.scheduledTimer(timeInterval: UVD_INTERVAL, target: self, selector: #selector(self.userVelocityTimerUpdate), userInfo: nil, repeats: true)
            RunLoop.current.add(receivedForceTimer!, forMode: .common)
        }

        if (requestTimer == nil && self.service == "FLT") {
            requestTimer = Timer.scheduledTimer(timeInterval: RQ_INTERVAL, target: self, selector: #selector(self.requestTimerUpdate), userInfo: nil, repeats: true)
            RunLoop.current.add(receivedForceTimer!, forMode: .common)
        }

        if (updateTimer == nil && self.service == "FLT") {
            updateTimer = Timer.scheduledTimer(timeInterval: UPDATE_INTERVAL, target: self, selector: #selector(self.outputTimerUpdate), userInfo: nil, repeats: true)
            RunLoop.current.add(receivedForceTimer!, forMode: .common)
        }

        if (osrTimer == nil && self.service == "FLT") {
            osrTimer = Timer.scheduledTimer(timeInterval: OSR_INTERVAL, target: self, selector: #selector(self.osrTimerUpdate), userInfo: nil, repeats: true)
            RunLoop.current.add(receivedForceTimer!, forMode: .common)
        }
    }
    
    func stopTimer() {
        if (receivedForceTimer != nil) {
            receivedForceTimer!.invalidate()
            receivedForceTimer = nil
        }

        if (userVelocityTimer != nil) {
            userVelocityTimer!.invalidate()
            userVelocityTimer = nil
        }

        if (osrTimer != nil) {
            osrTimer!.invalidate()
            osrTimer = nil
        }

        if (requestTimer != nil) {
            requestTimer!.invalidate()
            requestTimer = nil
        }

        if (updateTimer != nil) {
            updateTimer!.invalidate()
            updateTimer = nil
        }
    }
    
    func enterSleepMode() {
        let localTime: String = getLocalTimeString()
        print(localTime + " , (Jupiter) Enter Sleep Mode")
        
        if (self.updateTimer != nil) {
            self.updateTimer!.invalidate()
            self.updateTimer = nil
        }
    }
    
    func wakeUpFromSleepMode() {
        if (self.updateTimer == nil && self.service == "FLT") {
            updateTimer = Timer.scheduledTimer(timeInterval: UPDATE_INTERVAL, target: self, selector: #selector(self.outputTimerUpdate), userInfo: nil, repeats: true)
            RunLoop.current.add(receivedForceTimer!, forMode: .common)
        }
    }
    
    func startCollectTimer() {
        if (collectTimer == nil) {
            collectTimer = Timer.scheduledTimer(timeInterval: UVD_INTERVAL, target: self, selector: #selector(self.collectTimerUpdate), userInfo: nil, repeats: true)
            RunLoop.current.add(collectTimer!, forMode: .common)
        }
    }
    
    func stopCollectTimer() {
        if (collectTimer != nil) {
            collectTimer!.invalidate()
            collectTimer = nil
        }
    }
    
    @objc func outputTimerUpdate() {
        if (self.isActiveReturn && self.isActiveService) {
            let currentTime = getCurrentTimeInMilliseconds()
            self.outputResult.mobile_time = currentTime
            
            self.tracking(input: self.outputResult, isPast: self.flagPast)
        }
    }
    
    @objc func receivedForceTimerUpdate() {
        let currentTime = getCurrentTimeInMilliseconds() - (Int(bleManager.BLE_VALID_TIME)/2)
        
        let bleDictionary = bleManager.bleDictionary
        let bleTrimed = bleManager.trimBleData(bleData: bleDictionary)
        var bleAvg = bleManager.avgBleData(bleDictionary: bleTrimed)
        
        let bleCheckTime = Double(currentTime)
        let discoveredTime = bleManager.bleDiscoveredTime
        let diffBleTime = (bleCheckTime - discoveredTime)*1e-3
        
        if (!bleAvg.isEmpty) {
            self.timeActiveRF = 0
            self.timeSleepRF = 0
            self.timeEmptyRF = 0
            
            self.isActiveRF = true
            self.isEmptyRF = false
            self.isActiveService = true
            
            self.wakeUpFromSleepMode()
            if (self.isActiveService) {
                let data = ReceivedForce(user_id: self.user_id, mobile_time: currentTime, ble: bleAvg, pressure: self.pressure)
                
                inputReceivedForce.append(data)
                if ((inputReceivedForce.count-1) >= RFD_INPUT_NUM) {
                    inputReceivedForce.remove(at: 0)
                    NetworkManager.shared.putReceivedForce(url: RF_URL, input: inputReceivedForce, completion: { [self] statusCode, returnedStrig in
                        if (statusCode != 200) {
                            let localTime = getLocalTimeString()
                            let log: String = localTime + " , (Jupiter) Error : Fail to send bluetooth data"
                            print(log)
                        }
                    })
                    inputReceivedForce = [ReceivedForce(user_id: "", mobile_time: 0, ble: [:], pressure: 0)]
                }
            }
        } else {
            self.timeActiveRF += RFD_INTERVAL
            if (self.timeActiveRF >= SLEEP_THRESHOLD_RF) {
                self.isActiveRF = false
                self.timeActiveRF = 0
                
//                self.currentBuilding = ""
//                self.currentLevel = ""
//
//                self.phase = 1
//                self.outputResult.phase = 1
//                self.outputResult.building_name = ""
//                self.outputResult.level_name = ""
//                self.currentSpot = 0
//                self.lastOsrId = 0
//                self.travelingOsrDistance = 0
//                self.isPossibleEstBias = false
//                self.buildingLevelChangedTime = 0
//                self.isActiveKf = false
//                self.timeUpdateFlag = false
//                self.measurementUpdateFlag = false
//                self.timeUpdatePosition = KalmanOutput()
//                self.measurementPosition = KalmanOutput()
//                self.timeUpdateOutput = FineLocationTrackingFromServer()
//                self.measurementOutput = FineLocationTrackingFromServer()
                
                
//                if (self.isEntered && self.phase != 2) {
//                    self.currentBuilding = ""
//                    self.currentLevel = ""
//
//                    self.phase = 2
//                    self.outputResult.phase = 2
//                    self.outputResult.building_name = ""
//                    self.outputResult.level_name = ""
//                    self.currentSpot = 0
//                    self.lastOsrId = 0
//                    self.travelingOsrDistance = 0
//                    self.isPossibleEstBias = false
//                    self.buildingLevelChangedTime = 0
//                    self.isActiveKf = false
//                    self.timeUpdateFlag = false
//                    self.measurementUpdateFlag = false
//                    self.timeUpdatePosition = KalmanOutput()
//                    self.measurementPosition = KalmanOutput()
//                    self.timeUpdateOutput = FineLocationTrackingFromServer()
//                    self.measurementOutput = FineLocationTrackingFromServer()
//
//                    print(getLocalTimeString() + " , (Jupiter) Outdoor Detection Fail -> Change to Phase2")
//                    self.reporting(input: OUTDOOR_FLAG)
//                }
            }
            
            self.timeSleepRF += RFD_INTERVAL
            if (self.timeSleepRF >= SLEEP_THRESHOLD) {
                self.isActiveService = false
                self.timeSleepRF = 0
                
                self.enterSleepMode()
            }
        }
    }
    
    func checkStrongRfd(bleDict: [String: Double]) -> Bool {
        var count = 0
        for value in bleDict.values {
            if value >= -85 {
                count += 1
                if count >= 2 {
                    return true
                }
            }
        }
        return false
    }

    
    @objc func userVelocityTimerUpdate() {
        let currentTime = getCurrentTimeInMilliseconds()
        let localTime = getLocalTimeString()
        
        // UV Control
        setModeParam(mode: self.runMode, phase: self.phase)
        bleManager.setValidTime(mode: self.runMode)
        
        if (onStartFlag) {
            unitDRInfo = unitDRGenerator.generateDRInfo(sensorData: sensorData)
        }
        
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
            
            if (self.mode == "auto") {
                let autoMode = unitDRInfo.autoMode
                if (autoMode == 0) {
                    self.runMode = "pdr"
                    self.sector_id = self.sectorIdOrigin - 1
                    self.kalmanR = 0.5
                } else {
                    self.runMode = "dr"
                    self.sector_id = self.sectorIdOrigin
                    self.kalmanR = 6
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
                        let resultBufferData = ResultIsUvdChanged(mobile_time: lastResult.mobile_time, building_name: lastResult.building_name, level_name: lastResult.level_name)
                        if (self.isActiveReturn) {
                            self.lastResultBufferUvdChanged.append(resultBufferData)
                            if (self.lastResultBufferUvdChanged.count > 210) {
                                self.lastResultBufferUvdChanged.remove(at: 0)
                            }
                        }
                    }
                }
                
                if (self.isGetFirstResponse && !self.isPossibleEstBias) {
                    if (self.isActiveReturn) {
                        self.indexAfterResponse += 1
                        if (self.indexAfterResponse >= MINIMUN_INDEX_FOR_BIAS) {
                            self.isPossibleEstBias = true
                        }
                    }
                }
                
                inputUserVelocity.append(data)
                // Time Update
                if (self.isActiveKf) {
                    if (self.timeUpdateFlag) {
                        let tuOutput = timeUpdate(length: curUnitDRLength, diffHeading: diffHeading, mobileTime: currentTime, isNeedHeadingCorrection: isNeedHeadingCorrection)
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
                        if (bleManager.bluetoothReady) {
                            let trackingTime = getCurrentTimeInMilliseconds()
                            tuResult.mobile_time = trackingTime
                            self.outputResult = tuResult
                            self.flagPast = false
                        }
                    }
                    
                    if (self.isPhaseBreak) {
                        self.distanceAfterPhase1 += unitDRInfo.length
                    }
                }
                preUnitHeading = unitDRInfo.heading
                
                // Put UV
                if ((inputUserVelocity.count-1) >= UVD_INPUT_NUM) {
                    inputUserVelocity.remove(at: 0)
                    NetworkManager.shared.putUserVelocity(url: UV_URL, input: inputUserVelocity, completion: { [self] statusCode, returnedString in
                        if (statusCode == 200) {
                            self.pastTuResult = self.currentTuResult
                            self.indexSend = Int(returnedString) ?? 0
                            self.isAnswered = true
                        } else {
                            let localTime: String = getLocalTimeString()
                            let log: String = localTime + " , (Jupiter) Error : Fail to send sensor measurements\n"
                            print(log)
                        }
                    })
                    inputUserVelocity = [UserVelocity(user_id: user_id, mobile_time: 0, index: 0, length: 0, heading: 0, looking: true)]
                }
                
                // Phase 4 Request
                if (self.isAnswered && (self.phase == 4)) {
                    self.isAnswered = false
                    processPhase4(currentTime: currentTime, localTime: localTime)
                }
            }
        } else {
            // UV가 발생하지 않음
            self.timeActiveUV += UVD_INTERVAL
            if (self.timeActiveUV >= STOP_THRESHOLD && self.isGetFirstResponse) {
                self.isStop = true
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
    
    @objc func requestTimerUpdate() {
        let currentTime = getCurrentTimeInMilliseconds()
        let localTime = getLocalTimeString()
        
        if (self.isActiveService) {
            if (!self.isStop) {
                if (self.phase == 2) {
                    processPhase2(currentTime: currentTime, localTime: localTime)
                } else if (self.phase < 4) {
                    // Phase 1 ~ 3
                    processPhase3(currentTime: currentTime, localTime: localTime)
                }
            }
        }
    }
    
    private func processPhase2(currentTime: Int, localTime: String) {
        let input = FineLocationTracking(user_id: self.user_id, mobile_time: currentTime, sector_id: self.sector_id, building_name: self.currentBuilding, level_name: self.currentLevel, spot_id: self.currentSpot, phase: self.phase, rss_compensation_list: [self.rssiBias])
//        print(localTime + " , (Jupiter) OSR : Phase 2 Input = \(input)")
        NetworkManager.shared.postFLT(url: FLT_URL, input: input, completion: { [self] statusCode, returnedString in
            if (statusCode == 200) {
                let result = jsonToResult(json: returnedString)
                if (result.x != 0 && result.y != 0) {
                    if (result.mobile_time > self.preOutputMobileTime) {
                        self.preOutputMobileTime = result.mobile_time
                        self.phase = result.phase
                        self.currentBuilding = result.building_name
                        self.currentLevel = result.level_name
                        
                        self.timeUpdateOutput.building_name = result.building_name
                        self.timeUpdateOutput.level_name = result.level_name
                        
                        self.measurementOutput.building_name = result.building_name
                        self.measurementOutput.level_name = result.level_name
                        
                        displayOutput.indexRx = result.index
                        
                        let finalResult = fromServerToResult(fromServer: result, velocity: displayOutput.velocity)
                        self.outputResult = finalResult
                        
                        self.serverResult[0] = result.x
                        self.serverResult[1] = result.y
                        self.serverResult[2] = result.absolute_heading
                        
                        self.indexPast = result.index
                    }
                } else {
//                    if (!self.isActiveRF) {
//                        self.lastResultBufferUvdChanged = [Any]()
//
//                        self.isActiveReturn = false
//                        self.isGetFirstResponse = false
//                        self.indexAfterResponse = 0
//                        self.lastOsrId = 0
//                        self.phase4Count = 0
//                        self.isPossibleEstBias = false
//
//                        self.phase = result.phase
//                        self.preOutputMobileTime = getCurrentTimeInMilliseconds()
//
//                        displayOutput.phase = String(result.phase)
//                        self.currentBuilding = ""
//                        self.currentLevel = ""
//
//                        self.isActiveKf = false
//                        self.timeUpdateFlag = false
//                        self.measurementUpdateFlag = false
//                        self.timeUpdatePosition = KalmanOutput()
//                        self.measurementPosition = KalmanOutput()
//                        self.timeUpdateOutput = FineLocationTrackingFromServer()
//                        self.measurementOutput = FineLocationTrackingFromServer()
//
//                        self.isEntered = false
//                    }
                }
            } else {
                let log: String = localTime + " , (Jupiter) Error : Fail to request indoor position in Phase 2"
                print(log)
            }
        })
    }
    
    private func processPhase3(currentTime: Int, localTime: String) {
        var requestBiasArray: [Int] = [self.rssiBias]
        if (self.isPossibleEstBias) {
            if (self.isBiasRequested) {
                requestBiasArray = [self.rssiBias]
            } else {
                if (!isActiveKf) {
                    requestBiasArray = self.rssiBiasArray
                    self.biasRequestTime = currentTime
                    self.isBiasRequested = true
                } else if (self.phase > 2) {
                    requestBiasArray = self.rssiBiasArray
                    self.biasRequestTime = currentTime
                    self.isBiasRequested = true
                } else {
                    requestBiasArray = [self.rssiBias]
                }
            }
        }
        
        let input = FineLocationTracking(user_id: self.user_id, mobile_time: currentTime, sector_id: self.sector_id, building_name: self.currentBuilding, level_name: self.currentLevel, spot_id: self.currentSpot, phase: self.phase, rss_compensation_list: requestBiasArray)
//        print(localTime + " , (Jupiter) Phase 1~3 Input : \(input)")
        NetworkManager.shared.postFLT(url: FLT_URL, input: input, completion: { [self] statusCode, returnedString in
            if (statusCode == 200) {
                let result = jsonToResult(json: returnedString)
                if (result.x != 0 && result.y != 0) {
//                    print(localTime + " , (Jupiter) Phase 1~3 Result : \(result)")
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
                                    let biasAvg: Int = averageBiasArray(biasArray: self.sccGoodBiasArray)
                                    self.sccGoodBiasArray.remove(at: 0)
                                    self.rssiBias = biasAvg

                                    self.saveRssiBias(bias: self.rssiBias, sector_id: self.sector_id)
                                }
                            }
                            
                            self.isBiasRequested = false
                            displayOutput.bias = self.rssiBias
                        } else if (biasCheckTime > 3000) {
                            self.isBiasRequested = false
                        }
                    }
                    
                    if (result.mobile_time > self.preOutputMobileTime) {
                        if (!self.isGetFirstResponse) {
                            self.isGetFirstResponse = true
//                            if (self.isActiveReturn) {
//                                self.reporting(input: INDOOR_FLAG)
//                            }
                        }
                        
//                        if (!self.isActiveReturn) {
//                            let bleData = bleManager.bleAvg
//                            let isStrongRfd: Bool = checkStrongRfd(bleDict: bleData)
//                            self.isActiveReturn = isStrongRfd
//                            if (isStrongRfd) {
//                                self.reporting(input: INDOOR_FLAG)
//                            }
//                        }
                        
                        self.preOutputMobileTime = result.mobile_time
                        displayOutput.indexRx = result.index
                        self.phase = result.phase
                        
                        var resultCorrected = self.correct(building: result.building_name, level: result.level_name, x: result.x, y: result.y, heading: result.absolute_heading, tuXY: [0,0], mode: self.runMode, isPast: false, HEADING_RANGE: self.HEADING_RANGE)
                        resultCorrected.xyh[2] = compensateHeading(heading: resultCorrected.xyh[2], mode: self.runMode)
                        
                        self.serverResult[0] = resultCorrected.xyh[0]
                        self.serverResult[1] = resultCorrected.xyh[1]
                        self.serverResult[2] = resultCorrected.xyh[2]
                        
                        if (!self.isActiveKf) {
                            if (result.phase == 4) {
                                self.phase4Count += 1
                                if (self.phase4Count > 19) {
                                    self.isEntered = true
                                }
                                
                                self.timeUpdatePosition.x = resultCorrected.xyh[0]
                                self.timeUpdatePosition.y = resultCorrected.xyh[1]
                                self.timeUpdatePosition.heading = resultCorrected.xyh[2]
                                
                                self.timeUpdateOutput.x = resultCorrected.xyh[0]
                                self.timeUpdateOutput.y = resultCorrected.xyh[1]
                                self.timeUpdateOutput.absolute_heading = resultCorrected.xyh[2]
                                
                                self.outputResult.x = resultCorrected.xyh[0]
                                self.outputResult.y = resultCorrected.xyh[1]
                                self.outputResult.absolute_heading = resultCorrected.xyh[2]

                                self.isActiveKf = true
                            }
                            
                            let finalResult = fromServerToResult(fromServer: result, velocity: displayOutput.velocity)
                            self.currentBuilding = finalResult.building_name
                            self.currentLevel = finalResult.level_name
                            
                            self.flagPast = false
                            self.outputResult = finalResult
                        } else {
//                             Kalman Filter가 동작 중이면서 위치 요청시 input의 phase 가 1~3 인 경우
                            if (result.phase == 4) {
                                self.phase4Count += 1
                                if (self.phase4Count > 19) {
                                    self.isEntered = true
//                                    print(localTime + "(Jupiter) Phase 3 Result : isEntered = true")
                                }
                                if (resultCorrected.isSuccess) {
                                    self.updateAllResult(result: resultCorrected.xyh, flag: false)
                                }
                            } else if (result.phase == 3) {
                                self.updateAllResult(result: resultCorrected.xyh, flag: false)
                            }
                            var timUpdateOutputCopy = self.timeUpdateOutput
                            timUpdateOutputCopy.phase = result.phase
                            
                            if (result.building_name != self.currentBuilding || result.level_name != self.currentLevel) {
                                if ((result.mobile_time - self.buildingLevelChangedTime) > VALID_BL_CHANGE_TIME) {
                                    // Building Level 이 바뀐지 15초 이상 지남 -> 서버 결과를 이용해 바뀌어야 한다고 판단
                                    self.currentBuilding = result.building_name
                                    self.currentLevel = result.level_name

                                    timUpdateOutputCopy.building_name = result.building_name
                                    timUpdateOutputCopy.level_name = result.level_name
//                                    self.buildingLevelChangedTime = getCurrentTimeInMilliseconds()
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
                        }
                        self.indexPast = result.index
                    }
                } else {
                    self.phase = result.phase
                }
            } else {
                let log: String = localTime + " , (Jupiter) Error : Fail to request indoor position in Phase 3"
                print(log)
            }
        })
    }
    
    private func processPhase4(currentTime: Int, localTime: String) {
        self.nowTime = currentTime
        var requestBiasArray: [Int] = [self.rssiBias]
        if (self.isPossibleEstBias) {
            if (self.isBiasRequested) {
                requestBiasArray = [self.rssiBias]
            } else {
                requestBiasArray = self.rssiBiasArray
                self.biasRequestTime = currentTime
                self.isBiasRequested = true
            }
        }

        let input = FineLocationTracking(user_id: self.user_id, mobile_time: currentTime, sector_id: self.sector_id, building_name: self.currentBuilding, level_name: self.currentLevel, spot_id: self.currentSpot, phase: self.phase, rss_compensation_list: requestBiasArray)
        NetworkManager.shared.postFLT(url: FLT_URL, input: input, completion: { [self] statusCode, returnedString in
            if (statusCode == 200) {
                let result = jsonToResult(json: returnedString)
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
                                let biasAvg: Int = averageBiasArray(biasArray: self.sccGoodBiasArray)
                                self.sccGoodBiasArray.remove(at: 0)
                                self.rssiBias = biasAvg

                                self.saveRssiBias(bias: self.rssiBias, sector_id: self.sector_id)
                            }
                        }
                        self.isBiasRequested = false
                        displayOutput.bias = self.rssiBias
                    } else if (biasCheckTime > 3000) {
                        self.isBiasRequested = false
                    }
                }

                if ((self.nowTime - result.mobile_time) <= RECENT_THRESHOLD) {
                    if ((result.index - self.indexPast) < INDEX_THRESHOLD) {
                        if (result.mobile_time > self.preOutputMobileTime) {
                            if (result.phase == 4) {
                                if (self.isActiveReturn) {
                                    self.isActiveKf = true
                                    self.timeUpdateFlag = true
                                }
                            }
                            self.phase = result.phase
                            self.preOutputMobileTime = result.mobile_time

                            if (self.isActiveKf && result.phase == 4) {
                                if (!(result.x == 0 && result.y == 0)) {
                                    self.phase4Count += 1
                                    if (self.phase4Count > 19) {
                                        self.isEntered = true
                                    }
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
                                    if (measurementUpdateFlag && (diffIndex<10)) {
                                        displayOutput.indexRx = result.index

                                        // Measurement Update 하기전에 현재 Time Update 위치를 고려
                                        var resultForMu = result
                                        resultForMu.absolute_heading = compensateHeading(heading: resultForMu.absolute_heading, mode: self.runMode)
                                        let resultCorrected = self.correct(building: resultForMu.building_name, level: resultForMu.level_name, x: resultForMu.x, y: resultForMu.y, heading: resultForMu.absolute_heading, tuXY: [self.pastTuResult.x, self.pastTuResult.y], mode: self.runMode, isPast: false, HEADING_RANGE: self.HEADING_RANGE)

                                        self.serverResult[0] = resultCorrected.xyh[0]
                                        self.serverResult[1] = resultCorrected.xyh[1]
                                        self.serverResult[2] = resultCorrected.xyh[2]

                                        let indexBuffer: [Int] = self.uvdIndexBuffer
                                        let tuBuffer: [[Double]] = self.tuResultBuffer

                                        var currentTuResult = self.currentTuResult
                                        var pastTuResult = self.pastTuResult
                                        if (currentTuResult.mobile_time != 0 && pastTuResult.mobile_time != 0) {
                                            var dx: Double = 0
                                            var dy: Double = 0
                                            var dh: Double = 0

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

                                        if (result.building_name != self.currentBuilding || result.level_name != self.currentLevel) {
                                            if ((result.mobile_time - self.buildingLevelChangedTime) > VALID_BL_CHANGE_TIME) {
                                                // Building Level 이 바뀐지 15초 이상 지남 -> 서버 결과를 이용해 바뀌어야 한다고 판단
                                                self.currentBuilding = result.building_name
                                                self.currentLevel = result.level_name

                                                muResult.building_name = result.building_name
                                                muResult.level_name = result.level_name
                                                
//                                                self.buildingLevelChangedTime = getCurrentTimeInMilliseconds()
                                            } else {
                                                muResult.building_name = self.currentBuilding
                                                muResult.level_name = self.currentLevel
                                            }
                                        }

                                        self.flagPast = false
                                        self.outputResult = muResult

                                        timeUpdatePositionInit(serverOutput: muOutput)
                                    }
                                }
                            } else if (self.isActiveKf) {
                                self.SQUARE_RANGE = self.SQUARE_RANGE_LARGE

                                self.kalmanR = 0.01
                                self.headingKalmanR = 0.01

                                self.distanceAfterPhase1 = 0
                                self.isPhaseBreak = true
                            }
                        }
                    }
                    self.indexPast = result.index
                }
            } else {
                let log: String = localTime + " , (Jupiter) Error : Fail to request indoor position in Phase 4"
                print(log)
            }
        })
    }
    
    @objc func osrTimerUpdate() {
        if (self.isGetFirstResponse) {
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
            
            // Check Abnormal Area
            let scaleFactor = self.checkInAbnormalArea(result: self.lastResult)
            unitDRGenerator.setVelocityScaleFactor(scaleFactor: scaleFactor)
        } else {
            self.travelingOsrDistance = 0
        }
    }
    
    func isOnSpotRecognition(result: OnSpotRecognitionResult, level: String) -> (isOn: Bool, levelDestination: String, levelDirection: String) {
        let localTime = getLocalTimeString()
        var isOn: Bool = false
        
        let mobile_time = result.mobile_time
        let building_name = result.building_name
        let level_name = result.level_name
        let linked_level_name = result.linked_level_name
        let spot_id = result.spot_id
        
        let levelArray: [String] = [level_name, linked_level_name]
        var levelDestination: String = ""
        
        if (linked_level_name == "") {
            if (!self.isEntered) {
                // In & Out OSR
                if (self.lastResultBufferUvdChanged.count >= 200) {
                    // Going Out
                    levelDestination = ""
                    isOn = false
//                    print(localTime + " , (Jupiter) Spot Detected : Out (isEntered is false)")
                } else {
                    // Going In
                    self.isEntered = true
                    levelDestination = level_name
                    isOn = false
//                    print(localTime + " , (Jupiter) Spot Detected : In")
                }
            } else {
                levelDestination = ""
                isOn = false
//                print(localTime + " , (Jupiter) Spot Detected : Out (isEntered is true)")
            }
            return (isOn, levelDestination, "")
        } else {
            if (self.currentLevel == "") {
                isOn = false
//                self.reporting(input: ABNORMAL_FLAG)
                return (isOn, "", "")
            }
            
            if (levelArray[0] == levelArray[1]) {
                isOn = false
                self.isEntered = true
                self.isActiveReturn = true
//                print(localTime + " , (Jupiter) Spot Detected : Indoor Spot")
                
                return (isOn, "", "")
            }
            
            // Normal OSR
            let currentLevel: String = level
            let levelNameCorrected: String = removeLevelDirectionString(levelName: currentLevel)
            for i in 0..<levelArray.count {
                if levelArray[i] != levelNameCorrected {
                    self.isEntered = true
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
            spotDistance = 80
        }
        if (result.spot_id != lastSpotId) {
            // Different Spot Detected
            self.currentBuilding = result.building_name
            self.currentLevel = levelDestination
            
            self.phase = 2
            self.outputResult.phase = 2
            self.timeUpdateOutput.level_name = levelDestination
            self.measurementOutput.level_name = levelDestination
            self.outputResult.level_name = levelDestination
            self.currentSpot = result.spot_id
            self.lastOsrId = result.spot_id
            self.travelingOsrDistance = 0
            self.isPossibleEstBias = false
            self.buildingLevelChangedTime = currentTime
            
//            if (levelDestination == "") {
//                self.buildingLevelChangedTime = 0
//
//                self.isActiveKf = false
//                self.timeUpdateFlag = false
//                self.measurementUpdateFlag = false
//                self.timeUpdatePosition = KalmanOutput()
//                self.measurementPosition = KalmanOutput()
//
//                self.timeUpdateOutput = FineLocationTrackingFromServer()
//                self.measurementOutput = FineLocationTrackingFromServer()
//
//                self.reporting(input: OUTDOOR_FLAG)
//            } else {
//                self.buildingLevelChangedTime = currentTime
//                if (result.linked_level_name == "" && !self.isActiveReturn) {
//                    self.isActiveReturn = true
//                    self.reporting(input: INDOOR_FLAG)
//                }
//            }
            
            self.preOutputMobileTime = currentTime
//            print(localTime + " , (Jupiter) Spot Determined : Different Spot // levelDestination = \(levelDestination) , dist = \(spotDistance)")
        } else {
            // Same Spot Detected
            if (self.travelingOsrDistance >= spotDistance) {
                self.currentBuilding = result.building_name
                self.currentLevel = levelDestination
                
                self.phase = 2
                self.outputResult.phase = 2
                self.timeUpdateOutput.level_name = levelDestination
                self.measurementOutput.level_name = levelDestination
                self.outputResult.level_name = levelDestination
                self.currentSpot = result.spot_id
                self.lastOsrId = result.spot_id
                self.travelingOsrDistance = 0
                self.isPossibleEstBias = false
                self.buildingLevelChangedTime = currentTime
                
//                if (levelDestination == "") {
//                    self.buildingLevelChangedTime = 0
//
//                    self.isActiveKf = false
//                    self.timeUpdateFlag = false
//                    self.measurementUpdateFlag = false
//                    self.timeUpdatePosition = KalmanOutput()
//                    self.measurementPosition = KalmanOutput()
//
//                    self.timeUpdateOutput = FineLocationTrackingFromServer()
//                    self.measurementOutput = FineLocationTrackingFromServer()
//
//                    self.reporting(input: OUTDOOR_FLAG)
//                } else {
//                    if (result.linked_level_name == "" && !self.isActiveReturn) {
//                        self.isActiveReturn = true
//                        self.reporting(input: INDOOR_FLAG)
//                    }
//                    self.buildingLevelChangedTime = currentTime
//                }
                self.preOutputMobileTime = currentTime
//                print(localTime + " , (Jupiter) Spot Determined : Same Spot // levelDestination = \(levelDestination) , dist = \(spotDistance)")
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
        let levelName = lastResult.level_name
        
        let key = "\(buildingName)_\(levelName)"
        guard let abnormalArea: [[Double]] = AbnormalArea[key] else {
            return velocityScaleFactor
        }
        
        for i in 0..<abnormalArea.count {
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
        
        return velocityScaleFactor
    }
    
    func saveRssiBias(bias: Int, sector_id: Int) {
        do {
            let key: String = "JupiterRssiBias_\(sector_id)"
            UserDefaults.standard.set(bias, forKey: key)
        } catch {
            print("(Jupiter) Error : Fail to save RssiBias")
        }
    }
    
    func loadRssiBias(sector_id: Int) {
        let keyBias: String = "JupiterRssiBias_\(sector_id)"
        if let loadedRssiBias: Int = UserDefaults.standard.object(forKey: keyBias) as? Int {
            self.rssiBias = loadedRssiBias
            
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
            
            self.rssiBiasArray = biasArray
        }
    }
    
    
    func estimateRssiBias(sccResult: Double, biasResult: Int, biasArray: [Int]) -> (Bool, [Int]) {
        var isSccHigh: Bool = false
        var newBiasArray: [Int] = biasArray
        
        let biasStandard = biasResult
        let diffScc: Double = SCC_MAX - sccResult

        newBiasArray[0] = biasStandard

        var biasRange: Int = Int(round(diffScc*10))
        if (biasRange < 1) {
            biasRange = 1
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
    
    func averageBiasArray(biasArray: [Int]) -> Int {
        var result: Int = 0
        let array: [Double] = convertToDoubleArray(intArray: biasArray)
        
        let mean = array.reduce(0, +) / Double(array.count)
        let variance = array.map { pow($0 - mean, 2) }.reduce(0, +) / Double(array.count)
        let stdev = sqrt(variance)
        let validValues = array.filter { abs($0 - mean) <= 1.5 * stdev }
        
        if (validValues.count < 17) {
            let avgDouble: Double = biasArray.average
            
            result = Int(round(avgDouble))
            return result
        } else {
            let sum = validValues.reduce(0, +)
            let avgDouble: Double = Double(sum) / Double(validValues.count)
            
            result = Int(round(avgDouble))
            return result
        }
    }
    
    func convertToDoubleArray(intArray: [Int]) -> [Double] {
        return intArray.map { Double($0) }
    }
    
    @objc func collectTimerUpdate() {
        let currentTime = getCurrentTimeInMilliseconds()
        
        collectData.time = currentTime
        collectData.bleRaw = bleManager.bleRaw
        collectData.bleAvg = bleManager.bleAvg
        
        if (onStartFlag) {
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
    
    func getLocalTimeString() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd-HH-mm-ss"
        dateFormatter.locale = Locale(identifier:"ko_KR")
        let nowDate = Date()
        let convertNowStr = dateFormatter.string(from: nowDate)
        
        return convertNowStr
    }
    
    func jsonToResult(json: String) -> FineLocationTrackingFromServer {
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
    
    private func parseRoad(data: String) -> ( [[Double]], [String] ) {
        var road = [[Double]]()
        var roadHeading = [String]()
        
        var roadX = [Double]()
        var roadY = [Double]()
        
        let roadString = data.components(separatedBy: .newlines)
        for i in 0..<roadString.count {
            if (roadString[i] != "") {
                let lineData = roadString[i].components(separatedBy: ",")
                
                roadX.append(Double(lineData[0])!)
                roadY.append(Double(lineData[1])!)
                
                var headingArray: String = ""
                if (lineData.count > 2) {
                    for j in 2..<lineData.count {
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
        
        return (road, roadHeading)
    }
    
    private func loadAbnormalArea(buildingName: String, levelName: String) -> [[Double]] {
        var abnormalArea = [[Double]]()
        let key: String = "\(buildingName)_\(levelName)"
        if (key == "COEX_B2") {
            abnormalArea.append([115, 291, 165, 303, 0.8])
            abnormalArea.append([247, 263, 296, 305, 0.8])
            abnormalArea.append([34, 186, 100, 198, 1.6])
            abnormalArea.append([179, 7, 191, 32, 1.5])
            abnormalArea.append([195, 122, 225, 134, 1.5])
            abnormalArea.append([78, 99, 145, 111, 1.5])
            abnormalArea.append([214, 383, 226, 410, 0.8])
        } else if (key == "COEX_B3") {
            abnormalArea.append([214, 412, 226, 446, 0.8])
        } else if (key == "COEX_B4") {
            abnormalArea.append([214, 412, 226, 446, 0.8])
        }
        
        return abnormalArea
    }
    
    private func updateAllResult(result: [Double], flag: Bool) {
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
        
        if (flag) {
            self.timeUpdatePosition.heading = result[2]
            self.timeUpdatePosition.heading = result[2]
            self.measurementPosition.heading = result[2]
            self.measurementOutput.absolute_heading = result[2]
            self.outputResult.absolute_heading = result[2]
        }
    }
    
    private func correct(building: String, level: String, x: Double, y: Double, heading: Double, tuXY: [Double], mode: String, isPast: Bool, HEADING_RANGE: Double) -> (isSuccess: Bool, xyh: [Double]) {
        var isSuccess: Bool = false
        var xyh: [Double] = [x, y, heading]
        let levelCopy: String = self.removeLevelDirectionString(levelName: level)
        let key: String = "\(building)_\(levelCopy)"
        if (isPast) {
            isSuccess = true
            return (isSuccess, xyh)
        }
        
        if (!(building.isEmpty) && !(level.isEmpty)) {
            guard let mainRoad: [[Double]] = Road[key] else {
                return (isSuccess, xyh)
            }
            guard let mainHeading: [String] = RoadHeading[key] else {
                return (isSuccess, xyh)
            }
            
            // Heading 사용
            var idhArray = [[Double]]()
            var pathArray = [[Double]]()
            var failArray = [[Double]]()
            if (!mainRoad.isEmpty) {
                let roadX = mainRoad[0]
                let roadY = mainRoad[1]
                
                let xMin = x - SQUARE_RANGE
                let xMax = x + SQUARE_RANGE
                let yMin = y - SQUARE_RANGE
                let yMax = y + SQUARE_RANGE
                
                for i in 0..<roadX.count {
                    let xPath = roadX[i]
                    let yPath = roadY[i]

                    // XY 범위 안에 있는 값 중에 검사
                    if (xPath >= xMin && xPath <= xMax) {
                        if (yPath >= yMin && yPath <= yMax) {
                            let index = Double(i)
                            let distance = sqrt(pow(x-xPath, 2) + pow(y-yPath, 2))
                            var idh: [Double] = [index, distance, heading]
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
                                    idh[2] = minHeading
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
                                idhArray.append(idh)
                                pathArray.append(path)
                            } else {
                                failArray.append(idh)
                            }
                        }
                    }
                }
                
                if (!idhArray.isEmpty) {
                    let sortedIdh = idhArray.sorted(by: {$0[1] < $1[1] })
                    var index: Int = 0
                    var correctedHeading: Double = heading
                    
                    if (!sortedIdh.isEmpty) {
                        let minData: [Double] = sortedIdh[0]
                        index = Int(minData[0])
                        if (mode == "pdr") {
                            correctedHeading = heading
                        } else {
                            correctedHeading = minData[2]
                        }
                    }
                    
                    isSuccess = true
                    xyh = [roadX[index], roadY[index], correctedHeading]
                }
            }
        }
        return (isSuccess, xyh)
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
    
    func jsonToCardList(json: String) -> CardList {
        let result = CardList(sectors: [])
        let decoder = JSONDecoder()
        
        let jsonString = json
        
        if let data = jsonString.data(using: .utf8), let decoded = try? decoder.decode(CardList.self, from: data) {
            return decoded
        }
        
        return result
    }
    
    func setModeParam(mode: String, phase: Int) {
        if (mode == "pdr") {
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
            self.INIT_INPUT_NUM = 5
            self.VALUE_INPUT_NUM = 10
            self.SQUARE_RANGE = self.SQUARE_RANGE_SMALL
            
            if (phase == 4) {
                self.UVD_INPUT_NUM = self.VALUE_INPUT_NUM
                self.INDEX_THRESHOLD = 21
            } else {
                self.UVD_INPUT_NUM = self.INIT_INPUT_NUM
                self.INDEX_THRESHOLD = 11
            }
        }
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

    func timeUpdate(length: Double, diffHeading: Double, mobileTime: Int, isNeedHeadingCorrection: Bool) -> FineLocationTrackingFromServer {
        updateHeading = timeUpdatePosition.heading + diffHeading
        
        var dx = length*cos(updateHeading*D2R)
        var dy = length*sin(updateHeading*D2R)
        
        
        if (self.phase != 4) {
            if (self.runMode != "pdr") {
                dx = dx * TU_SCALE_VALUE
                dy = dy * TU_SCALE_VALUE
            }
        }
        
        timeUpdatePosition.x = timeUpdatePosition.x + dx
        timeUpdatePosition.y = timeUpdatePosition.y + dy
        timeUpdatePosition.heading = updateHeading
        
        var timeUpdateCopy = timeUpdatePosition
        let correctedTuCopy = self.correct(building: timeUpdateOutput.building_name, level: timeUpdateOutput.level_name, x: timeUpdateCopy.x, y: timeUpdateCopy.y, heading: timeUpdateCopy.heading, tuXY: [0,0], mode: self.runMode, isPast: false, HEADING_RANGE: self.HEADING_RANGE)
        if (correctedTuCopy.isSuccess) {
            if (self.runMode == "pdr") {
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
            if (self.runMode == "dr") {
                let correctedTuCopy = self.correct(building: timeUpdateOutput.building_name, level: timeUpdateOutput.level_name, x: timeUpdateCopy.x, y: timeUpdateCopy.y, heading: timeUpdateCopy.heading, tuXY: [0,0], mode: "pdr", isPast: false, HEADING_RANGE: self.HEADING_RANGE)
                timeUpdateCopy.x = correctedTuCopy.xyh[0]
                timeUpdateCopy.y = correctedTuCopy.xyh[1]
                timeUpdatePosition = timeUpdateCopy
            }
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
        let localTime = getLocalTimeString()
        var serverOutputHatCopy = serverOutputHat
        serverOutputHatCopy.absolute_heading = compensateHeading(heading: serverOutputHatCopy.absolute_heading, mode: self.runMode)
        
        // ServerOutputHat을 맵매칭
        let serverOutputHatCopyMm = self.correct(building: serverOutputHatCopy.building_name, level: serverOutputHatCopy.level_name, x: serverOutputHatCopy.x, y: serverOutputHatCopy.y, heading: serverOutputHatCopy.absolute_heading, tuXY: [0, 0], mode: self.runMode, isPast: false, HEADING_RANGE: self.HEADING_RANGE)
        
        var serverOutputHatMm: FineLocationTrackingFromServer = serverOutputHatCopy
        var timeUpdateHeadingCopy = compensateHeading(heading: timeUpdatePosition.heading, mode: self.runMode)
        
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
        
        let measurementOutputCorrected = self.correct(building: measurementOutput.building_name, level: measurementOutput.level_name, x: measurementOutput.x, y: measurementOutput.y, heading: updateHeading, tuXY: [0,0], mode: self.runMode, isPast: false, HEADING_RANGE: self.HEADING_RANGE)
        
        if (measurementOutputCorrected.isSuccess) {
            let diffX = timeUpdatePosition.x - measurementOutputCorrected.xyh[0]
            let diffY = timeUpdatePosition.y - measurementOutputCorrected.xyh[1]
            let diffXY = sqrt(diffX*diffX + diffY*diffY)
            
            if (diffXY > 30) {
                // Use Server Result
                self.timeUpdatePosition.x = originalResult[0]
                self.timeUpdatePosition.y = originalResult[1]
                self.timeUpdatePosition.heading = originalResult[2]
                
                measurementOutput.x = originalResult[0]
                measurementOutput.y = originalResult[1]
                updateHeading = originalResult[2]
                
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
            // Use Server Result
            self.timeUpdatePosition.x = originalResult[0]
            self.timeUpdatePosition.y = originalResult[1]
            self.timeUpdatePosition.heading = originalResult[2]
            
            measurementOutput.x = originalResult[0]
            measurementOutput.y = originalResult[1]
            updateHeading = originalResult[2]
            
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
    
    func CLDtoSD(json: String) -> String {
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
    
    func CLDtoBD(json: String) -> String {
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
    
    func CLEtoFLD(json: String) -> String {
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
}
