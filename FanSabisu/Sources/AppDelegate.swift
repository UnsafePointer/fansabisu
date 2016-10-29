import UIKit
import FanSabisuKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        window?.tintColor = UIColor.appearanceColor()
        GAI.sharedInstance().tracker(withTrackingId: GoogleAnalyticsCredentials.trackingId)
        return true
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        let userInfo = ["query": url.query as Any]
        FSKNotificationCenter.default.postNotificationName(Authorizer.applicationDidReceiveOAuthCallback, withParameters: userInfo)
        return true
    }

}

