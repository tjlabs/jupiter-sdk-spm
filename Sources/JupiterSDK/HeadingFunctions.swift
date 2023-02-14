import Foundation

public class HeadingFunctions: NSObject {
    
    public override init() {
        
    }
    
    public func calAngleOfRotation(timeInterval: Double, angularVelocity: Double) -> Double {
        return angularVelocity * Double(timeInterval) * 1e-3
    }

    public func degree2radian(degree: Double) -> Double {
        return degree * Double.pi / 180
    }

    public func radian2degree(radian: Double) -> Double {
        return radian * 180 / Double.pi
    }
    
    public func callRollUsingAcc(acc: [Double]) -> Double {
        if (acc[0] > 0 && acc[2] < 0) {
            return (atan(acc[0] / sqrt(acc[1]*acc[1] + acc[2]*acc[2])) - Double.pi)
        }
        else if (acc[2] < 0 && acc[0] < 0) {
            return (atan(acc[0] / sqrt(acc[1]*acc[1] + acc[2]*acc[2])) + Double.pi)
        }
        else {
            return -atan(acc[0] / sqrt(acc[1]*acc[1] + acc[2]*acc[2]))
        }
    }
    
    public func callPitchUsingAcc(acc: [Double]) -> Double {
        let result: Double = atan( acc[1] / sqrt(acc[0]*acc[0] + acc[2]*acc[2]) )
        
        return result
    }
}

