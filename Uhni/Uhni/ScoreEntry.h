//
//  ScoreEntry.h
//  Uhni
//
//  Created by burax on 11/1/18.
//  Copyright © 2018 Petr Bursik. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ScoreEntry: NSObject<NSCoding>

-(instancetype) initWithName:(NSString*) name andScore:(NSInteger) score;

@property NSString* name;
@property NSInteger score;

@end

NS_ASSUME_NONNULL_END
