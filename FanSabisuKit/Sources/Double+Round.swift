import Foundation

extension Double {

    func roundToPlaces(_ places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return Darwin.round(self * divisor) / divisor
    }

}
