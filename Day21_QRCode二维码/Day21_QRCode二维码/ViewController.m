//
//  ViewController.m
//  Day21_QRCode二维码
//
//  Created by HLJ on 16/2/26.
//  Copyright © 2016年 tarena. All rights reserved.
//

#import "ViewController.h"

@import AVFoundation;

@interface ViewController ()<AVCaptureMetadataOutputObjectsDelegate>
@property (weak, nonatomic) IBOutlet UIImageView *iv;
//管道
@property (nonatomic) AVCaptureSession *session;
//用于显示输出流的视图
@property (nonatomic) AVCaptureVideoPreviewLayer *layer;
@end

@implementation ViewController
#pragma mark - AVCaptureMetadataOutputObjectsDelegate
//当捕获到二维码时触发
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection {
    if (metadataObjects.count > 0) {
        AVMetadataMachineReadableCodeObject *obj = metadataObjects.firstObject;
        NSLog(@"%@",obj.stringValue);
        //关闭管道
        [_session stopRunning];
        //删除摄像内容
        [_layer removeFromSuperlayer];
        
        //扫到http开头的自动打开网页
        if ([obj.stringValue containsString:@"http"]) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:obj.stringValue]];
        }
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _iv.image = [self createQRCode:@"http://www.baidu.com/"];
}
- (IBAction)scanQRCode:(id)sender {
    /** 1.打开手机的后置摄像头
     2.通过摄像头读取数据流(输入流)
     3.搭建一个管道.输入流通过管道输出到屏幕上(输出流)
     4.在输出时, 不断检测输出的内容, 如果检测到有 二维码/条形码则通过代理方法通知我们
     */
    NSError *error = nil;
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
    if (error) {
        NSLog(@"error %@", error);
        return;
    }
    AVCaptureMetadataOutput *output = [AVCaptureMetadataOutput new];
    [output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    _session = [AVCaptureSession new];
    //设置传输质量
    [_session setSessionPreset:AVCaptureSessionPresetHigh];
    [_session addOutput:output];
    [_session addInput:input];
    //设置输出流监听的数据类型, 这个代码必须在管道连接完毕以后写, 否则崩溃
    output.metadataObjectTypes = @[AVMetadataObjectTypeQRCode,
                                   AVMetadataObjectTypeEAN13Code,
                                   AVMetadataObjectTypeEAN8Code,
                                   AVMetadataObjectTypeCode128Code];
    _layer = [AVCaptureVideoPreviewLayer layerWithSession:_session];
    _layer.frame = self.view.frame;
    [self.view.layer addSublayer:_layer];
    //启动管道
    [_session startRunning];
}

//生成二维码
- (UIImage *)createQRCode:(NSString *)code {
    NSData *codeData = [code dataUsingEncoding:NSUTF8StringEncoding];
    //过滤器
    CIFilter *filter = [CIFilter filterWithName:@"CIQRCodeGenerator"];
    [filter setValue:codeData forKey:@"inputMessage"];
    //拿到传出的图片
    CIImage *ciImg = filter.outputImage;
    
    return [UIImage imageWithCIImage:ciImg];
}

@end
