import UIKit
import FanSabisuKit

enum SettingType: Int {
    case twitterAccount
    case defaultFramesPerSecond
    case clearCache
    case contactDeveloper
    case openSource
    case version

    func title() -> String {
        switch self {
        case .twitterAccount: return String.localizedString(for: "TWITTER_ACCOUNT")
        case .defaultFramesPerSecond: return String.localizedString(for: "DEFAULT_FPS")
        case .clearCache: return String.localizedString(for: "CLEAR_CACHE")
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

        var twitter = Setting(type: .twitterAccount, value: String.localizedString(for: "TWITTER_ACCOUNT_NOT_FOUND"))
        let keychain = Keychain()
        if let screenName = try? keychain.retrieve().screenName {
            if let screenName = screenName {
                twitter = Setting(type: .twitterAccount, value: screenName)
            }
        }
        settings.append(twitter)

        let userDefaults = UserDefaults(suiteName: "group.com.ruenzuo.FanSabisu")!

        let fps: Setting
        let defaultFPS = userDefaults.double(forKey: SettingKey.fps.rawValue)
        if defaultFPS != 0  {
            fps = Setting(type: .defaultFramesPerSecond, value: "~\(Int(defaultFPS))")
        } else {
            fps = Setting(type: .defaultFramesPerSecond, value: "~24")
        }
        settings.append(fps)

        let clearCache = Setting(type: .clearCache, value: "")
        settings.append(clearCache)

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

class SettingsViewController: GAITrackedViewController {

    fileprivate var settings: [Setting]
    @IBOutlet var tableView: UITableView?

    required init?(coder aDecoder: NSCoder) {
        settings = Setting.settings()
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = String.localizedString(for: "SETTINGS")
        self.screenName = "Settings"
        automaticallyAdjustsScrollViewInsets = false

    }

    func configureTwitter() {
        let setting = settings[SettingType.twitterAccount.rawValue]
        if setting.value == String.localizedString(for: "TWITTER_ACCOUNT_NOT_FOUND") {
            authorize()
        } else {
            unauthorize()
        }
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
        if UIDevice.current.userInterfaceIdiom == .pad {
            let index = SettingType.defaultFramesPerSecond.rawValue
            let indexPath = IndexPath(row: index, section: 0)
            let cell = tableView?.cellForRow(at: indexPath)
            controller.popoverPresentationController?.sourceView = cell?.detailTextLabel
        }
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

    func authorize() {
        let authorizer = Authorizer(session: Session.shared)
        authorizer.requestOAuth(presentingViewController: self) { (result) in
            self.presentedViewController?.dismiss(animated: true, completion: nil)
            guard let oauth = try? result.resolve() else {
                return self.presentMessage(title: String.localizedString(for: "ERROR_TITLE"), message: String.localizedString(for: "OAUTH_ERROR"), actionHandler: nil)
            }
            let keychain = Keychain()
            do {
                try keychain.store(oauth: oauth)
            } catch {
                return self.presentMessage(title: String.localizedString(for: "ERROR_TITLE"), message: String.localizedString(for: "OAUTH_ERROR"), actionHandler: nil)
            }
            let index = SettingType.twitterAccount.rawValue
            let indexPath = IndexPath(row: index, section: 0)
            let setting = Setting(type: SettingType.twitterAccount, value: oauth.screenName!)
            self.settings[index] = setting
            DispatchQueue.main.async {
                self.tableView?.reloadRows(at: [indexPath], with: .automatic)
            }
        }
    }

    func unauthorize() {
        let controller = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        controller.addAction(UIAlertAction(title: String.localizedString(for: "UNAUTHORIZE"), style: .destructive, handler: { (action) in
            self.wipeKeychain()
        }))
        controller.addAction(UIAlertAction(title: String.localizedString(for: "CANCEL"), style: .cancel, handler: { (action) in
        }))
        if UIDevice.current.userInterfaceIdiom == .pad {
            let index = SettingType.twitterAccount.rawValue
            let indexPath = IndexPath(row: index, section: 0)
            let cell = tableView?.cellForRow(at: indexPath)
            controller.popoverPresentationController?.sourceView = cell?.detailTextLabel
        }
        present(controller, animated: true, completion: nil)
    }

    func wipeKeychain() {
        let keychain = Keychain()
        do {
            try keychain.wipe()
        } catch {
            return self.presentMessage(title: String.localizedString(for: "ERROR_TITLE"), message: String.localizedString(for: "OAUTH_ERROR"), actionHandler: nil)
        }
        let index = SettingType.twitterAccount.rawValue
        let indexPath = IndexPath(row: index, section: 0)
        let setting = Setting(type: .twitterAccount, value: String.localizedString(for: "TWITTER_ACCOUNT_NOT_FOUND"))
        self.settings[index] = setting
        DispatchQueue.main.async {
            self.tableView?.reloadRows(at: [indexPath], with: .automatic)
        }
    }

    func clearCache() {
        let manager = FileManager.default
        let contents = try? manager.contentsOfDirectory(atPath: NSTemporaryDirectory())
        contents?.forEach({ (file) in
            let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(file)
            try? manager.removeItem(at: url)
        })
        self.presentMessage(title: nil, message: String.localizedString(for: "CACHE_CLEARED"), actionHandler: nil)
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
        case .clearCache: clearCache()
        case .contactDeveloper: contactDeveloper()
        case .openSource: openSource()
        case .version: break
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }

}
