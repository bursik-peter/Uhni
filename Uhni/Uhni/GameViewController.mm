//
//  ViewController.m
//  Uhni
//
//  Created by Petr Bursik on 18/11/13.
//  Copyright (c) 2013 Petr Bursik. All rights reserved.
//


#import <opencv2/opencv.hpp>

#import "GameViewController.h"
#import "ControlViewController.h"
#import "BouncySquareEnemy.h"

#define START_LIVES 10
#define FRAMES_TO_DIE 3

typedef NS_ENUM(NSInteger, GameState)
{
    GameStateCountDown,
    GameStateWaiting,
    GameStatePlaying,
    GameStateGameOver
};


@interface GameViewController () <AVAudioPlayerDelegate>
{
    CGFloat time;
    
    __weak IBOutlet UILabel *_countdownLabel;
    int _countDown;
    NSTimer* _countdownTimer;
    __weak IBOutlet UIView *_readyView;
    
    GameState _gameState;
    
    AVAudioPlayer* _musicPlayer;
    NSMutableArray* _bulbPlayers;
    AVAudioPlayer* _gameOverPlayer;
    __weak IBOutlet UIView *_gameOverView;
    __weak IBOutlet UILabel *_gameOverScoreLabel;
    
    __weak IBOutlet UIImageView *_focusView;
    
    
    int _scoreStep;
}
@property (strong, nonatomic) IBOutlet UIView *enemyViewOutlet;

@end

@implementation GameViewController

- (void)viewDidLoad
{
    
    [super viewDidLoad];
    self.dl = [CADisplayLink displayLinkWithTarget:self selector:@selector(step)];
    [self.dl addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    
    self.enemies = [[NSMutableArray alloc] init];
    
    _calibrating = YES;
    [self setGameState:GameStateWaiting];
    
    _bulbPlayers = [[NSMutableArray alloc] init];
    _gameOverPlayer = [[AVAudioPlayer alloc] initWithData:[NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"gameover" ofType:@"wav"]] error:nil];
    
}

- (IBAction)onreadyTestButton:(id)sender {
    [self setGameState:GameStateCountDown];
}

-(void) setGameState:(GameState) gameState
{
    _gameState = gameState;
    switch (gameState) {
        case GameStateWaiting:
            
            [_musicPlayer pause];
            
            
            self.dl.paused = YES;
            [self.scoreTimer invalidate];
            [self.addEnemyTimer invalidate];
            self.addEnemyTimer = nil;
            
            _readyView.hidden = NO;
            _countdownLabel.hidden = YES;
            _gameOverView.hidden = YES;
            break;
            
        case GameStateCountDown:
            _readyView.hidden = YES;
            _countdownLabel.hidden = NO;
            _gameOverView.hidden = YES;
            [self startCountdown];
            break;
            
        case GameStatePlaying:
            _readyView.hidden = YES;
            _countdownLabel.hidden = YES;
            _gameOverView.hidden = YES;
            [self reset];
            break;
            
        case GameStateGameOver:
            [self.enemies makeObjectsPerformSelector:@selector(remove)];
            [_musicPlayer pause];
            self.dl.paused = YES;
            [self.scoreTimer invalidate];
            [self.addEnemyTimer invalidate];
            self.addEnemyTimer = nil;
            
            _readyView.hidden = YES;
            _countdownLabel.hidden = YES;
            _gameOverView.hidden = NO;
            
            [_gameOverPlayer play];
            
            _gameOverScoreLabel.text = [NSString stringWithFormat:@"Score: %d", _score];
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self setGameState:GameStateWaiting];
            });
            
    }
}

-(void) startCountdown {
    static const NSArray* songs = @[@"bensound-dance",@"bensound-dreams",@"bensound-house",@"bensound-scifi",];
    static const NSArray* beats = @[@(7),@(7),@(7),@(7)];
    static const NSArray* tempos = @[@(0.891125),@(1.264625),@(1.017125),@(1.371375)];
    
    int randIndex = (int)(randFloat()*4);
    
    NSString* song = songs[randIndex];
    int beat = ((NSNumber*)beats[randIndex]).integerValue;
    NSTimeInterval time = ((NSNumber*)tempos[randIndex]).floatValue;
    
    
    _musicPlayer = [[AVAudioPlayer alloc] initWithData:[NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:song ofType:@"m4a"]] error:nil];
    
    [self countDownWithBeats:beat time:time];
    [_musicPlayer play];
    
}

-(void) playBulbExplode {
    AVAudioPlayer* b = [[AVAudioPlayer alloc] initWithData:[NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"bulb" ofType:@"wav"]] error:nil];
    b.delegate = self;
    [_bulbPlayers addObject:b];
    [b play];
}

#pragma mark -
#pragma AVAudioPlayerDelegate

-(void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    [_bulbPlayers removeObject:player];
}


# pragma mark -

-(void)viewDidLayoutSubviews
{
    
}

-(void)setCalibrating:(BOOL)calibrating
{
    _calibrating = calibrating;
    _focusView.hidden = !calibrating;
    
    [self setGameState:GameStateWaiting];
}

-(void) countDownWithBeats:(int) beats time:(NSTimeInterval) time
{
    if(beats<0) {
        [self setGameState:GameStatePlaying];
        return;
    }
    
    _countdownLabel.hidden = NO;
    _countdown = beats;
    _countdownLabel.text = beats > 0 ? [NSString stringWithFormat:@"%d", beats] : @"GO!";
    _countdownLabel.alpha = 1.0;
    [UIView animateWithDuration:time delay:0.0 options:UIViewAnimationOptionCurveLinear animations:^{
        _countdownLabel.alpha = 0.0;
    } completion:^(BOOL finished) {
        [self countDownWithBeats:beats-1 time:time];
    }];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)calculateScore
{
    self.score+=_scoreStep;
}

-(void)step
{
    CGFloat dt = (self.dl.duration * self.dl.frameInterval);
    time+=dt;
    for(Enemy* o in [self.enemies copy])
    {
        [o incrementByTime:dt];
        if([o gone])
        {
            [o.view removeFromSuperview];
            [self.enemies removeObject:o];
        }
        
        
    }
    
}

-(void) reset
{
    _scoreStep = 0;
    
    [self.addEnemyTimer invalidate];
    [self.enemies makeObjectsPerformSelector:@selector(remove)];
    [self.enemies removeAllObjects];
    self.lives = START_LIVES;
    self.score = 0;
    self.dl.paused = NO;
    [self addEnemy];
    self.addEnemyTimer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(addEnemy) userInfo:nil repeats:YES];
    self.scoreTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(calculateScore) userInfo:nil repeats:YES];
}

-(void) addEnemy
{
    /*NSArray* a = @[@[@(0.0),@(0.5),@(150)],
                   @[@(0.5),@(1.0),@(150)],
                   @[@(0.0),@(0.25),@(150)],
                   @[@(0.75),@(1.0),@(150)]];
    
    NSArray* va = a[arc4random()%a.count];
    
    
    WallView* v = [[WallView alloc] initWithTop:[va[0] floatValue] Bottom:[va[1] floatValue]  width:50 speed:[va[2] floatValue]];
    v.view.top = 0;
    v.view.left = -v.view.width;
    v.view.height = _gameView.height;
    [_gameView addSubview:v.view];
    [self.enemies addObject:v];*/
    
    Enemy* e = [[BouncySquareEnemy alloc] initWithGameView:_gameView lives:(randFloat()<0.20)?1:-1];
    
    [self.enemies addObject:e];
    _scoreStep-=e.lives;
}

-(void) enemyRemoved:(Enemy*) e
{
    [self playBulbExplode];
    [e.view removeFromSuperview];
    [self.enemies removeObject:e];
    self.lives+=e.lives;
    if(self.lives==0) [self setGameState:GameStateGameOver];
    _scoreStep+=e.lives;
}

-(void)setLives:(int)lives
{
    _lives = lives;
    [self.livesViews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    self.livesViews  = [[NSMutableArray alloc] init];
    
    for(int i = 0;i<lives;i++)
    {
        UIImageView* lifeView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"dcb.png"]];
        lifeView.frame = CGRectMake(self.statusBar.bounds.size.width-(i+1)*self.statusBar.bounds.size.height, 0, self.statusBar.bounds.size.height, self.statusBar.bounds.size.height);
        lifeView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        [self.statusBar addSubview:lifeView];
        [self.livesViews addObject:lifeView];
    }
}

-(void)setScore:(int)score
{
    _score = score;
    self.scoreLabel.text = [NSString stringWithFormat:@"%d",score];
}

-(BOOL)onControlCapturedCamFrame
{
    switch (_gameState) {
        case GameStateCountDown: return YES;
        case GameStateWaiting:
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                std::vector<cv::Vec2f> rPoints;
                rPoints.push_back(cv::Vec2f(_readyView.centerX, _readyView.centerY));
                if(![_control isObjectViewVisible:rPoints]) {
                    [self setGameState:GameStateCountDown];
                }
            });
            return YES;
        }
        case GameStatePlaying:
            
            for(Enemy* o in [_enemies copy])
            {
                if(![_control isObjectViewVisible:o.controlPoints]) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self enemyRemoved:o];
                    });
                }
            }
    }
    
    
    
    
    /*NSArray* e = [_enemies copy];
    dispatch_async(dispatch_get_main_queue(), ^{
        [_control displayObjectsPoints:e];
    });*/
    
    return YES;
}

@end
