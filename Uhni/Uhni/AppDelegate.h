//
//  AppDelegate.h
//  Uhni
//
//  Created by Petr Bursik on 18/11/13.
//  Copyright (c) 2013 Petr Bursik. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ControlViewController;
@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) NSMutableArray *windows;
@property (strong,nonatomic) ControlViewController* controlViewController;

@end
