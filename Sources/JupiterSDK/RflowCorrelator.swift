import Foundation


public class RflowCorrelator {
    let D = 10*2 // 10s
    let T = 10*2 // 10s
    
    var rfdBufferLength = 40
    var rfdBuffer = [[String: Double]]()
    
    let D_V = 15*2
    let T_V = 3*2
    
    var rfdVelocityBufferLength = 36
    var rfdVelocityBuffer = [[String: Double]]()
    var rflowQueue = [Double]()
    var preSmoothedRflowForVelocity: Double = 0
    
    init() {
        self.rfdBufferLength = (self.D + self.T)
        self.rfdVelocityBufferLength = (self.D_V + self.T_V)
    }
    
    public func accumulateRfdBuffer(bleData: [String: Double]) -> Bool {
        var isSufficient: Bool = false
        if (self.rfdBuffer.count < self.rfdBufferLength) {
            if (self.rfdBuffer.isEmpty) {
                self.rfdBuffer.append(["empty": -100.0])
            } else {
                self.rfdBuffer.append(bleData)
            }
        } else {
            isSufficient = true
            self.rfdBuffer.remove(at: 0)
            if (self.rfdBuffer.isEmpty) {
                self.rfdBuffer.append(["empty": -100.0])
            } else {
                self.rfdBuffer.append(bleData)
            }
        }
        
        return isSufficient
    }
    
    public func getRflow() -> Double {
        var result: Double = 0
        
        if (self.rfdBuffer.count >= self.rfdBufferLength) {
            let preRfdBuffer = sliceDictionaryArray(self.rfdBuffer, startIndex: self.rfdBufferLength-T-D, endIndex: self.rfdBufferLength-T-1)
            let curRfdBuffer = sliceDictionaryArray(self.rfdBuffer, startIndex: self.rfdBufferLength-D, endIndex: self.rfdBufferLength-1)
            
            var sumDiffRssi: Double = 0
            var validKeyCount: Int = 0
            
            for i in 0..<D {
                let preRfd = preRfdBuffer[i]
                let curRfd = curRfdBuffer[i]
                
                for (key, value) in curRfd {
                    if (key != "empty" && value > -100.0) {
                        let curRssi = value
                        let preRssi = preRfd[key] ?? -100.0
                        sumDiffRssi += abs(curRssi - preRssi)
                        
                        validKeyCount += 1
                    }
                }
            }
            
            if (validKeyCount != 0) {
                let avgValue: Double = sumDiffRssi/Double(validKeyCount)
                if (avgValue != 0) {
                    result = calcScc(value: avgValue)
                }
            }
        }
        
        return result
    }
    
    public func accumulateRfdVelocityBuffer(bleData: [String: Double]) -> Bool {
        var isSufficient: Bool = false
        if (self.rfdVelocityBuffer.count < self.rfdVelocityBufferLength) {
            if (self.rfdVelocityBuffer.isEmpty) {
                self.rfdVelocityBuffer.append(["empty": -100.0])
            } else {
                self.rfdVelocityBuffer.append(bleData)
            }
        } else {
            isSufficient = true
            self.rfdVelocityBuffer.remove(at: 0)
            if (self.rfdVelocityBuffer.isEmpty) {
                self.rfdVelocityBuffer.append(["empty": -100.0])
            } else {
                self.rfdVelocityBuffer.append(bleData)
            }
        }
        
        return isSufficient
    }
    
    public func getRflowForVelocityScale() -> Double {
        var result: Double = 0
        
        
        if (self.rfdVelocityBuffer.count >= self.rfdVelocityBufferLength) {
            let preRfdBuffer = sliceDictionaryArray(self.rfdVelocityBuffer, startIndex: self.rfdVelocityBufferLength-T_V-D_V, endIndex: self.rfdVelocityBufferLength-T_V-1)
            let curRfdBuffer = sliceDictionaryArray(self.rfdVelocityBuffer, startIndex: self.rfdVelocityBufferLength-D_V, endIndex: self.rfdVelocityBufferLength-1)
            
            var sumDiffRssi: Double = 0
            var validKeyCount: Int = 0
            
            for i in 0..<D_V {
                let preRfd = preRfdBuffer[i]
                let curRfd = curRfdBuffer[i]
                
                for (key, value) in curRfd {
                    if (key != "empty" && value > -100.0) {
                        let curRssi = value
                        let preRssi = preRfd[key] ?? -100.0
                        sumDiffRssi += abs(curRssi - preRssi)
                        
                        validKeyCount += 1
                    }
                }
            }
            
            if (validKeyCount != 0) {
                let avgValue: Double = sumDiffRssi/Double(validKeyCount)
                if (avgValue != 0) {
                    result = calcScc(value: avgValue)
                }
            }
//            self.updateRflowQueue(data: result)
//            result = self.smoothRflowForVelocity(rflow: result)
        }
        
        return result
    }
    
    func calcScc(value: Double) -> Double {
        return exp(-value/10)
    }
    
    func sliceDictionaryArray(_ array: [[String: Double]], startIndex: Int, endIndex: Int) -> [[String: Double]] {
        let arrayCount = array.count
        
        guard startIndex >= 0 && startIndex < arrayCount && endIndex >= 0 && endIndex < arrayCount else {
            return []
        }
        
        var slicedArray: [[String: Double]] = []
        for index in startIndex...endIndex {
            slicedArray.append(array[index])
        }
        
        return slicedArray
    }
    
    func movingAverage(preMvalue: Double, curValue: Double, windowSize: Int) -> Double {
        let windowSizeDouble: Double = Double(windowSize)
        return preMvalue*((windowSizeDouble - 1)/windowSizeDouble) + (curValue/windowSizeDouble)
    }
    
    func updateRflowQueue(data: Double) {
        if (self.rflowQueue.count >= 6) {
            self.rflowQueue.remove(at: 0)
        }
        self.rflowQueue.append(data)
    }
    
    func smoothRflowForVelocity(rflow: Double) -> Double {
        var smoothedRflow: Double = 1.0
        if (self.rflowQueue.count == 1) {
            smoothedRflow = rflow
        } else {
            smoothedRflow = movingAverage(preMvalue: self.preSmoothedRflowForVelocity, curValue: rflow, windowSize: self.rflowQueue.count)
        }
        preSmoothedRflowForVelocity = smoothedRflow
        return smoothedRflow
    }
}
