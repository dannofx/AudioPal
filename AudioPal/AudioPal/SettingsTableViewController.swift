//
//  SettingsTableViewController.swift
//  AudioPal
//
//  Created by Danno on 7/4/17.
//  Copyright © 2017 Daniel Heredia. All rights reserved.
//

import UIKit

let versionTag = 60
let userNameTag = 61

enum TableSection: Int {
    case username = 0
    case blockedUsers = 1
    case about = 2
    
    var title: String {
        switch self {
        case .username:
            return "Username"
        case .blockedUsers:
            return "Blocked users"
        case .about:
            return "Username"
        }
    }
    
    var rowsNumber: Int {
        switch self {
        case .username:
            return 1
        case .blockedUsers:
            return 3
        case .about:
            return 2
        }
    }
    
    func cellId(forIndex index: Int) -> String {
        switch self {
        case .username:
            return CellIdentifiers.username
        case .blockedUsers:
            return CellIdentifiers.blockedPal
        case .about:
            if (index == 0) {
                return CellIdentifiers.info
            } else {
                return CellIdentifiers.version
            }
        }
    }
    
    func segueId(atIndex index: Int) -> String? {
        if self == .about && index == 0 {
            return StoryboardSegues.about
        } else {
            return nil
        }
    }
    
    static let count: Int = {
        var max: Int = 0
        while let _ = TableSection(rawValue: max) { max += 1 }
        return max
    }()

}

class SettingsTableViewController: UITableViewController, UITextFieldDelegate {
    
    fileprivate var username: String!
    weak var versionLabel: UILabel?
    weak var usernameTextfield: UITextField?
    @IBOutlet var saveButton: UIBarButtonItem!
    @IBOutlet var cancelButton: UIBarButtonItem!

    override func viewDidLoad() {
        super.viewDidLoad()
        username = UserDefaults.standard.value(forKey: StoredValues.username) as? String ?? ""
        toggleUsernameButtonsIfNecessary(hidden: true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func loadUsernameField() {
        guard let usernameTextfield = usernameTextfield else {
            return
        }
        usernameTextfield.text = username
        usernameTextfield.delegate = self
    }
    
    func loadVersionLabel() {
        guard let versionLabel = versionLabel else {
            return
        }
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            versionLabel.text = "Version \(version)"
        }
        
    }
}
    
// MARK: - Username management

extension SettingsTableViewController {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField.text == "" {
            textField.text = username
        }
    }
    
    @IBAction func didChangeText(sender: UITextField) {
        let hide = sender.text == "" || sender.text == username
        toggleUsernameButtonsIfNecessary(hidden: hide)
    }
    
    func toggleUsernameButtonsIfNecessary(hidden: Bool) {
        if self.navigationItem.rightBarButtonItem == nil && !hidden {
            self.navigationItem.rightBarButtonItem = saveButton
            self.navigationItem.leftBarButtonItem = cancelButton
        } else if self.navigationItem.rightBarButtonItem != nil && hidden {
            self.navigationItem.rightBarButtonItem = nil
            self.navigationItem.leftBarButtonItem = nil
        }
    }
    
    @IBAction func saveUsername(sender: UIBarButtonItem) {
        guard let newUsername = usernameTextfield?.text, newUsername != "" else {
            return
        }
        username = newUsername
        UserDefaults.standard.setValue(username, forKey: StoredValues.username)
        let userInfo: [AnyHashable : Any] = [StoredValues.username: username]
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: NotificationNames.userReady),
                                        object: self,
                                        userInfo: userInfo)
        toggleUsernameButtonsIfNecessary(hidden: true)
        self.view.endEditing(true)
    }
    
    @IBAction func cancelUsernameChanges(sender: UIBarButtonItem) {
        usernameTextfield?.text = username
        toggleUsernameButtonsIfNecessary(hidden: true)
    }

}

// MARK: - Table view data source

extension SettingsTableViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return TableSection.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionVals = TableSection(rawValue: section)!
        return sectionVals.rowsNumber
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = TableSection(rawValue: indexPath.section)!
        let cell = tableView.dequeueReusableCell(withIdentifier: section.cellId(forIndex: indexPath.row), for: indexPath)
        if let blockedPalCell = cell as? BlockedPalTableViewCell {
            blockedPalCell.configure(withName: "Foo")
        } else if let label = cell.viewWithTag(versionTag) as? UILabel {
            versionLabel = label
            loadVersionLabel()
        } else if let textfield = cell.viewWithTag(userNameTag) as? UITextField {
            usernameTextfield = textfield
            loadUsernameField()
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return SettingsSectionView.defaultHeight
    }

    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 1.0
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let sectionVals = TableSection(rawValue: section)!
        let sectionView = Bundle.main.loadNibNamed(String(describing: SettingsSectionView.self), owner: self, options: nil)!.first as! SettingsSectionView
        sectionView.titleLabel.text = sectionVals.title
        return sectionView
    }

    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView(frame: CGRect.zero)
    }
}

// MARK: - Table view delegate

extension SettingsTableViewController {
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let sectionVals = TableSection(rawValue: indexPath.section)!
        self.view.endEditing(true)
        tableView.deselectRow(at: indexPath, animated: true)
        if let segueId = sectionVals.segueId(atIndex: indexPath.row) {
            self.performSegue(withIdentifier: segueId, sender: self)
        }
    }
}
