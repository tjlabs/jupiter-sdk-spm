import Foundation


public protocol Observable {
    func addObserver(_ observer: Observer)
    func removeObserver(_ observer: Observer)
}
public protocol Observer: class {
    func update(result: FineLocationTrackingResult)
//    func reportErrors(errors: Int)
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
