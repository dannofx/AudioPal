//
//  Call.swift
//  AudioPal
//
//  Created by Danno on 6/1/17.
//  Copyright © 2017 Daniel Heredia. All rights reserved.
//

import UIKit

enum CallAnswer: UInt8 {
    case acceptance = 100
    case wait = 101
    case unknown = 102
    
    init(fromRaw value: UInt8) {
        self = CallAnswer(rawValue: value) ?? .unknown
    }
}

enum CallStatus: Int {
    case dialing
    case presented
    case onCall
    case responding
}

class Call: NSObject {
    let pal: NearbyPal
    let inputStream: InputStream
    let outputStream: OutputStream
    let uuid: UUID
    fileprivate (set) var callStatus: CallStatus
    var audioProcessor: ADProcessor?
    var inputBuffer: Data?
    var interactionEnded: Bool // Refers to CallKit UI
    var ended: Bool // Tells if the call was ended (there is no audio nor transmission)
    var isMuted: Bool {
        guard let audioProcessor = audioProcessor else {
            return false
        }
        
        return audioProcessor.muted
    }
    var useSpeakers: Bool {
        guard let audioProcessor = audioProcessor else {
            return false
        }
        
        return audioProcessor.useSpeakers
    }
    
    init(pal: NearbyPal, inputStream: InputStream, outputStream: OutputStream, asCaller caller: Bool) {
        self.pal = pal
        self.inputStream = inputStream
        self.outputStream = outputStream
        uuid = UUID()
        ended = false
        interactionEnded = false
        if caller {
            self.callStatus = .dialing
        } else {
            self.callStatus = .responding
        }
    }
    
}

// MARK: - Call management

extension Call {
    func sendCallerInfo(_ uuid: UUID) -> Bool{
        let uuidData = uuid.data
        let success = writeToOutputBuffer(data: uuidData)
        if success {
            callStatus = .presented
        }
        return success
    }
    
    func answerCall(_ answer: CallAnswer) {
        if outputStream.hasSpaceAvailable {
            var flag = answer.rawValue
            outputStream.write(&flag, maxLength: 1)
            print("Call started: accepted")
            if answer == CallAnswer.acceptance {
                callStatus = .onCall
            }
        } else {
            print("The call was not answered")
        }
    }
    
    func processAnswer() -> CallAnswer {
        if callStatus != .presented {
            return CallAnswer.unknown
        }
        
        if inputStream.hasBytesAvailable {
            var flag: UInt8 = 0
            inputStream.read(&flag, maxLength: 1)
            let answer = CallAnswer(fromRaw: flag)

            if answer == CallAnswer.acceptance {
                print("Call started: acceptance")
                callStatus = .onCall
            }
            return answer
        }
        
        return CallAnswer.unknown
    }
}

// MARK: - Audio management

extension Call {
    
    func prepareForAudioProcessing() {
        if audioProcessor != nil {
            return
        }
        audioProcessor = ADProcessor()
    }
    
    func startAudioProcessing() {
        
        if (audioProcessor == nil) || audioProcessor!.isStarted  {
            return
        }
        
        inputBuffer = Data()
        audioProcessor?.start()
    }
    
    func stopAudioProcessing() {
        if audioProcessor == nil {
            return
        }
        inputBuffer = nil;
        audioProcessor?.stop()
        audioProcessor = nil
    }
    
    func scheduleDataToPlay(_ data: Data) {
        if inputBuffer == nil {
            print("Error: The audio processing has not been started, so it cannot play any audio.")
            return
        }
        inputBuffer?.append(data)
        let buffersToPlay = extractAvailableInputBuffers()
        for currentBuffer in buffersToPlay {
            audioProcessor?.scheduleBuffer(toPlay: currentBuffer)
        }
    }
    
    func toggleMute() {
        let mute = !isMuted
        audioProcessor?.muted = mute
    }
    
    func toggleSpeaker() {
        let speakers = !useSpeakers
        audioProcessor?.useSpeakers = speakers
    }
}

// MARK: - Data management

extension Call {
    
    func writeToOutputBuffer(data: Data) -> Bool {
        let nsData = data as NSData
        if outputStream.hasSpaceAvailable {
            outputStream.write(nsData.bytes.assumingMemoryBound(to: UInt8.self),
                               maxLength: nsData.length)
            return true
        } else {
            return false
        }
    }
    
    func readInputBuffer() -> Data? {
        return type(of: self).readInputStream(inputStream)
    }
    
    class func readInputStream(_ inputStream: InputStream) -> Data?{
        var bytes = [UInt8](repeating: 0, count: maxBufferSize)
        let bytesRead = inputStream.read(&bytes, maxLength: maxBufferSize)
        if bytesRead < 1 {
            print("Problem reading buffer")
            return nil
        }
        return Data(bytes: bytes, count: bytesRead)
    }
    
    func extractAvailableInputBuffers() -> [Data] {
        
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
    
    func prepareOutputAudioBuffer(_ buffer: Data) -> (Data) {
        var fullBuffer = Data()
        var size: UInt16 = UInt16(buffer.count)
        withUnsafePointer(to: &size) { fullBuffer.append(UnsafeBufferPointer(start: $0, count: 1)) }
        fullBuffer.append(buffer)
        return fullBuffer
    }
}
