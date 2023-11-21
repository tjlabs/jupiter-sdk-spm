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


