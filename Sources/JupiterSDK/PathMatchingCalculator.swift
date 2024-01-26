import Foundation

public class PathMatchingCalculator {
    
    public var PathType = [String: [Int]]()
    public var PathPoint = [String: [[Double]]]()
    public var PathPointMinMax = [Double]()
    public  var PathMagScale = [String: [Double]]()
    public var PathHeading = [String: [String]]()
    public var EntranceMatchingArea = [String: [[Double]]]()
    public var LoadPathPoint = [String: Bool]()
    
    init() {
        
    }
    
    public func parseRoad(data: String) -> ([Int], [[Double]], [Double], [String] ) {
        var roadType = [Int]()
        var road = [[Double]]()
        var roadScale = [Double]()
        var roadHeading = [String]()
        
        var roadX = [Double]()
        var roadY = [Double]()
        
        let roadString = data.components(separatedBy: .newlines)
        for i in 0..<roadString.count {
            if (roadString[i] != "") {
                let lineData = roadString[i].components(separatedBy: ",")
                
                roadType.append(Int(Double(lineData[0])!))
                roadX.append(Double(lineData[1])!)
                roadY.append(Double(lineData[2])!)
                roadScale.append(Double(lineData[3])!)
                
                var headingArray: String = ""
                if (lineData.count > 4) {
                    for j in 4..<lineData.count {
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
        self.PathPointMinMax = [roadX.min() ?? 0, roadY.min() ?? 0, roadX.max() ?? 0, roadY.max() ?? 0]
        
        return (roadType, road, roadScale, roadHeading)
    }
    
    public func checkInEntranceMatchingArea(x: Double, y: Double, building: String, level: String) -> (Bool, [Double]) {
        var area = [Double]()
        
        let buildingName = building
        let levelName = removeLevelDirectionString(levelName: level)
        
        let key = "\(buildingName)_\(levelName)"
        guard let entranceMatchingArea: [[Double]] = self.EntranceMatchingArea[key] else {
            return (false, area)
        }
        
        for i in 0..<entranceMatchingArea.count {
            if (!entranceMatchingArea[i].isEmpty) {
                let xMin = entranceMatchingArea[i][0]
                let yMin = entranceMatchingArea[i][1]
                let xMax = entranceMatchingArea[i][2]
                let yMax = entranceMatchingArea[i][3]
                
                if (x >= xMin && x <= xMax) {
                    if (y >= yMin && y <= yMax) {
                        area = entranceMatchingArea[i]
                        return (true, area)
                    }
                }
            }
        }
        
        return (false, area)
    }
    
    public func pathMatching(building: String, level: String, x: Double, y: Double, heading: Double, isPast: Bool, HEADING_RANGE: Double, isUseHeading: Bool, pathType: Int, range: Double) -> (isSuccess: Bool, xyhs: [Double]) {
        var isSuccess: Bool = false
        var xyhs: [Double] = [x, y, heading, 1.0]
        let levelCopy: String = removeLevelDirectionString(levelName: level)
        let key: String = "\(building)_\(levelCopy)"
        if (isPast) {
            isSuccess = true
            return (isSuccess, xyhs)
        }
        
        if (!(building.isEmpty) && !(level.isEmpty)) {
            guard let mainType: [Int] = self.PathType[key] else {
                return (isSuccess, xyhs)
            }
            guard let mainRoad: [[Double]] = self.PathPoint[key] else {
                return (isSuccess, xyhs)
            }
            
            guard let mainMagScale: [Double] = self.PathMagScale[key] else {
                return (isSuccess, xyhs)
            }
            
            guard let mainHeading: [String] = self.PathHeading[key] else {
                return (isSuccess, xyhs)
            }
            
            let pathhMatchingArea = self.checkInEntranceMatchingArea(x: x, y: y, building: building, level: levelCopy)
            
            var idshArray = [[Double]]()
            var idshArrayWhenFail = [[Double]]()
            var pathArray = [[Double]]()
            if (!mainRoad.isEmpty) {
                let roadX = mainRoad[0]
                let roadY = mainRoad[1]
                
                var xMin = x - range
                var xMax = x + range
                var yMin = y - range
                var yMax = y + range
                if (pathhMatchingArea.0) {
                    xMin = pathhMatchingArea.1[0]
                    yMin = pathhMatchingArea.1[1]
                    xMax = pathhMatchingArea.1[2]
                    yMax = pathhMatchingArea.1[3]
                }
                
                for i in 0..<roadX.count {
                    let xPath = roadX[i]
                    let yPath = roadY[i]
                    
                    let pathTypeLoaded = mainType[i]
                    if (pathType == 1) {
                        if (pathType != pathTypeLoaded) {
                            continue
                        }
                    }
                    // XY 범위 안에 있는 값 중에 검사
                    if (xPath >= xMin && xPath <= xMax) {
                        if (yPath >= yMin && yPath <= yMax) {
                            let index = Double(i)
                            let distance = sqrt(pow(x-xPath, 2) + pow(y-yPath, 2))
                            
                            let magScale = mainMagScale[i]
                            var idsh: [Double] = [index, distance, magScale, heading]
                            var path: [Double] = [xPath, yPath, 0, 0]
                            
                            idshArrayWhenFail.append(idsh)
                            
                            // Heading 사용
                            if (isUseHeading) {
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
                                        if (isUseHeading) {
                                            if (heading > 270 && (minHeading >= 0 && minHeading < 90)) {
                                                if (abs(minHeading+360-heading) >= HEADING_RANGE) {
                                                    isValidIdh = false
                                                }
                                            } else if (minHeading > 270 && (heading >= 0 && heading < 90)) {
                                                if (abs(heading+360-minHeading) >= HEADING_RANGE) {
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
                                }
                                
                                if (!idshArray.isEmpty) {
                                    let sortedIdsh = idshArray.sorted(by: {$0[1] < $1[1] })
                                    var index: Int = 0
                                    var correctedHeading: Double = heading
                                    var correctedScale = 1.0
                                    
                                    if (!sortedIdsh.isEmpty) {
                                        let minData: [Double] = sortedIdsh[0]
                                        index = Int(minData[0])
                                        if (isUseHeading) {
                                            correctedScale = minData[2]
                                            correctedHeading = minData[3]
                                        } else {
                                            correctedHeading = heading
                                        }
                                    }
                                    
                                    isSuccess = true
                                    
                                    if (correctedScale < 0.7) {
                                        correctedScale = 0.7
                                    }
                                    
                                    xyhs = [roadX[index], roadY[index], correctedHeading, correctedScale]
                                } else {
                                    let sortedIdsh = idshArrayWhenFail.sorted(by: {$0[1] < $1[1] })
                                    var index: Int = 0
                                    var correctedScale = 1.0
                                    
                                    if (!sortedIdsh.isEmpty) {
                                        let minData: [Double] = sortedIdsh[0]
                                        index = Int(minData[0])
                                        correctedScale = minData[2]
                                    }
                                    
                                    isSuccess = false
                                    
                                    if (correctedScale < 0.7) {
                                        correctedScale = 0.7
                                    }
                                    
                                    xyhs = [roadX[index], roadY[index], heading, correctedScale]
                                }
                            } else {
                                // Heading 미사용
                                idshArray.append(idsh)
                                pathArray.append(path)
                                if (!idshArray.isEmpty) {
                                    isSuccess = true
                                    
                                    let sortedIdsh = idshArray.sorted(by: {$0[1] < $1[1] })
                                    var index: Int = 0
                                    var correctedScale = 1.0
                                    
                                    if (!sortedIdsh.isEmpty) {
                                        let minData: [Double] = sortedIdsh[0]
                                        index = Int(minData[0])
                                        correctedScale = minData[2]
                                        
                                        if (correctedScale < 0.7) {
                                            correctedScale = 0.7
                                        }
                                        
                                        xyhs = [roadX[index], roadY[index], heading, correctedScale]
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        return (isSuccess, xyhs)
    }
    
    public func pathTrajectoryMatching(building: String, level: String, x: Double, y: Double, heading: Double, pastResult: FineLocationTrackingResult, drBuffer: [UnitDRInfo], HEADING_RANGE: Double, pathType: Int, range: Double) -> (isSuccess: Bool, xyd: [Double], minTrajectory: [[Double]]) {
        let pastX = pastResult.x
        let pastY = pastResult.y
        
        var isSuccess: Bool = false
        var xyd: [Double] = [x, y, 50]
        var minTrajectory = [[Double]]()
        
        let levelCopy: String = removeLevelDirectionString(levelName: level)
        let key: String = "\(building)_\(levelCopy)"
        
        if (!(building.isEmpty) && !(level.isEmpty)) {
            guard let mainType: [Int] = self.PathType[key] else {
                return (isSuccess, xyd, minTrajectory)
            }
            guard let mainRoad: [[Double]] = self.PathPoint[key] else {
                return (isSuccess, xyd, minTrajectory)
            }
            
            if (!mainRoad.isEmpty) {
                let roadX = mainRoad[0]
                let roadY = mainRoad[1]
                
                var xMin = x - range
                var xMax = x + range
                var yMin = y - range
                var yMax = y + range
                
                var ppXydArray = [[Double]]()
                var minDistanceCoord = [Double]()
                
                for i in 0..<roadX.count {
                    let xPath = roadX[i]
                    let yPath = roadY[i]
                    
                    let pathTypeLoaded = mainType[i]
                    if (pathType == 1) {
                        if (pathType != pathTypeLoaded) {
                            continue
                        }
                    }
                    
                    // XY 범위 안에 있는 값 중에 검사
                    if (xPath >= xMin && xPath <= xMax) {
                        if (yPath >= yMin && yPath <= yMax) {
                            var distanceSum: Double = 0
                            
                            let headingCompensation: Double = heading - drBuffer[drBuffer.count-1].heading
                            var headingBuffer: [Double] = []
                            for i in 0..<drBuffer.count {
                                let compensatedHeading = compensateHeading(heading: drBuffer[i].heading + headingCompensation - 180)
                                headingBuffer.append(compensatedHeading)
                            }
                            
                            var xyFromHead: [Double] = [xPath, yPath]
                            let firstXyd = calDistacneFromNearestPp(coord: xyFromHead, mainRoad: mainRoad, mainType: mainType, pathType: pathType, range: range)
                            var xydArray: [[Double]] = [firstXyd]
                            distanceSum += firstXyd[2]
                            
                            var trajectoryFromHead = [[Double]]()
                            trajectoryFromHead.append(xyFromHead)
                            for i in (1..<drBuffer.count).reversed() {
                                let headAngle = headingBuffer[i]
                                xyFromHead[0] = xyFromHead[0] + drBuffer[i].length*cos(headAngle*D2R)
                                xyFromHead[1] = xyFromHead[1] + drBuffer[i].length*sin(headAngle*D2R)
                                trajectoryFromHead.append(xyFromHead)
                                
                                
                                let calculatedXyd = calDistacneFromNearestPp(coord: xyFromHead, mainRoad: mainRoad, mainType: mainType, pathType: pathType, range: range)
                                xydArray.append(calculatedXyd)
                                distanceSum += calculatedXyd[2]
                            }
                            let distWithPast = sqrt((pastX - xPath)*(pastX - xPath) + (pastY - yPath)*(pastY - yPath))
                            ppXydArray.append([xPath, yPath, distanceSum, distWithPast])
                            
                            if (minDistanceCoord.isEmpty) {
                                minDistanceCoord = [xPath, yPath, distanceSum, distWithPast]
                                minTrajectory = trajectoryFromHead
                            } else {
                                let distanceCurrent = distanceSum
                                let distancePast = minDistanceCoord[2]
                                if (distanceCurrent < distancePast && distWithPast <= 3) {
                                    minDistanceCoord = [xPath, yPath, distanceSum, distWithPast]
                                    minTrajectory = trajectoryFromHead
                                }
                            }
                        }
                    }
                    
                    if (!minDistanceCoord.isEmpty) {
                        if (minDistanceCoord[2] <= 15 && minDistanceCoord[3] <= 3) {
                            isSuccess = true
                        } else {
                            isSuccess = false
                        }
                        xyd = minDistanceCoord
                    }
                }
            }
        }
        return (isSuccess, xyd, minTrajectory)
    }
    
    public func extendedPathTrajectoryMatching(building: String, level: String, x: Double, y: Double, heading: Double, pastResult: FineLocationTrackingResult, drBuffer: [UnitDRInfo], HEADING_RANGE: Double, pathType: Int, mode: String, range: Double) -> (isSuccess: Bool, xyd: [Double], minTrajectory: [[Double]], minTrajectoryOriginal: [[Double]]) {
        let startTime: Double = getCurrentTimeInMillisecondsDouble()
        
        let pastX = pastResult.x
        let pastY = pastResult.y
        
        var isSuccess: Bool = false
        var xyd: [Double] = [x, y, 50]
        var minTrajectory = [[Double]]()
        var minTrajectoryOriginal = [[Double]]()
        
        let levelCopy: String = removeLevelDirectionString(levelName: level)
        let key: String = "\(building)_\(levelCopy)"
        
        if (!(building.isEmpty) && !(level.isEmpty)) {
            guard let mainType: [Int] = self.PathType[key] else {
                return (isSuccess, xyd, minTrajectory, minTrajectoryOriginal)
            }
            guard let mainRoad: [[Double]] = self.PathPoint[key] else {
                return (isSuccess, xyd, minTrajectory, minTrajectoryOriginal)
            }
            
            if (!mainRoad.isEmpty) {
                let roadX = mainRoad[0]
                let roadY = mainRoad[1]
                
                var xMin = x - range
                var xMax = x + range
                var yMin = y - range
                var yMax = y + range
                
                var ppXydArray = [[Double]]()
                var minDistanceCoord = [Double]()
                
                for i in 0..<roadX.count {
                    let xPath = roadX[i]
                    let yPath = roadY[i]
                    
                    let pathTypeLoaded = mainType[i]
                    if (pathType == 1) {
                        if (pathType != pathTypeLoaded) {
                            continue
                        }
                    }
                    
                    // XY 범위 안에 있는 값 중에 검사
                    if (xPath >= xMin && xPath <= xMax) {
                        if (yPath >= yMin && yPath <= yMax) {
                            var passedPp = [[Double]]()
                            var distanceSum: Double = 0
                            
                            let headingCompensation: Double = heading - drBuffer[drBuffer.count-1].heading
                            var headingBuffer: [Double] = []
                            for i in 0..<drBuffer.count {
                                let compensatedHeading = compensateHeading(heading: drBuffer[i].heading + headingCompensation - 180)
                                headingBuffer.append(compensatedHeading)
                            }
                            
                            var xyFromHead: [Double] = [xPath, yPath]
                            var xyOriginal: [Double] = [xPath, yPath]
                            let firstXyd = extendedCalDistacneFromNearestPp(coord: xyFromHead, passedPp: passedPp, mainRoad: mainRoad, mainType: mainType, pathType: pathType, range: range)
                            passedPp.append(xyFromHead)
                            
                            var xydArray: [[Double]] = [firstXyd]
                            distanceSum += firstXyd[2]
                            
                            var trajectoryFromHead = [[Double]]()
                            var trajectoryOriginal = [[Double]]()
                            trajectoryFromHead.append(xyFromHead)
                            trajectoryOriginal.append(xyOriginal)
                            for i in (1..<drBuffer.count).reversed() {
                                let headAngle = headingBuffer[i]
                                xyOriginal[0] = xyOriginal[0] + drBuffer[i].length*cos(headAngle*D2R)
                                xyOriginal[1] = xyOriginal[1] + drBuffer[i].length*sin(headAngle*D2R)
                                trajectoryOriginal.append(xyOriginal)
                                if (mode == "pdr") {
                                    if (i%2 == 0) {
                                        let propagatedX = xyFromHead[0] + drBuffer[i].length*cos(headAngle*D2R)
                                        let propagatedY = xyFromHead[1] + drBuffer[i].length*sin(headAngle*D2R)
                                        let calculatedXyd = extendedCalDistacneFromNearestPp(coord: [propagatedX, propagatedY], passedPp: passedPp, mainRoad: mainRoad, mainType: mainType, pathType: pathType, range: range)
                                        
                                        xyFromHead[0] = calculatedXyd[0]
                                        xyFromHead[1] = calculatedXyd[1]
                                        xydArray.append(calculatedXyd)
                                        distanceSum += calculatedXyd[2]
                                        trajectoryFromHead.append(xyFromHead)
                                        passedPp.append(xyFromHead)
                                    } else {
                                        let propagatedX = xyFromHead[0] + drBuffer[i].length*cos(headAngle*D2R)
                                        let propagatedY = xyFromHead[1] + drBuffer[i].length*sin(headAngle*D2R)
                                        let calculatedXyd = extendedCalDistacneFromNearestPp(coord: [propagatedX, propagatedY], passedPp: passedPp, mainRoad: mainRoad, mainType: mainType, pathType: pathType, range: range)
                                        
                                        xyFromHead[0] = propagatedX
                                        xyFromHead[1] = propagatedY
                                        xydArray.append(calculatedXyd)
                                        distanceSum += calculatedXyd[2]
                                        trajectoryFromHead.append(xyFromHead)
                                        passedPp.append(xyFromHead)
                                    }
                                } else {
                                    let propagatedX = xyFromHead[0] + drBuffer[i].length*cos(headAngle*D2R)
                                    let propagatedY = xyFromHead[1] + drBuffer[i].length*sin(headAngle*D2R)
                                    let calculatedXyd = extendedCalDistacneFromNearestPp(coord: [propagatedX, propagatedY], passedPp: passedPp, mainRoad: mainRoad, mainType: mainType, pathType: pathType, range: range)
                                    
                                    xyFromHead[0] = calculatedXyd[0]
                                    xyFromHead[1] = calculatedXyd[1]
                                    xydArray.append(calculatedXyd)
                                    distanceSum += calculatedXyd[2]
                                    trajectoryFromHead.append(xyFromHead)
                                    passedPp.append(xyFromHead)
                                }
                            }
                            
                            let distWithPast = sqrt((pastX - xPath)*(pastX - xPath) + (pastY - yPath)*(pastY - yPath))
                            ppXydArray.append([xPath, yPath, distanceSum, distWithPast])
                            
                            if (minDistanceCoord.isEmpty) {
                                minDistanceCoord = [xPath, yPath, distanceSum, distWithPast]
                                minTrajectory = trajectoryFromHead
                                minTrajectoryOriginal = trajectoryOriginal
                            } else {
                                let distanceCurrent = distanceSum
                                let distancePast = minDistanceCoord[2]
                                if (distanceCurrent < distancePast && distWithPast <= 3) {
                                    minDistanceCoord = [xPath, yPath, distanceSum, distWithPast]
                                    minTrajectory = trajectoryFromHead
                                    minTrajectoryOriginal = trajectoryOriginal
                                }
                            }
                        }
                    }
                    
//                    print(getLocalTimeString() + " , (PM) minDistanceCoord = \(minDistanceCoord)")
                    if (!minDistanceCoord.isEmpty) {
                        if (minDistanceCoord[2] <= 15 && minDistanceCoord[3] <= 3) {
                            isSuccess = true
                        } else {
                            isSuccess = false
                        }
                        xyd = minDistanceCoord
                    }
                }
            }
        }
        
//        print(getLocalTimeString() + " , (PM) isSuccess = \(isSuccess) // minTrajectory = \(minTrajectory)")
        let endTime: Double = getCurrentTimeInMillisecondsDouble()
        let checkTime = (endTime-startTime)*1e-3
//        print(getLocalTimeString() + " , (Jupiter) Path-Traj Matching : time = \(checkTime)")
        return (isSuccess, xyd, minTrajectory, minTrajectoryOriginal)
    }
    
    public func calDistacneFromNearestPp(coord: [Double], mainRoad: [[Double]], mainType: [Int], pathType: Int, range: Double) -> [Double] {
        let x = coord[0]
        let y = coord[1]
        
        var xyd: [Double] = [x, y, 50]
        
        var xydArray = [[Double]]()
        
        let roadX = mainRoad[0]
        let roadY = mainRoad[1]
        
        var xMin = x - range
        var xMax = x + range
        var yMin = y - range
        var yMax = y + range
        
        for i in 0..<roadX.count {
            let xPath = roadX[i]
            let yPath = roadY[i]
            
            let pathTypeLoaded = mainType[i]
            if (pathType == 1) {
                if (pathType != pathTypeLoaded) {
                    continue
                }
            }
            // XY 범위 안에 있는 값 중에 검사
            if (xPath >= xMin && xPath <= xMax) {
                if (yPath >= yMin && yPath <= yMax) {
                    let distance = sqrt(pow(x-xPath, 2) + pow(y-yPath, 2))
                    var xyd: [Double] = [xPath, yPath, distance]
                    
                    xydArray.append(xyd)
                }
            }
        }
        
        if (!xydArray.isEmpty) {
            let sortedXyd = xydArray.sorted(by: {$0[2] < $1[2] })
            if (!sortedXyd.isEmpty) {
                let minData: [Double] = sortedXyd[0]
                xyd = minData
            }
        }
        return xyd
    }
    
    public func extendedCalDistacneFromNearestPp(coord: [Double], passedPp: [[Double]], mainRoad: [[Double]], mainType: [Int], pathType: Int, range: Double) -> [Double] {
        let x = coord[0]
        let y = coord[1]
        
        var xyd: [Double] = [x, y, 50]
        
        var xydArray = [[Double]]()
        
        let roadX = mainRoad[0]
        let roadY = mainRoad[1]
        
        var xMin = x - range
        var xMax = x + range
        var yMin = y - range
        var yMax = y + range
        
        for i in 0..<roadX.count {
            let xPath = roadX[i]
            let yPath = roadY[i]
            
            let pathTypeLoaded = mainType[i]
            if (pathType == 1) {
                if (pathType != pathTypeLoaded) {
                    continue
                }
            }
            
            // XY 범위 안에 있는 값 중에 검사
            if (!passedPp.isEmpty) {
                let isContain: Bool = containsArray(passedPp, [xPath, yPath])
                if (isContain) {
                    continue
                }
            }
            
            if (xPath >= xMin && xPath <= xMax) {
                if (yPath >= yMin && yPath <= yMax) {
                    let distance = sqrt(pow(x-xPath, 2) + pow(y-yPath, 2))
                    var xyd: [Double] = [xPath, yPath, distance]
                    
                    xydArray.append(xyd)
                }
            }
        }
        
        if (!xydArray.isEmpty) {
            let sortedXyd = xydArray.sorted(by: {$0[2] < $1[2] })
            if (!sortedXyd.isEmpty) {
                let minData: [Double] = sortedXyd[0]
                xyd = minData
            }
        }
        return xyd
    }
    
    public func getBestMatchedTrajectory(building: String, level: String, searchRange: [Double], tailHeading: Double, uvHeading: [Double], uvLength: [Double], pathType: Int, mode: String, range: Double) -> MatchedTraj {
        var isSuccess: Bool = false
        var xyd: [Double] = [0, 0, 50]
        var minTrajectory = [[Double]]()
        var minTrajectoryOriginal = [[Double]]()
        
        var matchedTraj = MatchedTraj(isSuccess: isSuccess, xyd: xyd, minTrajectory: minTrajectory, minTrajectoryOriginal: minTrajectoryOriginal)
        let levelCopy: String = removeLevelDirectionString(levelName: level)
        let key: String = "\(building)_\(levelCopy)"
        
        if (!(building.isEmpty) && !(level.isEmpty)) {
            guard let mainType: [Int] = self.PathType[key] else {
                return matchedTraj
            }
            guard let mainRoad: [[Double]] = self.PathPoint[key] else {
                return matchedTraj
            }
            
            if (!mainRoad.isEmpty) {
                let roadX = mainRoad[0]
                let roadY = mainRoad[1]
                
                var xMin = searchRange[0]
                var xMax = searchRange[2]
                var yMin = searchRange[1]
                var yMax = searchRange[3]
                
                var ppXydArray = [[Double]]()
                var minDistanceCoord = [Double]()
                
                for i in 0..<roadX.count {
                    let xPath = roadX[i]
                    let yPath = roadY[i]
                    
                    let pathTypeLoaded = mainType[i]
                    if (pathType == 1) {
                        if (pathType != pathTypeLoaded) {
                            continue
                        }
                    }
                    
                    // XY 범위 안에 있는 값 중에 검사
                    if (xPath >= xMin && xPath <= xMax) {
                        if (yPath >= yMin && yPath <= yMax) {
                            var passedPp = [[Double]]()
                            var distanceSum: Double = 0
                            
                            let headingCompensation: Double = tailHeading - uvHeading[0]
                            var headingBuffer: [Double] = []
                            for i in 0..<uvHeading.count {
                                let compensatedHeading = compensateHeading(heading: uvHeading[i] + headingCompensation)
                                headingBuffer.append(compensatedHeading)
                            }
                            
                            var xyFromHead: [Double] = [xPath, yPath]
                            var xyOriginal: [Double] = [xPath, yPath]
                            let firstXyd = extendedCalDistacneFromNearestPp(coord: xyFromHead, passedPp: passedPp, mainRoad: mainRoad, mainType: mainType, pathType: pathType, range: range)
                            passedPp.append(xyFromHead)
                            
                            var xydArray: [[Double]] = [firstXyd]
                            distanceSum += firstXyd[2]
                            
                            var trajectoryFromHead = [[Double]]()
                            var trajectoryOriginal = [[Double]]()
                            trajectoryFromHead.append(xyFromHead)
                            trajectoryOriginal.append(xyOriginal)
                            for i in 1..<uvHeading.count{
                                let headAngle = headingBuffer[i]
                                xyOriginal[0] = xyOriginal[0] + uvLength[i]*cos(headAngle*D2R)
                                xyOriginal[1] = xyOriginal[1] + uvLength[i]*sin(headAngle*D2R)
                                trajectoryOriginal.append(xyOriginal)
                                
                                if (mode == "pdr") {
                                    if (i%2 == 0) {
                                        let propagatedX = xyFromHead[0] + uvLength[i]*cos(headAngle*D2R)
                                        let propagatedY = xyFromHead[1] + uvLength[i]*sin(headAngle*D2R)
                                        let calculatedXyd = extendedCalDistacneFromNearestPp(coord: [propagatedX, propagatedY], passedPp: passedPp, mainRoad: mainRoad, mainType: mainType, pathType: pathType, range: range)
                                        
                                        xyFromHead[0] = calculatedXyd[0]
                                        xyFromHead[1] = calculatedXyd[1]
                                        xydArray.append(calculatedXyd)
                                        distanceSum += calculatedXyd[2]
                                        trajectoryFromHead.append(xyFromHead)
                                        passedPp.append(xyFromHead)
                                    } else {
                                        let propagatedX = xyFromHead[0] + uvLength[i]*cos(headAngle*D2R)
                                        let propagatedY = xyFromHead[1] + uvLength[i]*sin(headAngle*D2R)
                                        let calculatedXyd = extendedCalDistacneFromNearestPp(coord: [propagatedX, propagatedY], passedPp: passedPp, mainRoad: mainRoad, mainType: mainType, pathType: pathType, range: range)
                                        
                                        xyFromHead[0] = propagatedX
                                        xyFromHead[1] = propagatedY
                                        xydArray.append(calculatedXyd)
                                        distanceSum += calculatedXyd[2]
                                        trajectoryFromHead.append(xyFromHead)
                                        passedPp.append(xyFromHead)
                                    }
                                } else {
                                    let propagatedX = xyFromHead[0] + uvLength[i]*cos(headAngle*D2R)
                                    let propagatedY = xyFromHead[1] + uvLength[i]*sin(headAngle*D2R)
                                    let calculatedXyd = extendedCalDistacneFromNearestPp(coord: [propagatedX, propagatedY], passedPp: passedPp, mainRoad: mainRoad, mainType: mainType, pathType: pathType, range: range)
                                    
                                    xyFromHead[0] = calculatedXyd[0]
                                    xyFromHead[1] = calculatedXyd[1]
                                    xydArray.append(calculatedXyd)
                                    distanceSum += calculatedXyd[2]
                                    trajectoryFromHead.append(xyFromHead)
                                    passedPp.append(xyFromHead)
                                }
                            }
                            
                            ppXydArray.append([xPath, yPath, distanceSum])
                            
                            if (minDistanceCoord.isEmpty) {
                                minDistanceCoord = [xPath, yPath, distanceSum]
                                minTrajectory = trajectoryFromHead
                                minTrajectoryOriginal = trajectoryOriginal
                            } else {
                                let distanceCurrent = distanceSum
                                let distancePast = minDistanceCoord[2]
                                if (distanceCurrent < distancePast) {
                                    minDistanceCoord = [xPath, yPath, distanceSum]
                                    minTrajectory = trajectoryFromHead
                                    minTrajectoryOriginal = trajectoryOriginal
                                }
                            }
                        }
                    }

                    if (!minDistanceCoord.isEmpty) {
                        isSuccess = true
                        xyd = minDistanceCoord
                    }
                }
            }
        }
        
        matchedTraj = MatchedTraj(isSuccess: isSuccess, xyd: xyd, minTrajectory: minTrajectory, minTrajectoryOriginal: minTrajectoryOriginal)
        
        return matchedTraj
    }
    
    public func extractMinSuccessfulMatchedTraj(_ matchedTrajs: [MatchedTraj]) -> MatchedTraj? {
        var minSuccessfulMatchedTraj: MatchedTraj? = nil
        var minSecondIndexValue: Double = Double.infinity

        for matchedTraj in matchedTrajs {
            if matchedTraj.isSuccess && matchedTraj.xyd.count > 1 {
                let secondIndexValue = matchedTraj.xyd[1]
                if secondIndexValue < minSecondIndexValue {
                    minSecondIndexValue = secondIndexValue
                    minSuccessfulMatchedTraj = matchedTraj
                }
            }
        }

        return minSuccessfulMatchedTraj
    }

    
    public func getPathMatchingHeadings(building: String, level: String, x: Double, y: Double, heading: Double, RANGE: Double, mode: String) -> [Double] {
        var headings: [Double] = []
        let levelCopy: String = removeLevelDirectionString(levelName: level)
        let key: String = "\(building)_\(levelCopy)"
        
        if (!(building.isEmpty) && !(level.isEmpty)) {
            guard let mainType: [Int] = self.PathType[key] else {
                return headings
            }
            
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
                    
                    let pathType = mainType[i]
                    
                    if (mode == "dr") {
                        if (pathType != 1) {
                            continue
                        }
                    }
                    
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
}
