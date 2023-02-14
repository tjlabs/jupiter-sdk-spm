import Foundation

extension Array {

}

public func += <V> ( left: inout [V], right: V) {
    left.append(right)
}

public func + <V>(left: Array<V>, right: V) -> Array<V>
{
    var map = Array<V>()
    for (v) in left {
        map.append(v)
    }

    map.append(right)

    return map
}

extension Array where Element: BinaryInteger {

    public var average: Double {
        if self.isEmpty {
            return 0.0
        } else {
            let sum = self.reduce(0, +)
            return Double(sum) / Double(self.count)
        }
    }

}

extension Array where Element: BinaryFloatingPoint {

    public var average: Double {
        if self.isEmpty {
            return 0.0
        } else {
            let sum = self.reduce(0, +)
            return Double(sum) / Double(self.count)
        }
    }

}
