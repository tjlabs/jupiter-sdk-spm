import Foundation


public class ReceivedForceSurfaceCorrelator {
    
    let D = 10*2 // 10s
    let T = 10*2 // 10s
    
    var rfdBufferLength = 40
    var rfdBuffer = [[String: Double]]()
    
    
    let D_V = 5*2
    let T_V = 5*2
    
    var rfdVelocityBufferLength = 20
    var rfdVelocityBuffer = [[String: Double]]()
    
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
    
    public func getRfdScc() -> Double {
        var result: Double = 0
        
        if (self.rfdBuffer.count >= self.rfdBufferLength) {
            let preRfdBuffer = sliceDictionaryArray(self.rfdBuffer, startIndex: self.rfdBufferLength-T-D, endIndex: self.rfdBufferLength-T-1)
            let curRfdBuffer = sliceDictionaryArray(self.rfdBuffer, startIndex: self.rfdBufferLength-D, endIndex: self.rfdBufferLength-1)
            
            var sumDiffRssiArray = [Double]()
            for i in 0..<D {
                let preRfd = preRfdBuffer[i]
                let curRfd = curRfdBuffer[i]
                
                var sumDiffRssi: Double = 0
                for (key, value) in curRfd {
                    let curRssi = value
                    let preRssi = preRfd[key] ?? -100.0
                    
                    sumDiffRssi += abs(curRssi - preRssi)
                }
                
                if (curRfd.keys.count != 0) {
                    sumDiffRssiArray.append(sumDiffRssi/Double(curRfd.keys.count))
                }
            }
            
            if (!sumDiffRssiArray.isEmpty) {
                let avgValue = sumDiffRssiArray.average
                if (avgValue != 0) {
                    result = calcScc(value: sumDiffRssiArray.average)
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
    
    public func getRfdVelocityScc() -> Double {
        var result: Double = 0
        
        if (self.rfdVelocityBuffer.count >= self.rfdVelocityBufferLength) {
            let preRfdBuffer = sliceDictionaryArray(self.rfdVelocityBuffer, startIndex: self.rfdVelocityBufferLength-T_V-D_V, endIndex: self.rfdVelocityBufferLength-T_V-1)
            let curRfdBuffer = sliceDictionaryArray(self.rfdVelocityBuffer, startIndex: self.rfdVelocityBufferLength-D_V, endIndex: self.rfdVelocityBufferLength-1)
            
            var sumDiffRssiArray = [Double]()
            for i in 0..<D_V {
                let preRfd = preRfdBuffer[i]
                let curRfd = curRfdBuffer[i]
                
                var sumDiffRssi: Double = 0
                for (key, value) in curRfd {
                    let curRssi = value
                    let preRssi = preRfd[key] ?? -100.0
                    
                    sumDiffRssi += abs(curRssi - preRssi)
                }
                
                if (curRfd.keys.count != 0) {
                    sumDiffRssiArray.append(sumDiffRssi/Double(curRfd.keys.count))
                }
            }
            
            if (!sumDiffRssiArray.isEmpty) {
                let avgValue = sumDiffRssiArray.average
                if (avgValue != 0) {
                    result = calcScc(value: sumDiffRssiArray.average)
                }
            }
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
}
