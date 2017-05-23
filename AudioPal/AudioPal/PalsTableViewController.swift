//
//  PalsTableViewController.swift
//  AudioPal
//
//  Created by Danno on 5/18/17.
//  Copyright © 2017 Daniel Heredia. All rights reserved.
//

import UIKit

class PalsTableViewController: UITableViewController, CallManagerDelegate {
    var callManager: CallManager
    
    private lazy var userName: String? = {
        return UserDefaults.standard.value(forKey: StoredValues.username) as? String
    }()
    
    override init(style: UITableViewStyle) {
        callManager = CallManager()
        super.init(style: style)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        callManager = CallManager()
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        callManager = CallManager()
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
        callManager.delegate = self
    }
    
    

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 0
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        // Configure the cell...

        return cell
    }
 

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
 

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
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
    
    // MARK: - CallManagerDelegate
    func callManager(_ callManager: CallManager, didDetectNearbyPal pal: NearbyPal) {
        
    }
    
    func callManager(_ callManager: CallManager, didDetectDisconnection pal: NearbyPal) {
        
    }
    
    func callManager(_ callManager: CallManager, didDetectCallError error:Error, withPal pal: NearbyPal) {
        
    }
    
    func callManager(_ callManager: CallManager, didPal pal: NearbyPal, changeStatus status: PalStatus) {
        
    }

}
