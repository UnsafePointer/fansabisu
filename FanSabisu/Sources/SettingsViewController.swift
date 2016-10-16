import UIKit
import FanSabisuKit

enum SettingType: Int {
    case twitterAccount
    case defaultFramesPerSecond
    case contactDeveloper
    case openSource
    case version

    func title() -> String {
        switch self {
        case .twitterAccount: return String.localizedString(for: "TWITTER_ACCOUNT")
        case .defaultFramesPerSecond: return String.localizedString(for: "DEFAULT_FPS")
        case .contactDeveloper: return String.localizedString(for: "CONTACT_DEVELOPER")
        case .openSource: return String.localizedString(for: "OPEN_SOURCE")
        case .version: return String.localizedString(for: "VERSION")
        }
    }
}

fileprivate struct Setting {

    let type: SettingType
    let value: String

    static func settings() -> [Setting] {
        var settings = [Setting]()
        let userDefaults = UserDefaults(suiteName: "group.com.ruenzuo.FanSabisu")!

        let twitter: Setting;
        if let twitterAccount = userDefaults.string(forKey: SettingKey.twitter.rawValue) {
            twitter = Setting(type: .twitterAccount, value: twitterAccount)
        } else {
            twitter = Setting(type: .twitterAccount, value: String.localizedString(for: "TWITTER_ACCOUNT_NOT_FOUND"))
        }
        settings.append(twitter)

        let fps: Setting;
        let defaultFPS = userDefaults.double(forKey: SettingKey.fps.rawValue)
        if defaultFPS != 0  {
            fps = Setting(type: .defaultFramesPerSecond, value: "~\(Int(defaultFPS))")
        } else {
            fps = Setting(type: .defaultFramesPerSecond, value: "~24")
        }
        settings.append(fps)

        let developer = Setting(type: .contactDeveloper, value: "@Ruenzuo")
        settings.append(developer)

        let opensource = Setting(type: .openSource, value: "")
        settings.append(opensource)

        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as! String
        let versionName = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String

        let version = Setting(type: .version, value: "\(versionName) (\(build))")
        settings.append(version)

        return settings
    }

}

extension Notification.Name {
    static let applicationDidReceiveOAuthCallback = Notification.Name("applicationDidReceiveOAuthCallback")
}

class SettingsViewController: UIViewController {

    fileprivate var settings: [Setting]
    @IBOutlet var tableView: UITableView?
    var authorizer: Authorizer?

    required init?(coder aDecoder: NSCoder) {
        settings = Setting.settings()
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = String.localizedString(for: "SETTINGS")
        automaticallyAdjustsScrollViewInsets = false
        NotificationCenter.default.addObserver(self, selector: #selector(handleApplicationDidReceiveOAuthCallback(with:)), name: .applicationDidReceiveOAuthCallback, object: nil)
    }

    func configureTwitter() {
        authorizer = Authorizer(presentingViewController: self) { (result) in

        }
        authorizer?.requestToken()
    }

    func handleApplicationDidReceiveOAuthCallback(with notification: Notification) {
        authorizer?.continueTokenRequest(with: notification.userInfo)
    }

    func configureFPS() {
        let controller = UIAlertController(title: "", message: String.localizedString(for: "DEFAULT_FPS_DESCRIPTION"), preferredStyle: .actionSheet)
        controller.addAction(UIAlertAction(title: "~12", style: .default, handler: { (action) in
            self.saveDefaultFPS(12)
        }))
        controller.addAction(UIAlertAction(title: "~24", style: .default, handler: { (action) in
            self.saveDefaultFPS(24)
        }))
        controller.addAction(UIAlertAction(title: "~60", style: .default, handler: { (action) in
            self.saveDefaultFPS(60)
        }))
        controller.addAction(UIAlertAction(title: String.localizedString(for: "CANCEL"), style: .cancel, handler: nil))
        present(controller, animated: true, completion: nil)
    }

    func contactDeveloper () {
        let url = URL(string: "https://twitter.com/Ruenzuo")!
        UIApplication.shared.openURL(url)
    }

    func openSource() {
        let url = URL(string: "https://github.com/Ruenzuo/fansabisu")!
        UIApplication.shared.openURL(url)
    }

    func saveDefaultFPS(_ fps: Double) {
        let userDefaults = UserDefaults(suiteName: "group.com.ruenzuo.FanSabisu")!
        userDefaults.set(fps, forKey: SettingKey.fps.rawValue)
        let index = SettingType.defaultFramesPerSecond.rawValue
        let indexPath = IndexPath(row: index, section: 0)
        let setting = Setting(type: SettingType.defaultFramesPerSecond, value: "~\(Int(fps))")
        settings[index] = setting
        self.tableView?.reloadRows(at: [indexPath], with: .automatic)
    }

}

extension SettingsViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return settings.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SettingCell", for: indexPath)
        let setting = settings[indexPath.row]
        cell.textLabel?.text = setting.type.title()
        cell.detailTextLabel?.text = setting.value
        if setting.type == .version {
            cell.selectionStyle = .none
            cell.detailTextLabel?.textColor = .black
        } else {
            cell.selectionStyle = .default
            cell.detailTextLabel?.textColor = UIColor.appearanceColor()
        }
        return cell
    }



}

extension SettingsViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let settingType = SettingType(rawValue: indexPath.row)!
        switch settingType {
        case .twitterAccount: configureTwitter()
        case .defaultFramesPerSecond: configureFPS()
        case .contactDeveloper: contactDeveloper()
        case .openSource: openSource()
        case .version: break
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }



}
