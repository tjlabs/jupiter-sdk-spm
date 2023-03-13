import Foundation

let INDOOR_FLAG: Int = 1
let OUTDOOR_FLAG: Int = 0
let ABNORMAL_FLAG: Int = -1
let MERCURY_FLAG: Int = 2
let JUPITER_FLAG: Int = 3

public protocol Observable {
    func addObserver(_ observer: Observer)
    func removeObserver(_ observer: Observer)
}
public protocol Observer: class {
    func update(result: FineLocationTrackingResult)
    func report(flag: Int)
}

public class Observation: Observable {
    var observers = [Observer]()
    public func addObserver(_ observer: Observer) {
        observers.append(observer)
    }
    public func removeObserver(_ observer: Observer) {
        observers = observers.filter({ $0 !== observer })
    }
}
