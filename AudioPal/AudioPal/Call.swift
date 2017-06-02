//
//  Call.swift
//  AudioPal
//
//  Created by Danno on 6/1/17.
//  Copyright © 2017 Daniel Heredia. All rights reserved.
//

import UIKit

enum CallStatus: Int {
    case dealing
    case presented
    case waitingResponse
    case onCall
    case rejected
    case responding
}

class Call: NSObject {
    let pal: NearbyPal
    let inputStream: InputStream
    let outputStream: OutputStream
    var callStatus: CallStatus
    var audioProcessor: ADProcessor?
    var inputBuffer: Data?
    
    init(pal: NearbyPal, inputStream: InputStream, outputStream: OutputStream) {
        self.pal = pal
        self.inputStream = inputStream
        self.outputStream = outputStream
        self.callStatus = .dealing
    }
    
    func startAudioProcessing() {
        inputBuffer = Data()
        audioProcessor = ADProcessor()
        audioProcessor?.start()
    }
    
    func stopAudioProcessing() {
        // TODO: What to do here?
    }
    
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
        
        var bytes = [UInt8](repeating: 0, count: maxBufferSize)
        let bytesRead = inputStream.read(&bytes, maxLength: maxBufferSize)
        if bytesRead < 1 {
            print("Problem reading buffer")
            return nil
        }
        return Data(bytes: bytes, count: bytesRead)
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
    
    private func extractAvailableInputBuffers() -> [Data] {
        
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
        fullBuffer.append(UnsafeBufferPointer(start: &size, count: 1))
        fullBuffer.append(buffer)
        return fullBuffer
    }
    
}
