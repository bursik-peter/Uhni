//
//  ScoreCell.h
//  Uhni
//
//  Created by burax on 10/31/18.
//  Copyright © 2018 Petr Bursik. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ScoreCell : UITableViewCell

-(void) displayPlace:(NSInteger)place Name:(NSString*) name andScore:(NSInteger) score;

-(void)setAsCurrent:(BOOL) current;

@end

NS_ASSUME_NONNULL_END
