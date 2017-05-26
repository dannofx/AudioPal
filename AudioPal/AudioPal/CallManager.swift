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
    let localIdentifier = UUID()
    var localService: NetService!
    var serviceBrowser: NetServiceBrowser!
    var localStatus: PalStatus = .NoAvailable
    weak var delegate: CallManagerDelegate?

    override init() {

    }
    
    // MARK: - Service initialization
    
    func setupService() {
        localService = NetService(domain: "\(domain).",
                                type: serviceType,
                                name: serviceName,
                                port: 0)
        localService.includesPeerToPeer = true
        localService.delegate = self
        //localService.startMonitoring()
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
        // Get username data
        let username = UserDefaults.standard.value(forKey: StoredValues.username) as! String
        let username_data = username.data(using: .utf8)!
        
        //Get uuid data
        var uuid_bytes = localIdentifier.uuid
        let uuid_data = withUnsafePointer(to: &uuid_bytes) { (unsafe_uuid) -> Data in
            Data(bytes: unsafe_uuid, count: MemoryLayout<uuid_t>.size)
        }
        
        // Get status data
        var statusValue = localStatus.rawValue
        let status_data = withUnsafePointer(to: &statusValue) { (unsafe_status) -> Data in
            Data(bytes: unsafe_status, count: MemoryLayout.size(ofValue: unsafe_status))
        }
        
        // Make a dictionary compatible with txt records format
        let packet: [String : Data] = [ PacketKeys.username: username_data,
                                        PacketKeys.uuid: uuid_data,
                                        PacketKeys.pal_status: status_data]
        
        // Create the record
        let txt = NetService.data(fromTXTRecord: packet)
        print("I SEND \(String(describing: username)) uuid \(localIdentifier.uuidString) (\(uuid_data.count)) status \(localStatus)")
        print("len \(txt.count)")
        return txt
    }
    
    func decodeTXTRecord(_ record: Data) -> [String: Any]? {
        let dict = NetService.dictionary(fromTXTRecord: record)
        if dict.count == 0 {
            //TODO: Manage this case
            return nil
        }
        guard let username_data = dict[PacketKeys.username] else {
            return nil
        }
        guard let uuid_data = dict[PacketKeys.uuid] else {
            return nil
        }
        guard let status_data = dict[PacketKeys.pal_status] else {
            return nil
        }
        
        print("Recibo!!! \(record.count)")

        let username =  String(data: username_data, encoding: String.Encoding.utf8) as String!
        
        var uuid_bytes: uuid_t = (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)
        print("Data?!!! \(uuid_data.count)")
        let uuid_p1: UnsafePointer<Data> = uuid_data.withUnsafeBytes { $0 }
        let uuid_p2: UnsafeMutablePointer<uuid_t> = withUnsafeMutablePointer(to: &uuid_bytes) { $0 }
        memcpy(uuid_p2, uuid_p1, MemoryLayout<uuid_t>.size)
        
        
        let uuid = UUID(uuid: uuid_bytes)
        
        let status_raw: Int = status_data.withUnsafeBytes { $0.pointee }
        let status = PalStatus(rawValue: status_raw)!
        
        print("I GOT username \(String(describing: username)) uuid \(uuid.uuidString) status \(status)")
        
        
        //uuid_data.get
        //let uuid = UUID(uuid: withU)
//        guard let packet = NSKeyedUnarchiver.unarchiveObject(with: record) else {
//
//            return nil
//        }
//        print("Some txt data retrieved \(packet)")
        
//        return packet as? [String : Any]
        return nil
        
    }
    
    // MARK: NetServiceDelegate
    
    public func netServiceDidPublish(_ sender: NetService) {
        if sender == localService {
            localStatus = .Available
            let txtData = createTXTRecord()
            localService.setTXTRecord(txtData)
            
            setupBrowser()
        }
    }
    
    
    public func netService(_ sender: NetService, didNotPublish errorDict: [String : NSNumber]) {
        //TODO: Manage error
        print("Error\(errorDict)")
    }
    
    
    public func netServiceWillResolve(_ sender: NetService) {
        print("Will resolve")
    }
    
    
    public func netServiceDidResolveAddress(_ sender: NetService) {
        print("RESUELTO!!")
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
        
        print("INFO UPDATED")
        _ = decodeTXTRecord(data)
//        guard let palInfo = decodeTXTRecord(data) else {
//            return
//        }
//        print("Pal info \(palInfo)")
        
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
            print("Another service found")
            service.delegate = self
            service.resolve(withTimeout: 5.0)
            service.perform(#selector(service.startMonitoring), with: nil, afterDelay: 3.0)
            //service.startMonitoring()
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
