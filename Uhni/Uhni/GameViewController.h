//
//  ViewController.h
//  Uhni
//
//  Created by Petr Bursik on 18/11/13.
//  Copyright (c) 2013 Petr Bursik. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>



@class ControlViewController;
@interface GameViewController : UIViewController

@property (nonatomic) BOOL paused;

@property (weak,nonatomic) ControlViewController* control;

-(void) onControlCapturedCamFrame;
-(void) showReference;


@end
