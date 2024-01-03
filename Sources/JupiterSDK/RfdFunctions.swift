import Foundation

let WEAK_THRESHOLD: Double = -92
let STRONG_THRESHOLD: Double = -80

enum TrimBleDataError: Error {
    case invalidInput
    case noValidData
}

public func trimBleData(bleInput: [String: [[Double]]]?, nowTime: Double, validTime: Double) -> Result<[String: [[Double]]], Error> {
    guard let bleInput = bleInput else {
            return .failure(TrimBleDataError.invalidInput)
        }
        
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
        
        if trimmedData.isEmpty {
            return .failure(TrimBleDataError.noValidData)
        } else {
            return .success(trimmedData)
        }
}

public func trimBleForCollect(bleData:[String: [[Double]]], nowTime: Double, validTime: Double) -> [String: [[Double]]] {
    var trimmedData = [String: [[Double]]]()

    for (bleID, bleData) in bleData {
        var newValue = [[Double]]()
        for data in bleData {
            let rssi = data[0]
            let time = data[1]

            if ((nowTime - time <= validTime) && (rssi >= -100)) {
                let dataToAdd: [Double] = [rssi, time]
                newValue.append(dataToAdd)
            }
        }

        if (newValue.count > 0) {
            trimmedData[bleID] = newValue
        }
    }

    return trimmedData
}

public func avgBleData(bleDictionary: [String: [[Double]]]) -> [String: Double] {
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

public func checkBleChannelNum(bleDict: [String: Double]) -> Int {
    var numChannels: Int = 0
    
    for key in bleDict.keys {
        let bleRssi: Double = bleDict[key] ?? -100.0
        
        if (bleRssi > -95.0) {
            numChannels += 1
        }
    }
    
    return numChannels
}

public func checkSufficientRfd(userTrajectory: [TrajectoryInfo]) -> Bool {
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

public func checkIsPossibleToIndoor(bleData: [String: Double]) -> Bool {
    var isPossible: Bool = false
    var countWeak: Int = 0
    var countStrong: Int = 0
    
    let bleIds = bleData.keys.count
    for (_, value) in bleData {
        if (value >= WEAK_THRESHOLD) {
            countWeak += 1
            if (value >= STRONG_THRESHOLD) {
                countStrong += 1
            }
        }
    }
    
    if (countWeak >= 2) {
        isPossible = true
    } else if (countStrong >= 1) {
        isPossible = true
    } else {
        isPossible = false
    }
    
    return isPossible
}

public func latestBleData(bleDictionary: [String: [[Double]]]) -> [String: Double] {
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

public func getLastScannedEntranceOuterWardTime(bleAvg: [String: Double], entranceOuterWards: [String]) -> (Bool, Double) {
    var isScanned: Bool = false
    var scannedTime: Double = 0

    for (key, value) in bleAvg {
        if entranceOuterWards.contains(key) {
            if (value >= -85.0) {
                isScanned = true
                scannedTime = getCurrentTimeInMillisecondsDouble()
                
                return (isScanned, scannedTime)
            }
        }
    }
    
    return (isScanned, scannedTime)
}

public func findNetworkBadEntrance(bleAvg: [String: Double]) -> (Bool, FineLocationTrackingFromServer) {
    var isInNetworkBadEntrance: Bool = false
    var entrance = FineLocationTrackingFromServer()
    
    let networkBadEntranceWards = ["TJ-00CB-00000386-0000"]
    for (key, value) in bleAvg {
        if networkBadEntranceWards.contains(key) {
            let rssi = value
            if (rssi >= -82.0) {
                isInNetworkBadEntrance = true
                
                entrance.building_name = "COEX"
                entrance.level_name = "B0"
                entrance.x = 270
                entrance.y = 10
                entrance.absolute_heading = 270
                
                return (isInNetworkBadEntrance, entrance)
            }
        }
    }
    
    return (isInNetworkBadEntrance, entrance)
}
