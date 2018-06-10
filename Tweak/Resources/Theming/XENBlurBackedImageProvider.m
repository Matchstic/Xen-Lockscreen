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

#import "XENBlurBackedImageProvider.h"
#import "XENBlurBackedImageView.h"
#import "XENTintedView.h"



@implementation XENBlurBackedImageProvider

+(_UIBackdropView*)backdropViewWithFrame:(CGRect)frame {
    _UIBackdropViewSettings *settings;
    settings = [objc_getClass("_UIBackdropViewSettings") settingsForPrivateStyle:([XENResources shouldUseDarkColouration] ? 1 : 2060)];
    
    _UIBackdropView *view = [[objc_getClass("_UIBackdropView") alloc] initWithFrame:frame autosizesToFitSuperview:NO settings:settings];
    view.tag = 2;
    
    UIView *adjustment = [[UIView alloc] initWithFrame:frame];
    adjustment.backgroundColor = [XENResources effectiveLegibilityColor];
    adjustment.alpha = 0.25;
    adjustment.tag = 9001;
    
    [view addSubview:adjustment];
    
    // Add tintable view to backdrop
    UIView *tintview = [[UIView alloc] initWithFrame:frame];
    tintview.backgroundColor = [UIColor clearColor];
    tintview.tag = 1337;
    [view addSubview:tintview];
    
    return view;
}

+(UIView*)alarmCancel {
    UIImage *upImage = [XENResources themedImageWithName:@"AlarmCancel"];
    XENBlurBackedImageView *imageView = [[XENBlurBackedImageView alloc] initWithFrame:CGRectZero];
    
    if (upImage) {
        [imageView setupWithImageView:[[UIImageView alloc] initWithImage:upImage] orBlur:nil];
    } else {
       // UIView *backingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 60, 60)];
       // backingView.backgroundColor = [UIColor clearColor];
        
        //_UIBackdropView *backdrop = [XENBlurBackedImageProvider backdropViewWithFrame:CGRectMake(0, 0, 60, 60)];
        /*XENTintedView *backdrop = [[XENTintedView alloc] initWithFrame:CGRectZero];
        backdrop.layer.masksToBounds = YES;
        backdrop.layer.cornerRadius = 30.0;
        
        CALayer *maskLayer = [CALayer layer];
        maskLayer.frame = CGRectMake(0, 0, 60, 60);
        
        maskLayer.contents = (id)[XENResources themedImageWithName:@"AlarmCancelTemplate"].CGImage;
        
        backdrop.layer.mask = maskLayer;
        
        [backingView addSubview:backdrop];
        
        [imageView setupWithImageView:nil orBlur:backingView];*/
        
        upImage = [[XENResources themedImageWithName:@"AlarmCancelTemplate"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        
        UIImageView *imgView = [[UIImageView alloc] initWithImage:upImage];
        imgView.layer.masksToBounds = YES;
        imgView.layer.cornerRadius = 30.0;
        imgView.frame = CGRectMake(0, 0, 60, 60);
        imgView.tintColor = [UIColor whiteColor];
        
        //[imageView setupWithImageView:imgView orBlur:nil];
        
        return imgView;
    }
    
    [imageView updateLegibilityIfNecessary];
    
    return imageView;
}

+(UIView*)alarmSnooze {
    UIImage *upImage = [XENResources themedImageWithName:@"AlarmSnooze"];
    XENBlurBackedImageView *imageView = [[XENBlurBackedImageView alloc] initWithFrame:CGRectZero];
    
    if (upImage) {
        [imageView setupWithImageView:[[UIImageView alloc] initWithImage:upImage] orBlur:nil];
    } else {
        /*UIView *backingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 60, 60)];
        backingView.backgroundColor = [UIColor clearColor];
        
        _UIBackdropView *backdrop = [XENBlurBackedImageProvider backdropViewWithFrame:CGRectMake(0, 0, 60, 60)];
        backdrop.layer.masksToBounds = YES;
        backdrop.layer.cornerRadius = 30.0;
        
        CALayer *maskLayer = [CALayer layer];
        maskLayer.frame = CGRectMake(0, 0, 60, 60);
        
        maskLayer.contents = (id)[XENResources themedImageWithName:@"AlarmSnoozeTemplate"].CGImage;
        
        backdrop.layer.mask = maskLayer;
        
        [backingView addSubview:backdrop];
        
        [imageView setupWithImageView:nil orBlur:backingView];*/
        
        upImage = [[XENResources themedImageWithName:@"AlarmSnoozeTemplate"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        
        UIImageView *imgView = [[UIImageView alloc] initWithImage:upImage];
        imgView.layer.masksToBounds = YES;
        imgView.layer.cornerRadius = 30.0;
        imgView.frame = CGRectMake(0, 0, 60, 60);
        imgView.tintColor = [UIColor whiteColor];
        
        //[imageView setupWithImageView:imgView orBlur:nil];
        
        return imgView;

    }
    
    return imageView;
}

+(UIView*)upArrow {
    UIImage *upImage = [XENResources themedImageWithName:@"UpArrow"];
    XENBlurBackedImageView *imageView = [[XENBlurBackedImageView alloc] initWithFrame:CGRectZero];
    
    if (upImage) {
        [imageView setupWithImageView:[[UIImageView alloc] initWithImage:upImage] orBlur:nil];
    } else {
        UIView *backingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 80, 80)];
        backingView.backgroundColor = [UIColor clearColor];
        
        _UIBackdropView *backdrop = [XENBlurBackedImageProvider backdropViewWithFrame:CGRectMake(10, 10, 60, 60)];
        backdrop.layer.masksToBounds = YES;
        backdrop.layer.cornerRadius = 30.0;
        
        /*
         * Sigh.
         *
         * On iOS 10, masking the backdrop view directly doesn't work. And, for some reason, utilising
         * UIVisualEffectView breaks everything in a horrendous way. So, we're stuck "faking" a mask.
         */
        
        // Add bezier path to create "up" shape
        if ([UIDevice currentDevice].systemVersion.floatValue < 10) {
            CAShapeLayer *maskLayer = [CAShapeLayer layer];
            maskLayer.frame = CGRectMake(0, 0, 60, 60);
            maskLayer.fillColor = [UIColor blackColor].CGColor;
        
            UIBezierPath *plusPath = [UIBezierPath new];
            plusPath.lineWidth = 2;
        
            [plusPath moveToPoint:CGPointMake(0, 33)];
            [plusPath addLineToPoint:CGPointMake(17, 33)];
            [plusPath addLineToPoint:CGPointMake(30, 22)];
            [plusPath addLineToPoint:CGPointMake(43, 33)];
            [plusPath addLineToPoint:CGPointMake(40, 33)];
            [plusPath addLineToPoint:CGPointMake(30, 25)];
            [plusPath addLineToPoint:CGPointMake(20, 33)];
            [plusPath addLineToPoint:CGPointMake(17, 33)];
            [plusPath addLineToPoint:CGPointMake(0, 33)];
            [plusPath addLineToPoint:CGPointMake(0, 60)];
            [plusPath addLineToPoint:CGPointMake(60, 60)];
            [plusPath addLineToPoint:CGPointMake(60, 0)];
            [plusPath addLineToPoint:CGPointMake(0, 0)];
            [plusPath addLineToPoint:CGPointMake(0, 37)];
        
            plusPath.usesEvenOddFillRule = YES;
            maskLayer.path = plusPath.CGPath;
        
            backdrop.layer.mask = maskLayer;
        }
        
        UIView *shading = [[UIView alloc] initWithFrame:CGRectMake(10, 10, 60, 60)];
        shading.tag = 1;
        shading.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.25];
        
        CAShapeLayer *maskLayer2 = [CAShapeLayer layer];
        maskLayer2.frame = CGRectMake(0, 0, 60, 60);
        maskLayer2.fillColor = [UIColor blackColor].CGColor;
        
        UIBezierPath *plusPath = [UIBezierPath new];
        plusPath.lineWidth = 2;
        
        [plusPath moveToPoint:CGPointMake(17, 33)];
        [plusPath addLineToPoint:CGPointMake(30, 22)];
        [plusPath addLineToPoint:CGPointMake(43, 33)];
        [plusPath addLineToPoint:CGPointMake(40, 33)];
        [plusPath addLineToPoint:CGPointMake(30, 25)];
        [plusPath addLineToPoint:CGPointMake(20, 33)];
        [plusPath addLineToPoint:CGPointMake(17, 33)];
        
        plusPath.usesEvenOddFillRule = YES;
        maskLayer2.path = plusPath.CGPath;
        
        shading.layer.mask = maskLayer2;
        
        if ([UIDevice currentDevice].systemVersion.floatValue >= 10) {
            [backingView addSubview:backdrop];
            [backingView addSubview:shading];
            
            shading.backgroundColor = [XENResources shouldUseDarkColouration] ? [UIColor colorWithWhite:1.0 alpha:0.25] : [UIColor colorWithWhite:0.0 alpha:0.25];
        } else {
            [backingView addSubview:shading];
            [backingView addSubview:backdrop];
        }
            
        [imageView setupWithImageView:nil orBlur:backingView];
    }
    
    return imageView;
}

+(UIView*)sider {
    UIImage *upImage = [XENResources themedImageWithName:@"SlideIndicator"];
    XENBlurBackedImageView *imageView = [[XENBlurBackedImageView alloc] initWithFrame:CGRectZero];
    
    if (upImage) {
        [imageView setupWithImageView:[[UIImageView alloc] initWithImage:upImage] orBlur:nil];
    } else {
        UIView *backingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 41, 41)];
        backingView.backgroundColor = [UIColor clearColor];
        
        _UIBackdropView *backdrop = [XENBlurBackedImageProvider backdropViewWithFrame:CGRectMake(0, 0, 41, 41)];
        backdrop.layer.masksToBounds = YES;
        backdrop.layer.cornerRadius = 20.5;
        backdrop.alpha = 0.35;
        
        [backingView addSubview:backdrop];
        
        [imageView setupWithImageView:nil orBlur:backingView];
    }
    
    return imageView;
}

@end
