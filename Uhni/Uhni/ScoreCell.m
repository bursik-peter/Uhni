//
//  ScoreCell.m
//  Uhni
//
//  Created by burax on 10/31/18.
//  Copyright © 2018 Petr Bursik. All rights reserved.
//

#import "ScoreCell.h"

@interface ScoreCell()
{
    __weak IBOutlet UILabel* _nameLabel;
    __weak IBOutlet UILabel* _scoreLabel;
    __weak IBOutlet UILabel *_placeLabel;
}
@end

@implementation ScoreCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.contentView.layer.cornerRadius = self.contentView.bounds.size.height/2.0;
    self.contentView.layer.masksToBounds = YES;
    // Initialization code
}

-(void) displayPlace:(NSInteger)place Name:(NSString*) name andScore:(NSInteger) score {
    
    _placeLabel.text = [NSString stringWithFormat:@"%ld.",place];
    _nameLabel.text = name;
    _scoreLabel.text = [NSString stringWithFormat:@"%ld",score];
}

- (void)setAsCurrent:(BOOL)current {
    self.contentView.backgroundColor = current ? [UIColor colorWithRed:155/255.0 green:250/255.0 blue:155/255.0 alpha:0.25] : [UIColor clearColor];
    _placeLabel.hidden = current;
    _scoreLabel.hidden = current;
}

@end
