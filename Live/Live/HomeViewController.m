//
//  HomeViewController.m
//  helloAnyChat
//
//  Created by bairuitech on 2017/6/30.
//  Copyright © 2017年 GuangZhou BaiRui NetWork Technology Co.,Ltd. All rights reserved.
//

#import "HomeViewController.h"
#import <AVFoundation/AVFoundation.h>

@interface HomeViewController ()<AVCaptureVideoDataOutputSampleBufferDelegate,AVCaptureAudioDataOutputSampleBufferDelegate>
@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong) AVCaptureDeviceInput *videoInput;
@property (nonatomic, strong) AVCaptureDeviceInput *audioInput;
@property (nonatomic, strong) AVCaptureConnection *videoConnection;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previedLayer;
@end

@implementation HomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setUpCaputureVideo];
    
    __weak typeof (self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
//        [weakSelf toggleCapture];
//        [weakSelf changeSessionPreset];
    });
}

- (void)setUpCaputureVideo{
    
    self.session = [[AVCaptureSession alloc]init];
    
    AVCaptureDevice *videoDevice = [self getVideoDevice:AVCaptureDevicePositionBack];
    if ([videoDevice isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) {
        
        [videoDevice lockForConfiguration:nil];
        CGPoint autofocusPoint = CGPointMake(0.5f, 0.5f);
        [videoDevice setFocusPointOfInterest:autofocusPoint];
        [videoDevice setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
        [videoDevice unlockForConfiguration];
    }
    
    AVCaptureDevice *audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    
    
    self.videoInput = [[AVCaptureDeviceInput alloc]initWithDevice:videoDevice error:nil];
    
    self.audioInput = [[AVCaptureDeviceInput alloc]initWithDevice:audioDevice error:nil];
    
    
    if ([self.session canAddInput:self.videoInput]) {
        
        [self.session addInput:self.videoInput];
    };
    
    if ([self.session canAddInput:self.audioInput]) {
        
        [self.session addInput:self.audioInput];
    };
    
    
    //
    AVCaptureVideoDataOutput *videoOutput = [[AVCaptureVideoDataOutput alloc]init];
    NSMutableDictionary *outputSettings = [NSMutableDictionary dictionary];
    [outputSettings setObject:@(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange) forKey:(id)kCVPixelBufferPixelFormatTypeKey];
    videoOutput.videoSettings = outputSettings;
    dispatch_queue_t videoQueue = dispatch_queue_create("Video Queue", NULL);
    [videoOutput setSampleBufferDelegate:self queue:videoQueue];
    if ([self.session canAddOutput:videoOutput]) {
        [self.session addOutput:videoOutput];
    }
    
    AVCaptureAudioDataOutput *audioOutPut = [[AVCaptureAudioDataOutput alloc]init];
    dispatch_queue_t audioQueue = dispatch_queue_create("Audio Queue", NULL);
    [audioOutPut setSampleBufferDelegate:self queue:audioQueue];
    if ([self.session canAddOutput:audioOutPut]) {
        [self.session addOutput:audioOutPut];
    }

    
    //
   self.videoConnection = [videoOutput connectionWithMediaType:AVMediaTypeVideo];
    
   self.previedLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.session];
   self.previedLayer.frame = [UIScreen mainScreen].bounds;
   [self.view.layer insertSublayer:self.previedLayer atIndex:0];
    
    
    //
    [self.session startRunning];
    
    
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate
// 获取输入设备数据，有可能是音频有可能是视频
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    if (self.videoConnection == connection) {
//        NSLog(@"采集到视频数据");
    } else {
//        NSLog(@"采集到音频数据");
    }
}
// Create a UIImage from sample buffer data
// Works only if pixel format is kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
-(UIImage *)convertSampleBufferToUIImageSampleBuffer:(CMSampleBufferRef)sampleBuffer{
    
    // Get a CMSampleBuffer's Core Video image buffer for the media data
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    // Lock the base address of the pixel buffer
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    
    // Get the number of bytes per row for the plane pixel buffer
    void *baseAddress = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0);
    
    // Get the number of bytes per row for the plane pixel buffer
    size_t bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(imageBuffer,0);
    // Get the pixel buffer width and height
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    
    // Create a device-dependent gray color space
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
    
    // Create a bitmap graphics context with the sample buffer data
    CGContextRef context = CGBitmapContextCreate(baseAddress, width, height, 8,
                                                 bytesPerRow, colorSpace, kCGImageAlphaNone);
    // Create a Quartz image from the pixel data in the bitmap graphics context
    CGImageRef quartzImage = CGBitmapContextCreateImage(context);
    // Unlock the pixel buffer
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    
    // Free up the context and color space
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    
    // Create an image object from the Quartz image
    UIImage *image = [UIImage imageWithCGImage:quartzImage];
    
    // Release the Quartz image
    CGImageRelease(quartzImage);
    
    return (image);
    
}


// 指定摄像头方向获取摄像头
- (AVCaptureDevice *)getVideoDevice:(AVCaptureDevicePosition)position
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) {
        if (device.position == position) {
            return device;
        }
    }
    
    
    return nil;
}

- (void)toggleCapture{
    
    [self.session beginConfiguration];
    
    //
    AVCaptureDevicePosition cutPostition = self.videoInput.device.position;
    //
    AVCaptureDevice *toggleDevice = [self getVideoDevice:AVCaptureDevicePositionFront];
    
    AVCaptureDeviceInput *toggleInput = [AVCaptureDeviceInput deviceInputWithDevice:toggleDevice error:nil];
    
    //
    [self.session removeInput:self.videoInput];
    //
    [self.session addInput:toggleInput];
    
    self.videoInput = toggleInput;
    
    [self.session commitConfiguration];
}

- (void)changeSessionPreset{
    
    [self.session beginConfiguration];
    if ([self.session canSetSessionPreset:AVCaptureSessionPreset1280x720]) {
        
        [self.session setSessionPreset:AVCaptureSessionPreset1280x720];
    }
    [self.session commitConfiguration];
    
}

@end
