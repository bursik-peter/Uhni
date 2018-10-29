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

@property (nonatomic,strong) CADisplayLink* dl;
@property (nonatomic,strong) NSMutableArray* enemies;
@property (nonatomic,strong) NSTimer* addEnemyTimer;
@property (strong, nonatomic) IBOutlet UIView *gameView;

@property (nonatomic) int lives;
@property (strong, nonatomic) NSMutableArray* livesViews;
@property (strong, nonatomic) IBOutlet UILabel *scoreLabel;
@property (strong, nonatomic) IBOutlet UIView *statusBar;
@property (nonatomic) int score;
@property (nonatomic,strong) NSTimer* scoreTimer;

@property (nonatomic) int countdown;

@property (nonatomic) BOOL calibrating;

@property (strong, nonatomic) IBOutlet UIView *calibrationView;

@property (weak,nonatomic) ControlViewController* control;

-(BOOL) onControlCapturedCamFrame;


@end
