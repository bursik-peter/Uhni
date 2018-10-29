//
// Created by Andrey Streltsov on 16/11/15.
//

#import "UIImageView+CoordinateTransform.h"


@implementation UIImageView (CoordinateTransform)
-(CGPoint) pixelPointFromViewPoint:(CGPoint)touch
{
    // http://developer.apple.com/library/ios/#DOCUMENTATION/UIKit/Reference/UIView_Class/UIView/UIView.html#//apple_ref/occ/cl/UIView
    switch(self.contentMode)
    {
            // Simply scale the image size by the size of the frame
        case UIViewContentModeScaleToFill:
            // Redraw is basically the same as scale to fill but redraws itself in the drawRect call (so when bounds change)
        case UIViewContentModeRedraw:
            return CGPointMake(floor(touch.x/(self.frame.size.width/self.image.size.width)),floor(touch.y/(self.frame.size.height/self.image.size.height)));
            // Although the documentation doesn't state it, we will assume a centered image. This mode makes the image fit into the view with its aspect ratio
        case UIViewContentModeScaleAspectFit:
        {
            // If the aspect ratio favours width over height in relation to the images aspect ratio
            if(self.frame.size.width/self.frame.size.height >= self.image.size.width/self.image.size.height)
            {
                // Scaling by using the height ratio as a reference, and minusing the blank x coordiantes on the view
                return CGPointMake(floor((touch.x-((self.frame.size.width/2.0)-(((self.frame.size.height/self.image.size.height)*self.image.size.width)/2.0)))/(self.frame.size.height/self.image.size.height)),floor(touch.y/(self.frame.size.height/self.image.size.height)));
                
            }
            // Or if the aspect ratio favours height over width in relation to the images aspect ratio
            else
            {
                // Obtaining half of the view that is taken up by the aspect ratio
                CGFloat halfAspectFit = ((self.frame.size.width/self.image.size.width)*self.image.size.height)/2.0;
                // Checking whether the touch coordinate is not in a 'blank' spot on the view
                return CGPointMake(floor(touch.x/(self.frame.size.width/self.image.size.width)),floor((touch.y-((self.frame.size.width/2.0)-halfAspectFit))/(self.frame.size.height/self.image.size.height)));
            }
        }
            // This fills the view with the image in its aspect ratio, meaning that it could get cut off in either axis
        case UIViewContentModeScaleAspectFill:
        {
            // If the aspect ratio favours width over height in relation to the images aspect ratio
            if(self.frame.size.width/self.frame.size.height >= self.image.size.width/self.image.size.height)
            {
                // Scaling by using the width ratio, this will cut off some height
                return CGPointMake(floor(touch.x/(self.frame.size.width/self.image.size.width)),floor(touch.y/(self.frame.size.width/self.image.size.width)));
            }
            // If the aspect ratio favours height over width in relation to the images aspect ratio
            else
            {
                // Scaling by using the height ratio, this will cut off some width
                return CGPointMake(floor(touch.x/(self.frame.size.height/self.image.size.height)),floor(touch.y/(self.frame.size.height/self.image.size.height)));
            }
        }
            // This centers the image in the view both vertically and horizontally
        case UIViewContentModeCenter:
        {
            return CGPointMake(floor(touch.x-((self.frame.size.width/2.0)-(self.image.size.width/2.0))),floor(touch.y-((self.frame.size.height/2.0)-(self.image.size.height/2.0))));
        }
            // This centers the image horizontally and moves it up to the top
        case UIViewContentModeTop:
        {
            return CGPointMake(floor(touch.x-((self.frame.size.width/2.0)-(self.image.size.width/2.0))),floor(touch.y));
        }
            // This centers the image horizontally and moves it down to the bottom
        case UIViewContentModeBottom:
        {
            return CGPointMake(floor(touch.x-((self.frame.size.width/2.0)-(self.image.size.width/2.0))),floor(touch.y-(self.frame.size.height-self.image.size.height)));
        }
            // This moves the image to the horizontal start and centers it vertically
        case UIViewContentModeLeft:
        {
            return CGPointMake(floor(touch.x),floor(touch.y-((self.frame.size.height/2.0)-(self.image.size.height/2.0))));
        }
            // This moves the image to the horizontal end and centers it vertically
        case UIViewContentModeRight:
        {
            return CGPointMake(floor(touch.x-(self.frame.size.width-self.image.size.width)),floor(touch.y-((self.frame.size.height/2.0)-(self.image.size.height/2.0))));
        }
            // This simply moves the image to the horizontal and vertical start
        case UIViewContentModeTopLeft:
        {
            return CGPointMake(floor(touch.x),floor(touch.y));
        }
            // This moves the image to the horizontal end and vertical start
        case UIViewContentModeTopRight:
        {
            return CGPointMake(floor(touch.x-(self.frame.size.width-self.image.size.width)),floor(touch.y));
        }
            // This moves the image to the horizontal start and vertical end
        case UIViewContentModeBottomLeft:
        {
            return CGPointMake(floor(touch.x),floor(touch.y-(self.frame.size.height-self.image.size.height)));
        }
            // This moves the image to the horizontal and vertical end
        case UIViewContentModeBottomRight:
        {
            return CGPointMake(floor(touch.x-(self.frame.size.width-self.image.size.width)),floor(touch.y-(self.frame.size.height-self.image.size.height)));
        }
        default: return CGPointZero;
    }
}

-(CGPoint) viewPointFromPixelPoint:(CGPoint)pixelPoint
{
       switch(self.contentMode)
        {
            case UIViewContentModeScaleToFill:
            case UIViewContentModeRedraw:
                return CGPointMake(floor(pixelPoint.x*(self.frame.size.width/self.image.size.width)),floor(pixelPoint.y*(self.frame.size.height/self.image.size.height)));
            case UIViewContentModeScaleAspectFit:
            {
                if(self.frame.size.width/self.frame.size.height >= self.image.size.width/self.image.size.height)
                    return CGPointMake(floor(((self.frame.size.width/2.0)-((self.image.size.width/2.0)*(self.frame.size.height/self.image.size.height)))+pixelPoint.x*(self.frame.size.height/self.image.size.height)),floor(pixelPoint.y*(self.frame.size.height/self.image.size.height)));
                else return CGPointMake(floor(pixelPoint.x*(self.frame.size.width/self.image.size.width)),floor(((self.frame.size.height/2.0)-((self.image.size.height/2.0)*(self.frame.size.width/self.image.size.width)))+pixelPoint.y*(self.frame.size.width/self.image.size.width)));
            }
            case UIViewContentModeScaleAspectFill:
            {
                if(self.frame.size.width/self.frame.size.height >= self.image.size.width/self.image.size.height)
                    return CGPointMake(floor(pixelPoint.x*(self.frame.size.width/self.image.size.width)),floor(pixelPoint.y*(self.frame.size.width/self.image.size.width)));
                else return CGPointMake(floor(pixelPoint.x*(self.frame.size.height/self.image.size.height)),floor(pixelPoint.y*(self.frame.size.height/self.image.size.height)));
            }
            case UIViewContentModeCenter:
                return CGPointMake(floor(pixelPoint.x+(self.frame.size.width/2.0)-(self.image.size.width/2.0)),floor(pixelPoint.y+(self.frame.size.height/2.0)-(self.image.size.height/2.0)));
            case UIViewContentModeTop:
                return CGPointMake(floor(pixelPoint.x+(self.frame.size.width/2.0)-(self.image.size.width/2.0)),floor(pixelPoint.y));
            case UIViewContentModeBottom:
                return CGPointMake(floor(pixelPoint.x+(self.frame.size.width/2.0)-(self.image.size.width/2.0)),floor(pixelPoint.y-(self.frame.size.height-self.image.size.height)));
            case UIViewContentModeLeft:
                return CGPointMake(floor(pixelPoint.x),floor(pixelPoint.y+(self.frame.size.height/2.0)-(self.image.size.height/2.0)));
            case UIViewContentModeRight:
                return CGPointMake(floor(pixelPoint.x-(self.frame.size.width-self.image.size.width)),floor(pixelPoint.y+(self.frame.size.height/2.0)-(self.image.size.height/2.0)));
            case UIViewContentModeTopLeft:
                return CGPointMake(floor(pixelPoint.x),floor(pixelPoint.y));
            case UIViewContentModeTopRight:
                return CGPointMake(floor(pixelPoint.x-(self.frame.size.width-self.image.size.width)),floor(pixelPoint.y));
            case UIViewContentModeBottomLeft:
                return CGPointMake(floor(pixelPoint.x),floor(pixelPoint.y-(self.frame.size.height-self.image.size.height)));
            case UIViewContentModeBottomRight:
                return CGPointMake(floor(pixelPoint.x-(self.frame.size.width-self.image.size.width)),floor(pixelPoint.y-(self.frame.size.height-self.image.size.height)));
            default: return CGPointZero;
        }
}

@end
