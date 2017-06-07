//
//  ADProcessor.m
//  ADProcessorSample
//
//  Created by Danno on 5/3/17.
//  Copyright © 2017 Daniel Heredia. All rights reserved.
//

#import "ADProcessor.h"
#import <AVFoundation/AVFoundation.h>

#import "AACELDDecoder.h"
#import "AACELDEncoder.h"

static AudioUnitElement const m_inputElement = 1;
static AudioUnitElement const m_outputElement = 0;
static UInt32 const m_inChannels = 1;
static UInt32 const m_outChannels = 2;
static UInt32 const m_frameSize = 512;
static UInt32 const m_sampleRate = 44100;
static UInt32 const m_encBitrate = 32000;

@interface ADProcessor() {
    AudioBuffer m_inputBuffer;
    AudioBuffer m_outputBuffer;
    AudioComponentInstance m_audioComponent;
    
    UInt32 m_inputByteSize;
    UInt32 m_outputByteSize;
    
    AACELDEncoder * m_encoder;
    AACELDDecoder * m_decoder;
    
    NSMutableArray * receivedBuffers;
    dispatch_queue_t receivedBuffersQueue;
    
    BOOL audioOutputClean;

}

@end

@implementation ADProcessor
@synthesize isStarted = _isStarted;

#pragma mark - Initialization
- (id)init {
    self = [super init];
    if (self) {
        m_inputByteSize  = 0;
        m_outputByteSize = 0;
        m_encoder = nil;
        m_decoder = nil;
        _useSpeakers = NO;
        _isStarted = NO;
        receivedBuffersQueue = dispatch_queue_create("audiopal.adprocessor", DISPATCH_QUEUE_SERIAL);
        
        [self initializeAudioUnit];
        
    }
    return self;
}

- (void)initializeEncoder {
    
    EncoderProperties encProperties;
    encProperties.samplingRate = (Float64)m_sampleRate;
    encProperties.inChannels   = 1;
    encProperties.outChannels  = 1;
    encProperties.frameSize    = m_frameSize;
    encProperties.bitrate      = m_encBitrate;
    
    m_encoder = [[AACELDEncoder alloc] initWith:encProperties];

    DecoderProperties decProperties;
    decProperties.samplingRate = encProperties.samplingRate;
    decProperties.inChannels   = 1;
    decProperties.outChannels  = 2;
    decProperties.frameSize    = encProperties.frameSize;
    
    //TODO: Esto tedría que cambiar de acuerdo al encoder del otro lado.
    m_decoder = [[AACELDDecoder alloc] initWith:decProperties magicCookie:m_encoder.magicCookie];
}

- (void)initializeAudioUnit {
    
    //Set properties for audio session
    AVAudioSession * session = [AVAudioSession sharedInstance];
    NSError * sError = nil;
    [session setCategory:AVAudioSessionCategoryPlayAndRecord error:&sError];
    [self printErrorIfNecessary:sError];
    if (self.useSpeakers)
    {
        //TODO: Vamos a tener que hacer esto para poner speaker siempre? (pasar por aquí)
        [session overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:&sError];
        [self printErrorIfNecessary:sError];
    }
    Float32 preferredBufferTime = ((Float32)m_frameSize) / ((Float64)m_sampleRate);
    [session setPreferredIOBufferDuration:preferredBufferTime error:&sError];
    [self printErrorIfNecessary:sError];
    [session setActive:YES error:&sError];
    [self printErrorIfNecessary:sError];
    
    //Initialize buffers
    m_inputByteSize  = m_frameSize * m_inChannels  * sizeof(SInt32);
    m_outputByteSize = m_frameSize * m_outChannels * sizeof(SInt32);
    m_inputBuffer.mNumberChannels = m_inChannels;
    m_inputBuffer.mDataByteSize   = m_inputByteSize;
    m_outputBuffer.mNumberChannels = m_outChannels;
    m_outputBuffer.mDataByteSize   = m_outputByteSize;
    
    //TODO: falta liberar, es necesario?
    //Allocate memory for buffers
    m_inputBuffer.mData = malloc(sizeof(unsigned char)*m_inputByteSize);
    memset(m_inputBuffer.mData, 0, m_inputByteSize);
    m_outputBuffer.mData = malloc(sizeof(unsigned char)*m_outputByteSize);
    memset(m_outputBuffer.mData, 0, m_outputByteSize);
    
    //Retrieve audio component
    AudioComponentDescription compDesc;
    compDesc.componentType = kAudioUnitType_Output;
    compDesc.componentSubType = kAudioUnitSubType_RemoteIO;
    compDesc.componentManufacturer = kAudioUnitManufacturer_Apple;
    compDesc.componentFlags = 0;
    compDesc.componentFlagsMask = 0;
    AudioComponent component = AudioComponentFindNext(NULL, &compDesc);
    AudioComponentInstanceNew(component, &m_audioComponent);
    
    //Enable audio input
    //TODO: Se puede deshabilitar microfono a este nivel?
    UInt32 enableInput = 1;
    AudioUnitSetProperty(m_audioComponent,
                         kAudioOutputUnitProperty_EnableIO,
                         kAudioUnitScope_Input,
                         m_inputElement,
                         &enableInput,
                         sizeof(enableInput));
    //Set input callback
    AURenderCallbackStruct inputCallbackInfo;
    inputCallbackInfo.inputProc = audioInputCallback;
    inputCallbackInfo.inputProcRefCon = (__bridge void * _Nullable)(self);
    AudioUnitSetProperty(m_audioComponent,
                         kAudioOutputUnitProperty_SetInputCallback,
                         kAudioUnitScope_Global,
                         m_inputElement,
                         &inputCallbackInfo,
                         sizeof(inputCallbackInfo));
    
    //Set output callback
    AURenderCallbackStruct outputCallbackInfo;
    outputCallbackInfo.inputProc = audioOutputCallback;
    outputCallbackInfo.inputProcRefCon = (__bridge void * _Nullable)(self);
    AudioUnitSetProperty(m_audioComponent,
                         kAudioUnitProperty_SetRenderCallback,
                         kAudioUnitScope_Global,
                         m_outputElement,
                         &outputCallbackInfo,
                         sizeof(outputCallbackInfo));
    
    //Set audio format
    AudioStreamBasicDescription audioFormat;
    audioFormat.mFormatID = kAudioFormatLinearPCM;
    audioFormat.mChannelsPerFrame = m_inChannels;
    audioFormat.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
    audioFormat.mSampleRate = m_sampleRate;
    audioFormat.mFramesPerPacket = 1;
    audioFormat.mBitsPerChannel = 8 * sizeof(SInt32);
    audioFormat.mBytesPerFrame = audioFormat.mChannelsPerFrame * sizeof(SInt32);
    audioFormat.mBytesPerPacket = audioFormat.mBytesPerFrame;
    
    AudioUnitSetProperty(m_audioComponent,
                         kAudioUnitProperty_StreamFormat,
                         kAudioUnitScope_Output,
                         m_inputElement,
                         &audioFormat,
                         sizeof(audioFormat));
    
    audioFormat.mChannelsPerFrame = m_outChannels;
    //TODO: Es necesario volver a setear estos 2 valores?
    audioFormat.mBytesPerFrame    = audioFormat.mChannelsPerFrame * sizeof(SInt32);
    audioFormat.mBytesPerPacket   = audioFormat.mBytesPerFrame;
    AudioUnitSetProperty(m_audioComponent,
                         kAudioUnitProperty_StreamFormat,
                         kAudioUnitScope_Input,
                         m_outputElement,
                         &audioFormat,
                         sizeof(audioFormat));
    
    [self initializeEncoder];
}

- (void)printErrorIfNecessary:(NSError *)error
{
    if (error) {
        NSLog(@"Audio error: %@", error.localizedDescription);
    }
}

#pragma mark - Client methods

- (void)start {
    
    if (self.isStarted) {
        return;
    }
    _isStarted = YES;
    receivedBuffers = [[NSMutableArray alloc] init];
    audioOutputClean = YES;
    AudioUnitInitialize(m_audioComponent);
    AudioOutputUnitStart(m_audioComponent);
}

- (void)stop {
    if (!self.isStarted) {
        return;
    }
    _isStarted = NO;
    [receivedBuffers removeAllObjects];
    receivedBuffers = nil;
    //stop audiounits
    AudioOutputUnitStop(m_audioComponent);
    AudioComponentInstanceDispose(m_audioComponent);
}

- (void)scheduleBufferToPlay:(NSData *)buffer {
    
    if (m_decoder == nil || buffer == nil) {
        return;
    }
    
    dispatch_sync(receivedBuffersQueue, ^{
        if ([receivedBuffers count] >= 50) {
            [receivedBuffers removeAllObjects];
        }
        [receivedBuffers addObject:buffer];
    });
}

#pragma mark - Audio samples processing 

- (void)receiveAudioInputCallBackWithFlags:(AudioUnitRenderActionFlags *) ioActionFlags
                            timeStamp:(const AudioTimeStamp *)inTimeStamp
                            busNumber: (UInt32) nBusNumber
                       numberOfFrames:(UInt32)inNumberOfFrames
                               ioData:(AudioBufferList *)ioData {
    
    AudioBuffer buffer;
    buffer.mNumberChannels = 1;
    buffer.mDataByteSize = inNumberOfFrames * sizeof(SInt32);
    buffer.mData = malloc(buffer.mDataByteSize);
    
    AudioBufferList bufferList;
    SInt32 samples[inNumberOfFrames]; // A large enough size to not have to worry about buffer overrun
    memset (&samples, 0, sizeof (samples));
    bufferList.mNumberBuffers = 1;
    bufferList.mBuffers[0] = buffer;
    
    // Get the input buffer
    AudioUnitRender(m_audioComponent,
                    ioActionFlags,
                    inTimeStamp,
                    m_inputElement,
                    inNumberOfFrames,
                    &bufferList);
    
    NSData * dataBuffer = [m_encoder encodeBuffer:&(bufferList.mBuffers[0])];
    if (dataBuffer != nil && self.delegate) {
        [self.delegate processor:self didReceiveRecordedBuffer:dataBuffer];
    }
    free(bufferList.mBuffers[0].mData);
}

- (void)receiveAudioOutputCallBackWithFlags:(AudioUnitRenderActionFlags *) ioActionFlags
                            timeStamp:(const AudioTimeStamp *)inTimeStamp
                            busNumber: (UInt32) nBusNumber
                       numberOfFrames:(UInt32)inNumberOfFrames
                               ioData:(AudioBufferList *)ioData {

    __block NSData * currentBuffer;
    dispatch_sync(receivedBuffersQueue, ^{
        if ([receivedBuffers count] > 0) {
            currentBuffer = [receivedBuffers firstObject];
            [receivedBuffers removeObject:currentBuffer];
        }
        
    });
    
    if (currentBuffer != nil)
    {
        [self playDataBuffer:currentBuffer ioData:ioData];
        audioOutputClean = NO;
    } else {
        //Clean
        [self checkForCleanAudioOutput:ioData];

    }
    
}

- (void)playDataBuffer:(NSData *)dataBuffer ioData:(AudioBufferList *)ioData {
    // Decode
    m_outputBuffer.mDataByteSize = m_outputByteSize;
    OSStatus status = [m_decoder decodeBuffer:dataBuffer outData:&m_outputBuffer];
    
    if (status != noErr) {
        if (self.delegate) {
            NSString * errMess = [NSString stringWithFormat:@"The buffer was not played due an error during decoding: %d", (int)status];
            NSDictionary * errorInfo = @{
                                         NSLocalizedDescriptionKey:errMess
                                        };
            NSError * error = [NSError errorWithDomain:@"ADProcessor"
                                                  code:status
                                              userInfo:errorInfo];
            [self.delegate processor:self
                didFailPlayingBuffer:dataBuffer
                           withError:error];
        }
        return;
    }
    
    // Play the buffer
    ioData->mBuffers[0].mNumberChannels = m_outputBuffer.mNumberChannels;
    ioData->mBuffers[0].mDataByteSize = m_outputBuffer.mDataByteSize;
    memcpy(ioData->mBuffers[0].mData, m_outputBuffer.mData, m_outputBuffer.mDataByteSize);
    
}

- (void)checkForCleanAudioOutput:(AudioBufferList *)ioData {
    
    if (!audioOutputClean) {
        NSLog(@"Limpiado");
        ioData->mBuffers[0].mNumberChannels = m_outputBuffer.mNumberChannels;
        memset(ioData->mBuffers[0].mData, 0, ioData->mBuffers[0].mDataByteSize);
        audioOutputClean = YES;
    }
}

#pragma mark - Audio callback

static OSStatus audioInputCallback(void *inRefCon,
                                       AudioUnitRenderActionFlags *ioActionFlags,
                                       const AudioTimeStamp *inTimeStamp,
                                       UInt32 nBusNumber,
                                       UInt32 inNumberOfFrames,
                                       AudioBufferList *ioData) {
    ADProcessor * processor = (__bridge ADProcessor *)(inRefCon);
    [processor receiveAudioInputCallBackWithFlags:ioActionFlags
                                   timeStamp:inTimeStamp
                                   busNumber:nBusNumber
                              numberOfFrames:inNumberOfFrames
                                      ioData:ioData];
    
    return noErr;
}

static OSStatus audioOutputCallback(void *inRefCon,
                                       AudioUnitRenderActionFlags *ioActionFlags,
                                       const AudioTimeStamp *inTimeStamp,
                                       UInt32 nBusNumber,
                                       UInt32 inNumberOfFrames,
                                       AudioBufferList *ioData) {
    ADProcessor * processor = (__bridge ADProcessor *)(inRefCon);
    [processor receiveAudioOutputCallBackWithFlags:ioActionFlags
                                   timeStamp:inTimeStamp
                                   busNumber:nBusNumber
                              numberOfFrames:inNumberOfFrames
                                      ioData:ioData];
    
    return noErr;
}

- (void)dealloc {
    m_encoder = nil;
    m_decoder = nil;
}

@end
