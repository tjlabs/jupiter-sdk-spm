import Foundation


public func getLocalTimeString() -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd-HH-mm-ss"
    dateFormatter.locale = Locale(identifier:"ko_KR")
    let nowDate = Date()
    let convertNowStr = dateFormatter.string(from: nowDate)
    
    return convertNowStr
}

public func getCurrentTimeInMilliseconds() -> Int
{
    return Int(Date().timeIntervalSince1970 * 1000)
}

public func getCurrentTimeInMillisecondsDouble() -> Double
{
    return (Date().timeIntervalSince1970 * 1000)
}

public func convertToDoubleArray(intArray: [Int]) -> [Double] {
    return intArray.map { Double($0) }
}

public func containsArray(_ array2D: [[Double]], _ targetArray: [Double]) -> Bool {
    for array in array2D {
        if array == targetArray {
            return true
        }
    }
    return false
}

public func fromServerToResult(fromServer: FineLocationTrackingFromServer, velocity: Double) -> FineLocationTrackingResult {
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

public func calTrajectoryRatio(trajPm: [[Double]], trajOg: [[Double]]) -> Double {
    var ratio = 1.0
    
    var lengthPm: Double = 0
    var lengthOg: Double = 0
    
    for i in 1..<trajPm.count {
        let pmDiffX = trajPm[i][0] - trajPm[i-1][0]
        let pmDiffY = trajPm[i][1] - trajPm[i-1][1]
        lengthPm += sqrt(pmDiffX*pmDiffX + pmDiffY*pmDiffY)
        
        let ogDiffX = trajOg[i][0] - trajOg[i-1][0]
        let ogDiffY = trajOg[i][1] - trajOg[i-1][1]
        lengthOg += sqrt(ogDiffX*ogDiffX + ogDiffY*ogDiffY)
    }
    
    ratio = lengthPm/lengthOg
    
    return ratio
}

public func checkLevelDirection(currentLevel: Int, destinationLevel: Int) -> String {
    var levelDirection: String = ""
    let diffLevel: Int = destinationLevel - currentLevel
    if (diffLevel > 0) {
        levelDirection = "_D"
    }
    return levelDirection
}

public func removeLevelDirectionString(levelName: String) -> String {
    var levelToReturn: String = levelName
    if (levelToReturn.contains("_D")) {
        levelToReturn = levelName.replacingOccurrences(of: "_D", with: "")
    }
    return levelToReturn
}

public func findClosestValueIndex(to target: Int, in array: [Int]) -> Int? {
    guard !array.isEmpty else {
        return nil
    }

    var closestIndex = 0
    var smallestDifference = abs(array[0] - target)

    for i in 0..<array.count {
        let value = array[i]
        let difference = abs(value - target)
        if difference < smallestDifference {
            smallestDifference = difference
            closestIndex = i
        }
    }

    return closestIndex
}

public func findClosestStructure(to myOsVersion: Int, in array: [rss_compensation]) -> rss_compensation? {
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

public func countAllValuesInDictionary(_ dictionary: [String: [String]]) -> Int {
    var count = 0
    for (_, value) in dictionary {
        count += value.count
    }
    return count
}

public func calculateAccumulatedLength(userTrajectory: [TrajectoryInfo]) -> Double {
    var accumulatedLength = 0.0
    for unitTraj in userTrajectory {
        accumulatedLength += unitTraj.length
    }
    
    return accumulatedLength
}

public func compensateHeading(heading: Double) -> Double {
    var headingToReturn: Double = heading
    
    if (headingToReturn < 0) {
        headingToReturn = headingToReturn + 360
    }
    headingToReturn = headingToReturn - floor(headingToReturn/360)*360

    return headingToReturn
}

public func checkIsSimilarXyh(input: [Double]) -> Bool {
    var dh = input[2]
    if (dh >= 270) {
        dh = 360 - dh
    }
    
    if (dh < 20) {
        return true
    } else {
        return false
    }
}

public func checkDiagonal(userTrajectory: [TrajectoryInfo], DIAGONAL_CONDITION: Double) -> [TrajectoryInfo] {
    var accumulatedDiagonal = 0.0
    
    if (!userTrajectory.isEmpty) {
        let startHeading = userTrajectory[0].heading
        let headInfo = userTrajectory[userTrajectory.count-1]
        var xyFromHead: [Double] = [headInfo.userX, headInfo.userY]
        
        var headingFromHead = [Double] (repeating: 0, count: userTrajectory.count)
        for i in 0..<userTrajectory.count {
            headingFromHead[i] = compensateHeading(heading: userTrajectory[i].heading  - 180 - startHeading)
        }
        
        var trajectoryFromHead = [[Double]]()
        trajectoryFromHead.append(xyFromHead)
        for i in (1..<userTrajectory.count).reversed() {
            let headAngle = headingFromHead[i]
            xyFromHead[0] = xyFromHead[0] + userTrajectory[i].length*cos(headAngle*D2R)
            xyFromHead[1] = xyFromHead[1] + userTrajectory[i].length*sin(headAngle*D2R)
            trajectoryFromHead.append(xyFromHead)
            
            let trajectoryMinMax = getMinMaxValues(for: trajectoryFromHead)
            let dx = trajectoryMinMax[2] - trajectoryMinMax[0]
            let dy = trajectoryMinMax[3] - trajectoryMinMax[1]
            
            accumulatedDiagonal = sqrt(dx*dx + dy*dy)
            if (accumulatedDiagonal >= DIAGONAL_CONDITION) {
                let newTrajectory = getTrajectoryForDiagonal(from: userTrajectory, N: i)
                return newTrajectory
            }
        }
    }
    
    return userTrajectory
}

public func checkAccumulatedLength(userTrajectory: [TrajectoryInfo], LENGTH_CONDITION: Double) -> [TrajectoryInfo] {
    var accumulatedLength = 0.0

    var longTrajIndex: Int = 0
    var isFindLong: Bool = false
    var shortTrajIndex: Int = 0
    var isFindShort: Bool = false

    if (!userTrajectory.isEmpty) {
        let startHeading = userTrajectory[0].heading
        let headInfo = userTrajectory[userTrajectory.count-1]
        var xyFromHead: [Double] = [headInfo.userX, headInfo.userY]

        var headingFromHead = [Double] (repeating: 0, count: userTrajectory.count)
        for i in 0..<userTrajectory.count {
            headingFromHead[i] = compensateHeading(heading: userTrajectory[i].heading  - 180 - startHeading)
        }

        var trajectoryFromHead = [[Double]]()
        trajectoryFromHead.append(xyFromHead)
        for i in (1..<userTrajectory.count).reversed() {
            let headAngle = headingFromHead[i]
            let uvdLength = userTrajectory[i].length
            accumulatedLength += uvdLength

            if ((accumulatedLength >= LENGTH_CONDITION*2) && !isFindLong) {
                isFindLong = true
                longTrajIndex = i
            }

            if ((accumulatedLength >= LENGTH_CONDITION) && !isFindShort) {
                isFindShort = true
                shortTrajIndex = i
            }

            xyFromHead[0] = xyFromHead[0] + uvdLength*cos(headAngle*D2R)
            xyFromHead[1] = xyFromHead[1] + uvdLength*sin(headAngle*D2R)
            trajectoryFromHead.append(xyFromHead)
        }

        let trajectoryMinMax = getMinMaxValues(for: trajectoryFromHead)
        let width = trajectoryMinMax[2] - trajectoryMinMax[0]
        let height = trajectoryMinMax[3] - trajectoryMinMax[1]

        if (width <= 3 || height <= 3) {
            let newTrajectory = getTrajectoryForDiagonal(from: userTrajectory, N: longTrajIndex)
            return newTrajectory
        } else {
            let newTrajectory = getTrajectoryForDiagonal(from: userTrajectory, N: shortTrajIndex)
            return newTrajectory
        }
    }

    return userTrajectory
}

public func calculateAccumulatedDiagonal(userTrajectory: [TrajectoryInfo]) -> Double {
    var accumulatedDiagonal = 0.0
    
    if (!userTrajectory.isEmpty) {
        let startHeading = userTrajectory[0].heading
        let headInfo = userTrajectory[userTrajectory.count-1]
        var xyFromHead: [Double] = [headInfo.userX, headInfo.userY]
        
        var headingFromHead = [Double] (repeating: 0, count: userTrajectory.count)
        for i in 0..<userTrajectory.count {
            headingFromHead[i] = compensateHeading(heading: userTrajectory[i].heading  - 180 - startHeading)
        }
        
        var trajectoryFromHead = [[Double]]()
        trajectoryFromHead.append(xyFromHead)
        for i in (1..<userTrajectory.count).reversed() {
            let headAngle = headingFromHead[i]
            xyFromHead[0] = xyFromHead[0] + userTrajectory[i].length*cos(headAngle*D2R)
            xyFromHead[1] = xyFromHead[1] + userTrajectory[i].length*sin(headAngle*D2R)
            trajectoryFromHead.append(xyFromHead)
        }
        
        let trajectoryMinMax = getMinMaxValues(for: trajectoryFromHead)
        let dx = trajectoryMinMax[2] - trajectoryMinMax[0]
        let dy = trajectoryMinMax[3] - trajectoryMinMax[1]
        
        accumulatedDiagonal = sqrt(dx*dx + dy*dy)
    }
    
    return accumulatedDiagonal
}

public func isTrajectoryStraight(for array: [Double], size: Int, mode: String, conditionPdr: Int, conditionDr: Int) -> Int {
    var CONDITON: Int = 10
    if (mode == "pdr") {
        CONDITON = conditionPdr
    } else {
        CONDITON = conditionDr
    }
    if (size < CONDITON) {
        return 0
    }
    
    let straightAngle: Double = 1.5
    // All Straight
    let circularStandardDeviationAll = circularStandardDeviation(for: array)
    if (circularStandardDeviationAll <= straightAngle) {
        return 1
    }
    
    // Head Straight
    let lastTenValues = Array(array[(size-CONDITON)..<size])
    let circularStandardDeviationHead = circularStandardDeviation(for: lastTenValues)
    if (circularStandardDeviationHead <= straightAngle) {
        return 2
    }
    
    // Tail Straight
    let firstTenValues = Array(array[0..<CONDITON])
    let circularStandardDeviationTail = circularStandardDeviation(for: firstTenValues)
    if (circularStandardDeviationTail <= straightAngle) {
        return 3
    }
    
    return 0
}

public func getTrajectoryFromIndex(from userTrajectory: [TrajectoryInfo], index: Int) -> [TrajectoryInfo] {
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

public func getTrajectoryFromLast(from userTrajectory: [TrajectoryInfo], N: Int) -> [TrajectoryInfo] {
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

public func getTrajectoryForDiagonal(from userTrajectory: [TrajectoryInfo], N: Int) -> [TrajectoryInfo] {
    let size = userTrajectory.count
    guard size >= N else {
        return userTrajectory
    }
    
    let startIndex = N
    let endIndex = size
    
    var result: [TrajectoryInfo] = []
    for i in startIndex..<endIndex {
        result.append(userTrajectory[i])
    }

    return result
}

public func cutTrajectoryFromLast(from userTrajectory: [TrajectoryInfo], userLength: Double, cutLength: Double) -> [TrajectoryInfo] {
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

public func getSearchCoordinates(areaMinMax: [Double], interval: Double) -> [[Double]] {
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

public func getSearchAreaMinMax(xyMinMax: [Double], heading: [Double], recentScc: Double, searchType: Int, lengthCondition: Double) -> [Double] {
    var areaMinMax: [Double] = []
    
    var xMin = xyMinMax[0]
    var yMin = xyMinMax[1]
    var xMax = xyMinMax[2]
    var yMax = xyMinMax[3]
    
    let SEARCH_LENGTH: Double = lengthCondition*0.4
    
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
        xMin = xMin - lengthCondition*0.05
        xMax = xMax + lengthCondition*0.05
    }

    if (abs(yMin - yMax) < 5.0) {
        yMin = yMin - lengthCondition*0.05
        yMax = yMax + lengthCondition*0.05
    }
    
    // U-Turn인 경우
    let diffHeading = compensateHeading(heading: abs(headingStart - headingEnd))
    let diffX = abs(xMax - xMin)
    let diffY = abs(yMax - yMin)
    let diffXy = abs(diffX - diffY)*0.2
    
    if (diffHeading > 150) {
        if (diffX < diffY) {
            xMin = xMin - diffXy
            xMax = xMax + diffXy
        } else {
            yMin = yMin - diffXy
            yMax = yMax + diffXy
        }
    } else {
        // Check ㄹ Trajectory
        if (diffHeading < 30 && searchType != 1) {
            if (diffX < diffY) {
                xMin = xMin - diffXy
                xMax = xMax + diffXy
            } else {
                yMin = yMin - diffXy
                yMax = yMax + diffXy
            }
        }
    }

    areaMinMax = [xMin, yMin, xMax, yMax]
    
    return areaMinMax
}

public func convertToValidSearchRange(inputRange: [Int], pathPointMinMax: [Double]) -> [Int] {
    var searchRange = inputRange
    
    let minMax: [Int] = pathPointMinMax.map { Int($0) }
    if (pathPointMinMax.isEmpty) {
        return searchRange
    }
    if (pathPointMinMax[0] == 0 && pathPointMinMax[1] == 0 && pathPointMinMax[2] == 0 && pathPointMinMax[3] == 0) {
        return searchRange
    }
    
    // Check isValid
    if (inputRange[0] < minMax[0]) {
        let diffX = minMax[0] - inputRange[0]
        searchRange[0] = minMax[0]
        
        searchRange[2] = inputRange[2] + Int(Double(diffX)*0.5)
        if (searchRange[2] > minMax[2]) {
            searchRange[2] = minMax[2]
        }
    }
    
    if (inputRange[1] < minMax[1]) {
        let diffY = minMax[1] - inputRange[1]
        searchRange[1] = minMax[1]
        
        searchRange[3] = inputRange[3] + Int(Double(diffY)*0.5)
        if (searchRange[3] > minMax[3]) {
            searchRange[3] = minMax[3]
        }
    }
    
    if (inputRange[2] > minMax[2]) {
        let diffX = inputRange[2] - minMax[2]
        searchRange[2] = minMax[2]
        
        searchRange[0] = inputRange[0] - Int(Double(diffX)*0.5)
        if (searchRange[0] < minMax[0]) {
            searchRange[0] = minMax[0]
        }
    }
    
    if (inputRange[3] > minMax[3]) {
        let diffY = inputRange[3] - minMax[3]
        searchRange[3] = minMax[3]
        
        searchRange[1] = inputRange[1] - Int(Double(diffY)*0.5)
        if (searchRange[1] < minMax[1]) {
            searchRange[1] = minMax[1]
        }
    }
    
    return searchRange
}

public func extractSectionWithLeastChange(inputArray: [Double]) -> [Double] {
    guard inputArray.count > 7 else {
        return []
    }
    var bestSliceStartIndex = 0
    var bestSliceEndIndex = 0

    for startIndex in 0..<(inputArray.count-6) {
        for endIndex in (startIndex+7)..<inputArray.count {
            let slice = Array(inputArray[startIndex...endIndex])
            guard let minSliceValue = slice.min(), let maxSliceValue = slice.max() else {
                continue
            }

            let currentDifference = abs(maxSliceValue - minSliceValue)
            if currentDifference < 5 && slice.count > bestSliceEndIndex - bestSliceStartIndex {
                bestSliceStartIndex = startIndex
                bestSliceEndIndex = endIndex
            }
        }
    }

    return Array(inputArray[bestSliceStartIndex...bestSliceEndIndex])
}

public func propagateUsingUvd(drBuffer: [UnitDRInfo], result: FineLocationTrackingFromServer) -> (Bool, [Double]) {
    var isSuccess: Bool = false
    var propagationValues: [Double] = [0, 0, 0]
    let resultIndex = result.index
    var matchedIndex: Int = -1
    
    for i in 0..<drBuffer.count {
        let drBufferIndex = drBuffer[i].index
        if (drBufferIndex == resultIndex) {
            matchedIndex = i
        }
    }
    
    var dx: Double = 0
    var dy: Double = 0
    var dh: Double = 0
    
    if (matchedIndex != -1) {
        let drBuffrerFromIndex = sliceArray(drBuffer, startingFrom: matchedIndex)
        let headingCompensation: Double = result.absolute_heading - drBuffrerFromIndex[0].heading
        var headingBuffer = [Double]()
        for i in 0..<drBuffrerFromIndex.count {
            let compensatedHeading = compensateHeading(heading: drBuffrerFromIndex[i].heading + headingCompensation)
            headingBuffer.append(compensatedHeading)
            
            dx += drBuffrerFromIndex[i].length * cos(compensatedHeading*D2R)
            dy += drBuffrerFromIndex[i].length * sin(compensatedHeading*D2R)
        }
        dh = headingBuffer[headingBuffer.count-1] - headingBuffer[0]
        
        isSuccess = true
        propagationValues = [dx, dy, dh]
    }
    
    return (isSuccess, propagationValues)
}

public func isResultHeadingStraight(drBuffer: [UnitDRInfo], result: FineLocationTrackingFromServer) -> Bool {
    var isStraight: Bool = false
    let resultIndex = result.index
    
    var matchedIndex: Int = -1
    
    for i in 0..<drBuffer.count {
        let drBufferIndex = drBuffer[i].index
        if (drBufferIndex == resultIndex) {
            matchedIndex = i
        }
    }
    
    if (matchedIndex != -1 && matchedIndex >= 4) {
        var startHeading: Double = 0
        var endHeading: Double = 0
        if (drBuffer.count < 5) {
            startHeading = drBuffer[0].heading
            endHeading = drBuffer[matchedIndex].heading
        } else {
            startHeading = drBuffer[matchedIndex-4].heading
            endHeading = drBuffer[matchedIndex].heading
        }
        
        if (abs(endHeading - startHeading) < 5.0) {
            isStraight = true
        } else {
            isStraight = false
        }
    }
    
    return isStraight
}


