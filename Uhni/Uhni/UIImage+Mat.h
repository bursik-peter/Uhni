//
//  UIImage+FromMat.h
//  Uhni
//
//  Created by burax on 10/29/18.
//  Copyright © 2018 Petr Bursik. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <opencv2/opencv.hpp>

NS_ASSUME_NONNULL_BEGIN

@interface UIImage(Mat)

+(UIImage*) fromMat:(cv::Mat)mat;


@end

NS_ASSUME_NONNULL_END
