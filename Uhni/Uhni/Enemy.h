//
//  objectView.h
//  Uhni
//
//  Created by Petr Bursik on 18/11/13.
//  Copyright (c) 2013 Petr Bursik. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIView+Layout.h"
#import "ControlViewController.h"

CGFloat randFloat();
@interface Enemy : NSObject

@property (nonatomic,strong) IBOutlet UIView* view;
@property (nonatomic,assign) int shadedFramesCount;

-(void) incrementByTime:(CGFloat) dt;
-(std::vector<cv::Vec2f>) controlPoints;
-(std::vector<cv::Vec2f>) displayPoints;
-(BOOL) gone;
-(void) remove;
-(int) lives;


@end
