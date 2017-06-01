//
//  EncodingUtils.cpp
//  ADProcessorSample
//
//  Created by Danno on 5/3/17.
//  Copyright © 2017 Daniel Heredia. All rights reserved.
//

#include "EncodingUtils.hpp"

void EUFillOutASBDForLPCM(AudioStreamBasicDescription * outASBD,
                               Float64 inSampleRate,
                               UInt32 inChannelsPerFrame,
                               UInt32 inValidBitsPerChannel,
                               UInt32 inTotalBitsPerChannel,
                               bool inIsFloat,
                               bool inIsBigEndian)
{
    FillOutASBDForLPCM(*outASBD,
                       inSampleRate,
                       inChannelsPerFrame,
                       inValidBitsPerChannel,
                       inTotalBitsPerChannel,
                       inIsFloat,
                       inIsBigEndian,
                       false);
}
