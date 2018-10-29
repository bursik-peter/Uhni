//
//  ControlViewController.h
//  Uhni
//
//  Created by Petr Bursik on 18/11/13.
//  Copyright (c) 2013 Petr Bursik. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreMedia/CoreMedia.h>
#import <AVFoundation/AVFoundation.h>

#import "Enemy.h"

@class GameViewController;
@interface ControlViewController : UIViewController

@property (nonatomic,strong) GameViewController* gameViewController;

-(BOOL)isObjectViewVisible:(std::vector<cv::Vec2f>)controlPoints;
-(void)displayObjectsPoints:(NSArray*) objectViews;

@end
