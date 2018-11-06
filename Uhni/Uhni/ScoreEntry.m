//
//  ScoreEntry.m
//  Uhni
//
//  Created by burax on 11/1/18.
//  Copyright © 2018 Petr Bursik. All rights reserved.
//

#import "ScoreEntry.h"

@implementation ScoreEntry

- (instancetype)initWithName:(NSString *)name andScore:(NSInteger)score
{
    self = [super init];
    if (self) {
        _name = name;
        _score = score;
    }
    return self;
}

-(void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeInteger:_score forKey:@"score"];
    [aCoder encodeObject:_name forKey:@"name"];
}

-(instancetype)initWithCoder:(NSCoder *)aDecoder {
    if(self = [super init])
    {
        _score = [aDecoder decodeIntegerForKey:@"score"];
        _name = [aDecoder decodeObjectForKey:@"name"];
    }
    return self;
}
@end
