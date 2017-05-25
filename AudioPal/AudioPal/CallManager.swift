//
//  CallManager.swift
//  AudioPal
//
//  Created by Danno on 5/22/17.
//  Copyright © 2017 Daniel Heredia. All rights reserved.
//

import UIKit

let domain = "local"
let serviceType = "_apal._tcp."
let serviceName = "audiopal"

protocol CallManagerDelegate: class {
    func callManager(_ callManager: CallManager, didDetectNearbyPal pal: NearbyPal)
    func callManager(_ callManager: CallManager, didDetectDisconnection pal: NearbyPal)
    func callManager(_ callManager: CallManager, didDetectCallError error: Error, withPal pal: NearbyPal)
    func callManager(_ callManager: CallManager, didPal pal: NearbyPal, changeStatus status: PalStatus)
}

class CallManager: NSObject, NetServiceDelegate, NetServiceBrowserDelegate, StreamDelegate {
    //TODO: Add persistence
    let localIdentifier = UUID().uuidString
    var localService: NetService
    var serviceBrowser: NetServiceBrowser
    var localStatus: PalStatus = .NoAvailable
    weak var delegate: CallManagerDelegate?

    override init() {
        serviceBrowser = NetServiceBrowser()
        localService = NetService()
    }
    
    // MARK: - Service initialization
    
    func setupService() {
        localService = NetService(domain: "\(domain).",
                                type: serviceType,
                                name: serviceName,
                                port: 0)
        localService.includesPeerToPeer = true
        localService.delegate = self
        localService.startMonitoring()
        localService.publish(options: .listenForConnections)
    }
    
    func setupBrowser() {
        serviceBrowser = NetServiceBrowser()
        serviceBrowser.includesPeerToPeer = true
        serviceBrowser.delegate = self
        serviceBrowser.searchForServices(ofType: serviceType, inDomain: domain)
        
    }

    public func start() {
        setupService()

    }

    public func stop() {

    }
    
    func createTXTRecord() -> Data {
        let username = UserDefaults.standard.value(forKey: StoredValues.username) as! String
        let statusValue = localStatus.rawValue
        let packet: [String : Any] = [ PacketKeys.username: username,
                       PacketKeys.uuid: localIdentifier,
                       PacketKeys.pal_status: statusValue ]
        
        let data = NSKeyedArchiver.archivedData(withRootObject: packet)
        let d = "A".data(using: .utf8)
        let txt = NetService.data(fromTXTRecord: ["l": d!])
        print("len \(txt.count)")
        return txt
    }
    
    func decodeTXTRecord(_ record: Data) -> [String: Any]? {
        let d = NetService.dictionary(fromTXTRecord: record)
        if d.count == 0 {
            return nil
        }
        guard let packet = NSKeyedUnarchiver.unarchiveObject(with: d["l"]!) else {
            //TODO: Manage this case
            return nil
        }
        return packet as? [String : Any]
        
    }
    
    // MARK: NetServiceDelegate
    
    public func netServiceDidPublish(_ sender: NetService) {
        localStatus = .Available
        let txtData = createTXTRecord()
        localService.setTXTRecord(txtData)
        
        setupBrowser()
    }
    
    
    public func netService(_ sender: NetService, didNotPublish errorDict: [String : NSNumber]) {
        //TODO: Manage error
        print("Error\(errorDict)")
    }
    
    
    public func netServiceWillResolve(_ sender: NetService) {
        print("Will resolve")
    }
    
    
    public func netServiceDidResolveAddress(_ sender: NetService) {
        if sender.txtRecordData() != nil {
            let dic = decodeTXTRecord(sender.txtRecordData()!)
            if dic == nil {
                return
            }
            print("RESOLVED \(String(describing: dic))")
        } else {
            print("Not fully resolved")
        }
    }
    
    
    public func netService(_ sender: NetService, didNotResolve errorDict: [String : NSNumber]) {
        print("Service was not resolved")
    }
    
    
    public func netServiceDidStop(_ sender: NetService) {
        print("Service stopped")
    }
    
    
    public func netService(_ sender: NetService, didUpdateTXTRecord data: Data) {
        
        guard let palInfo = decodeTXTRecord(data) else {
            return
        }
        print("Pal info \(palInfo)")
        
    }
    
    public func netService(_ sender: NetService, didAcceptConnectionWith inputStream: InputStream, outputStream: OutputStream) {
//        self.inputStream = inputStream
//        self.outputStream = outputStream
//        openStreams()
//        print("Service accepted")
        
    }
    
    // MARK: NetServiceBrowserDelegate
    
    public func netServiceBrowserWillSearch(_ browser: NetServiceBrowser) {
        
    }
    
    public func netServiceBrowserDidStopSearch(_ browser: NetServiceBrowser) {
        
    }
    
    public func netServiceBrowser(_ browser: NetServiceBrowser, didNotSearch errorDict: [String : NSNumber]) {
        
    }
    
    public func netServiceBrowser(_ browser: NetServiceBrowser, didFindDomain domainString: String, moreComing: Bool) {
        
    }
    
    public func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        
        if service != localService {
            print("Service found!!!!!")
            service.delegate = self
            service.resolve(withTimeout: 5.0)
            service.startMonitoring()
        }
       // let txtData = createTXTRecord()
       // localService.setTXTRecord(txtData)
        
//        if localService?.name == service.name || (service.name.range(of: baseServiceName) == nil) {
//            return
//        }
//        
//        let localValue = localService!.name.crc32()
//        let remoteValue = service.name.crc32()
//        
//        if localValue > remoteValue {
//            print("Connection starts")
//            let success = service.getInputStream(&inputStream, outputStream: &outputStream)
//            if (success) {
//                sender = true
//                openStreams()
//                print("Connection established")
//            } else {
//                print("Connection aborted")
//            }
//        } else {
//            print("Waiting for connection")
//        }
    }
    
    public func netServiceBrowser(_ browser: NetServiceBrowser, didRemoveDomain domainString: String, moreComing: Bool) {
        
    }
    
    public func netServiceBrowser(_ browser: NetServiceBrowser, didRemove service: NetService, moreComing: Bool){
        
    }

}
