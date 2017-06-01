//
//  EncodingUtils.hpp
//  ADProcessorSample
//
//  Created by Danno on 5/3/17.
//  Copyright © 2017 Daniel Heredia. All rights reserved.
//

#ifndef EncodingUtils_hpp
#define EncodingUtils_hpp

#include <AudioToolbox/AudioToolbox.h>

typedef struct
{
    Float64 samplingRate;
    UInt32  inChannels;
    UInt32  outChannels;
    UInt32  frameSize;
    UInt32  bitrate;
} EncoderProperties;

typedef struct
{
    Float64 samplingRate;
    UInt32  inChannels;
    UInt32  outChannels;
    UInt32  frameSize;
} DecoderProperties;

typedef struct
{
    UInt32 mChannels;
    UInt32 mDataBytesSize;
    void *data;
} EncodedAudioBuffer;

#ifdef __cplusplus
extern "C" {
#endif
//TODO: Verificar si esto es necesario.
void EUFillOutASBDForLPCM(AudioStreamBasicDescription * outASBD,
                                 Float64 inSampleRate,
                                 UInt32 inChannelsPerFrame,
                                 UInt32 inValidBitsPerChannel,
                                 UInt32 inTotalBitsPerChannel,
                                 bool inIsFloat,
                                 bool inIsBigEndian);
#ifdef __cplusplus
}
#endif

#endif /* EncodingUtils_hpp */
