import Foundation


public class ParameterEstimator {
    var entranceWardRssi = [String: Double]()
    var allEntranceWardRssi = [String: Double]()
    
    var wardMinRssi = [Double]()
    var wardMaxRssi = [Double]()
    var deviceMinValue: Double = -99.0
    var updateMinArrayCount: Int = 0
    var updateMaxArrayCount: Int = 0
    let ARRAY_SIZE: Int = 3
    
    var preSmoothedNormalizationScale: Double = 1.0
    var scaleQueue = [Double]()
    
    public func clearEntranceWardRssi() {
        self.entranceWardRssi = [String: Double]()
        self.allEntranceWardRssi = [String: Double]()
    }
    
    public func getMaxRssi() -> Double {
        if (self.wardMaxRssi.isEmpty) {
            return -90.0
        } else {
            let avgMax = self.wardMaxRssi.average
            return avgMax
        }
    }
    
    public func getMinRssi() -> Double {
        if (self.wardMinRssi.isEmpty) {
            return -60.0
        } else {
            let avgMin = self.wardMinRssi.average
            return avgMin
        }
    }
    
    public func refreshWardMinRssi(bleData: [String: Double]) {
        for (_, value) in bleData {
            if (value > -100) {
                if (self.wardMinRssi.isEmpty) {
                    self.wardMinRssi.append(value)
                } else {
                    let newArray = appendAndKeepMin(inputArray: self.wardMinRssi, newValue: value, size: self.ARRAY_SIZE)
                    self.wardMinRssi = newArray
                }
            }
        }
    }
    
    public func refreshWardMaxRssi(bleData: [String: Double]) {
        for (_, value) in bleData {
            if (self.wardMaxRssi.isEmpty) {
                self.wardMaxRssi.append(value)
            } else {
                let newArray = appendAndKeepMax(inputArray: self.wardMaxRssi, newValue: value, size: self.ARRAY_SIZE)
                self.wardMaxRssi = newArray
            }
        }
    }
    
    public func calNormalizationScale(standardMin: Double, standardMax: Double) -> (Bool, Double) {
        let standardAmplitude: Double = abs(standardMax - standardMin)
        
        if (self.wardMaxRssi.isEmpty || self.wardMinRssi.isEmpty) {
            return (false, 1.0)
        } else {
            let avgMax = self.wardMaxRssi.average
            let avgMin = self.wardMinRssi.average
            self.deviceMinValue = avgMin
            
            let amplitude: Double = abs(avgMax - avgMin)
            
            let normalizationScale: Double = standardAmplitude/amplitude
            updateScaleQueue(data: normalizationScale)
            return (true, normalizationScale)
        }
    }
    
    func updateScaleQueue(data: Double) {
        if (self.scaleQueue.count >= 20) {
            self.scaleQueue.remove(at: 0)
        }
        self.scaleQueue.append(data)
    }
    
    public func smoothNormalizationScale(scale: Double) -> Double {
        var smoothedScale: Double = 1.0
        if (self.scaleQueue.count == 1) {
            smoothedScale = scale
        } else {
            smoothedScale = movingAverage(preMvalue: self.preSmoothedNormalizationScale, curValue: scale, windowSize: self.scaleQueue.count)
        }
        self.preSmoothedNormalizationScale = smoothedScale
        
        return smoothedScale
    }
    
    public func refreshEntranceWardRssi(entranceWard: [String: Int], bleData: [String: Double]) {
        let entranceWardIds: [String] = Array(entranceWard.keys)
        
        for (key, value) in bleData {
            if (entranceWardIds.contains(key)) {
                if (self.entranceWardRssi.keys.contains(key)) {
                    if let previousValue = self.entranceWardRssi[key] {
                        if (value > previousValue) {
                            self.entranceWardRssi[key] = value
                        }
                    }
                } else {
                    self.entranceWardRssi[key] = value
                }
            }
        }
    }
    
    public func refreshAllEntranceWardRssi(allEntranceWards: [String], bleData: [String: Double]) {
        let allEntranceWardIds: [String] = allEntranceWards
        
        for (key, value) in bleData {
            if (allEntranceWardIds.contains(key)) {
                if (self.allEntranceWardRssi.keys.contains(key)) {
                    if let previousValue = self.allEntranceWardRssi[key] {
                        if (value > previousValue) {
                            self.allEntranceWardRssi[key] = value
                        }
                    }
                } else {
                    self.allEntranceWardRssi[key] = value
                }
            }
        }
    }
    
    public func estimateRssiBiasInEntrance(entranceWard: [String: Int]) -> Int {
        var result: Int = -100
        
        var diffRssiArray = [Double]()
        
        for (key, value) in self.allEntranceWardRssi {
            if let entranceData = entranceWard[key] {
                let entranceWardRssi = Double(entranceData)
                let diffRssi = entranceWardRssi - value
//                print(getLocalTimeString() + " , (Jupiter) Bias in Entrance : \(key) = \(diffRssi)")
                diffRssiArray.append(diffRssi)
            }
        }
        
        if (!diffRssiArray.isEmpty) {
            let arrayWithoutMax = excludeLargestAbsoluteValue(from: diffRssiArray)
            let biasWithOutMax: Int = Int(round(arrayWithoutMax.mean))
            let bias: Int = Int(round(diffRssiArray.mean))
            
            if (abs(biasWithOutMax-bias) <= 2) {
                result = bias
            } else {
                result = biasWithOutMax
            }
        }
        
        return result
    }
    
    public func saveRssiBias(bias: Int, biasArray: [Int], isConverged: Bool, sector_id: Int) {
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

    public func loadRssiBias(sector_id: Int) -> (Int, [Int], Bool) {
        var bias: Int = 2
        var biasArray: [Int] = []
        var isConverged: Bool = false
        
        let currentTime = getCurrentTimeInMilliseconds()
        let keyBiasTime: String = "JupiterRssiBiasTime_\(sector_id)"
        if let biasTime: Int = UserDefaults.standard.object(forKey: keyBiasTime) as? Int {
            if (currentTime - biasTime) > 1000*3600*24*15  {
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

    public func makeRssiBiasArray(bias: Int) -> [Int] {
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

    public func estimateRssiBias(sccResult: Double, biasResult: Int, biasArray: [Int]) -> (Bool, [Int]) {
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

    public func averageBiasArray(biasArray: [Int]) -> (Int, Bool) {
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
    
    public func loadNormalizationScale(sector_id: Int) -> (Bool, Double) {
        var isLoadedFromCache: Bool = false
        var scale: Double = 1.0
        
        let keyScale: String = "JupiterNormalizationScale_\(sector_id)"
        if let loadedScale: Double = UserDefaults.standard.object(forKey: keyScale) as? Double {
            scale = loadedScale
            isLoadedFromCache = true
            if (scale >= 1.7) {
                scale = 1.0
            }
        }
        
        return (isLoadedFromCache, scale)
    }
    
    public func saveNormalizationScale(scale: Double, sector_id: Int) {
        let currentTime = getCurrentTimeInMilliseconds()
        print(getLocalTimeString() + " , (Jupiter) Save NormalizationScale : \(scale)")
        
        // Scale
        do {
            let key: String = "JupiterNormalizationScale_\(sector_id)"
            UserDefaults.standard.set(scale, forKey: key)
        } catch {
            print("(Jupiter) Error : Fail to save NormalizattionScale")
        }
    }
    
    func excludeLargestAbsoluteValue(from array: [Double]) -> [Double] {
        guard !array.isEmpty else {
            return []
        }

        var largestAbsoluteValueFound = false
        let result = array.filter { element -> Bool in
            let isLargest = abs(element) == abs(array.max(by: { abs($0) < abs($1) })!)
            if isLargest && !largestAbsoluteValueFound {
                largestAbsoluteValueFound = true
                return false
            }
            return true
        }

        return result
    }
    
    func appendAndKeepMin(inputArray: [Double], newValue: Double, size: Int) -> [Double] {
        var array: [Double] = inputArray
        array.append(newValue)
        if array.count > size {
            if let maxValue = array.max() {
                if let index = array.firstIndex(of: maxValue) {
                    array.remove(at: index)
                }
            }
        }
        return array
    }
    
    func appendAndKeepMax(inputArray: [Double], newValue: Double, size: Int) -> [Double] {
        var array: [Double] = inputArray
        array.append(newValue)
        
        if array.count > size {
            if let minValue = array.min() {
                if let index = array.firstIndex(of: minValue) {
                    array.remove(at: index)
                }
            }
        }
        return array
    }
    
    func updateWardMinRss(inputArray: [Double], size: Int) -> [Double] {
        var array: [Double] = inputArray
        if array.count < size {
            return array
        } else {
            if let minValue = array.min() {
                if let index = array.firstIndex(of: minValue) {
                    array.remove(at: index)
                }
            }
        }
        return array
    }
    
    func updateWardMaxRss(inputArray: [Double], size: Int) -> [Double] {
        var array: [Double] = inputArray
        if array.count < size {
            return array
        } else {
            if let maxValue = array.max() {
                if let index = array.firstIndex(of: maxValue) {
                    array.remove(at: index)
                }
            }
        }
        return array
    }
    
    func movingAverage(preMvalue: Double, curValue: Double, windowSize: Int) -> Double {
        let windowSizeDouble: Double = Double(windowSize)
        return preMvalue*((windowSizeDouble - 1)/windowSizeDouble) + (curValue/windowSizeDouble)
    }
    
    public func getDeviceMinRss() -> Double {
        return self.deviceMinValue
    }
}
