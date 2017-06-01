//
//  AACELDEncoder.h
//  ADProcessorSample
//
//  Created by Danno on 5/4/17.
//  Copyright © 2017 Daniel Heredia. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EncodingUtils.hpp"


@interface AACELDEncoder : NSObject

@property (nonatomic, retain) NSData * magicCookie;

- (id)initWith:(EncoderProperties)properties;
- (NSData *)encodeBuffer:(AudioBuffer *)inSamples;

@end
