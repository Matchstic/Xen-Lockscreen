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

#import <UIKit/UIKit.h>

@protocol XENHomeArrowDelegate <NSObject>
-(BOOL)isLocked;
-(SBUIPasscodeLockViewBase*)passcodeView;
-(UIView*)componentsView;
-(void)setWallpaperBlurWithPercent:(CGFloat)percentage;
-(UIView*)wallpaperView;
-(void)setAlphaToExtraViews:(CGFloat)alpha;
-(void)setHiddenToExtraViews:(BOOL)hidden;
-(void)setDarkeningViewToAlpha:(CGFloat)alpha;
-(void)setScrollEnabled:(BOOL)enabled;
-(void)adjustSidersForUnlockPercent:(CGFloat)percent;
-(void)didStartTouch;
-(void)setBlurRequired:(BOOL)required forRequester:(NSString*)requester;
-(void)setPasscodeIsFirstResponder:(BOOL)arg1;
@end

@interface XENHomeArrowView : UIView <UIGestureRecognizerDelegate> {
    BOOL _isDragging;
    NSDate *_lastTouchTime;
    BOOL _showingPasscode;
    UIView *_lockGlyph;
}

@property (nonatomic, weak) id<XENHomeArrowDelegate> delegate;
@property (nonatomic, strong) UIView *upwardsSlidingView;
@property (nonatomic, strong) UIImageView *upImageView;

-(void)rotateToOrientation:(UIInterfaceOrientation)orientation;
-(void)showPasscodeView;
-(void)bounce;
-(void)setLockGlyph:(UIView*)glyph;
-(BOOL)isDragging;

@end
