import Foundation


public class BiasEstimator {
    
    var entranceWardRssi = [String: Double]()
    
    init() {
        
    }
    
    public func clearEntranceWardRssi() {
        self.entranceWardRssi = [String: Double]()
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
    
    public func estimateRssiBiasInEntrance(entranceWard: [String: Int]) -> Int {
        var result: Int = -100
        
        var diffRssiArray = [Double]()
        
        for (key, value) in self.entranceWardRssi {
            if let entranceData = entranceWard[key] {
                let entranceWardRssi = Double(entranceData)
                let diffRssi = entranceWardRssi - value
                print(getLocalTimeString() + " , (Jupiter) Bias in Entrance : \(key) = \(diffRssi)")
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
            
            print(getLocalTimeString() + " , (Jupiter) Bias in Entrance : Bias = \(result)")
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
}

