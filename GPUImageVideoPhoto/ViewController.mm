//
//  ViewController.m
//  GPUImageVideoPhoto
//
//  Created by Administrator on 2014/09/01.
//  Copyright (c) 2014年 mhfm001. All rights reserved.
//

#import "ViewController.h"


#define clamp(a) (a>255?255:(a<0?0:a));

@interface ViewController ()

@property (strong, nonatomic) UIView *previewView;
@property GPUImageOutput<GPUImageInput> *sepiaFilter;
@property GPUImageView *filterView;
@property GPUImageVideoCamera *videoCamera;

@property NSInteger screenWidth;
@property NSInteger screenHeight;
@property BOOL shutterTriggered;

@property UIImage *processedImage;
@end



@implementation ViewController



- (void)viewDidLoad
{
    [super viewDidLoad];
    
    main_queue = dispatch_get_main_queue();
    sub_queue = dispatch_queue_create("jp.cariya.demo",nil);
    
    [self initProcess];
    
    [self startCapturing];
    
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)initProcess
{
    //Screen
    self.screenWidth = [[UIScreen mainScreen] bounds].size.width;
    self.screenHeight = [[UIScreen mainScreen] bounds].size.height;
    
    self.shutterTriggered = NO;
    
}


- (void)startCapturing
{
    //キャプチャー設定
    [self initVideoCamera];
    
    //セッションスタート
    [self.videoCamera startCameraCapture];//Start
    
}


- (IBAction)takePhotoNow:(id)sender
{
    
    self.shutterTriggered = YES;
    
}



- (void)initVideoCamera
{
    self.videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPresetHigh cameraPosition:AVCaptureDevicePositionBack];
    
    self.videoCamera.delegate = self;//ビデオ撮影から、サンプルバッファーを得るため(GPUImageVideoCameraDelegate)
    
    //現在のデバイスの向きを得る
    self.videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
    
    // filter 設定
    self.sepiaFilter = [[GPUImageSepiaFilter alloc] init];
    
    // Camera にfilterを設定する
    [self.videoCamera addTarget:self.sepiaFilter];
    
    GPUImageView *primaryView = [[GPUImageView alloc] initWithFrame:CGRectMake(0, 0, self.screenWidth, self.screenHeight-44)];
    [self.view addSubview:primaryView];
    
    self.filterView = (GPUImageView *)primaryView;
    [self.sepiaFilter addTarget:self.filterView];
    
    
    
}

//OpenCVを使う（YUV planar ==> RGBA変換用）
cv::Mat* YUV2RGB(cv::Mat *src){
    cv::Mat *output = new cv::Mat(src->rows, src->cols, CV_8UC4);
    for(int i=0;i<output->rows;i++)
        for(int j=0;j<output->cols;j++){
            // from Wikipedia
            int c = src->data[i*src->cols*src->channels() + j*src->channels() + 0] - 16;
            int d = src->data[i*src->cols*src->channels() + j*src->channels() + 1] - 128;
            int e = src->data[i*src->cols*src->channels() + j*src->channels() + 2] - 128;
            
            output->data[i*src->cols*src->channels() + j*src->channels() + 0] = clamp((298*c+409*e+128)>>8);
            output->data[i*src->cols*src->channels() + j*src->channels() + 1] = clamp((298*c-100*d-208*e+128)>>8);
            output->data[i*src->cols*src->channels() + j*src->channels() + 2] = clamp((298*c+516*d+128)>>8);
        }
    
    return output;
}


// サンプルバッファのデータ（YUV Planar）からCGImageRefを生成する
- (void)willOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
{
    if(!self.shutterTriggered) return;//トリガーが切られるまで待つ
    
    self.shutterTriggered = NO;
    
    //------------------GPUImageのサンプルバッファーはYUV Planar
    CVImageBufferRef imageBuffer =  CMSampleBufferGetImageBuffer(sampleBuffer);
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    
    uint8_t *baseAddress = (uint8_t*)CVPixelBufferGetBaseAddress(imageBuffer);
    
    CVPlanarPixelBufferInfo_YCbCrBiPlanar *bufferInfo = (CVPlanarPixelBufferInfo_YCbCrBiPlanar *)baseAddress;
    
    NSUInteger yOffset = CFSwapInt32BigToHost(bufferInfo->componentInfoY.offset);
    NSUInteger yPitch = CFSwapInt32BigToHost(bufferInfo->componentInfoY.rowBytes);
    
    NSUInteger cbCrOffset = CFSwapInt32BigToHost(bufferInfo->componentInfoCbCr.offset);
    NSUInteger cbCrPitch = CFSwapInt32BigToHost(bufferInfo->componentInfoCbCr.rowBytes);
    
    uint8_t *yBuffer = baseAddress + yOffset;
    uint8_t *cbCrBuffer = baseAddress + cbCrOffset;
    
    cv::Mat *src = new cv::Mat((int)(height), (int)(width), CV_8UC4);
    
    //YUV -> cv::Mat
    
    for(int i = 0; i< (int)height; i++)
    {
        uint8_t *yBufferLine = &yBuffer[i * yPitch];
        uint8_t *cbCrBufferLine = &cbCrBuffer[(i >> 1) * cbCrPitch];
        
        for(int j = 0; j < (int)width; j++)
        {
            uint8_t y = yBufferLine[j];
            uint8_t cb = cbCrBufferLine[j & ~1];
            uint8_t cr = cbCrBufferLine[j | 1];
            
            src->data[i*width*src->channels() + j*src->channels() + 0] = y;
            src->data[i*width*src->channels() + j*src->channels() + 1] = cb;
            src->data[i*width*src->channels() + j*src->channels() + 2] = cr;
        }
    }
    
    
    cv::Mat *output = YUV2RGB(src);
    
    CGColorSpaceRef grayColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(output->data, output->cols, output->rows, 8, output->step, grayColorSpace, kCGImageAlphaNoneSkipLast);
    CGImageRef dstImage = CGBitmapContextCreateImage(context);
    
    UIImage *uiimage = [UIImage imageWithCGImage:dstImage scale:1.0 orientation:UIImageOrientationRight];
    NSData * processedJPEG = [[NSData alloc] initWithData:UIImageJPEGRepresentation(uiimage,0.9)];
    
    CGImageRelease(dstImage);
    CGContextRelease(context);
    CGColorSpaceRelease(grayColorSpace);
    output->release();
    src->release();
    //----------------------
    
    self.processedImage = [self sepiaFilter:[UIImage imageWithData:processedJPEG scale:1.0]];
    
    //測定中止
    [self.videoCamera stopCameraCapture];
    
    [self finishAndProceed];
    
}

- (void)finishAndProceed
{
    dispatch_async(main_queue, ^{
        //撮影済み写真の表示
        for(UIView *subview in self.view.subviews){
            if(subview.tag == 1)[subview removeFromSuperview];
        }
        
        UIImageView *takenPicture = [[UIImageView alloc] initWithFrame:CGRectMake(0, self.screenHeight - 74, 60, 74)];
        takenPicture.contentMode = UIViewContentModeScaleAspectFill;
        takenPicture.image = self.processedImage;
        takenPicture.alpha = 1.0;
        takenPicture.tag = 1;
        [self.view addSubview:takenPicture];
    });
    //カメラロールへ書き出す
    UIImageWriteToSavedPhotosAlbum(self.processedImage, self, nil, nil);
    
    //キャプチャー設定
    //[self initVideoCamera];
    
    //セッションスタート
    [self.videoCamera startCameraCapture];//Start
    
}

- (UIImage *)sepiaFilter:(UIImage *)inputImage
{
    GPUImagePicture *stillImageSource = [[GPUImagePicture alloc] initWithImage:inputImage];
    GPUImageSepiaFilter *stillImageFilter = [[GPUImageSepiaFilter alloc] init];
    
    [stillImageSource addTarget:stillImageFilter];
    [stillImageFilter useNextFrameForImageCapture];
    [stillImageSource processImage];
    
    UIImage *currentFilteredVideoFrame = [stillImageFilter imageFromCurrentFramebufferWithOrientation:inputImage.imageOrientation];
    return currentFilteredVideoFrame;
}


@end
