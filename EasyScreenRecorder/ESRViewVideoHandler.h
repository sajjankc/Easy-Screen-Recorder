//
//  ESRViewVideoHandler.h
//  EasyScreenRecord
//
//  Created by Sajjan on 8/1/13.
//  Copyright (c) 2013 sajjankc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface ESRViewVideoHandler : NSObject

+ (ESRViewVideoHandler *)sharedViewVideoHandler;
+ (void) startScreenRecording;
+ (void) stopScreenRecording;

@property (nonatomic, strong) UIImage *currentScreen;
@property (nonatomic) CGPoint tapPoint;
@property BOOL isTapped;

//video writing
@property (nonatomic, strong) AVAssetWriter *videoWriter;
@property (nonatomic, strong) AVAssetWriterInput *videoWriterInput;
@property (nonatomic, strong) AVAssetWriterInputPixelBufferAdaptor *avAdaptor;
@property (nonatomic, strong) NSURL *outputURL;

//recording state
@property (nonatomic) BOOL isRecording;
@property (nonatomic, strong) NSDate *startedAt;
@property (nonatomic) void* bitmapData;

@end