//
//  GPUImageViewController.m
//  helloAnyChat
//
//  Created by bairuitech on 2017/7/1.
//  Copyright © 2017年 GuangZhou BaiRui NetWork Technology Co.,Ltd. All rights reserved.
//

#import "GPUImageViewController.h"
#import <GPUImage/GPUImage.h>
@interface GPUImageViewController ()

@property (nonatomic, strong) GPUImageVideoCamera *videoCamera;
@property (nonatomic, strong) GPUImageBilateralFilter *bilateralFilter;
@property (nonatomic, strong) GPUImageBrightnessFilter *brightnessFilrer;



@end

@implementation GPUImageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setUpGPUImage];
    // Do any additional setup after loading the view.
}


- (void)setUpGPUImage{
    
    //
    self.videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPresetHigh cameraPosition:AVCaptureDevicePositionFront];
    _videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;

    
    // 创建最终预览View
    GPUImageView *captureVideoPreview = [[GPUImageView alloc] initWithFrame:self.view.bounds];
    [self.view insertSubview:captureVideoPreview atIndex:0];

    
    // 创建滤镜：磨皮，美白，组合滤镜
    GPUImageFilterGroup *groupFilter = [[GPUImageFilterGroup alloc] init];
    
    // 磨皮滤镜
    GPUImageBilateralFilter *bilateralFilter = [[GPUImageBilateralFilter alloc] init];
    [groupFilter addTarget:bilateralFilter];
    
    
    // 美白滤镜
    GPUImageBrightnessFilter *brightnessFilter = [[GPUImageBrightnessFilter alloc] init];
    [groupFilter addTarget:brightnessFilter];
  
    
    // 设置滤镜组链
    [bilateralFilter addTarget:brightnessFilter];
    [groupFilter setInitialFilters:@[bilateralFilter]];
    groupFilter.terminalFilter = brightnessFilter;
    
    // 设置GPUImage处理链，从数据源 => 滤镜 => 最终界面效果
    [_videoCamera addTarget:groupFilter];
    [groupFilter addTarget:captureVideoPreview];
    
    // 必须调用startCameraCapture，底层才会把采集到的视频源，渲染到GPUImageView中，就能显示了。
    // 开始采集视频
    [_videoCamera startCameraCapture];
    [groupFilter setFrameProcessingCompletionBlock:^(GPUImageOutput * filter, CMTime frameTime){
//        CVPixelBufferRef *buffer = [filter.framebufferForOutput bytesBuffer];
    }];
}

@end
