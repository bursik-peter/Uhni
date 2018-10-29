//
//  objectView.m
//  Uhni
//
//  Created by Petr Bursik on 18/11/13.
//  Copyright (c) 2013 Petr Bursik. All rights reserved.
//

#import "Enemy.h"

#define ARC4RANDOM_MAX      0x100000000
CGFloat randFloat() {return ((CGFloat)arc4random())/(CGFloat)ARC4RANDOM_MAX;}

@implementation Enemy

- (instancetype)init
{
    self = [super init];
    if (self) {
        _shadedFramesCount = 0;
    }
    return self;
}

-(void)incrementByTime:(CGFloat)dt
{
    
}

-(std::vector<cv::Vec2f>) controlPoints
{
    std::vector<cv::Vec2f> res;
    return res;
}

-(std::vector<cv::Vec2f>) displayPoints
{
    std::vector<cv::Vec2f> res;
    return res;
}

-(BOOL)gone
{
    return NO;
}

-(void)remove
{
    [_view removeFromSuperview];
}

- (int)lives
{
    return -1;
}

@end
