//
//  BouncySquareEnemy.h
//  Uhni
//
//  Created by burax on 10/10/18.
//  Copyright © 2018 Petr Bursik. All rights reserved.
//

#import "Enemy.h"

NS_ASSUME_NONNULL_BEGIN

@interface BouncySquareEnemy : Enemy
- (instancetype)initWithGameView:(UIView*) gameView lives:(int) lives;

@end

NS_ASSUME_NONNULL_END
