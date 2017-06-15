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
    
    override init(style: UITableViewStyle) {
        callManager = CallManager()
        connectedPals = []
        super.init(style: style)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        callManager = CallManager()
        connectedPals = []
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        callManager = CallManager()
        connectedPals = []
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        registerForNotifications()
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if (userName == nil) {
            self.parent!.performSegue(withIdentifier: StoryboardSegues.setName, sender: self)
        } else {
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == StoryboardSegues.showCall {
            let callViewController = segue.destination as! CallViewController
            callViewController.callManager = callManager
        }
    }
    
    // MARK: - Notifications
    func registerForNotifications() {
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: NotificationNames.userReady),
                                               object: nil,
                                               queue: nil) { (notification) in
                                                self.userName = (notification.userInfo![StoredValues.username] as! String)
                                                self.startCallManager()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "palCell", for: indexPath) as! PalTableViewCell
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
        _ = callManager.startCall(toPal: pal)
    }
}

// MARK: - PalConnectionDelegate

extension PalsTableViewController {
    
    func callManager(_ callManager: CallManager, didDetectNearbyPal pal: NearbyPal) {
        print("Inserting")
        tableView.beginUpdates()
        let indexPath = IndexPath.init(row: connectedPals.count, section: 0)
        connectedPals.append(pal)
        tableView.insertRows(at: [indexPath], with: UITableViewRowAnimation.automatic)
        tableView.endUpdates()
    }
    
    func callManager(_ callManager: CallManager, didDetectDisconnection pal: NearbyPal) {
        guard let index = connectedPals.index(of: pal) else {
            return
        }
        print("Deleting")
        tableView.beginUpdates()
        let indexPath = IndexPath.init(row: index, section: 0)
        connectedPals.remove(at: index)
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
        guard let index = connectedPals.index(of: pal) else {
            return
        }
        print("Updating")
        tableView.beginUpdates()
        let indexPath = IndexPath.init(row: index, section: 0)
        tableView.reloadRows(at: [indexPath], with: UITableViewRowAnimation.automatic)
        tableView.endUpdates()
    }
}
