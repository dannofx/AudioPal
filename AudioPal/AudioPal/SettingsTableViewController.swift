//
//  SettingsTableViewController.swift
//  AudioPal
//
//  Created by Danno on 7/4/17.
//  Copyright © 2017 Daniel Heredia. All rights reserved.
//

import UIKit
import CoreData

let versionTag = 60
let userNameTag = 61

enum TableSection: Int {
    case username = 0
    case blockedUsers = 1
    case about = 2
    
    var index: Int {
        switch self {
        case .username:
            return 0
        case .blockedUsers:
            return 1
        case .about:
            return 2
        }
    }
    
    var title: String {
        switch self {
        case .username:
            return NSLocalizedString("Username", comment: "")
        case .blockedUsers:
            return NSLocalizedString("Blocked users", comment: "")
        case .about:
            return NSLocalizedString("About", comment: "")
        }
    }
    
    func rowsNumber(_ fetchedController: NSFetchedResultsController<BlockedUser>?) -> Int {
        switch self {
        case .username:
            return 1
        case .blockedUsers:
            if let count = fetchedController?.sections?[0].numberOfObjects, count > 0 {
                return  count
            } else {
                return 1
            }
        case .about:
            return 2
        }
    }
    
    func cellId(forIndex index: Int, fetchedController: NSFetchedResultsController<BlockedUser>?) -> String {
        switch self {
        case .username:
            return CellIdentifiers.username
        case .blockedUsers:
            if let count = fetchedController?.sections?[0].numberOfObjects, count > 0 {
                return  CellIdentifiers.blockedPal
            } else {
                return CellIdentifiers.noBlockedUsers
            }
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
    fileprivate var fetchedResultController: NSFetchedResultsController<BlockedUser>!
    weak var dataController: DataController!
    weak var versionLabel: UILabel?
    weak var usernameTextfield: UITextField?
    @IBOutlet var saveButton: UIBarButtonItem!
    @IBOutlet var cancelButton: UIBarButtonItem!

    override func viewDidLoad() {
        super.viewDidLoad()
        username = UserDefaults.standard.value(forKey: StoredValues.username) as? String ?? ""
        toggleUsernameButtonsIfNecessary(hidden: true)
        fetchedResultController = dataController.createFetchedResultController()
        fetchedResultController.delegate = self
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
            versionLabel.text = String(format: NSLocalizedString("Version %@", comment: ""), version)
        }
        
    }
    
    deinit {
        saveButton = nil
        cancelButton = nil
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
        return sectionVals.rowsNumber(fetchedResultController)
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = TableSection(rawValue: indexPath.section)!
        let cell = tableView.dequeueReusableCell(withIdentifier: section.cellId(forIndex: indexPath.row, fetchedController: fetchedResultController), for: indexPath)
        if let blockedPalCell = cell as? BlockedPalTableViewCell {
            let modIndexPath = IndexPath.init(row: indexPath.row, section: 0)
            let blockedUser = fetchedResultController.object(at: modIndexPath)
            blockedPalCell.configure(withBlockedUser: blockedUser)
            blockedPalCell.delegate = self
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

// MARK: - Blocked Pal Cell Delegate 

extension SettingsTableViewController: BlockedPalTableViewCellDelegate {
    func blockedPalCell(_ cell: BlockedPalTableViewCell, didUnblock objectID: NSManagedObjectID) {
        let blockedUser = dataController.persistentContainer.viewContext.object(with: objectID) as! BlockedUser
        let alertController = UIAlertController(title: NSLocalizedString("Unblock user", comment: ""),
                                                message: String(format: NSLocalizedString("unblock.user %@", comment: ""), blockedUser.username ?? "(unknown)"),
                                         preferredStyle: UIAlertController.Style.alert)
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Not", comment: ""), style: UIAlertAction.Style.default))
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Yes", comment: ""), style: UIAlertAction.Style.default) { action in
            blockedUser.managedObjectContext?.delete(blockedUser)
            self.dataController.saveContext()
        })
        
        self.present(alertController, animated: true)
    }
}

// MARK: - Fetched Result Controller Delegate

extension SettingsTableViewController: NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        let tableIndexPath = IndexPath.init(row: indexPath!.row, section: TableSection.blockedUsers.rawValue)
        let tableNewIndexPath = IndexPath.init(row: newIndexPath!.row, section: TableSection.blockedUsers.rawValue)
        switch type {
            case .insert:
                tableView.insertRows(at: [tableNewIndexPath], with: .automatic)
            case .delete:
                tableView.deleteRows(at: [tableIndexPath], with: .automatic)
                if controller.sections![0].numberOfObjects == 0 {
                    tableView.insertRows(at: [tableIndexPath], with: .automatic) // this cell will show the "empty" message
                }
            case .update:
                let cell =  tableView.cellForRow(at: tableIndexPath) as! BlockedPalTableViewCell
                let blockedUser = fetchedResultController.object(at: indexPath!)
                cell.configure(withBlockedUser: blockedUser)
            case .move:
                tableView.deleteRows(at: [tableIndexPath], with: .automatic)
                tableView.insertRows(at: [tableNewIndexPath], with: .automatic)
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
}
