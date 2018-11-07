//
//  ControlViewController.m
//  Uhni
//
//  Created by Petr Bursik on 18/11/13.
//  Copyright (c) 2013 Petr Bursik. All rights reserved.
//

#import <opencv2/opencv.hpp>
#import <opencv2/imgproc.hpp>
#import <vector>
#import <AVFoundation/AVFoundation.h>

#import "ControlViewController.h"
#import "GameViewController.h"
#import "UIImageView+CoordinateTransform.h"
#import "UIImage+Mat.h"

#import <opencv2/imgcodecs/ios.h>



#define BORDER_INSET_ERROR 0


@interface ControlViewController ()<AVCaptureVideoDataOutputSampleBufferDelegate>
{
    IBOutlet UIImageView *_imageView;
    __weak IBOutlet UISlider *_thresholdSlider;
    __weak IBOutlet UISlider *_focusSlider;
    BOOL _transform;
    BOOL _calibrating;
    
    CGPoint _panCorners[4];
    CGFloat _lensPosition;
    
    AVCaptureDevice* _cam;
    
    cv::Mat _mat;
    cv::Mat _referenceMat;
    cv::Mat _transmtx;
    
    CAShapeLayer* _warpedDestQuadLayer;
    
    CGRect _destFrame;// Corners of the destination image
    std::vector<cv::Point2f> _dest_corners;
    cv::Mat _destMat;

    
    NSArray* _displayEnemyLayers;
    
    BOOL _gameInitialized;
}

@property (strong,nonatomic) AVCaptureSession* captureSession;

@property BOOL calibrating;

@end

@implementation ControlViewController

- (void)viewDidLoad
{

    [super viewDidLoad];
    
    [self createAVSession];
    [self loadCalibrationFromDefaults];
    [self updateAndShowWarpedDestQuadLayer];
    
    _transform = NO;
    self.calibrating = NO;
    _gameInitialized = NO;
    
    // Do any additional setup after loading the view.
}

-(void)gameDidLayoutSubviews:(GameViewController *)gameViewController
{
    if(!_gameInitialized) {
        [self captureReferenceAndStartGame];
        _gameInitialized = YES;
    }
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
    
}

-(void) saveCalibrationToDefaults {
    [[NSUserDefaults standardUserDefaults] setObject:@[@[@(_panCorners[0].x),@(_panCorners[0].y)],
                                                       @[@(_panCorners[1].x),@(_panCorners[1].y)],
                                                       @[@(_panCorners[2].x),@(_panCorners[2].y)],
                                                       @[@(_panCorners[3].x),@(_panCorners[3].y)]]
                                              forKey:@"corners"];
    
    [[NSUserDefaults standardUserDefaults] setFloat:_lensPosition forKey:@"lensPosition"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


-(void)dealloc {
    [_cam unlockForConfiguration];
}

-(BOOL)calibrating {
    return _calibrating;
}

- (void)setCalibrating:(BOOL)calibrating {
    _calibrating = calibrating;
    
    _imageView.userInteractionEnabled = calibrating;
    _thresholdSlider.hidden = !calibrating;
    
    if(calibrating){
        [self updateAndShowWarpedDestQuadLayer];
    }
    else {
        _warpedDestQuadLayer.opacity = 0.5;
    }
}



-(void) updateAndShowWarpedDestQuadLayer {
    
    [_warpedDestQuadLayer removeFromSuperlayer];
    _warpedDestQuadLayer = [[CAShapeLayer alloc] init];
    _warpedDestQuadLayer.frame = _imageView.bounds;
    _warpedDestQuadLayer.strokeColor = [UIColor clearColor].CGColor;
    _warpedDestQuadLayer.fillColor = [UIColor colorWithRed:0 green:0.5 blue:1.0 alpha:0.5].CGColor;
    UIBezierPath *rectPath = [UIBezierPath bezierPath];
    [rectPath moveToPoint:_panCorners[0]];
    [rectPath addLineToPoint:_panCorners[1]];
    [rectPath addLineToPoint:_panCorners[2]];
    [rectPath addLineToPoint:_panCorners[3]];
    [rectPath closePath];
    
    _warpedDestQuadLayer.path = rectPath.CGPath;
    [_imageView.layer addSublayer:_warpedDestQuadLayer];
}

-(void) calculateTransformationMatrix {
    std::vector<cv::Point2f> pixelSpaceSourceCorners;
    
    _destFrame = CGRectMake(0, 0, (int)(_gameViewController.view.frame.size.width), (int)(_gameViewController.view.frame.size.height));
    _dest_corners.clear();
    _dest_corners.push_back(cv::Point2f(CGRectGetMinX(_destFrame), CGRectGetMinY(_destFrame)));
    _dest_corners.push_back(cv::Point2f(CGRectGetMaxX(_destFrame), CGRectGetMinY(_destFrame)));
    _dest_corners.push_back(cv::Point2f(CGRectGetMaxX(_destFrame), CGRectGetMaxY(_destFrame)));
    _dest_corners.push_back(cv::Point2f(CGRectGetMinX(_destFrame), CGRectGetMaxY(_destFrame)));
    
    pixelSpaceSourceCorners.push_back(vecPoint([_imageView pixelPointFromViewPoint:_panCorners[0]]));
    pixelSpaceSourceCorners.push_back(vecPoint([_imageView pixelPointFromViewPoint:_panCorners[1]]));
    pixelSpaceSourceCorners.push_back(vecPoint([_imageView pixelPointFromViewPoint:_panCorners[2]]));
    pixelSpaceSourceCorners.push_back(vecPoint([_imageView pixelPointFromViewPoint:_panCorners[3]]));
    _transmtx = cv::getPerspectiveTransform(_dest_corners,pixelSpaceSourceCorners);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    NSLog(@"mamory warning");// Dispose of any resources that can be recreated.
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

#pragma mark -
#pragma mark Actions

- (IBAction)onToggleCalibrationPause:(UIButton*)sender {
    
    BOOL paused = !sender.selected;
    
    sender.selected = paused;
    self.calibrating = paused;
    
    if(paused){
        [_displayEnemyLayers makeObjectsPerformSelector:@selector(removeFromSuperlayer)];
        _displayEnemyLayers = nil;
        _gameViewController.paused = YES;
    } else {
        [self captureReferenceAndStartGame];
    }
}

-(void) captureReferenceAndStartGame{
    [self saveCalibrationToDefaults];
    [_gameViewController showReference];
    
    if(_mat.empty())
    {
        //should happen only in test mode
        _gameViewController.paused = NO;
        return;
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        _mat.copyTo(_referenceMat);
        
        
        cv::Mat edges = cv::Mat::zeros(_mat.rows, _mat.cols, CV_8U);
        //_mat.convertTo(edges, CV_32F);
        
        cv::blur(_mat, edges, cv::Size(3,3));
        cv::Canny(edges, edges, 50.0, 200.0);
        
        std::vector<std::vector<cv::Point>> countours;
        std::vector<cv::Vec4i> temp;
        
        cv::floodFill(edges, cv::Point(edges.cols/2,edges.rows/2), 255);
        cv::findContours(edges, countours, temp, cv::RETR_EXTERNAL, cv::CHAIN_APPROX_TC89_KCOS);

        std::vector<cv::Point> finalRectangle;
        
        double maxArea = 0.0;
        for(auto i = countours.begin(); i<countours.end(); i++)
        {
            std::vector<cv::Point> approxCurve;
            
            cv::approxPolyDP((*i), approxCurve, 2.0, true);
            
            
            if(approxCurve.size()!=4) continue;
            
            double curveArea = cv::moments(approxCurve).m00;
            if(curveArea > maxArea)
            {
                finalRectangle = approxCurve;
                maxArea = curveArea;
            }
        }
        
        if(!finalRectangle.empty()) {
            
            //map the contour to the final rect (start at top left and go counterclockwise)
            
            //order
            //calculate vector product to test if the first two sides of the rectangle turn "right" (clockwise)
            cv::Vec2i a = cv::Vec2i(finalRectangle[1].x-finalRectangle[0].x,finalRectangle[1].y-finalRectangle[0].y);
            cv::Vec2i b = cv::Vec2i(finalRectangle[2].x-finalRectangle[1].x,finalRectangle[2].y-finalRectangle[1].y);
            //coordinate system is flipped vertically, so clockwise actually means the vector product is positive
            if(a[0]*b[1]-a[1]*b[0] < 0) {
                //if negative we need to reverse the points
                std::reverse(finalRectangle.begin(), finalRectangle.end());
            }
            
            //orientation - shift the points so that we start with the top left (x+y is the lowest there)
            auto topLeft = finalRectangle.begin();
            for(auto i = finalRectangle.begin()+1;i<finalRectangle.end();i++) {
                if(i->x+i->y < topLeft->x+topLeft->y ) {
                    topLeft = i;
                }
            }
            std::rotate(finalRectangle.begin(), topLeft, finalRectangle.end());
            
            //transform to view coordinatest
            for(int i = 0; i<4; i++) {
                _panCorners[i] = [_imageView viewPointFromPixelPoint:CGPointMake(finalRectangle[i].x, finalRectangle[i].y)];
            }
            
            [self calculateTransformationMatrix];
            [self updateAndShowWarpedDestQuadLayer];
            [self saveCalibrationToDefaults];
        }

        _gameViewController.paused = NO;
    });
}

- (IBAction)onTransform:(id)sender {
    _transform = !_transform;
}

- (IBAction)onTestGameVC:(id)sender {
    self.calibrating = NO;
    _gameViewController = [[GameViewController alloc] initWithNibName:nil bundle:nil];
    [self addChildViewController:_gameViewController];
    _gameViewController.control = self;
    _gameViewController.view.frame = self.view.bounds;
    [self.view addSubview:_gameViewController.view];
    
    
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
    
    
    if(!_calibrating) {
        [_gameViewController onControlCapturedCamFrame];
    }
    
    cv::Mat matToDisplay;
    
    if(_transform && !_calibrating)
    {
        if(_destMat.empty())
        {
            _destMat = cv::Mat::zeros(_destFrame.size.height,_destFrame.size.width, CV_8UC1);
        }
        
        //Apply perspective transformation
        cv::warpPerspective(_mat, _destMat, _transmtx, _destMat.size(), CV_WARP_INVERSE_MAP);
        
        matToDisplay = _destMat;
    } else if(_calibrating || _referenceMat.empty()){
        matToDisplay = _mat;
    } else {
        matToDisplay = (_mat-(_referenceMat/5*4-8))*255;
    }
    
    if(!matToDisplay.empty()) {
        UIImage* i = [UIImage fromMat:matToDisplay];
        dispatch_async(dispatch_get_main_queue(), ^{
            _imageView.image = i;
        });
    }
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
}

#pragma mark -
#pragma mark GameViewControllerDelegate


-(BOOL)isObjectViewVisible:(std::vector<cv::Vec2f>) controlPoints {
    
    if(_referenceMat.empty()) return YES;
    
    std::vector<cv::Vec2f> camFrameControlPoints;
    cv::perspectiveTransform(controlPoints, camFrameControlPoints, _transmtx);
    if(camFrameControlPoints.empty()) return YES;
    
    for(std::vector<cv::Vec2f>::iterator i = camFrameControlPoints.begin();i!=camFrameControlPoints.end();i++)
    {
        int current = _mat.at<unsigned char>((*i)[1],(*i)[0]);
        int orig = _referenceMat.at<unsigned char>((*i)[1],(*i)[0]);
        
        if(current < (orig*0.8)-8) return NO;
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

#pragma mark -
#pragma mark Calibrations


- (IBAction)focusSliderValueChanged:(UISlider*)sender {
    _lensPosition = sender.value;
    [_cam setFocusModeLockedWithLensPosition:_lensPosition completionHandler:^(CMTime syncTime) {
        
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


@end
