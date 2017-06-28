//
//  ADProcessor.h
//  ADProcessorSample
//
//  Created by Danno on 5/3/17.
//  Copyright © 2017 Daniel Heredia. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ADProcessor;

@protocol ADProcessorDelegate <NSObject>

- (void)processor:(ADProcessor *)processor didReceiveRecordedBuffer:(NSData *)buffer;
- (void)processor:(ADProcessor *)processor didFailPlayingBuffer:(NSData *)buffer withError:(NSError *) error;
//- (void)processorDidDeniedPermission:(ADProcessor *)processor;

@end

@interface ADProcessor : NSObject
@property (nonatomic, weak) id<ADProcessorDelegate> delegate;
@property (nonatomic) BOOL useSpeakers;
@property (nonatomic) BOOL muted;
@property (nonatomic, readonly) BOOL isStarted;

- (void)start;
- (void)stop;
- (void)scheduleBufferToPlay:(NSData *)buffer;


@end
