//
//  ViewController.m
//  AVFoundationStudy
//
//  Created by Shen,Yan(BBTD) on 2019/2/15.
//  Copyright © 2019 Shen,Yan(BBTD). All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <Photos/Photos.h>

@interface ViewController () <AVCapturePhotoCaptureDelegate>
/**
 捕捉会话
 */
@property (nonatomic, strong) AVCaptureSession *captureSession;
/**
 后置摄像头
 */
@property (nonatomic, strong) AVCaptureDevice *backCamera;
/**
 前置摄像头
 */
@property (nonatomic, strong) AVCaptureDevice *frontCamera;
/**
 设备输出
 */
@property (nonatomic, strong) AVCapturePhotoOutput *deviceOutput;
/**
 设备输入
 */
@property (nonatomic, strong) AVCaptureDeviceInput *deviceInput;
/**
 设备输入
 */
@property (nonatomic, strong) AVCapturePhotoSettings *outputSettings;
/**
 拍照按钮
 */
@property (weak, nonatomic) IBOutlet UIButton *takePhoto;
/**
 切换镜头
 */
@property (weak, nonatomic) IBOutlet UIButton *changeDevice;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self authorizeAndConfiguration];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.captureSession startRunning];
}

- (void)authorizeAndConfiguration
{
    // 相机权限
    AVAuthorizationStatus videoStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (videoStatus == AVAuthorizationStatusRestricted || videoStatus == AVAuthorizationStatusDenied)
    {
        // 没有权限, AVAuthorizationStatusRestricted可能家长控制 AVAuthorizationStatusDenied拒绝权限
        [self showAlertViewWithMessage:@"亲,目前没有相机权限!"];
    }
    [self configuration];
}

- (void)configuration
{
    // 1.创建捕捉会话
    [self createCaptureSession];
    
    // 2.开启后置摄像头配置
    [self createCameraConfigWithSession:self.captureSession];
    
    // 3.预览图层
    [self createPreviewLayer];
    
    // 4.提交会话配置
    [self.captureSession commitConfiguration];
}

- (void)createCaptureSession
{
    AVCaptureSession *captureSession = [[AVCaptureSession alloc] init];
    captureSession.sessionPreset = AVCaptureSessionPreset1280x720;
    [captureSession beginConfiguration];
    self.captureSession = captureSession;
}

- (void)createCameraConfigWithSession:(AVCaptureSession *)session
{
    // 1. 找到硬件设备
    for (AVCaptureDevice *device in AVCaptureDevice.devices)
    {
        if ([device hasMediaType:AVMediaTypeVideo])
        {
            if (device.position == AVCaptureDevicePositionBack)
            {
                // 找到后置摄像
                self.backCamera = device;
            }
            
            if (device.position == AVCaptureDevicePositionFront)
            {
                // 找到前置摄像
                self.frontCamera = device;
            }
        }
    }
    
    // 2. 配置输入和输出设置
    // 2.1 配置输入
    NSError *inputError = nil;
    AVCaptureDeviceInput *deviceInput = [[AVCaptureDeviceInput alloc] initWithDevice:self.backCamera error:&inputError];
    if (inputError)
    {
        [self showAlertViewWithMessage:inputError.domain];
        return;
    }
    ![session canAddInput:deviceInput] ?: [session addInput:deviceInput];
    self.deviceInput = deviceInput;
    
    // 2.2 配置输出
    AVCapturePhotoOutput *deviceOutput = [[AVCapturePhotoOutput alloc] init];
    NSDictionary *setDic = @{AVVideoCodecKey:AVVideoCodecTypeJPEG};
    self.outputSettings = [AVCapturePhotoSettings photoSettingsWithFormat:setDic];
    [deviceOutput setPhotoSettingsForSceneMonitoring:self.outputSettings];
    ![session canAddOutput:deviceOutput] ?: [session addOutput:deviceOutput];
    self.deviceOutput = deviceOutput;

    AVCaptureConnection *captureConnection = [deviceOutput connectionWithMediaType:AVMediaTypeVideo];
    //视频旋转方向设置
    captureConnection.videoScaleAndCropFactor = captureConnection.videoMaxScaleAndCropFactor;
    //视频稳定设置
    if ([captureConnection isVideoStabilizationSupported])
    {
        captureConnection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeAuto;
    }
}

- (void)createPreviewLayer
{
    AVCaptureVideoPreviewLayer *previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.captureSession];
    [previewLayer setVideoGravity:AVLayerVideoGravityResizeAspect];
    previewLayer.frame = self.view.frame;
    [self.view.layer insertSublayer:previewLayer atIndex:0];
}

#pragma mark - Action

- (IBAction)click:(UIButton *)sender
{
    [self.captureSession stopRunning];
    [self.deviceOutput capturePhotoWithSettings:self.outputSettings delegate:self];
}

- (IBAction)changeCamera:(UIButton *)sender
{
    [self.captureSession stopRunning];
    [self.captureSession removeInput:self.deviceInput];
    if (self.deviceInput.device == self.backCamera)
    {
        self.deviceInput = [[AVCaptureDeviceInput alloc] initWithDevice:self.frontCamera error:nil];
    }
    else
    {
        self.deviceInput = [[AVCaptureDeviceInput alloc] initWithDevice:self.backCamera error:nil];
    }
    ![self.captureSession canAddInput:self.deviceInput] ?: [self.captureSession addInput:self.deviceInput];
    [self.captureSession startRunning];
}

#pragma mark - AVCapturePhotoOutputDelegate
- (void)captureOutput:(AVCapturePhotoOutput *)output willBeginCaptureForResolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings
{
    NSLog(@"%s",__func__);
}

- (void)captureOutput:(AVCapturePhotoOutput *)output didCapturePhotoForResolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings
{
    NSLog(@"%s",__func__);
}

- (void)captureOutput:(AVCapturePhotoOutput *)output didFinishProcessingPhoto:(AVCapturePhoto *)photo error:(nullable NSError *)error
{
    // 完成处理图片, 存入相册
    // 判断是否有相册权限
//    PHAuthorizationStatus authorStatus = [PHPhotoLibrary authorizationStatus];
//    if (authorStatus == PHAuthorizationStatusRestricted || authorStatus == PHAuthorizationStatusDenied)
//    {
//        NSString *errorStr = @"没有使用相册权限,请设置info.plist文件";
//        [self showAlertViewWithMessage:errorStr];
//        return;
//    }
   
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus authorStatus) {
        if (authorStatus == PHAuthorizationStatusRestricted || authorStatus == PHAuthorizationStatusDenied)
        {
            NSString *errorStr = @"没有使用相册权限,请设置info.plist文件";
            [self showAlertViewWithMessage:errorStr];
            return;
        }

        NSData *data = photo.fileDataRepresentation;
        UIImage *image = [UIImage imageWithData:data];
        
        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
            [PHAssetChangeRequest creationRequestForAssetFromImage:image];
        } completionHandler:^(BOOL success, NSError * _Nullable error) {
            if (success)
            {
                [self.captureSession startRunning];
            }
        }];
    }];
}

#pragma mark - Alert
- (void)showAlertViewWithMessage:(NSString *)message
{
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"提示" message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *ensureAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    
    [alertVC addAction:ensureAction];
    [alertVC addAction:cancelAction];
    
    [self presentViewController:alertVC animated:YES completion:nil];
}
@end
