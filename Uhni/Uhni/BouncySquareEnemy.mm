//
//  BouncySquareEnemy.m
//  Uhni
//
//  Created by burax on 10/10/18.
//  Copyright © 2018 Petr Bursik. All rights reserved.
//

#import "BouncySquareEnemy.h"

@interface BouncySquareEnemy()
{
    CGPoint _speedVector;
    CGRect _gameFrame;
    CGRect _frame;
    
    int _lives;
    __weak IBOutlet UIView *_colorView;
}
@end

@implementation BouncySquareEnemy

- (instancetype)initWithGameView:(UIView*) gameView lives:(int) lives
{
    self = [super init];
    if (self) {
        _gameFrame = gameView.bounds;
        [[NSBundle mainBundle] loadNibNamed:@"BouncySquareEnemy" owner:self options:nil];
        _speedVector = CGPointMake((randFloat()-0.5)*280.0, randFloat()*140.0);
        CGRect bounds = self.view.bounds = CGRectMake(0, 0, 50, 50);
        
        _lives = lives;
        if(lives>0) {
            _colorView.backgroundColor = [UIColor colorWithRed:155/255.0 green:250/255.0 blue:155/255.0 alpha:1.0];
        }
        
        self.view.center = CGPointMake((_gameFrame.size.width-bounds.size.width)*randFloat()+bounds.size.width/2.0,bounds.size.height/2.0);
        
        [gameView addSubview:self.view];
        
        _frame = self.view.frame;
    }
    return self;
}

- (void)incrementByTime:(CGFloat)dt
{
    _frame.origin.x += dt*_speedVector.x;
    _frame.origin.y += dt*_speedVector.y;
    
    if(_frame.origin.x<0)
    {
        _frame.origin.x = -_frame.origin.x;
        _speedVector.x = -_speedVector.x;
    }
    else if(_frame.origin.x>_gameFrame.size.width-_frame.size.width)
    {
        _frame.origin.x = 2*(_gameFrame.size.width-_frame.size.width)-_frame.origin.x;
        _speedVector.x = -_speedVector.x;
    }
    
    if(_frame.origin.y<0)
    {
        _frame.origin.y = -_frame.origin.y;
        _speedVector.y = -_speedVector.y;
    }
    else if(_frame.origin.y>_gameFrame.size.height-_frame.size.height)
    {
        _frame.origin.y = 2*(_gameFrame.size.height-_frame.size.height)-_frame.origin.y;
        _speedVector.y = -_speedVector.y;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.view.frame = _frame;
    });
}

-(std::vector<cv::Vec2f>)controlPoints {
    std::vector<cv::Vec2f> result;
    CGRect fTemp = CGRectInset(_frame, 20, 20);
    
    result.push_back(cv::Vec2f(fTemp.origin.x,fTemp.origin.y));
    result.push_back(cv::Vec2f(fTemp.origin.x+fTemp.size.width,fTemp.origin.y));
    result.push_back(cv::Vec2f(fTemp.origin.x+fTemp.size.width,fTemp.origin.y+fTemp.size.height));
    result.push_back(cv::Vec2f(fTemp.origin.x,fTemp.origin.y+fTemp.size.height));
    return result;
}

-(std::vector<cv::Vec2f>)displayPoints {
    return [self controlPoints];
}

- (int)lives
{
    return _lives;
}

- (IBAction)onTestTap:(id)sender {
    self.shadedFramesCount++;
}

@end
