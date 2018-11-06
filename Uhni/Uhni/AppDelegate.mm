//
//  AppDelegate.m
//  Uhni
//
//  Created by Petr Bursik on 18/11/13.
//  Copyright (c) 2013 Petr Bursik. All rights reserved.
//

#import "AppDelegate.h"
#import "GameViewController.h"
#import "ControlViewController.h"
#import <AVFoundation/AVFoundation.h>


@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    
    
    // Override point for customization after application launch.
    [application setStatusBarHidden:YES];
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    
    UIWindow    *_window    = nil;
    NSArray     *_screens   = nil;
    
    self.windows = [[NSMutableArray alloc] init];
    
    _screens = [UIScreen screens];
    
    UIScreen* screen = [_screens objectAtIndex:0];
    
    self.controlViewController = [[ControlViewController alloc] initWithNibName:@"ControlViewController" bundle:nil];
    _window = [self createWindowForScreen:screen];
    _window.rootViewController = self.controlViewController;
    _window.hidden = NO;
    [_window makeKeyAndVisible];
    
    
    if(_screens.count > 1)
    {
        [self addGameControllerToScreen:_screens.lastObject];
    }
    
    // Register for notification
    [[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(screenDidConnect:)
												 name:UIScreenDidConnectNotification
											   object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(screenDidDisconnect:)
												 name:UIScreenDidDisconnectNotification
											   object:nil];
    
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker error:nil];
    [[AVAudioSession sharedInstance] overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker
                                                       error:nil];
    
    return YES;
}

-(void) addGameControllerToScreen:(UIScreen*) screen
{
    GameViewController* gvc = [[GameViewController alloc] initWithNibName:@"GameViewController" bundle:nil];
    UIWindow* _window = [self createWindowForScreen:screen];
    _window.rootViewController = gvc;
    _window.hidden = NO;
    _window = nil;
    
    self.controlViewController.gameViewController = gvc;
    gvc.control = self.controlViewController;
}

- (UIWindow *) createWindowForScreen:(UIScreen *)screen {
    UIWindow    *_window    = nil;
    
    // Do we already have a window for this screen?
    for (UIWindow *window in self.windows){
        if (window.screen == screen){
            _window = window;
        }
    }
    // Still nil? Create a new one.
    if (_window == nil){
        _window = [[UIWindow alloc] initWithFrame:[screen bounds]];
        [_window setScreen:screen];
        [self.windows addObject:_window];
    }
    
    return _window;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void) screenDidConnect:(NSNotification *) notification {
    [self addGameControllerToScreen:notification.object];
}

- (void) screenDidDisconnect:(NSNotification *) notification {
    UIScreen    *_screen    = nil;
    
    NSLog(@"Screen disconnected");
    _screen = [notification object];
    
    // Find any window attached to this screen, remove it from our window list, and release it.
    
    NSMutableArray* _tempWindows = [[NSMutableArray alloc] initWithArray:self.windows];
    
    for (UIWindow *_window in _tempWindows){
        if (_window.screen == _screen){
            [self.windows removeObjectIdenticalTo:_window];
        }
    }
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker error:nil];
    [[AVAudioSession sharedInstance] overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker
                                                       error:nil];
    return;
    
}

@end
