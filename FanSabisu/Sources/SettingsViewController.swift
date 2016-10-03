import UIKit

enum SettingKey: String {
    case twitter = "TwitterAccount"
    case fps = "FramesPerSecond"
}

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
        let defaultFPS = userDefaults.integer(forKey: SettingKey.fps.rawValue)
        if defaultFPS != 0  {
            fps = Setting(type: .defaultFramesPerSecond, value: "~\(defaultFPS)")
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

class SettingsViewController: UIViewController {

    fileprivate let settings: [Setting]

    required init?(coder aDecoder: NSCoder) {
        settings = Setting.settings()
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = String.localizedString(for: "SETTINGS")
        automaticallyAdjustsScrollViewInsets = false
    }

    func configureTwitter() {

    }

    func configureFPS() {

    }

    func contactDeveloper () {
        let url = URL(string: "https://twitter.com/Ruenzuo")!
        UIApplication.shared.openURL(url)
    }

    func openSource() {
        let url = URL(string: "https://github.com/Ruenzuo/fansabisu")!
        UIApplication.shared.openURL(url)
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
