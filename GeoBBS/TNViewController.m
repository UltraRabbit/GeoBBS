//
//  TNViewController.m
//  GeoBBS
//
//  Created by Jack He on 12/26/12.
//  Copyright (c) 2012 Telenav. All rights reserved.
//

#import "TNViewController.h"

@interface TNViewController ()
{
    bool isTrackStarted;
    CMMotionManager* motionManager;
    AVCaptureSession* captureSession;
    AVCaptureVideoPreviewLayer* videoLayer;
    AVCaptureStillImageOutput* stillImageOutput;
}

@end



@implementation TNViewController

@synthesize labelX;
@synthesize labelY;
@synthesize labelZ;
@synthesize labelDistance;
@synthesize btnStart;
@synthesize videoView;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    isTrackStarted = false;
    motionManager = nil;
    captureSession = nil;
    videoLayer = nil;
    stillImageOutput = nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    if (isTrackStarted)
        [self onStartClicked:self];
}

- (void)viewWillAppear:(BOOL)animated
{
    [labelX setText:@"Test X"];
    [labelY setText:@"Test Y"];
    [labelZ setText:@"Test Z"];
}

- (IBAction)onStartClicked:(id)sender {
    if (isTrackStarted == true) {
        [btnStart setTitle:@"Start Track" forState:UIControlStateNormal];
        isTrackStarted = false;
        [self stopTracking];
        [self stopPreview];
    }
    else {
        [btnStart setTitle:@"Stop Track" forState:UIControlStateNormal];
        isTrackStarted = true;
        [self startTracking];
        [self startPreview];
    }
}

- (void)startTracking
{
    if (motionManager == nil) {
        motionManager = [[CMMotionManager alloc] init];
    }
    
    TNViewController* __weak myself = self;
    
    if ([motionManager isGyroAvailable] && ![motionManager isGyroActive]) {
        [motionManager setGyroUpdateInterval:0.1];
        [motionManager startGyroUpdatesToQueue:[NSOperationQueue mainQueue]
                       withHandler:^(CMGyroData *gyroData, NSError *error) {
                           
                           if (nil != error || nil == gyroData)
                               return;
                           
                           [myself.labelX setText:[NSString stringWithFormat:@"%f",gyroData.rotationRate.x]];
                           [myself.labelY setText:[NSString stringWithFormat:@"%f",gyroData.rotationRate.y]];
                           [myself.labelZ setText:[NSString stringWithFormat:@"%f",gyroData.rotationRate.z]];
                           
                       }
        ];
    }
}

- (void)stopTracking
{
    if (motionManager == nil)
        return;
    
    if ([motionManager isGyroActive]) {
       [motionManager stopGyroUpdates];
    }
    
}

- (void)startPreview
{
    if (captureSession != nil || videoView == nil)
        return;
    
    AVCaptureDevice* camera = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
	if (camera == nil) {
		return;
	}

    // Setup the camera configuration and observe the focusing event
    NSError* error;
//    [camera lockForConfiguration:&error];
//    [camera setFocusMode:AVCaptureFocusModeAutoFocus];
//    [camera setFocusPointOfInterest:CGPointMake(0.5, 0.5)];
//    [camera unlockForConfiguration];
    [camera addObserver:self forKeyPath:@"adjustingFocus" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:nil];

	
    // Create a new capture session
	captureSession = [[AVCaptureSession alloc] init];
    
    // Setup the video input
	AVCaptureDeviceInput *newVideoInput = [[AVCaptureDeviceInput alloc] initWithDevice:camera error:nil];
	[captureSession addInput:newVideoInput];
    newVideoInput = nil;
    
    // Setup the video output
    AVCaptureStillImageOutput *newStillImageOutput = [[AVCaptureStillImageOutput alloc] init];
    NSDictionary *outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys:
                                    AVVideoCodecJPEG, AVVideoCodecKey,
                                    nil];
    [newStillImageOutput setOutputSettings:outputSettings];
    outputSettings = nil;
    [captureSession addOutput:newStillImageOutput];
    stillImageOutput = newStillImageOutput;
    newStillImageOutput = nil;
    
    AVCaptureVideoPreviewLayer* captureLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:captureSession];
	captureLayer.frame = videoView.bounds;
    [captureLayer.connection setVideoOrientation:AVCaptureVideoOrientationPortrait];
	[captureLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
	[videoView.layer addSublayer:captureLayer];
    videoLayer = captureLayer;
    
    // Start the session. This is done asychronously since -startRunning doesn't return until the session is running.
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		[captureSession startRunning];
	});
    
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([@"adjustingFocus" isEqualToString:keyPath])
    {
        AVCaptureDevice* camera = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        if (camera!=nil && [camera isAdjustingFocus]==NO) {
            NSLog(@"Camera got focused.  Try to detect the distance ...");
            [self captureStillImage];
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}


- (void)captureStillImage
{
        
    AVCaptureConnection *stillImageConnection = [TNViewController connectionWithMediaType:AVMediaTypeVideo fromConnections:[stillImageOutput connections]];
    
    if (stillImageConnection != nil) {
        [stillImageOutput captureStillImageAsynchronouslyFromConnection:stillImageConnection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
            if (imageDataSampleBuffer != nil) {
                
//                CFArrayRef attachments = CMSampleBufferGetSampleAttachmentsArray(imageDataSampleBuffer, FALSE);
//                if (attachments) {
//                    CFIndex count = CFArrayGetCount(attachments);
//                    for (CFIndex i=0; i<count; i++) {
//                       CFTypeRef value = CFArrayGetValueAtIndex(attachments, i);
//                        CFShow(value);
//                    }
//                }
//                
                
                CFDictionaryRef exifAttachments =
                CMGetAttachment(imageDataSampleBuffer, kCGImagePropertyExifDictionary, NULL);
                
                if (exifAttachments) {
                    CFIndex count = CFDictionaryGetCount(exifAttachments);
                    CFStringRef* keys = malloc(sizeof(CFStringRef)*count);
                    CFTypeRef* values = malloc(sizeof(CFTypeRef)*count);
                    CFDictionaryGetKeysAndValues(exifAttachments, (CFTypeRef*)keys, values);
                    
                    for (CFIndex i=0; i<count; i++) {
                        NSLog(@"%s", CFStringGetCStringPtr(keys[i], CFStringGetFastestEncoding(keys[i])));
                        CFTypeRef value = values[i];
                        CFShow(value);
                    }
                    
                    free(keys);
                    free(values);
                    
                    CFNumberRef cfDistance = CFDictionaryGetValue(exifAttachments, kCGImagePropertyExifSubjectDistance);
                    if (cfDistance) {
                        float distance = 0.0;
                        CFNumberGetValue(cfDistance, kCFNumberFloatType, &distance);
                        NSLog(@"Get distance at %f meters.", distance);
                    } else {
                        NSLog(@"Subject distance unavailable.");
                    }
                }
            }
        }];
    }
        
}

- (void)stopPreview
{
    if (captureSession == nil)
        return;
    
    if ([captureSession isRunning])
        [captureSession stopRunning];

    [captureSession removeOutput:stillImageOutput];

    stillImageOutput = nil;
    
    captureSession = nil;
    
    if (videoLayer != nil)
    {
        [videoLayer removeFromSuperlayer];
        videoLayer = nil;
    }
    
    AVCaptureDevice* camera = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
	if (camera != nil) {
        [camera removeObserver:self forKeyPath:@"adjustingFocus"];
    }
}

+ (AVCaptureConnection *)connectionWithMediaType:(NSString *)mediaType fromConnections:(NSArray *)connections
{
	for ( AVCaptureConnection *connection in connections ) {
		for ( AVCaptureInputPort *port in [connection inputPorts] ) {
			if ( [[port mediaType] isEqual:mediaType] ) {
				return connection;
			}
		}
	}
	return nil;
}

@end
