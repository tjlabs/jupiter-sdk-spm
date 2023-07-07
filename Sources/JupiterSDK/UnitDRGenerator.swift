import Foundation

public class UnitDRGenerator: NSObject {
    
    public override init() {
        
    }
    
    var STEP_VALID_TIME: Double = 1000
    
    public var unitMode = String()
    
    public let CF = CalculateFunctions()
    public let HF = HeadingFunctions()
    public let unitAttitudeEstimator = UnitAttitudeEstimator()
    public let unitStatusEstimator = UnitStatusEstimator()
    public let pdrDistanceEstimator = PDRDistanceEstimator()
    public let drDistanceEstimator = DRDistanceEstimator()
    
    var pdrQueue = LinkedList<DistanceInfo>()
    var drQueue = LinkedList<DistanceInfo>()
    var autoMode: Int = 0
    
    var normalStepTime: Double = 0
    var unitIndexAuto = 0
    
    var preRoll: Double = 0
    var prePitch: Double = 0
    
    public var isEnteranceLevel: Bool = false
    
    public func setMode(mode: String) {
        unitMode = mode
    }
    
    public func generateDRInfo(sensorData: SensorData) -> UnitDRInfo {
        if (unitMode != MODE_PDR && unitMode != MODE_DR && unitMode != MODE_AUTO) {
            print(getLocalTimeString() + " , (Jupiter) uniMode is forcibly set to auto (\(unitMode) - > MODR_AUTO)")
            unitMode = MODE_AUTO
        }
        
        let currentTime = getCurrentTimeInMilliseconds()
        
        var curAttitudeDr = Attitude(Roll: 0, Pitch: 0, Yaw: 0)
        var curAttitudePdr = Attitude(Roll: 0, Pitch: 0, Yaw: 0)
        
        var unitDistanceDr = UnitDistance()
        var unitDistancePdr = UnitDistance()
        var unitDistanceAuto = UnitDistance()
        
        switch (unitMode) {
        case MODE_PDR:
            pdrDistanceEstimator.isAutoMode(autoMode: false)
            pdrDistanceEstimator.normalStepCountSet(normalStepCountSet: pdrDistanceEstimator.normalStepCountSetting)
            unitDistancePdr = pdrDistanceEstimator.estimateDistanceInfo(time: currentTime, sensorData: sensorData)
            self.autoMode = 0
            
            var sensorAtt = sensorData.att
            
            if (sensorAtt[0].isNaN) {
                sensorAtt[0] = preRoll
            } else {
                preRoll = sensorAtt[0]
            }

            if (sensorAtt[1].isNaN) {
                sensorAtt[1] = prePitch
            } else {
                prePitch = sensorAtt[1]
            }
            
            curAttitudePdr = Attitude(Roll: sensorAtt[0], Pitch: sensorAtt[1], Yaw: sensorAtt[2])
            
            let unitStatus = unitStatusEstimator.estimateStatus(Attitude: curAttitudePdr, isIndexChanged: unitDistancePdr.isIndexChanged, unitMode: unitMode)
            if (!unitStatus && unitMode == MODE_PDR) {
                unitDistancePdr.length = 0.7
            }
            
            let heading = HF.radian2degree(radian: curAttitudePdr.Yaw)
            
            return UnitDRInfo(index: unitDistancePdr.index, length: unitDistancePdr.length, heading: heading, velocity: unitDistancePdr.velocity, lookingFlag: unitStatus, isIndexChanged: unitDistancePdr.isIndexChanged, autoMode: 0)
        case MODE_DR:
            unitDistanceDr = drDistanceEstimator.estimateDistanceInfo(time: currentTime, sensorData: sensorData)
            self.autoMode = 1
            curAttitudeDr = unitAttitudeEstimator.estimateAtt(time: currentTime, acc: sensorData.acc, gyro: sensorData.gyro, rotMatrix: sensorData.rotationMatrix)
            
            let heading = HF.radian2degree(radian: curAttitudeDr.Yaw)
            
            let unitStatus = unitStatusEstimator.estimateStatus(Attitude: curAttitudeDr, isIndexChanged: unitDistanceDr.isIndexChanged, unitMode: unitMode)
            return UnitDRInfo(index: unitDistanceDr.index, length: unitDistanceDr.length, heading: heading, velocity: unitDistanceDr.velocity, lookingFlag: unitStatus, isIndexChanged: unitDistanceDr.isIndexChanged, autoMode: 0)
        case MODE_AUTO:
            pdrDistanceEstimator.isAutoMode(autoMode: true)
            pdrDistanceEstimator.normalStepCountSet(normalStepCountSet: MODE_AUTO_NORMAL_STEP_COUNT_SET)
            unitDistancePdr = pdrDistanceEstimator.estimateDistanceInfo(time: currentTime, sensorData: sensorData)
            unitDistanceDr = drDistanceEstimator.estimateDistanceInfo(time: currentTime, sensorData: sensorData)
            
            var isPossibleDrLevel = pdrDistanceEstimator.normalStepCountFlag
            if (self.isEnteranceLevel) {
                isPossibleDrLevel = false
            }
            
            if (isPossibleDrLevel) {
                if (unitDistancePdr.isIndexChanged) {
                    unitIndexAuto += 1
                }
                unitDistanceAuto = unitDistancePdr
                self.autoMode = 0
                normalStepTime = getCurrentTimeInMilliseconds()
            } else {
                unitDistanceAuto = unitDistanceDr
                if (unitDistanceDr.isIndexChanged) {
                    unitIndexAuto += 1
                }
                self.autoMode = 1
            }
            
            if ((getCurrentTimeInMilliseconds() - normalStepTime) >= 5*1000) {
                unitDistanceAuto = unitDistanceDr
                self.autoMode = 1
            }
            
            var sensorAtt = sensorData.att
            if (sensorAtt[0].isNaN) {
                sensorAtt[0] = preRoll
            } else {
                preRoll = sensorAtt[0]
            }

            if (sensorAtt[1].isNaN) {
                sensorAtt[1] = prePitch
            } else {
                prePitch = sensorAtt[1]
            }
            
            curAttitudePdr = Attitude(Roll: sensorAtt[0], Pitch: sensorAtt[1], Yaw: sensorAtt[2])
            curAttitudeDr = unitAttitudeEstimator.estimateAtt(time: currentTime, acc: sensorData.acc, gyro: sensorData.gyro, rotMatrix: sensorData.rotationMatrix)
            
            let headingPdr = HF.radian2degree(radian: curAttitudePdr.Yaw)
            let headingDr = HF.radian2degree(radian: curAttitudeDr.Yaw)
            
            let unitStatusPdr = unitStatusEstimator.estimateStatus(Attitude: curAttitudePdr, isIndexChanged: unitDistancePdr.isIndexChanged, unitMode: MODE_PDR)
            let unitStatusDr = unitStatusEstimator.estimateStatus(Attitude: curAttitudeDr, isIndexChanged: unitDistanceDr.isIndexChanged, unitMode: MODE_DR)
            
            if (self.autoMode == 0) {
                return UnitDRInfo(index: unitIndexAuto, length: unitDistanceAuto.length, heading: headingPdr, velocity: unitDistanceAuto.velocity, lookingFlag: unitStatusPdr, isIndexChanged: unitDistanceAuto.isIndexChanged, autoMode: self.autoMode)
            } else {
                return UnitDRInfo(index: unitIndexAuto, length: unitDistanceAuto.length, heading: headingDr, velocity: unitDistanceAuto.velocity, lookingFlag: unitStatusDr, isIndexChanged: unitDistanceAuto.isIndexChanged, autoMode: self.autoMode)
            }
        default:
            // (Default : DR Mode)
            unitDistanceDr = drDistanceEstimator.estimateDistanceInfo(time: currentTime, sensorData: sensorData)
            self.autoMode = 1
            curAttitudeDr = unitAttitudeEstimator.estimateAtt(time: currentTime, acc: sensorData.acc, gyro: sensorData.gyro, rotMatrix: sensorData.rotationMatrix)
            
            let heading = HF.radian2degree(radian: curAttitudeDr.Yaw)
            
            let unitStatus = unitStatusEstimator.estimateStatus(Attitude: curAttitudeDr, isIndexChanged: unitDistanceDr.isIndexChanged, unitMode: unitMode)
            return UnitDRInfo(index: unitDistanceDr.index, length: unitDistanceDr.length, heading: heading, velocity: unitDistanceDr.velocity, lookingFlag: unitStatus, isIndexChanged: unitDistanceDr.isIndexChanged, autoMode: 0)
        }
    }
    
    public func updateDrQueue(data: DistanceInfo) {
        if (drQueue.count >= Int(MODE_QUEUE_SIZE)) {
            drQueue.pop()
        }
        drQueue.append(data)
    }
    
    public func updatePdrQueue(data: DistanceInfo) {
        if (pdrQueue.count >= Int(MODE_QUEUE_SIZE)) {
            pdrQueue.pop()
        }
        pdrQueue.append(data)
    }
    
    public func setVelocityScaleFactor(scaleFactor: Double) {
        self.drDistanceEstimator.velocityScaleFactor = scaleFactor
    }
    
    public func setScVelocityScaleFactor(scaleFactor: Double) {
        self.drDistanceEstimator.scVelocityScaleFactor = scaleFactor
    }
    
    public func setIsEntranceLevel (flag: Bool) {
        self.isEnteranceLevel = flag
    }
    
    func getCurrentTimeInMilliseconds() -> Double
    {
        return Double(Date().timeIntervalSince1970 * 1000)
    }
    
    func getLocalTimeString() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd-HH-mm-ss"
        dateFormatter.locale = Locale(identifier:"ko_KR")
        let nowDate = Date()
        let convertNowStr = dateFormatter.string(from: nowDate)
        
        return convertNowStr
    }
}
