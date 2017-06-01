//
//  AACELDDecoder.h
//  ADProcessorSample
//
//  Created by Danno on 5/3/17.
//  Copyright © 2017 Daniel Heredia. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EncodingUtils.hpp"

@interface AACELDDecoder : NSObject

- (id)initWith:(DecoderProperties)properties magicCookie:(const NSData *)cookie;
- (OSStatus)decodeBuffer:(NSData *)inData outData:(AudioBuffer *)outData;

@end
