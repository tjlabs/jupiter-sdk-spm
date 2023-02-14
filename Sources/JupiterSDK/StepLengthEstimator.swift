import Foundation


public class StepLengthEstimator: NSObject {
    
    public override init() {
        
    }

    public var preStepLength = DEFAULT_STEP_LENGTH
    
    public func estStepLength(accPeakQueue: LinkedList<TimestampDouble>, accValleyQueue: LinkedList<TimestampDouble>) -> Double {
        if (accPeakQueue.count < 1 || accValleyQueue.count < 1) {
            return DEFAULT_STEP_LENGTH
        }
        
        let differencePV = accPeakQueue.last!.value.valuestamp - accValleyQueue.last!.value.valuestamp
        var stepLength = DEFAULT_STEP_LENGTH
        
        if (differencePV > DIFFERENCE_PV_THRESHOLD) {
            stepLength = calLongStepLength(differencePV: differencePV)
        } else {
            stepLength = calShortStepLength(differencePV: differencePV)
        }
//        print("StepLengthEstimator / Step Length :", stepLength)
        
        stepLength = limitStepLength(stepLength: stepLength)
        
        return compensateStepLength(curStepLength: stepLength)
    }
    
    public func calLongStepLength(differencePV: Double) -> Double {
        return (ALPHA * (differencePV - DIFFERENCE_PV_STANDARD) + DEFAULT_STEP_LENGTH)
    }
    
    public func calShortStepLength(differencePV: Double) -> Double {
        return ((MID_STEP_LENGTH - MIN_STEP_LENGTH) / (DIFFERENCE_PV_THRESHOLD - MIN_DIFFERENCE_PV)) * (differencePV - DIFFERENCE_PV_THRESHOLD) + MID_STEP_LENGTH
    }
    
    public func compensateStepLength(curStepLength: Double) -> Double {
        let compensateStepLength = COMPENSATION_WEIGHT * (curStepLength) - (curStepLength - preStepLength) * (1 - COMPENSATION_WEIGHT) + COMPENSATION_BIAS
        preStepLength = compensateStepLength
        
        return compensateStepLength
    }
    
    public func limitStepLength(stepLength: Double) -> Double {
        if (stepLength > MAX_STEP_LENGTH) {
            return MAX_STEP_LENGTH
        } else if (stepLength < MIN_STEP_LENGTH) {
            return MIN_STEP_LENGTH
        } else {
            return stepLength
        }
    }
}
