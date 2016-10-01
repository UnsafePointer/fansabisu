import Foundation

public extension String {
    static func localizedString(for key: String) -> String {
        guard let bundle = Bundle(identifier: "com.ruenzuo.FanSabisuKit") else {
            return ""
        }
        return NSLocalizedString(key, tableName: nil, bundle: bundle, value: "", comment: "")
    }
}
