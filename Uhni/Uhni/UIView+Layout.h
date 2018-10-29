//
//  UIView+Layout.h
//  BBKit
//
//  Created by Rolf on 9/16/13.
//  Copyright (c) 2013 Blackboard Mobile. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
    Adds convenience methods for accessing common properties of frame-based layouts.
    @description @b Example: Moving a view
    
    @a Before:
 
    @code
    view.frame = CGRectMake (view.frame.origin.x + offset, view.frame.origin.y, view.bounds.size.width, view.bounds.size.height);
    @endcode
 
    @a After:
 
    @code
    view.left += offset;
    @endcode
 
    @b Example: Alignment: Place one view under another view
 
    @a Before:
 
    @code
    view.frame = CGectMake (otherview.frame.origin.x, CGRectGetMaxY(otherview.frame) + spacing, view.bounds.size.width, view.bounds.size.height);
    @endcode
 
    @a After:
 
    @code
    view.top = otherview.bottom + spacing;
    @endcode
 
    @b Example: Right align two views
 
    @a Before:
 
    @code
    view.frame = CGRectMake ( CGRectGetMaxX(otherview.frame) - view.bounds.size.width, view.frame.origin.y, view.bounds.size.width, view.bounds.size.height);
    @endcode
 
    @a After:
 
    @code
    view.right = otherview.right;
    @endcode
 */
@interface UIView (Layout)

#pragma mark - View Accessors

/**
 *  The receiver's y-origin.
 */
@property (assign, nonatomic) CGFloat top;

/**
 *  The receiver's maximum y value.
 */
@property (assign, nonatomic) CGFloat bottom;

/**
 *  The receiver's x-origin.
 */
@property (assign, nonatomic) CGFloat left;

/**
 *  The receiver's maximum x value.
 */
@property (assign, nonatomic) CGFloat right;

/**
 *  The receiver's bounds width.
 */
@property (assign, nonatomic) CGFloat width;

/**
 *  The receiver's bounds height.
 */
@property (assign, nonatomic) CGFloat height;

/**
 *  The receiver's origin point.
 */
@property (assign, nonatomic) CGPoint origin;

/**
 *  The receiver's center x coordinate.
 */
@property (assign, nonatomic) CGFloat centerX;

/**
 *  The receiver's center y coordinate.
 */
@property (assign, nonatomic) CGFloat centerY;

#pragma mark - Frame adjustments

/**
 *  Applies an offset to the X and Y origin coordinates affecting a change of position.
 *
 *  @param offset Point representing the number of pixels to adjust the view.  Positive values move the view right and down, while negative numbers move the view left and up.
 */
- (void) moveBy:(CGPoint)offset;

/**
 *  Convenience method for directly setting the view's vertical origin and view's height while maintaining the horizontal orgin and width.
 *
 *  @param top    The new vertical origin.
 *  @param height The new height of the view.
 */
- (void) setTop:(CGFloat)top height:(CGFloat)height;

/**
 *  Convenience method for directly setting the view's horizontal origin and view's width while maintaining the vertical origin and height.
 *
 *  @param left  The new horizontal origin.
 *  @param width The new width of the view.
 */
- (void) setLeft:(CGFloat)left width:(CGFloat)width;

#pragma mark - View Debugging

/**
 *  Recursively logs the the view hierarchy to the console, using one line per subview.
 */
- (void) logViewHierarchy;

@end
