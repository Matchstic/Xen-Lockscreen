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

#import "XENBlurBackedImageView.h"

@interface CustomCoverAPI : NSObject
+ (UIView *)mainLSView;
+ (UIView *)backgroundLSView;
+ (UIColor *)primaryLSColour;
+ (UIColor *)secondaryLSColour;
+ (UIColor *)backgroundLSColour;
@end

@implementation XENBlurBackedImageView

-(id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.userInteractionEnabled = NO;
        
        // We need to register for changes from CustomCover
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleCustomCoverChanged:)
                                                     name:@"CustomCoverLockScreenColourUpdateNotification"
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleCustomCoverReset:)
                                                     name:@"CustomCoverLockScreenColourResetNotification"
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(updateLegibilityIfNecessary)
                                                     name:@"XENLegibibilityDidChange"
                                                   object:nil];
    }
    
    return self;
}

-(void)handleCustomCoverChanged:(NSNotification*)sender {
    NSDictionary *dict = [sender userInfo];
    self.imageView.tintColor = dict[@"SecondaryColour"];
    
    _UIBackdropView *backdrop;
    
    for (UIView *view in self.blurContainerView.subviews) {
        if ([view isKindOfClass:[objc_getClass("_UIBackdropView") class]]) {
            backdrop = (_UIBackdropView*)view;
            break;
        }
    }
    
    UIView *backdropViewTinter = [backdrop viewWithTag:1337];
    backdropViewTinter.backgroundColor = dict[@"SecondaryColour"];
    [backdrop viewWithTag:9001].hidden = YES;
}

-(void)handleCustomCoverReset:(NSNotification*)sender {
    self.imageView.tintColor = [UIColor clearColor];
    
    _UIBackdropView *backdrop;
    
    for (UIView *view in self.blurContainerView.subviews) {
        if ([view isKindOfClass:[objc_getClass("_UIBackdropView") class]]) {
            backdrop = (_UIBackdropView*)view;
            break;
        }
    }
    
    UIView *backdropViewTinter = [backdrop viewWithTag:1337];
    backdropViewTinter.backgroundColor = [UIColor clearColor];
    [backdrop viewWithTag:9001].hidden = NO;
}

-(void)handleNoctisEnabled:(NSNotification*)sender {
    
}

-(void)handleNoctisDisabled:(NSNotification*)sender {
    
}

-(void)setupWithImageView:(UIImageView *)img orBlur:(UIView *)blurContainer {
    [self addSubview:(img != nil ? img : blurContainer)];
    
    self.imageView = img;
    self.blurContainerView = blurContainer;
    
    if (img) {
        self.frame = CGRectMake(0, 0, self.imageView.bounds.size.width, self.imageView.bounds.size.height);
    } else {
        self.frame = CGRectMake(0, 0, self.blurContainerView.bounds.size.width, self.blurContainerView.bounds.size.height);
    }
}

-(void)updateLegibilityIfNecessary {
    if (self.blurContainerView) {
        _UIBackdropView *backdrop = (_UIBackdropView*)[self viewWithTag:2];
        UIView *shading = [self viewWithTag:1];
        UIView *adjustment = [backdrop viewWithTag:9001];
        
        if ([UIDevice currentDevice].systemVersion.floatValue >= 10) {
            shading.backgroundColor = [XENResources shouldUseDarkColouration] ? [UIColor colorWithWhite:1.0 alpha:0.25] : [UIColor colorWithWhite:0.0 alpha:0.25];
        } else {
            shading.hidden = [XENResources shouldUseDarkColouration];
        }
        adjustment.backgroundColor = [XENResources effectiveLegibilityColor];
        
        _UIBackdropViewSettings *settings = [objc_getClass("_UIBackdropViewSettings") settingsForPrivateStyle:([XENResources shouldUseDarkColouration] ? 1 : 2060)];
        [backdrop transitionToSettings:settings];
    }
}

-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    for (UIView *view in self.subviews) {
        [view removeFromSuperview];
    }
}

@end
