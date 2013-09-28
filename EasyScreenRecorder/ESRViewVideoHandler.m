//
//  ESRViewVideoHandler.m
//  EasyScreenRecord
//
//  Created by Sajjan on 8/1/13.
//  Copyright (c) 2013 sajjankc. All rights reserved.
//

#import "ESRViewVideoHandler.h"
#import <QuartzCore/QuartzCore.h>

@interface ESRViewVideoHandler(Private)
- (void) writeVideoFrameAtTimeThread;
@end

@implementation ESRViewVideoHandler

static ESRViewVideoHandler *_shareViewVideoHandler = nil;

@synthesize videoWriter, videoWriterInput, avAdaptor, isRecording, startedAt, bitmapData, outputURL, currentScreen;

- (UIImage*)screenImage {
    //Get Image Context *not checked on retina devices but i think it works..
    UIGraphicsBeginImageContextWithOptions([[UIApplication sharedApplication]keyWindow].bounds.size, NO, 0);
    [[[UIApplication sharedApplication]keyWindow].layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *screenshotImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return screenshotImage;
}

- (void) initialize {
    self.currentScreen = nil;
	self.isRecording = NO;
	self.videoWriter = nil;
	self.videoWriterInput = nil;
	self.avAdaptor = nil;
	self.startedAt = nil;
	self.bitmapData = NULL;
}

- (id) init {
	self = [super init];
	if (self) {
		[self initialize];
	}
	return self;
}

- (CGContextRef) createBitmapContextOfSize:(CGSize) size {
	CGContextRef context = NULL;
	CGColorSpaceRef colorSpace;
	int bitmapByteCount;
	int bitmapBytesPerRow;
	
	bitmapBytesPerRow = (size.width * 4);
	bitmapByteCount = (bitmapBytesPerRow * size.height);
	colorSpace = CGColorSpaceCreateDeviceRGB();
	if (self.bitmapData != NULL) {
		free(self.bitmapData);
	}
	self.bitmapData = malloc( bitmapByteCount );
	if (self.bitmapData == NULL) {
		fprintf (stderr, "Memory not allocated!");
		return NULL;
	}
	context = CGBitmapContextCreate (self.bitmapData,size.width, size.height,8,      // bits per component
									 bitmapBytesPerRow, colorSpace, kCGImageAlphaNoneSkipFirst);
	CGContextSetAllowsAntialiasing(context,NO);
	if (context== NULL) {
		free (self.bitmapData);
		fprintf (stderr, "Context not created!");
		return NULL;
	}
	CGColorSpaceRelease(colorSpace);
	return context;
}

// get screenshot images afterDelay:0.5(change afterDelay time as your requirement currently it capture 2 screenshot each second) and write it to video (writeVideoFrameAtTimeThread)
- (void) makeVideoFrame {
    if (self.isRecording) {
        UIImage *screenShotImg = [self screenImage];
        self.currentScreen = screenShotImg;
        
        dispatch_queue_t backgroundMethod = dispatch_queue_create("backgroundMethod", NULL);
        dispatch_sync(backgroundMethod, ^(void) {
            [self writeVideoFrameAtTimeThread];
            [self performSelector:@selector(makeVideoFrame) withObject:nil afterDelay:0.5];
        });
    }
}

- (void) cleanupWriter {
	self.avAdaptor = nil;
	self.videoWriterInput = nil;
	self.videoWriter = nil;
	self.startedAt = nil;
	if (self.bitmapData != NULL) {
		free(self.bitmapData);
		self.bitmapData = NULL;
	}
}

// temp file path/URL for video write and storage
- (NSURL*) tempFileURL {
	NSString* videoPath = [[NSString alloc] initWithFormat:@"%@/%@", [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0], @"AppVideo.mov"];
	NSURL* videoURL = [[NSURL alloc] initFileURLWithPath:videoPath];
	NSFileManager* fileManager = [NSFileManager defaultManager];
	if ([fileManager fileExistsAtPath:videoPath]) {
		NSError* error;
        if ([fileManager isDeletableFileAtPath:videoPath]) {
            //delete video if already exit at videoPath
            BOOL success = [[NSFileManager defaultManager] removeItemAtPath:videoPath error:&error];
            if (!success) {
                NSLog(@"Could not delete old recording file at path:  %@", videoPath);
            }
        }
	}
	return videoURL;
}

- (BOOL) setUpWriter {
	NSError *error = nil;
	self.videoWriter = [[AVAssetWriter alloc] initWithURL:[self tempFileURL] fileType:AVFileTypeQuickTimeMovie error:&error];
	NSParameterAssert(self.videoWriter);
	
	//Configure video
	NSDictionary *videoCompressionProps = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithDouble:1024.0*1024.0], AVVideoAverageBitRateKey,nil ];
    
	NSDictionary* videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
								   AVVideoCodecH264, AVVideoCodecKey,
								   [NSNumber numberWithInt:[[UIApplication sharedApplication] keyWindow].bounds.size.width], AVVideoWidthKey,
								   [NSNumber numberWithInt:[[UIApplication sharedApplication] keyWindow].bounds.size.height], AVVideoHeightKey,
								   videoCompressionProps, AVVideoCompressionPropertiesKey,
								   nil];
	
	self.videoWriterInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];
	
	NSParameterAssert(self.videoWriterInput);
	self.videoWriterInput.expectsMediaDataInRealTime = YES;
	NSDictionary* bufferAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA], kCVPixelBufferPixelFormatTypeKey, nil];
	
	self.avAdaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:self.videoWriterInput sourcePixelBufferAttributes:bufferAttributes];
	
	//add input
	[self.videoWriter addInput:self.videoWriterInput];
	[self.videoWriter startWriting];
	[self.videoWriter startSessionAtSourceTime:CMTimeMake(0, 1000)];
	return YES;
}

- (void) completeRecordingSession {
    @autoreleasepool {
        [self.videoWriterInput markAsFinished];
        // Wait for the video
        int status = self.videoWriter.status;
        while (status == AVAssetWriterStatusUnknown) {
            [NSThread sleepForTimeInterval:0.5f];
            status = self.videoWriter.status;
        }
        @synchronized(self) {
            BOOL success = [self.videoWriter finishWriting];
            if (!success) {
                NSLog(@"finishWriting returned NO");
            }
            [self cleanupWriter];
            NSString *outputPath = [[NSString alloc] initWithFormat:@"%@/%@", [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0], @"AppVideo.mov"];
            self.outputURL = [NSURL fileURLWithPath:outputPath];
            //save video to photoAlbum
            UISaveVideoAtPathToSavedPhotosAlbum(outputPath,self,nil,nil);
            self.isRecording = NO;
        }
    }
}

+ (void) startScreenRecording {
    bool result = NO;
    @synchronized([ESRViewVideoHandler class]) {
        if (_shareViewVideoHandler == nil) {
            _shareViewVideoHandler = [[ESRViewVideoHandler alloc] init];
        }
        @synchronized(_shareViewVideoHandler) {
            if (!_shareViewVideoHandler.isRecording) {
                result = [_shareViewVideoHandler setUpWriter];
                _shareViewVideoHandler.startedAt = [NSDate date];
                _shareViewVideoHandler.isRecording = YES;
                [_shareViewVideoHandler makeVideoFrame];
            }
        }
    }
}


+ (void) stopScreenRecording {
    @synchronized(_shareViewVideoHandler) {
        if (_shareViewVideoHandler.isRecording) {
            _shareViewVideoHandler.isRecording = NO;
            [_shareViewVideoHandler completeRecordingSession];
        }
    }
}

//write video
- (void) writeVideoFrameAtTimeThread {
    float millisElapsed = [[NSDate date] timeIntervalSinceDate:self.startedAt] * 1000.0;
    CMTime time = CMTimeMake((int)millisElapsed, 1000);
	if (![self.videoWriterInput isReadyForMoreMediaData]) {
		NSLog(@"Not ready for video data");
	} else {
		@synchronized (self) {
			UIImage *newFrame = self.currentScreen;
			CVPixelBufferRef pixelBuffer = NULL;
			CGImageRef cgImage = CGImageCreateCopy([newFrame CGImage]);
			CFDataRef image = CGDataProviderCopyData(CGImageGetDataProvider(cgImage));
			
			int status = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, self.avAdaptor.pixelBufferPool, &pixelBuffer);
			if(status != 0){
				//could not get a buffer from the pool
				NSLog(@"Error creating pixel buffer:  status=%d", status);
			}
			// set image data into pixel buffer
			CVPixelBufferLockBaseAddress( pixelBuffer, 0 );
			uint8_t* destPixels = CVPixelBufferGetBaseAddress(pixelBuffer);
			CFDataGetBytes(image, CFRangeMake(0, CFDataGetLength(image)), destPixels);  //  will work if the pixel buffer is contiguous and has the same bytesPerRow as the input data
			if(status == 0){
				BOOL success = [self.avAdaptor appendPixelBuffer:pixelBuffer withPresentationTime:time];
				if (!success)
					NSLog(@"Warning:  Unable to write buffer to video");
			}
			//clean up
			CVPixelBufferUnlockBaseAddress( pixelBuffer, 0 );
			CVPixelBufferRelease( pixelBuffer );
			CFRelease(image);
			CGImageRelease(cgImage);
		}
	}
}

@end
