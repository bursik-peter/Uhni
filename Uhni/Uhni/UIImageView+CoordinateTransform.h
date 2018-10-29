//
// Created by Andrey Streltsov on 16/11/15.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface UIImageView (CoordinateTransform)
-(CGPoint) pixelPointFromViewPoint:(CGPoint)viewPoint;
-(CGPoint) viewPointFromPixelPoint:(CGPoint)pixelPoint;
@end
