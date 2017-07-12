//
//  PalsTableViewController.swift
//  AudioPal
//
//  Created by Danno on 5/18/17.
//  Copyright © 2017 Daniel Heredia. All rights reserved.
//

import UIKit

class PalsTableViewController: UITableViewController, PalConnectionDelegate {
    var callManager: CallManager
    var connectedPals: [NearbyPal]
    
    private lazy var userName: String? = {
        return UserDefaults.standard.value(forKey: StoredValues.username) as? String
    }()
    
    fileprivate var dataController: DataController
    
    override init(style: UITableViewStyle) {
        callManager = CallManager()
        connectedPals = []
        dataController = DataController()
        super.init(style: style)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        callManager = CallManager()
        connectedPals = []
        dataController = DataController()
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        callManager = CallManager()
        connectedPals = []
        dataController = DataController()
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        if let navigationBar = navigationController?.navigationBar {
            let statusBarHeight: CGFloat = UIApplication.shared.statusBarFrame.size.height
            let totalHeight = navigationBar.frame.size.height + statusBarHeight
            let shadowHeight: CGFloat = 27.0
            let mainHeight = totalHeight - shadowHeight
            
            var colorBars = [(color: UIColor, height: CGFloat)]()
            colorBars.append((UIColor.untBlueGreen, mainHeight))
            colorBars.append((UIColor.untMustardYellow, shadowHeight))
            
            let backgroundImage = UIImage.imageWithColorBars(colorBars, totalHeight: totalHeight)
            navigationBar.setBackgroundImage(backgroundImage, for: .default)
        }
        dataController.delegate = self
        registerForNotifications()
        checkForNoPalsView()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if (userName == nil) {
            self.parent!.performSegue(withIdentifier: StoryboardSegues.setName, sender: self)
        } else {
            ADProcessor.askForMicrophoneAccess()
            startCallManager()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func startCallManager() {
        callManager.palDelegate = self
        callManager.start()
    }
    
    func restartCallManager() {
        if callManager.isStarted {
            callManager.stop()
        }
        startCallManager()
    }
    
    func checkForNoPalsView() {
        if connectedPals.count == 0 {
            let emptyView = Bundle.main.loadNibNamed("EmptyTable", owner: self, options: nil)!.first as! UIView
            tableView.tableHeaderView = emptyView
            tableView.separatorColor = UIColor.clear
        } else {
            tableView.tableHeaderView = nil
            tableView.separatorColor = UIColor.untLightYellow
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == StoryboardSegues.showCall {
            let callViewController = segue.destination as! CallViewController
            callViewController.callManager = callManager
        }else if segue.identifier == StoryboardSegues.settings {
            let settingsViewController = segue.destination as! SettingsTableViewController
            settingsViewController.dataController =  dataController
        }
    }
    
    // MARK: - Notifications
    func registerForNotifications() {
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: NotificationNames.userReady),
                                               object: nil,
                                               queue: nil) { (notification) in
                                                self.userName = (notification.userInfo![StoredValues.username] as! String)
                                                self.restartCallManager()
        }
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: NotificationNames.micAccessRequired),
                                               object: nil, queue: nil) { (notification) in
                                                let missedCall = (notification.userInfo![DictionaryKeys.missedCall] as! Bool)
                                                self.showPermissionsAlert(missedCall: missedCall)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

}

// MARK: - Alerts 
extension PalsTableViewController {
    
    func showPermissionsAlert(missedCall: Bool) {
        let title: String!
        let message: String!
        if missedCall {
            title = "Rejected call"
            message = "A call was rejected due you haven't granted access to the microphone. " +
            "Please grant access by going to the privacy section of your iPhone."
        } else {
            title = "Microphone access denied!"
            message = "AudioPal needs access to the microphone to work.\n" +
            "Please grant access by going to the privacy section of your iPhone."
        }
        let alert = UIAlertController(title: title,
                                      message: message,
                                      preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func showCannotCallAlert(blockedPal: NearbyPal) {
        let title = "Blocked user"
        let message = "You need to unblock \(blockedPal.username!) to perform a call."
        let alert = UIAlertController(title: title,
                                      message: message,
                                      preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}

// MARK: - Table view data source

extension PalsTableViewController {
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return connectedPals.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CellIdentifiers.pal, for: indexPath) as! PalTableViewCell
        let pal = connectedPals[indexPath.row]
        cell.configure(withPal: pal)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }
    }
}

// MARK: - Table view delegate

extension PalsTableViewController {
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let pal = connectedPals[indexPath.row]
        if !pal.isBlocked {
            _ = callManager.startCall(toPal: pal)
        } else {
            showCannotCallAlert(blockedPal: pal)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let pal = connectedPals[indexPath.row]
        let title: String!
        let color: UIColor!
        
        if pal.isBlocked {
            title = "Unblock"
            color = UIColor.untGreen
        } else {
            title = "Block"
            color = UIColor.untReddish
        }
        
        let blockAction = UITableViewRowAction(style: UITableViewRowActionStyle.default, title: title){ (_, _) in
            pal.isBlocked = !pal.isBlocked
            self.tableView.beginUpdates()
            tableView.reloadRows(at: [indexPath], with: UITableViewRowAnimation.automatic)
            self.tableView.endUpdates()
            self.dataController.updateBlockStatus(pal: pal)
        }
        blockAction.backgroundColor = color
        
        return [blockAction]
    }
}

// MARK: - PalConnectionDelegate

extension PalsTableViewController {
    
    func callManager(_ callManager: CallManager, didDetectNearbyPal pal: NearbyPal) {
        print("Inserting pal in main list")
        tableView.beginUpdates()
        let index = connectedPals.sortedInsert(item: pal, isAscendant: NearbyPal.isAscendant)
        let indexPath = IndexPath.init(row: index, section: 0)
        checkForNoPalsView()
        tableView.insertRows(at: [indexPath], with: UITableViewRowAnimation.automatic)
        tableView.endUpdates()
        
        dataController.checkIfBlocked(pal: pal) { (pal, blocked) in
            if pal.isBlocked != blocked {
                pal.isBlocked = blocked
                self.updateCell(forPal: pal)
            }
        }
    }
    
    func callManager(_ callManager: CallManager, didDetectDisconnection pal: NearbyPal) {
        guard let index = connectedPals.index(of: pal) else {
            return
        }
        print("Deleting pal in main list")
        tableView.beginUpdates()
        let indexPath = IndexPath.init(row: index, section: 0)
        connectedPals.remove(at: index)
        checkForNoPalsView()
        tableView.deleteRows(at: [indexPath], with: UITableViewRowAnimation.automatic)
        tableView.endUpdates()
    }
    
    func callManager(_ callManager: CallManager, didDetectCallError error:Error, withPal pal: NearbyPal) {
        
    }
    
    func callManager(_ callManager: CallManager, didPal pal: NearbyPal, changeStatus status: PalStatus) {
        updateCell(forPal: pal)
    }
    
    func callManager(_ callManager: CallManager, didPal pal: NearbyPal, changeUsername username: String) {
        updateCell(forPal: pal)
    }
    
    func callManager(_ callManager: CallManager, didStartCallWithPal pal: NearbyPal) {
        performSegue(withIdentifier: StoryboardSegues.showCall, sender: self)
    }
    
    func updateCell(forPal pal: NearbyPal) {
        guard connectedPals.index(of: pal) != nil else {
            return
        }
        print("Updating pal in main list")
        guard let tuple = connectedPals.sortedUpdate(item: pal, isAscendant: NearbyPal.isAscendant) else {
            return
        }
        tableView.beginUpdates()
        let oldIndexPath = IndexPath.init(row: tuple.old, section: 0)
        let newIndexPath = IndexPath.init(row: tuple.new, section: 0)
        tableView.moveRow(at: oldIndexPath, to: newIndexPath)
        tableView.endUpdates()
        tableView.beginUpdates()
        tableView.reloadRows(at: [newIndexPath], with: UITableViewRowAnimation.automatic)
        tableView.endUpdates()
    }
}

// MARK: - Data Controller Delegate

extension PalsTableViewController: DataControllerDelegate {
    
    func dataController(_ dataController: DataController, didUnblockUserWithId uuid: UUID) {
        if let unblockedPal = ( connectedPals.filter{ $0.uuid == uuid }.first ) {
            unblockedPal.isBlocked = false
            updateCell(forPal: unblockedPal)
        }
    }
}
