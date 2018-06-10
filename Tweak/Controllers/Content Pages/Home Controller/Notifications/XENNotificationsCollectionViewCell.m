/*
 Copyright (C) 2018  Matt Clarke
 
 This program is free software; you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation; either version 2 of the License, or
 (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License along
 with this program; if not, write to the Free Software Foundation, Inc.,
 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
 */

#import "XENNotificationsCollectionViewCell.h"
#include <math.h>

@interface UIImage (Private4)
+(UIImage *)_applicationIconImageForBundleIdentifier:(NSString *)bundleIdentifier format:(int)format scale:(CGFloat)scale;
@end

@implementation XENNotificationsCollectionViewCell

+(UIImage*)circularImage:(UIImage*)img inRect:(CGRect)rect {
    // This function returns a newImage, based on image, that has been:
    // - scaled to fit in (CGRect) rect
    // - and cropped within a circle of radius: rectWidth/2
    
    //Create the bitmap graphics context
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(rect.size.width, rect.size.height), NO, 0.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    //Get the width and heights
    CGFloat imageWidth = img.size.width;
    CGFloat imageHeight = img.size.height;
    CGFloat rectWidth = rect.size.width;
    CGFloat rectHeight = rect.size.height;
    
    //Calculate the scale factor
    CGFloat scaleFactorX = rectWidth/imageWidth;
    CGFloat scaleFactorY = rectHeight/imageHeight;
    
    //Calculate the centre of the circle
    CGFloat imageCentreX = rectWidth/2;
    CGFloat imageCentreY = rectHeight/2;
    
    // Create and CLIP to a CIRCULAR Path
    // (This could be replaced with any closed path if you want a different shaped clip)
    CGFloat radius = (rectWidth/2)-2;
    CGContextBeginPath (context);
    CGContextAddArc (context, imageCentreX, imageCentreY, radius, 0, 2*M_PI, 0);
    CGContextClosePath (context);
    CGContextClip (context);
    
    //Set the SCALE factor for the graphics context
    //All future draw calls will be scaled by this factor
    CGContextScaleCTM (context, scaleFactorX, scaleFactorY);
    
    // Draw the IMAGE
    CGRect myRect = CGRectMake(0, 0, imageWidth, imageHeight);
    [img drawInRect:myRect];
    
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    UIColor *colr = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.35];
    
    return [XENNotificationsCollectionViewCell image:newImage WithShadowColor:colr offset:CGSizeMake(0, 0) blur:5.0];
}

+(UIImage *)image:(UIImage*)img WithShadowColor:(UIColor *)color offset:(CGSize)offset blur:(CGFloat)blur {
    //get size
    CGSize border = CGSizeMake(fabs(offset.width) + blur, fabs(offset.height) + blur);
    CGSize size = CGSizeMake(img.size.width + border.width * 2.0f, img.size.height + border.height * 2.0f);
    
    //create drawing context
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0f);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    //set up shadow
    CGContextSetShadowWithColor(context, offset, blur, color.CGColor);
    
    //draw with shadow
    [img drawAtPoint:CGPointMake(border.width, border.height)];
    
    //capture resultant image
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

-(id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:CGRectMake(0, 0, 50, 50)];
    if (self) {
        self.clipsToBounds = NO;
        self.backgroundColor = [UIColor clearColor];
    }
    
    return self;
}

-(void)setupWithBundleIdentifier:(NSString*)bundleIdentifier {
    // set image
    if (bundleIdentifier == nil)
        return;
    
    self.bundleId = bundleIdentifier;
    
    if (!_baseView) {
        _baseView = [[UIView alloc] initWithFrame:CGRectZero];
        _baseView.backgroundColor = [UIColor clearColor];
        _baseView.clipsToBounds = NO;
        [self.contentView addSubview:_baseView];
    }
    
    // TODO: Rewrite icon to use SBIconImageView instead
    //UIImage *img = [UIImage _applicationIconImageForBundleIdentifier:bundleIdentifier format:2 scale:[UIScreen mainScreen].scale];
    //img = [XENNotificationsCollectionViewCell circularImage:img inRect:CGRectMake(0, 0, NOTIFICATION_ICON_SIZE, NOTIFICATION_ICON_SIZE)];
    
    //self.icon = [[UIImageView alloc] initWithImage:img];
    
    self.icon = [XENResources iconImageViewForBundleIdentifier:bundleIdentifier];
    
    self.icon.frame = CGRectMake(0, 0, NOTIFICATION_ICON_SIZE, NOTIFICATION_ICON_SIZE);
    self.icon.backgroundColor = [UIColor clearColor];
    self.icon.alpha = 0.95;
    self.icon.clipsToBounds = NO;
    
    CALayer *layer = self.icon.layer;
    layer.shadowOpacity = ([XENResources shouldUseDarkColouration] ? .35 : .75);
    layer.shadowColor = ([XENResources shouldUseDarkColouration] ? [UIColor blackColor] : [UIColor whiteColor]).CGColor;
    layer.shadowOffset = CGSizeMake(0, 0);
    layer.shadowRadius = 15;
    
    [_baseView addSubview:self.icon];
        
    self.count = [[XENLegibilityLabel alloc] initWithFrame:CGRectMake(NOTIFICATION_ICON_SIZE + NOTIFICATION_UI_SPACING, 0, NOTIFICATION_COUNT_WIDTH, NOTIFICATION_ICON_SIZE)];
    self.count.font = [UIFont systemFontOfSize:(IS_IPAD ? 24 : 21) weight:UIFontWeightLight];
    self.currentValue = 0;
    self.count.backgroundColor = [UIColor clearColor];
    self.count.textColor = [XENResources textColour];
    self.count.clipsToBounds = NO;
    
    [_baseView addSubview:self.count];

    
    [self layoutIconAndCountAfterUpdates];
}

-(void)setNotificationCount:(int)count {
    [self setNotificationCount:count animate:YES];
}

-(void)setNotificationCount:(int)count animate:(BOOL)animate {
    BOOL greater = count > self.currentValue;
    self.currentValue = count;
    self.count.text = [NSString stringWithFormat:@"%i", self.currentValue];
    
    [self layoutIconAndCountAfterUpdates];
    
    if (animate)
        [self animateForChangeOfCount:count <= 0];
    
    // Make icon glow to say we have new things available to read
    if (greater && ![[XENResources currentlyShownNotificationAppIdentifier] isEqualToString:self.bundleId]) {
        [self setNewNotificationGlow:YES];
    }
}

-(void)setCellColumn:(int)column {
    _columnForCell = column;
    
    [self layoutIconAndCountAfterUpdates];
}

-(void)layoutIconAndCountAfterUpdates {
    CGSize sizeForLabel = [XENResources getSizeForText:self.count.text maxWidth:NOTIFICATION_COUNT_WIDTH font:@"HelveticaNeue-Light" fontSize:21];
    
    CGFloat width = sizeForLabel.width + NOTIFICATION_UI_SPACING + NOTIFICATION_ICON_SIZE;
    CGFloat originX;
    
    if (_columnForCell == 1) {
        originX = 0;
    } else if (_columnForCell == [XENResources notificationCellsPerRow]) {
        originX = self.contentView.frame.size.width - width;
    } else {
        // Calculate position of cell from shit

        // Move cell to center at first...
        originX = (self.contentView.frame.size.width/2) - (width/2);
        
        // Figure out displacement due to cell location...
        /*CGFloat displacement = 0.0;
        
        if ([XENResources notificationCellsPerRow] % 2 != 0) {
            // notifications count is odd
            if (_columnForCell < [XENResources notificationCellsPerRow]/2) {
                // We're moving to the left
                displacement =
            } else {
                // We're moving to the right
            }
        } else {
            // is even - cannot be centered!
            if (_columnForCell < ([XENResources notificationCellsPerRow]/2 + 0.5)) {
                // We're moving to the left
            } else {
                // We're moving to the right
            }
        }
        
        originX += displacement;*/
    }
    
    originX = (self.contentView.bounds.size.width/2) - (width/2);
    
    _baseView.frame = CGRectMake(originX, 0, width, _baseView.frame.size.height);
}

-(void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    
    if (highlighted)
        [UIView animateWithDuration:0.05 animations:^{
            self.transform = CGAffineTransformMakeScale(1.2, 1.2);
        }];
    else
        [UIView animateWithDuration:0.075 animations:^{
            self.transform = CGAffineTransformMakeScale(1.0, 1.0);
        }];
}

-(void)animateForChangeOfCount:(BOOL)negative {
    if (!negative) {
        [UIView animateWithDuration:0.15 animations:^{
            _baseView.transform = CGAffineTransformMakeScale(1.15, 1.15);
        } completion:^(BOOL finished) {
            if (finished) {
                [UIView animateWithDuration:0.15 animations:^{
                    _baseView.transform = CGAffineTransformMakeScale(1.0, 1.0);
                }];
            }
        }];
    }
}

-(void)setNewNotificationGlow:(BOOL)isOn {
    // Start 'glowing' behind app icon to indicate a new message has arrived.
    if (isOn && self.icon.layer.shadowOpacity == 0) {
        [UIView animateWithDuration:0.2 animations:^{
            self.icon.layer.shadowOpacity = ([XENResources shouldUseDarkColouration] ? .35 : .75);
        }];
    } else if (!isOn && self.icon.layer.shadowOpacity != 0) {
        [UIView animateWithDuration:0.2 animations:^{
            self.icon.layer.shadowOpacity = .0;
        }];
    }
}

-(void)layoutSubviews {
    [super layoutSubviews];
    
    [self setNotificationCount:self.currentValue animate:NO];
}

-(void)prepareForReuse {
    if (self.icon) {
        [self.icon removeFromSuperview];
        self.icon = nil;
    }
    
    if (self.count) {
        [self.count removeFromSuperview];
        self.count = nil;
    }
    
    [_baseView removeFromSuperview];
    _baseView = nil;
    
    self.bundleId = nil;
}

-(void)dealloc {
    [self prepareForReuse];
}

@end
