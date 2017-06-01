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
let baseServiceName = "audiopal"

protocol CallManagerDelegate: class {
    func callManager(_ callManager: CallManager, didDetectNearbyPal pal: NearbyPal)
    func callManager(_ callManager: CallManager, didDetectDisconnection pal: NearbyPal)
    func callManager(_ callManager: CallManager, didDetectCallError error: Error, withPal pal: NearbyPal)
    func callManager(_ callManager: CallManager, didPal pal: NearbyPal, changeStatus status: PalStatus)
    func callManager(_ callManager: CallManager, didPal pal: NearbyPal, changeUsername username: String)
}

struct Call {
    let pal: NearbyPal
    let inputStream: InputStream
    let outputStream: OutputStream
    
    init(pal: NearbyPal, inputStream: InputStream, outputStream: OutputStream) {
        self.pal = pal
        self.inputStream = inputStream
        self.outputStream = outputStream
    }
}

class CallManager: NSObject, NetServiceDelegate, NetServiceBrowserDelegate, StreamDelegate {
    var localService: NetService!
    var serviceBrowser: NetServiceBrowser!
    var localStatus: PalStatus = .NoAvailable
    var currentCall: Call?
    weak var delegate: CallManagerDelegate?
    var adProcessor: ADProcessor?
    var inputBuffer: Data?
    
    private lazy var localIdentifier: UUID = {
        var uuidString = UserDefaults.standard.value(forKey: StoredValues.uuid) as? String
        var uuid: UUID!
        if (uuidString == nil) {
            uuid = UUID()
            UserDefaults.standard.set(uuid.uuidString, forKey: StoredValues.uuid)
        } else {
            uuid = NSUUID.init(uuidString: uuidString!)! as UUID
        }
        
        return uuid
    }()
    
    var nearbyPals: [NearbyPal] = []

    override init() {

    }
    
    // MARK: - Service initialization
    
    func setupService() {
        localService = NetService(domain: domain,
                                    type: serviceType,
                                baseName: baseServiceName,
                                    uuid: localIdentifier,
                                    port: 0)
        localService.includesPeerToPeer = true
        localService.delegate = self
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

//        Meter todo dentro de call (ADProcessor e input buffer)
//        Instanciar el procesador de audio cuando es debido
//        Probar los metodos de desconexion e implementar rechazar llamada
//        Hay que manejar los errores de streams como desconexiones.

    }

    public func stop() {

    }
    
    // MARK: - Call amangement
    
    public func call(toPal pal: NearbyPal) -> Bool {
        if localStatus != .Available {
            return false
        }
        var inputStream: InputStream?
        var outputStream: OutputStream?
        let success = pal.service.getInputStream(&inputStream, outputStream: &outputStream)
        if !success {
            return false
        }
        // Open Streams
        currentCall = Call(pal: pal, inputStream: inputStream!, outputStream: outputStream!)
        openStreams(forCall: currentCall!)
        // Update information for nearby pals
        localStatus = .Occupied
        propagateLocalTxtRecord()
        
    }
    
    public func acceptCall(_ call: Call) -> Bool{
        if localStatus != .Available {
            return false
        }
        // Open Streams
        currentCall = Call(pal: call.pal, inputStream: call.inputStream, outputStream: call.outputStream)
        openStreams(forCall: currentCall!)
        // Update information for nearby pals
        localStatus = .Occupied
        propagateLocalTxtRecord()
        
    }
    
    public func rejectCall(_ call: Call) {
        // TODO: Pending implementation
    }
    
    public func endCall(_ call: Call) {
        closeStreams(forCall: call)
        localStatus = .Available
        propagateLocalTxtRecord()
    }
    
    // MARK: - Streams management
    
    private func openStreams(forCall call: Call) {
        call.outputStream.delegate = self
        call.outputStream.schedule(in: RunLoop.current, forMode: RunLoopMode.defaultRunLoopMode)
        call.outputStream.open()
        
        call.inputStream.delegate = self
        call.inputStream.schedule(in: RunLoop.current, forMode: RunLoopMode.defaultRunLoopMode)
        call.inputStream.open()
    }
    
    private func closeStreams(forCall call: Call) {
        call.outputStream.delegate = nil
        call.outputStream.close()
        
        call.inputStream.delegate = nil
        call.inputStream.close()
        
        call.pal.service.stop() // This really do something??
    }
    
    // MARK: - Audio management
    func startAudioProcessor() {
        
    }
    
    func stopAudioProcessor() {
        
    }
    
    func extractCompleteBuffers() -> [Data] {
        
        var completeBuffers = [Data]()
        while inputBuffer!.count > 0 {
            let globalBuffer = inputBuffer! as NSData
            // Check if at least has data for the first index and the first byte
            if (globalBuffer.length < 3) {
                // print("Not enough received data (not even the index)")
                return completeBuffers
            }
            //Index where the real data should start
            let dataIndex =  MemoryLayout<UInt16>.size
            // get the buffer size
            var bufferSize_Int16: UInt16 = 0
            globalBuffer.getBytes(&bufferSize_Int16, range: NSMakeRange(0, dataIndex))
            let bufferSize: Int = Int(bufferSize_Int16)
            // Check if the real data buffer can fit in the remaining data
            let remainingSize = globalBuffer.length - bufferSize
            if (remainingSize < bufferSize) {
                return completeBuffers
            }
            // Get the actual data buffer
            let currentBuffer = globalBuffer.subdata(with: NSMakeRange(dataIndex, bufferSize))
            completeBuffers.append(currentBuffer)
            // Clean from the global buffer
            let totalSizeForBuffer = (dataIndex + bufferSize)
            inputBuffer?.removeSubrange(0..<totalSizeForBuffer)
        }
        
        return completeBuffers
        
    }
    
    // MARK - TXT record utils
    
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
        return txt
    }
    
    func decodeTXTRecord(_ record: Data) -> (username: String, uuid: UUID, status: PalStatus)?{
        let dict = NetService.dictionary(fromTXTRecord: record)
        if dict.count == 0 {
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
        
        // Decode username
        let username =  String(data: username_data, encoding: String.Encoding.utf8)!
        
        // Decode uuid
        var uuid_bytes: uuid_t = (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)
        let uuid_p1: UnsafePointer<Data> = uuid_data.withUnsafeBytes { $0 }
        let uuid_p2: UnsafeMutablePointer<uuid_t> = withUnsafeMutablePointer(to: &uuid_bytes) { $0 }
        memcpy(uuid_p2, uuid_p1, MemoryLayout<uuid_t>.size)
        let uuid = UUID(uuid: uuid_bytes)
        
        //Decode status
        let status_raw: Int = status_data.withUnsafeBytes { $0.pointee }
        let status = PalStatus(rawValue: status_raw)!
        
        print("Pal updated TXT record: username \(String(describing: username)) uuid \(uuid.uuidString) status \(status)")
        
        return (username, uuid, status)
        
    }
    
    func propagateLocalTxtRecord() {
        let txtData = createTXTRecord()
        localService.setTXTRecord(txtData)
    }
    
    func processTxtUpdate(forService service: NetService, withData data: Data?) {
        if data != nil {
            let tuple = decodeTXTRecord(data!)
            if tuple == nil {
                return
            }
            
            if tuple!.uuid != service.uuid ||
                tuple!.uuid == localIdentifier {
                //If the uuid doesn't coincide or
                // it's the same than the local identifier
                // the information is not reliable
                return
            }
            
            let pal = getPalWithService(service)
            if pal != nil {
                
                updatePal(pal!, withData: tuple!)
            }
        } else {
            print("Peer not fully resolved")
        }
    }
    
    // MARK: - Nearby pal utils
    
    func getPalWithService(_ service: NetService) -> NearbyPal? {
        return nearbyPals.filter{ $0.service == service }.first
    }
    
    func getPalWithUUID(_ uuid: UUID) -> NearbyPal? {
        return nearbyPals.filter{ $0.uuid == uuid || $0.service.uuid == uuid }.first
    }
    
    func addPal(withService service: NetService) -> NearbyPal {
        let existingPal = getPalWithService(service)
        
        if existingPal != nil {
            return existingPal!
        } else {
            let pal = NearbyPal(service)
            nearbyPals.append(pal)
            return pal
        }
    }
    
    func removePal(_ pal: NearbyPal) {
        guard let index = nearbyPals.index(of: pal) else {
            return
        }
        //TODO: Add events like close connections if opened
        nearbyPals.remove(at: index)
        delegate?.callManager(self, didDetectDisconnection: pal)
    }
    
    func updatePal(_ pal: NearbyPal, withData data:(username: String, uuid: UUID, status: PalStatus)) {
        let oldStatus = pal.status
        let oldName = pal.username
        pal.username = data.username
        pal.uuid = data.uuid
        pal.status = data.status
        
        if oldStatus != pal.status {
            if pal.status == .Available {
                delegate?.callManager(self, didDetectNearbyPal: pal)
            } else if pal.status == .NoAvailable {
                // I keep the pal, but it isn't available for the client until
                // it's available again.
                delegate?.callManager(self, didDetectDisconnection: pal)
            } else {
                delegate?.callManager(self, didPal: pal, changeStatus: pal.status)
            }
        }
        
        if oldName != nil && oldName != pal.username{
            delegate?.callManager(self, didPal: pal, changeUsername: pal.username!)
        }
        
    }
    
    
    // MARK: - NetServiceDelegate
    
    public func netServiceDidPublish(_ sender: NetService) {
        if sender == localService {
            localStatus = .Available
            propagateLocalTxtRecord()
            setupBrowser()
        }
    }
    
    
    public func netService(_ sender: NetService, didNotPublish errorDict: [String : NSNumber]) {
        //TODO: Manage error
        print("Error\(errorDict)")
    }
    
    
    public func netServiceWillResolve(_ sender: NetService) {
    }
    
    
    public func netServiceDidResolveAddress(_ sender: NetService) {
        if sender == localService {
            return
        }
        processTxtUpdate(forService: sender, withData: sender.txtRecordData())
    }
    
    
    public func netService(_ sender: NetService, didNotResolve errorDict: [String : NSNumber]) {
        print("Service was not resolved")
    }
    
    
    public func netServiceDidStop(_ sender: NetService) {

    }
    
    
    public func netService(_ sender: NetService, didUpdateTXTRecord data: Data) {
        if sender == localService {
            return
        }
        processTxtUpdate(forService: sender, withData: data)
    }
    
    public func netService(_ sender: NetService, didAcceptConnectionWith inputStream: InputStream, outputStream: OutputStream) {
        guard let pal = getPalWithService(sender) else {
            return
        }
        currentCall = Call(pal: pal, inputStream: inputStream, outputStream: outputStream)
        _ = acceptCall(currentCall!)
    }
    
    // MARK: NetServiceBrowserDelegate
    
    public func netServiceBrowserWillSearch(_ browser: NetServiceBrowser) {
        
    }
    
    public func netServiceBrowserDidStopSearch(_ browser: NetServiceBrowser) {
        //TODO: Manage this event (show to the user)
        
    }
    
    public func netServiceBrowser(_ browser: NetServiceBrowser, didNotSearch errorDict: [String : NSNumber]) {
        //TODO: Manage this event (show to the user)
    }
    
    public func netServiceBrowser(_ browser: NetServiceBrowser, didFindDomain domainString: String, moreComing: Bool) {
        
    }
    
    public func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        print("Name \(service.name)")
        let validService = service != localService &&
            service.baseName != "" &&
            service.baseName == baseServiceName
        
        if !validService {
            return
        }
        print("It's a valid service \(service.name)")
        if getPalWithService(service) == nil{
            
            let existingPal = getPalWithUUID(service.uuid!)
            if existingPal != nil {
                // Just the newer version of the service will remain
                if existingPal!.service.version < service.version {
                    removePal(existingPal!)
                } else {
                    return
                }
            }
            service.delegate = self
            service.resolve(withTimeout: 5.0)
            let currentQueue = OperationQueue.current?.underlyingQueue
            let time = DispatchTime.now() + DispatchTimeInterval.milliseconds(300)
            currentQueue?.asyncAfter(deadline: time) {
                service.startMonitoring()
            }
            print("Another service found \(service.name)")
            
            _ = addPal(withService: service)
        }
    }
    
    public func netServiceBrowser(_ browser: NetServiceBrowser, didRemoveDomain domainString: String, moreComing: Bool) {
        
    }
    
    public func netServiceBrowser(_ browser: NetServiceBrowser, didRemove service: NetService, moreComing: Bool){
        let pal = getPalWithService(service)
        if pal != nil {
            self.removePal(pal!)
        }
        
    }
    
    // MARK: StreamDelegate
    
    public func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        
        switch eventCode {
        case Stream.Event.openCompleted:
            print("Completed")
        case Stream.Event.hasSpaceAvailable:
            break
        case Stream.Event.hasBytesAvailable:
            var bytes = [UInt8](repeating: 0, count: maxBufferSize)
            guard let bytesRead = self.inputStream?.read(&bytes, maxLength: maxBufferSize), bytesRead > 1 else {
                print("Problem reading audio")
                return
            }
            let data = Data(bytes: bytes, count: bytesRead)
            inputBuffer?.append(data)
            let completedBuffers = extractCompleteBuffers()
            for currentBuffer in completedBuffers {
                adProcessor?.scheduleBuffer(toPlay: currentBuffer)
            }
            
        case Stream.Event.errorOccurred:
            print("Error")
            if let call = currentCall {
                self.endCall(call)
            }
        case Stream.Event.endEncountered:
            print("End encountered")
            if let call = currentCall {
                self.endCall(call)
            }
        default:
            print("default")
        }
        
    }
    
    // MARK: - ADProcessorDelegate
    

}
