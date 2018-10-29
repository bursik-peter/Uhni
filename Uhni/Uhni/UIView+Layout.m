//
//  UIView+Layout.m
//  BBKit
//
//  Created by Rolf on 9/16/13.
//  Copyright (c) 2013 Blackboard Mobile. All rights reserved.
//

#import "UIView+Layout.h"

@implementation UIView (Layout)

- (CGFloat) top     { return self.frame.origin.y; }
- (CGFloat) bottom  { return CGRectGetMaxY(self.frame); }
- (CGFloat) left    { return self.frame.origin.x; }
- (CGFloat) right   { return CGRectGetMaxX(self.frame); }
- (CGFloat) width   { return self.bounds.size.width; }
- (CGFloat) height  { return self.bounds.size.height; }
- (CGPoint) origin  { return self.frame.origin; }
- (CGFloat) centerX { return self.center.x; }
- (CGFloat) centerY { return self.center.y; }

- (void) setTop:(CGFloat)top        { self.frame = CGRectMake(self.left, top, self.width, self.height); }
- (void) setBottom:(CGFloat)bottom  { self.frame = CGRectMake(self.left, bottom - self.height, self.width, self.height); }
- (void) setLeft:(CGFloat)left      { self.frame = CGRectMake(left, self.top, self.width, self.height); }
- (void) setRight:(CGFloat)right    { self.frame = CGRectMake(right - self.width, self.top, self.width, self.height); }
- (void) setWidth:(CGFloat)width    { self.frame = CGRectMake(self.left, self.top, width, self.height); }
- (void) setHeight:(CGFloat)height  { self.frame = CGRectMake(self.left, self.top, self.width, height); }
- (void) setOrigin:(CGPoint)origin  { self.frame = CGRectMake(origin.x, origin.y, self.width, self.height); }
- (void) setCenterX:(CGFloat)centerX { self.center = CGPointMake(centerX, self.center.y); }
- (void) setCenterY:(CGFloat)centerY { self.center = CGPointMake(self.center.x, centerY); }


- (void) moveBy:(CGPoint)offset     { self.frame = CGRectMake(self.left + offset.x, self.top + offset.y, self.width, self.height); }
- (void) setTop:(CGFloat)top height:(CGFloat)height { self.frame = CGRectMake(self.left, top, self.width, height); }
- (void) setLeft:(CGFloat)left width:(CGFloat)width { self.frame = CGRectMake(left, self.top, width, self.height); }

#pragma mark - View Debugging

- (void) logViewHierarchy
{
    NSLog(@"\n%@", [self hierarchy]);
}

#pragma mark - View Debugging (Private)

+ (NSMutableString*) hierarchyWithView:(UIView*)view indentations:(int)indentations
{
    NSMutableString* result = [NSMutableString string];
    for (int i = 0; i < indentations; ++i){
        [result appendString:@"|\t"];
    }
    [result appendFormat:@"%@\n", view];
    for (UIView* subview in view.subviews)
    {
        [result appendString:[self hierarchyWithView:subview indentations:indentations+1]];
    }
    return result;
}

- (NSString*) hierarchy
{
    return [self.class hierarchyWithView:self indentations:0];
}

@end
