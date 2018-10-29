//
//  ControlViewController.m
//  Uhni
//
//  Created by Petr Bursik on 18/11/13.
//  Copyright (c) 2013 Petr Bursik. All rights reserved.
//

#import <opencv2/opencv.hpp>
#import <vector>
#import <AVFoundation/AVFoundation.h>

#import "ControlViewController.h"
#import "GameViewController.h"
#import "UIImageView+CoordinateTransform.h"




#define BORDER_INSET_ERROR 0


@interface ControlViewController ()<AVCaptureVideoDataOutputSampleBufferDelegate>
{
    IBOutlet UIImageView *_imageView;
    __weak IBOutlet UISlider *_thresholdSlider;
    __weak IBOutlet UISlider *_focusSlider;
    BOOL _calibrating;
    BOOL _transform;
    BOOL _applyThreshold;
    
    CGPoint _panCorners[4];
    CGFloat _shadowThreshold;
    CGFloat _lensPosition;
    
    AVCaptureDevice* _cam;
    
    cv::Mat _mat;
    cv::Mat _transmtx;
    
    CAShapeLayer* _warpedDestQuadLayer;
    
    CGRect _destFrame;// Corners of the destination image
    std::vector<cv::Point2f> _dest_corners;
    cv::Mat _destMat;
    
    NSArray* _displayEnemyLayers;
}

@property (strong,nonatomic) AVCaptureSession* captureSession;

@end

@implementation ControlViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self createAVSession];
    [self onCalibrate:nil];
    [self loadCalibrationFromDefaults];
    
    _transform = NO;
    _applyThreshold = YES;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if(_gameViewController)
        {
            [self onDoneCalibrating:nil];
        }
    });
    
    // Do any additional setup after loading the view.
    
}

- (IBAction)thresholdValueChanged:(UISlider *)sender {
    _shadowThreshold = sender.value;
}

- (IBAction)focusSliderValueChanged:(UISlider*)sender {
    [_cam setFocusModeLockedWithLensPosition:sender.value completionHandler:^(CMTime syncTime) {
        
    }];
}

- (IBAction)onPan:(UIPanGestureRecognizer*)sender
{
    CGPoint p = [sender locationInView:_imageView];
    CGPoint d = [sender translationInView:_imageView];
    CGPoint s = CGPointMake(p.x-d.x, p.y-d.y);
    
    bool left = s.x > (_imageView.bounds.size.width/2.0) ? NO:YES;
    bool top = s.y > (_imageView.bounds.size.height/2.0) ? NO:YES;
    
    p.x+=left?-30:30;
    
    _panCorners[left ? (top ? 0 : 3) : (top ? 1 : 2) ] = p;
    
    [self updateAndShowWarpedDestQuadLayer];
}

- (void) loadCalibrationFromDefaults {
    NSArray* storedCorners = [[NSUserDefaults standardUserDefaults] arrayForKey:@"corners"];
    if(storedCorners)
    {
        _panCorners[0] = CGPointMake([storedCorners[0][0] floatValue],[storedCorners[0][1] floatValue]);
        _panCorners[1] = CGPointMake([storedCorners[1][0] floatValue],[storedCorners[1][1] floatValue]);
        _panCorners[2] = CGPointMake([storedCorners[2][0] floatValue],[storedCorners[2][1] floatValue]);
        _panCorners[3] = CGPointMake([storedCorners[3][0] floatValue],[storedCorners[3][1] floatValue]);
    }
    else
    {
        //default values are the image view corners
        _panCorners[0] = CGPointMake(0,0);
        _panCorners[1] = CGPointMake(_imageView.bounds.size.width,0);
        _panCorners[2] = CGPointMake(_imageView.bounds.size.width,_imageView.bounds.size.height);
        _panCorners[3] = CGPointMake(0,_imageView.bounds.size.height);
    }
    
    NSNumber* lensPositionVal = [[NSUserDefaults standardUserDefaults] valueForKey:@"lensPosition"];
    _lensPosition = lensPositionVal ? lensPositionVal.floatValue : 0.5;
    [_focusSlider setValue:_lensPosition animated:NO];
    [_cam setFocusModeLockedWithLensPosition:_lensPosition completionHandler:^(CMTime syncTime) {}];
    
    
    NSNumber* thresholdVal = [[NSUserDefaults standardUserDefaults] valueForKey:@"shadowThreshold"];
    _shadowThreshold = thresholdVal ? thresholdVal.integerValue : 128;
    [_thresholdSlider setValue:_shadowThreshold animated:NO];
}

-(void) saveCalibrationToDefaults {
    [[NSUserDefaults standardUserDefaults] setObject:@[@[@(_panCorners[0].x),@(_panCorners[0].y)],
                                                       @[@(_panCorners[1].x),@(_panCorners[1].y)],
                                                       @[@(_panCorners[2].x),@(_panCorners[2].y)],
                                                       @[@(_panCorners[3].x),@(_panCorners[3].y)]]
                                              forKey:@"corners"];
    
    [[NSUserDefaults standardUserDefaults] setFloat:_lensPosition forKey:@"lensPosition"];
    [[NSUserDefaults standardUserDefaults] setFloat:_shadowThreshold forKey:@"shadowThreshold"];
    
    [[NSUserDefaults standardUserDefaults] synchronize];
}


-(void)dealloc {
    [_cam unlockForConfiguration];
}



- (IBAction)onCalibrate:(id)sender {
    _imageView.userInteractionEnabled = YES;
    _gameViewController.calibrating = YES;
    _calibrating = YES;
    _thresholdSlider.hidden = NO;
    
    [_displayEnemyLayers makeObjectsPerformSelector:@selector(removeFromSuperlayer)];
    _displayEnemyLayers = nil;
    
    
    [self updateAndShowWarpedDestQuadLayer];
}

- (IBAction)onTransform:(id)sender {
    _transform = !_transform;
}
- (IBAction)onThreshold:(id)sender {
    _applyThreshold = !_applyThreshold;
}

-(void) updateAndShowWarpedDestQuadLayer {
    
    [_warpedDestQuadLayer removeFromSuperlayer];
    _warpedDestQuadLayer = [[CAShapeLayer alloc] init];
    _warpedDestQuadLayer.frame = _imageView.bounds;
    _warpedDestQuadLayer.strokeColor = [UIColor redColor].CGColor;
    _warpedDestQuadLayer.fillColor = [UIColor clearColor].CGColor;
    _warpedDestQuadLayer.lineWidth = 3;
    UIBezierPath *rectPath = [UIBezierPath bezierPath];
    [rectPath moveToPoint:_panCorners[0]];
    [rectPath addLineToPoint:_panCorners[1]];
    [rectPath addLineToPoint:_panCorners[2]];
    [rectPath addLineToPoint:_panCorners[3]];
    [rectPath closePath];
    
    _warpedDestQuadLayer.path = rectPath.CGPath;
    [_imageView.layer addSublayer:_warpedDestQuadLayer];
}

- (IBAction)onDoneCalibrating:(id)sender {
    
    

    
    if(!_calibrating) return;
    
    _warpedDestQuadLayer.opacity = 0.5;
    
    [self saveCalibrationToDefaults];
    
    _calibrating = NO;
    _imageView.userInteractionEnabled = NO;
    _thresholdSlider.hidden = YES;
    _gameViewController.calibrating = NO;
    
    _destFrame = CGRectMake(0, 0, (int)(_gameViewController.view.frame.size.width), (int)(_gameViewController.view.frame.size.height));
    _dest_corners.clear();
    _dest_corners.push_back(cv::Point2f(CGRectGetMinX(_destFrame), CGRectGetMinY(_destFrame)));
    _dest_corners.push_back(cv::Point2f(CGRectGetMaxX(_destFrame), CGRectGetMinY(_destFrame)));
    _dest_corners.push_back(cv::Point2f(CGRectGetMaxX(_destFrame), CGRectGetMaxY(_destFrame)));
    _dest_corners.push_back(cv::Point2f(CGRectGetMinX(_destFrame), CGRectGetMaxY(_destFrame)));
    
    _destMat = cv::Mat::zeros(_destFrame.size.height,_destFrame.size.width, CV_8UC1);
    
    // Get transformation matrix
    
    [self calculateTransformationMatrix];
}

- (IBAction)onTestGameVC:(id)sender {
    _gameViewController = [[GameViewController alloc] initWithNibName:nil bundle:nil];
    [self addChildViewController:_gameViewController];
    _gameViewController.control = self;
    _gameViewController.view.frame = self.view.bounds;
    [self.view addSubview:_gameViewController.view];
}

-(void) calculateTransformationMatrix {
    std::vector<cv::Point2f> pixelSpaceSourceCorners;
    
    pixelSpaceSourceCorners.clear();
    pixelSpaceSourceCorners.push_back(vecPoint([_imageView pixelPointFromViewPoint:_panCorners[0]]));
    pixelSpaceSourceCorners.push_back(vecPoint([_imageView pixelPointFromViewPoint:_panCorners[1]]));
    pixelSpaceSourceCorners.push_back(vecPoint([_imageView pixelPointFromViewPoint:_panCorners[2]]));
    pixelSpaceSourceCorners.push_back(vecPoint([_imageView pixelPointFromViewPoint:_panCorners[3]]));
    _transmtx = cv::getPerspectiveTransform(_dest_corners,pixelSpaceSourceCorners);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) createAVSession
{
    _cam = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
//    NSArray *videoDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
//    for (AVCaptureDevice *device in videoDevices)
//    {
//        if (device.position == AVCaptureDevicePositionFront)
//        {
//            cam = device;
//            break;
//        }
//    }
    
    [_cam lockForConfiguration:nil];
    _cam.focusMode = AVCaptureFocusModeLocked;
    _cam.exposureMode = AVCaptureExposureModeLocked;   
    
    AVCaptureDeviceInput *captureInput = [AVCaptureDeviceInput
                                          deviceInputWithDevice:_cam
                                          error:nil];
    AVCaptureVideoDataOutput *captureOutput = [[AVCaptureVideoDataOutput alloc] init];
    captureOutput.alwaysDiscardsLateVideoFrames = YES;
    
    dispatch_queue_t queue;
    queue = dispatch_queue_create("cameraQueue", NULL);
    [captureOutput setSampleBufferDelegate:self queue:queue];
    // Set the video output to store frame in BGRA (It is supposed to be faster)
    
    NSString* key = (NSString*)kCVPixelBufferPixelFormatTypeKey;
    NSNumber* value = [NSNumber numberWithUnsignedInt:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange];
    NSDictionary* videoSettings = [NSDictionary dictionaryWithObject:value forKey:key];
    [captureOutput setVideoSettings:videoSettings];
    /*And we create a capture session*/
    self.captureSession = [[AVCaptureSession alloc] init];
    /*We add input and output*/
    
    if(captureInput && captureOutput) {
        [self.captureSession addInput:captureInput];
        [self.captureSession addOutput:captureOutput];
    }
    
    [self.captureSession setSessionPreset:AVCaptureSessionPresetMedium];
    
    
    /*We start the capture*/
    
    //processedImageData = nil;
    
    /*for(AVCaptureConnection* c in captureOutput.connections)
    {
        //c.videoOrientation = AVCaptureVideoOrientationPortrait;
    }*/
    
    [self.captureSession startRunning];
    
}


cv::Point2f computeIntersect(cv::Vec4i a, cv::Vec4i b)
{
    int x1 = a[0], y1 = a[1], x2 = a[2], y2 = a[3];
    int x3 = b[0], y3 = b[1], x4 = b[2], y4 = b[3];
    
    if (float d = ((float)(x1-x2) * (y3-y4)) - ((y1-y2) * (x3-x4)))
    {
        cv::Point2f pt;
        pt.x = ((x1*y2 - y1*x2) * (x3-x4) - (x1-x2) * (x3*y4 - y3*x4)) / d;
        pt.y = ((x1*y2 - y1*x2) * (y3-y4) - (y1-y2) * (x3*y4 - y3*x4)) / d;
        return pt;
    }
    else
        return cv::Point2f(-1, -1);
}

CGFloat lengthSquared(cv::Vec4f l)
{
    return (l[2]-l[0])*(l[2]-l[0]) + (l[3]-l[1])*(l[3]-l[1]);
}

CGPoint point(cv::Vec2f p)
{
    return CGPointMake(p[0], p[1]);
}

cv::Vec2f vecPoint(CGPoint p)
{
    return cv::Vec2f(p.x,p.y);
}

std::vector<cv::Vec2f> vecFromArray(NSArray* pointArray)
{
    std::vector<cv::Vec2f> result;
    for(NSValue* v in pointArray) {
        result.push_back(vecPoint([v CGPointValue]));
    }
    return result;
}


#pragma mark -
#pragma mark AVCaptureSession delegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection
{
    
    
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    OSType format = CVPixelBufferGetPixelFormatType(pixelBuffer);
    
    // Set the following dict on AVCaptureVideoDataOutput's videoSettings to get YUV output
    // @{ kCVPixelBufferPixelFormatTypeKey : kCVPixelFormatType_420YpCbCr8BiPlanarFullRange }
    
    NSAssert(format == kCVPixelFormatType_420YpCbCr8BiPlanarFullRange, @"Only YUV is supported");
    
    // The first plane / channel (at index 0) is the grayscale plane
    // See more infomation about the YUV format
    // http://en.wikipedia.org/wiki/YUV
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    void *baseaddress = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
    
    size_t width = CVPixelBufferGetWidth(pixelBuffer);
    size_t height = CVPixelBufferGetHeight(pixelBuffer);
    
    _mat = cv::Mat((int)height, (int)width, CV_8UC1, baseaddress, CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0));
    
    if(_applyThreshold) {
        cv::threshold(_mat, _mat,_shadowThreshold, 255, cv::THRESH_BINARY);
    }
    
    if(!_calibrating) {
        [_gameViewController onControlCapturedCamFrame];
    }
    
    if(_transform && !_calibrating)
    {
        //Apply perspective transformation
        cv::warpPerspective(_mat, _destMat, _transmtx, _destMat.size(), CV_WARP_INVERSE_MAP);
        
        UIImage* i = [self UIImageFromCVMat:_destMat];
        dispatch_sync(dispatch_get_main_queue(), ^{
            _imageView.image = i;
        });
    } else {
        UIImage* i = [self UIImageFromCVMat:_mat];
        dispatch_async(dispatch_get_main_queue(), ^{
            _imageView.image = i;
        });
    }
    
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);

}

-(BOOL)isObjectViewVisible:(std::vector<cv::Vec2f>) controlPoints {
    
    std::vector<cv::Vec2f> camFrameControlPoints;
    cv::perspectiveTransform(controlPoints, camFrameControlPoints, _transmtx);
    if(camFrameControlPoints.empty()) return YES;
    
    for(std::vector<cv::Vec2f>::iterator i = camFrameControlPoints.begin();i!=camFrameControlPoints.end();i++)
    {
        if(_mat.at<unsigned char>((*i)[1],(*i)[0])<_shadowThreshold) return NO;
    }
    return YES;
}

-(void)displayObjectsPoints:(NSArray*) enemies;
{
    [_displayEnemyLayers makeObjectsPerformSelector:@selector(removeFromSuperlayer)];
    NSMutableArray* displayLayersMutable = [[NSMutableArray alloc] init];
    
    
    for(Enemy* enemy in [enemies copy])
    {
        
        CAShapeLayer* l;
        [l removeFromSuperlayer];
        l = [[CAShapeLayer alloc] init];
        [_imageView.layer addSublayer:l];
        l.frame = _imageView.bounds;
        l.strokeColor = [UIColor blueColor].CGColor;
        l.fillColor = [UIColor clearColor].CGColor;
        l.lineWidth = 3;
        
        UIBezierPath *rectPath = [UIBezierPath bezierPath];
        
        std::vector<cv::Vec2f> displayPoints;
        cv::perspectiveTransform(enemy.displayPoints, displayPoints, _transmtx);
        if(displayPoints.size()<2) continue;
        
        [rectPath moveToPoint:[_imageView viewPointFromPixelPoint:point(*(displayPoints.end()-1))]];
        for(std::vector<cv::Vec2f>::iterator i = displayPoints.begin();i!=displayPoints.end();i++)
        {
            [rectPath addLineToPoint:[_imageView viewPointFromPixelPoint:point(*i)]];
        }
        
        l.path = rectPath.CGPath;
        
        [displayLayersMutable addObject:l];
        [_imageView.layer addSublayer:l];
    }
    
    _displayEnemyLayers = [NSArray arrayWithArray:displayLayersMutable];
    
}

-(UIImage *)UIImageFromCVMat:(cv::Mat)cvMat
{
    NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize()*cvMat.rows*cvMat.step[0]];
    CGColorSpaceRef colorSpace;
    
    if (cvMat.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    // Creating CGImage from cv::Mat
    CGImageRef imageRef = CGImageCreate(cvMat.cols,                                 //width
                                        cvMat.rows,                                 //height
                                        8,                                          //bits per component
                                        8 * cvMat.elemSize(),                       //bits per pixel
                                        cvMat.step[0],                              //bytesPerRow
                                        colorSpace,                                 //colorspace
                                        kCGImageAlphaNone|kCGBitmapByteOrderDefault,// bitmap info
                                        provider,                                   //CGDataProviderRef
                                        NULL,                                       //decode
                                        false,                                      //should interpolate
                                        kCGRenderingIntentDefault                   //intent
                                        );
    
    
    // Getting UIImage from CGImage
    UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return finalImage;
}


@end
