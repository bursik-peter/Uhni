//
//  ViewController.m
//  Uhni
//
//  Created by Petr Bursik on 18/11/13.
//  Copyright (c) 2013 Petr Bursik. All rights reserved.
//


#import <opencv2/opencv.hpp>
#import <iCarousel/iCarousel.h>
#import <AVFoundation/AVFoundation.h>

#import "GameViewController.h"
#import "ControlViewController.h"
#import "BouncySquareEnemy.h"
#import "ScoreCell.h"
#import "ScoreEntry.h"

#define START_LIVES 1
#define FRAMES_TO_DIE 3

typedef NS_ENUM(NSInteger, GameState)
{
    GameStateCountDown,
    GameStateNameInput,
    GameStateWaiting,
    GameStatePlaying,
    GameStateGameOver
};


@interface GameViewController () <AVAudioPlayerDelegate,UITableViewDataSource,UITableViewDelegate>
{
    CGFloat time;
    
    __weak IBOutlet UILabel *_countdownLabel;
    int _countDown;
    NSTimer* _countdownTimer;
    __weak IBOutlet UIView *_readyView;
    
    __weak IBOutlet UIView *_nameInputView;
    NSMutableArray* _letterViews;
    NSMutableSet* _spentLetterViews;
    __weak IBOutlet UIButton *_resetNameButton;
    __weak IBOutlet UIButton *_confirmNameButton;
    __weak IBOutlet UILabel *_nameLabel;
    __weak IBOutlet UILabel *_nameInputScoreLabel;
    
    
    __weak IBOutlet UITableView *_scoreBoardTableView;
    IBOutlet ScoreCell *_scoreCellOutlet;
    NSMutableArray<ScoreEntry*>* _scores;
    
    NSInteger _currentPosition;
    
    GameState _gameState;
    
    AVAudioPlayer* _musicPlayer;
    NSMutableArray* _bulbPlayers;
    AVAudioPlayer* _gameOverPlayer;
    __weak IBOutlet UIView *_gameOverView;
    __weak IBOutlet UILabel *_gameOverScoreLabel;
    __weak IBOutlet UILabel *_gameOverPlaceLabel;
    
    __weak IBOutlet UIImageView *_focusView;
    __weak IBOutlet UIView *_enemyColorView;
        
    int _scoreStep;
}
@property (strong, nonatomic) IBOutlet UIView *enemyViewOutlet;

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

@property (nonatomic) NSInteger countdown;


@property (strong, nonatomic) IBOutlet UIView *calibrationView;

@end

@implementation GameViewController

- (void)viewDidLoad
{
    
    [super viewDidLoad];
    self.dl = [CADisplayLink displayLinkWithTarget:self selector:@selector(step)];
    [self.dl addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    
    self.enemies = [[NSMutableArray alloc] init];
    
    _paused = YES;
    [self setGameState:GameStateWaiting];
    
    _bulbPlayers = [[NSMutableArray alloc] init];
    for(int i = 0; i<4; i++) {
        AVAudioPlayer* b = [[AVAudioPlayer alloc] initWithData:[NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"bulb" ofType:@"wav"]] error:nil];
        b.delegate = self;
        [_bulbPlayers addObject:b];
        [b prepareToPlay];
    }
    
    _gameOverPlayer = [[AVAudioPlayer alloc] initWithData:[NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"gameover" ofType:@"wav"]] error:nil];
    
    NSData* scoreData = [[[NSUserDefaults standardUserDefaults] dataForKey:@"score"] mutableCopy];
    if(scoreData)
    {
        _scores = [NSKeyedUnarchiver unarchiveObjectWithData:scoreData];
    } else
    {
        _scores = [[NSMutableArray alloc] init];
    }
    [_scoreBoardTableView reloadData];
}

- (IBAction)onreadyTestButton:(id)sender {
    [self setGameState:GameStateNameInput];
}
- (IBAction)onConfirmName:(id)sender {
    [self setGameState:GameStateCountDown];
}

-(void) onLetterTest:(UIButton*) sender {
    _nameLabel.text = [_nameLabel.text stringByAppendingString:sender.titleLabel.text];
}

-(IBAction)onResetName:(UIButton*) sender {
    _nameLabel.text = @"";
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
            _nameInputView.hidden = YES;
            
            _scoreLabel.text = @"";
            
            break;
            
        case GameStateNameInput:
            
            _readyView.hidden = YES;
            _countdownLabel.hidden = NO;
            _gameOverView.hidden = YES;
            
            _nameLabel.text = @"";
            
            _nameInputView.hidden = NO;
            break;
            
        case GameStateCountDown:
            
            _nameInputView.hidden = YES;
            _readyView.hidden = YES;
            _countdownLabel.hidden = NO;
            _gameOverView.hidden = YES;
            [self startCountdown];
            break;
            
        case GameStatePlaying:
            _readyView.hidden = YES;
            _countdownLabel.hidden = YES;
            _gameOverView.hidden = YES;
            _nameInputView.hidden = YES;
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
            
            BOOL highScore = [self addScoreEntry:[[ScoreEntry alloc] initWithName:_nameLabel.text andScore:_score]];

            
            
            [_scoreBoardTableView reloadData];
            
            [_gameOverPlayer play];
            
            _gameOverScoreLabel.text = [NSString stringWithFormat:@"Score: %d", _score];
            _gameOverPlaceLabel.text = [NSString stringWithFormat:(highScore ? @"New Record! %@ place!" : @"No record! Staying at %@ place" ), [self getOrdinalStringFromInteger:[_scores indexOfObject:[self scoreForPlayer:_nameLabel.text]]+1]];
            
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self setGameState:GameStateWaiting];
            });
            
    }
}

- (NSString *)getOrdinalStringFromInteger:(NSInteger)integer
{
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setLocale:[NSLocale currentLocale]];
    [formatter setNumberStyle:NSNumberFormatterOrdinalStyle];
    return [formatter stringFromNumber:[NSNumber numberWithInteger:integer]];
}

-(void) startCountdown {
    static const NSArray* songs = @[@"bensound-dance",@"bensound-dreams",@"bensound-house",@"bensound-scifi",@"SP-Tarova"];
    static const NSArray* beats = @[@(7),@(7),@(7),@(7),@(7)];
    static const NSArray* tempos = @[@(0.891125),@(1.264625),@(1.017125),@(1.371375),@(1.295)];
    
    int randIndex = (int)(randFloat()*songs.count);
    
    NSString* song = songs[randIndex];
    NSInteger beat = ((NSNumber*)beats[randIndex]).integerValue;
    NSTimeInterval time = ((NSNumber*)tempos[randIndex]).floatValue;
    
    
    _musicPlayer = [[AVAudioPlayer alloc] initWithData:[NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:song ofType:@"m4a"]] error:nil];
    _musicPlayer.numberOfLoops = -1;
    
    [self countDownWithBeats:beat time:time];
    [_musicPlayer play];
    
}

-(void) playBulbExplode {
    AVAudioPlayer* b = _bulbPlayers.firstObject;
    [b play];
    [_bulbPlayers removeObjectAtIndex:0];
    [_bulbPlayers addObject:b];
}



#pragma mark -
#pragma AVAudioPlayerDelegate

-(void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    [player prepareToPlay];
}


# pragma mark -

-(void)viewDidLayoutSubviews
{
    [_control gameDidLayoutSubviews:self];
    [self layoutLetters];
}

-(void)setPaused:(BOOL)calibrating
{
    _paused = calibrating;
    _focusView.hidden = !calibrating;
    _enemyColorView.hidden = YES;
    
    [self setGameState:GameStateWaiting];
}

-(void) countDownWithBeats:(NSInteger) beats time:(NSTimeInterval) time
{
    if(beats<0) {
        [self setGameState:GameStatePlaying];
        return;
    }
    
    if(_paused) return;
    
    _countdownLabel.hidden = NO;
    _countdown = beats;
    _countdownLabel.text = beats > 0 ? [NSString stringWithFormat:@"%ld", (long)beats] : @"GO!";
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
        
        if(o.shadedFramesCount>0) [self enemyRemoved:o];
        
        
    }
    
    
    
}

-(void) reset
{
    _scoreStep = 0;
    
    [self.addEnemyTimer invalidate];
    [self.enemies makeObjectsPerformSelector:@selector(remove)];
    [self.enemies removeAllObjects];
    self.lives = START_LIVES;
    _currentPosition = _scores.count;
    [_scoreBoardTableView reloadData];
    self.score = 0;
    self.dl.paused = NO;
    [self addEnemy];
    self.addEnemyTimer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(addEnemy) userInfo:nil repeats:YES];
    self.scoreTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(calculateScore) userInfo:nil repeats:YES];
    
    [_scoreBoardTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:_currentPosition inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
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
        lifeView.frame = CGRectMake(self.statusBar.bounds.size.width-(i+1)*30, 5, 20, 20);
        lifeView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        [self.statusBar addSubview:lifeView];
        [self.livesViews addObject:lifeView];
    }
} 

-(void)setScore:(int)score
{
    _score = score;
    self.scoreLabel.text = [NSString stringWithFormat:@"%d",score];
    
    if(_currentPosition > 0 && _scores[_currentPosition-1].score < score) {
        [_scoreBoardTableView beginUpdates];
        [_scoreBoardTableView moveRowAtIndexPath:[NSIndexPath indexPathForRow:_currentPosition inSection:0] toIndexPath:[NSIndexPath indexPathForRow:_currentPosition-1 inSection:0]];
        _currentPosition--;
        [_scoreBoardTableView endUpdates];
        [_scoreBoardTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:_currentPosition inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    }
//    else if(_currentPosition < _scores.count-1 && _scores[_currentPosition+1].score > score)
//    {
//        [_scoreBoardTableView beginUpdates];
//        [_scoreBoardTableView moveRowAtIndexPath:[NSIndexPath indexPathForRow:_currentPosition inSection:0] toIndexPath:[NSIndexPath indexPathForRow:_currentPosition+1 inSection:0]];
//        _currentPosition++;
//        [_scoreBoardTableView endUpdates];
//        [_scoreBoardTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:_currentPosition inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
//    }
}



-(ScoreEntry*) scoreForPlayer:(NSString*) name
{
    for(ScoreEntry* s in _scores) {
        if([name isEqualToString:s.name]) return s;
    }
    return nil;
}

-(BOOL)addScoreEntry:(ScoreEntry*) scoreEntry
{
    ScoreEntry* previousRecord = [self scoreForPlayer:_nameLabel.text];
    BOOL highScore = _score > (previousRecord?previousRecord.score:NSIntegerMin);
    
    if(!highScore) return false;
    
    [_scores removeObject:previousRecord];
    
    [_scores addObject:scoreEntry];
    [_scores sortUsingComparator:^NSComparisonResult(ScoreEntry*  _Nonnull obj1, ScoreEntry*  _Nonnull obj2) {
        return [@(obj2.score) compare:@(obj1.score)];
    }];
    [_scoreBoardTableView reloadData];
    [self saveScore];
    
    return true;
}

-(void) saveScore {
    [[NSUserDefaults standardUserDefaults] setObject:[NSKeyedArchiver archivedDataWithRootObject:_scores] forKey:@"score"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(void)onControlCapturedCamFrame
{
    dispatch_async(dispatch_get_main_queue(), ^{
        switch (_gameState) {
            case GameStateNameInput:
            {
                
                for(UIButton* v in _letterViews)
                {
                    if([_spentLetterViews containsObject:v]) continue;
                    
                    
                    std::vector<cv::Vec2f> rPoints = {(cv::Vec2f(CGRectGetMidX(v.frame), CGRectGetMidY(v.frame)))};
                    
                    if(![_control isObjectViewVisible:rPoints]) {
                        
                        if(_nameLabel.text.length<3) {
                            _nameLabel.text = [_nameLabel.text stringByAppendingString:v.titleLabel.text];
                            ScoreEntry* scoreEntry = [self scoreForPlayer:_nameLabel.text];
                            if(scoreEntry) {
                                _nameInputScoreLabel.text = [NSString stringWithFormat:@"Score: %ld", scoreEntry.score];
                            }
                            else
                            {
                                _nameInputScoreLabel.text = @"";
                            }
                        }
                        [_spentLetterViews addObject:v];
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                            [_spentLetterViews removeObject:v];
                        });
                    }
                    
                }
                
                
                std::vector<cv::Vec2f> confirmPoint = {(cv::Vec2f(_confirmNameButton.centerX, _confirmNameButton.centerY))};
                if(![_control isObjectViewVisible:confirmPoint]) {
                    
                    if(_nameLabel.text.length>=3) [self setGameState:GameStateCountDown];
                    
                }
                
                
                std::vector<cv::Vec2f> resetPoint = {(cv::Vec2f(_resetNameButton.centerX, _resetNameButton.centerY))};
                if(![_control isObjectViewVisible:resetPoint]) {
                    _nameLabel.text=@"";
                    
                }
                return;
            }
            case GameStateWaiting:
            {
                std::vector<cv::Vec2f> rPoints = {(cv::Vec2f(_readyView.centerX, _readyView.centerY))};
                if(![_control isObjectViewVisible:rPoints]) {
                    [self setGameState:GameStateNameInput];
                }
                return;
            }
            case GameStatePlaying:
                
                for(Enemy* o in [_enemies copy])
                {
                    if(![_control isObjectViewVisible:o.controlPoints] || o.shadedFramesCount>0) {
                        
                        [self enemyRemoved:o];
                        
                    }
                }
                return;
            default: return;
        }
    });
}

-(void)showReference
{
    _enemyColorView.hidden = NO;
}

-(void)layoutLetters
{
    CGRect bounds = _nameInputView.bounds;
    CGPoint center = CGPointMake(CGRectGetMidX(bounds), CGRectGetMaxY(bounds));
    CGRect letterBounds = CGRectMake(0, 0, 50, 50);
    CGPoint anchorPoint = CGPointMake(0.5,(MIN(bounds.size.height,bounds.size.width/2.0)/50.0));
    
    [_letterViews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    _letterViews = [[NSMutableArray alloc] init];
    _spentLetterViews = [[NSMutableSet alloc] init];
    
    char c = 'A';
    for(int i = 1; i<=26; i++)
    {
        UIButton* l = [[UIButton alloc] init];
        [l setTitle:[NSString stringWithFormat:@"%c",c] forState:UIControlStateNormal];
        [l setTitleColor:[UIColor colorWithRed:155/255.0 green:250/255.0 blue:155/255.0 alpha:1.0] forState:UIControlStateNormal];
        l.titleLabel.textAlignment = NSTextAlignmentCenter;
        l.titleLabel.font = [UIFont fontWithName:@"Futura-Bold" size:40.0];
        l.frame = letterBounds;
        [_nameInputView addSubview:l];
        l.center = center;
        l.layer.anchorPoint = anchorPoint;
        l.transform = CGAffineTransformMakeRotation((i-15.5 + (i>13?4:0))*M_PI/30.0);
        l.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.5];
        l.layer.cornerRadius = 25.0;
        l.layer.masksToBounds = YES;
        l.userInteractionEnabled = YES;
        [l addTarget:self action:@selector(onLetterTest:) forControlEvents:UIControlEventTouchUpInside];
        
        [_letterViews addObject:l];
        c++;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    ScoreCell* cell = [tableView dequeueReusableCellWithIdentifier:@"ScoreCell"];
    if(cell == nil) {
        [[NSBundle mainBundle] loadNibNamed:@"ScoreCell" owner:self options:nil];
        cell = _scoreCellOutlet;
    }
    
    
    if(_gameState == GameStatePlaying) {
        BOOL currentPlayer = indexPath.row == _currentPosition;
        if(currentPlayer) {
            [cell displayPlace:0 Name:_nameLabel.text andScore:_score];
        } else {
            NSInteger scoreIndex = indexPath.row - (indexPath.row > _currentPosition ? 1 : 0);
            [cell displayPlace:scoreIndex+1 Name:_scores[scoreIndex].name andScore:_scores[scoreIndex].score];
        }
        [cell setAsCurrent: currentPlayer];
    } else {
        [cell setAsCurrent:NO];
        [cell displayPlace:indexPath.row+1 Name:_scores[indexPath.row].name andScore:_scores[indexPath.row].score];
    }
    
    return cell;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _scores.count + (_gameState==GameStatePlaying ? 1 : 0);
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return .00001;
}

-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return .00001;
}




@end
