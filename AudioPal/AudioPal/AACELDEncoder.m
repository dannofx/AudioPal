//
//  AACELDEncoder.m
//  ADProcessorSample
//
//  Created by Danno on 5/4/17.
//  Copyright © 2017 Daniel Heredia. All rights reserved.
//

#import "AACELDEncoder.h"
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>

@interface AACELDEncoder() {
    
    AudioStreamBasicDescription destinationFormat;
    AudioConverterRef audioConverter;

    void * encodedBuffer;
    AudioStreamPacketDescription packetDesc[1];
    
    UInt32 maxOutputPacketSize;
    EncoderProperties encProperties;
}

@property (nonatomic) UInt32 bytesToEncode;
@property (nonatomic, readonly) AudioStreamBasicDescription sourceFormat;
@property (nonatomic, readonly) AudioBuffer * sampleToEncode;

@end

@implementation AACELDEncoder

#pragma mark - Initialization

- (id)initWith:(EncoderProperties)properties {
    
    self = [super init];
    if (self) {
        memset(&(_sourceFormat), 0, sizeof(AudioStreamBasicDescription));
        memset(&(destinationFormat), 0, sizeof(AudioStreamBasicDescription));
        
        _bytesToEncode = 0;
        encodedBuffer = NULL;
        _sampleToEncode = NULL;
        maxOutputPacketSize = 0;
        [self initializeEncoderWith:properties];
        
    }
    return self;
    
}

- (void)initializeEncoderWith:(EncoderProperties)properties {
    
    encProperties = properties;
    
    EUFillOutASBDForLPCM(&_sourceFormat,
                         encProperties.samplingRate,
                         encProperties.inChannels,
                         8*sizeof(SInt32),
                         8*sizeof(SInt32),
                         false,
                         false);
    
    destinationFormat.mFormatID = kAudioFormatMPEG4AAC_ELD;
    destinationFormat.mChannelsPerFrame = encProperties.outChannels;
    destinationFormat.mSampleRate = encProperties.samplingRate;
    
    UInt32 dataSize = sizeof(destinationFormat);
    
    AudioFormatGetProperty(kAudioFormatProperty_FormatInfo,
                           0,
                           NULL,
                           &dataSize,
                           &(destinationFormat));
    
    AudioConverterNew(&(_sourceFormat),
                      &(destinationFormat),
                      &(audioConverter));
    
    if (!audioConverter)
    {
        return;
    }
    
    // Get the maximum packet size.
    UInt32 outputBitrate = encProperties.bitrate;
    dataSize = sizeof(outputBitrate);
    AudioConverterSetProperty(audioConverter,
                              kAudioConverterEncodeBitRate,
                              dataSize,
                              &outputBitrate);
    
    if (destinationFormat.mBytesPerPacket == 0)
    {
        UInt32 maxOutputSizePerPacket = 0;
        dataSize = sizeof(maxOutputSizePerPacket);
        AudioConverterGetProperty(audioConverter,
                                  kAudioConverterPropertyMaximumOutputPacketSize,
                                  &dataSize,
                                  &maxOutputSizePerPacket);
        maxOutputPacketSize = maxOutputSizePerPacket;
    }
    else
    {
        maxOutputPacketSize = destinationFormat.mBytesPerPacket;
    }
    
    // Generate the magic cookie that will be used by the decoder.
    UInt32 cookieSize = 0;
    AudioConverterGetPropertyInfo(audioConverter,
                                  kAudioConverterCompressionMagicCookie,
                                  &cookieSize,
                                  NULL);
    void * l_cookie = (char*)malloc(cookieSize*sizeof(char));
    AudioConverterGetProperty(audioConverter,
                              kAudioConverterCompressionMagicCookie,
                              &cookieSize,
                              l_cookie);
    self.magicCookie = [NSData dataWithBytes:l_cookie length:cookieSize];
    
    encodedBuffer = malloc(maxOutputPacketSize);
    
}

#pragma mark - Encoding

- (NSData *)encodeBuffer:(AudioBuffer *)inSamples {
    
    memset(encodedBuffer, 0, sizeof(maxOutputPacketSize));
    // Reference to the sample to be encoded
    _sampleToEncode = inSamples;
    _bytesToEncode       = inSamples->mDataByteSize;
    
    UInt32 numOutputDataPackets = 1;
    AudioStreamPacketDescription outPacketDesc[1];
    AudioBufferList outBufferList;
    outBufferList.mNumberBuffers = 1;
    outBufferList.mBuffers[0].mNumberChannels = encProperties.outChannels;
    outBufferList.mBuffers[0].mDataByteSize   = maxOutputPacketSize;
    outBufferList.mBuffers[0].mData           = encodedBuffer;
    
    // Encode the buffer list
    OSStatus status = AudioConverterFillComplexBuffer(audioConverter,
                                                      inputDataProc,
                                                      (__bridge void * _Nullable)(self),
                                                      &numOutputDataPackets,
                                                      &outBufferList,
                                                      outPacketDesc);
    if (status != noErr)
    {
        return nil;
    }
    
    NSData * data = [[NSData alloc] initWithBytes:encodedBuffer
                                           length:outPacketDesc[0].mDataByteSize];
    return data;
}

#pragma mark - Input data provider

static OSStatus inputDataProc(AudioConverterRef inAudioConverter,
                           UInt32 *ioNumberDataPackets,
                           AudioBufferList *ioData,
                           AudioStreamPacketDescription **outDataPacketDescription,
                           void *inUserData)
{
    AACELDEncoder *encoder = (__bridge AACELDEncoder*) inUserData;
    
    // Adjust the number of packets if neccessary
    UInt32 maxPackets = encoder.bytesToEncode / encoder.sourceFormat.mBytesPerPacket;
    if (*ioNumberDataPackets > maxPackets)
    {
        *ioNumberDataPackets = maxPackets;
    }
    
    // Only one audio buffer can be processed/
    if (ioData->mNumberBuffers != 1)
    {
        return 1;
    }
    
    // Data to encode
    ioData->mBuffers[0].mDataByteSize   = encoder.sampleToEncode->mDataByteSize;
    ioData->mBuffers[0].mData           = encoder.sampleToEncode->mData;
    ioData->mBuffers[0].mNumberChannels = encoder.sampleToEncode->mNumberChannels;
    
    if (outDataPacketDescription)
    {
        *outDataPacketDescription = NULL;
    }
    
    if (encoder.bytesToEncode == 0)
    {
        return 1;
    }
    
    encoder.bytesToEncode = 0;
    
    
    return noErr;
}

- (void)dealloc
{
    AudioConverterDispose(audioConverter);
    free(encodedBuffer);
}

@end
