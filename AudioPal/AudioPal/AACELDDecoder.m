//
//  AACELDDecoder.m
//  ADProcessorSample
//
//  Created by Danno on 5/3/17.
//  Copyright © 2017 Daniel Heredia. All rights reserved.
//

#import "AACELDDecoder.h"
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>

#import "EncodingUtils.hpp"



@interface AACELDDecoder() {
    AudioStreamBasicDescription  sourceFormat;
    AudioConverterRef audioConverter;
    DecoderProperties decProperties;
    
    AudioStreamPacketDescription _outPacketDesc[1];
    
}

@property (nonatomic) UInt32 bytesToDecode;
@property (nonatomic, readonly) AudioStreamBasicDescription destinationFormat;
@property (nonatomic, readonly) AudioStreamPacketDescription * outPacketDesc;
@property (nonatomic, readonly) void * decodeBuffer;
@property (nonatomic, readonly) UInt32 maxOutputPacketSize;
@property (nonatomic, readonly) UInt32 inChannels;

@end

@implementation AACELDDecoder

- (id)initWith:(DecoderProperties)properties magicCookie:(const NSData *)cookie {
    
    self = [super init];
    if (self) {
        memset(&(sourceFormat), 0, sizeof(AudioStreamBasicDescription));
        memset(&(_destinationFormat), 0, sizeof(AudioStreamBasicDescription));
        _bytesToDecode = 0;
        _decodeBuffer = NULL;
        [self initializeDecoderWith:properties magicCookie:cookie];
        
    }
    return self;
    
}

#pragma mark - Initialization

- (void)initializeDecoderWith: (DecoderProperties)properties magicCookie:(const NSData *)cookie {
    
    decProperties = properties;
    
    EUFillOutASBDForLPCM(&_destinationFormat,
                       decProperties.samplingRate,
                       decProperties.outChannels,
                       8*sizeof(SInt32),
                       8*sizeof(SInt32),
                       false,
                       false);
    
    sourceFormat.mFormatID = kAudioFormatMPEG4AAC_ELD;
    sourceFormat.mChannelsPerFrame = decProperties.inChannels;
    sourceFormat.mSampleRate = decProperties.samplingRate;
    
    UInt32 dataSize = sizeof(sourceFormat);
    AudioFormatGetProperty(kAudioFormatProperty_FormatInfo,
                           0,
                           NULL,
                           &dataSize,
                           &(sourceFormat));
    
    
    AudioConverterNew(&(sourceFormat),
                      &(_destinationFormat),
                      &(audioConverter));
    
    if (!audioConverter)
    {
        //TODO: No converter
        return ;
    }
    
    // Get the maximum packet size.
    if (_destinationFormat.mBytesPerPacket == 0)
    {
        UInt32 maxOutputSizePerPacket = 0;
        dataSize = sizeof(maxOutputSizePerPacket);
        AudioConverterGetProperty(audioConverter,
                                  kAudioConverterPropertyMaximumOutputPacketSize,
                                  &dataSize,
                                  &maxOutputSizePerPacket);
        _maxOutputPacketSize = maxOutputSizePerPacket;
    }
    else
    {
        _maxOutputPacketSize = _destinationFormat.mBytesPerPacket;
    }
    
    // Set the magic cookie generated from the encoder
    AudioConverterSetProperty(audioConverter,
                              kAudioConverterDecompressionMagicCookie,
                              (unsigned int)cookie.length,
                              cookie.bytes);
}

#pragma mark - Client methods

- (OSStatus)decodeBuffer:(NSData *)inData outData:(AudioBuffer *)outData {
    OSStatus status = noErr;
    
    // Reference to the sample to be decoded
    _decodeBuffer  = (void *)inData.bytes;
    _bytesToDecode = (UInt32)inData.length;
    
    UInt32 outBufferMaxSizeBytes = decProperties.frameSize * decProperties.outChannels * sizeof(SInt32);
    
    assert(outData->mDataByteSize <= outBufferMaxSizeBytes);
    
    UInt32 numOutputDataPackets = outBufferMaxSizeBytes / _maxOutputPacketSize;
    
    AudioStreamPacketDescription outputPacketDesc[decProperties.frameSize];
    
    AudioBufferList outBufferList;
    outBufferList.mNumberBuffers = 1;
    outBufferList.mBuffers[0].mNumberChannels = decProperties.outChannels;
    outBufferList.mBuffers[0].mDataByteSize = outData->mDataByteSize;
    outBufferList.mBuffers[0].mData = outData->mData;
    
    // Decode the buffer list
    status = AudioConverterFillComplexBuffer(audioConverter,
                                             inputDataProc,
                                             (__bridge void * _Nullable)(self),
                                             &numOutputDataPackets,
                                             &outBufferList,
                                             outputPacketDesc);
    
    return status;
}

#pragma mark - Accessors

- (AudioStreamPacketDescription *)outPacketDesc {
    return _outPacketDesc;
}

- (UInt32)inChannels {
    return decProperties.inChannels;
}

#pragma mark - Input data provider


static OSStatus inputDataProc(AudioConverterRef inAudioConverter,
                           UInt32 *ioNumberDataPackets,
                           AudioBufferList *ioData,
                           AudioStreamPacketDescription **outDataPacketDescription,
                           void *inUserData)
{
    AACELDDecoder * decoder = (__bridge AACELDDecoder *)inUserData;
    
     // Adjust the number of packets if neccessary
    UInt32 maxPackets = decoder.bytesToDecode / decoder.maxOutputPacketSize;
    if (*ioNumberDataPackets > maxPackets)
    {
        if (maxPackets == 0) {
            maxPackets = 1;
        }
        *ioNumberDataPackets = maxPackets;
    }
    
    // Det data to encode
    if (decoder.bytesToDecode)
    {
        ioData->mBuffers[0].mData = decoder.decodeBuffer;
        ioData->mBuffers[0].mDataByteSize = decoder.bytesToDecode;
        ioData->mBuffers[0].mNumberChannels = decoder.inChannels;
    }
    
    // Set packet description
    if (outDataPacketDescription)
    {
        decoder.outPacketDesc[0].mStartOffset = 0;
        decoder.outPacketDesc[0].mVariableFramesInPacket = 0;
        decoder.outPacketDesc[0].mDataByteSize = decoder.bytesToDecode;
        
        (*outDataPacketDescription) = decoder.outPacketDesc;
    }
    
    if (decoder.bytesToDecode == 0)
    {
        return 1;
    }
    
    decoder.bytesToDecode = 0;
    
    return noErr;
}

- (void)dealloc
{
    AudioConverterDispose(audioConverter);
}



@end
