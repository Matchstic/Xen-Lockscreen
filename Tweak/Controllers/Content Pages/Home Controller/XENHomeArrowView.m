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

#import "XENHomeArrowView.h"
#import "SKBounceAnimation.h"

typedef enum : NSUInteger {
    kXENArrowUp,
    kXENArrowDown
} XENArrowDirection;

// TODO: Check if Login is installed. If so, we defer to that for blur.

@implementation XENHomeArrowView

-(id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        _isDragging = NO;
        self.exclusiveTouch = YES;
        
        self.upwardsSlidingView = [[UIView alloc] initWithFrame:self.bounds];
        self.upImageView = (UIImageView*)[self upwardsImageView];
        CGPoint center = [self.upwardsSlidingView convertPoint:self.upwardsSlidingView.center fromView:self.upwardsSlidingView.superview];
        center.y = SCREEN_HEIGHT*0.9;
        self.upImageView.center = center;
        self.upImageView.transform = CGAffineTransformMakeScale(0.88, 0.88);
        
        UITapGestureRecognizer *tap;
        
        //if (![XENResources fadeForFirstUnlockNotify])
        tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(bounce)];
        //else
        //    tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(pulse)];
        
        if (tap) {
            tap.numberOfTapsRequired = 1;
            tap.numberOfTouchesRequired = 1;
            tap.delegate = self;
            
            [self addGestureRecognizer:tap];
        }
        
        [self.upwardsSlidingView addSubview:self.upImageView];
        [self addSubview:self.upwardsSlidingView];
    }
    
    return self;
}

-(void)setLockGlyph:(UIView*)glyph {
    _lockGlyph = glyph;
    
    _lockGlyph.center = self.upImageView.center;
    [self.upwardsSlidingView addSubview:_lockGlyph];
    self.upImageView.hidden = YES;
}

-(UIView*)upwardsImageView {
    // If no image view returned, then we use a fancy blurred version!
    /*UIImage *upImage = [UIImage imageWithContentsOfFile:[XENResources themedResourceFilePathWithName:@"up" andExtension:@"png"]];
    if (upImage) {
        return [[UIImageView alloc] initWithImage:upImage];
    } else {
        return [XENBlurBackedImageProvider upArrow];
    }*/
    
    return [XENBlurBackedImageProvider upArrow];
}

-(void)bounce {
    CGFloat animator = SCREEN_HEIGHT;
    
    //if (IS_IPAD && (orient3 == 3 || orient3 == 4))
    //    animator = SCREEN_WIDTH;
    
    [UIView animateWithDuration:0.1 animations:^{
        self.upImageView.center = CGPointMake(self.upImageView.center.x, animator*0.8);
        _lockGlyph.center = self.upImageView.center;
    } completion:^(BOOL finished){
        NSString *keyPath = @"position.y";
        id finalValue = [NSNumber numberWithFloat:animator*0.9];
        
        if (_lockGlyph) {
            [_lockGlyph.layer setValue:finalValue forKeyPath:keyPath];
        } else {
            [self.upImageView.layer setValue:finalValue forKeyPath:keyPath];
        }
        
        SKBounceAnimation *bounceAnimation = [SKBounceAnimation animationWithKeyPath:keyPath];
        bounceAnimation.fromValue = [NSNumber numberWithFloat:animator*0.8];
        bounceAnimation.toValue = finalValue;
        bounceAnimation.duration = 0.8f;
        bounceAnimation.shouldOvershoot = NO;
        bounceAnimation.stiffness = SKBounceAnimationStiffnessLight;
        bounceAnimation.numberOfBounces = 2;
        
        if (_lockGlyph) {
            [_lockGlyph.layer addAnimation:bounceAnimation forKey:@"someKey"];
        } else {
            [self.upImageView.layer addAnimation:bounceAnimation forKey:@"someKey"];
        }
        bounceAnimation = nil;
    }];
    
    [XENResources resetLockscreenDimTimer];
}

/*-(void)pulse {
    [UIView animateWithDuration:0.32 animations:^{
        self.upImageView.alpha = 0.1;
        self.upImageView.transform = CGAffineTransformMakeScale(0.75, 0.75);
    } completion:^(BOOL finished){
        [UIView animateWithDuration:0.36 animations:^{
            self.upImageView.alpha = 1.0;
            self.upImageView.transform = CGAffineTransformMakeScale(0.88, 0.88);
        }];
    }];
    
    [XENResources resetLockscreenDimTimer];
}*/

-(void)showPasscodeView {
    if (_showingPasscode) {
        return;
    }
    
    [self.delegate setBlurRequired:YES forRequester:@"passcode"];
    
    [self.delegate passcodeView].hidden = NO;
    [self.delegate passcodeView].alpha = 0.0;
    [self.delegate passcodeView].transform = CGAffineTransformMakeScale(0.6, 0.6);
    //[self.delegate wallpaperView].hidden = NO;
    if ([XENResources blurredPasscodeBackground])
        [self.delegate setWallpaperBlurWithPercent:0.0];
    
    [self.delegate setPasscodeIsFirstResponder:YES];
    
    if ([[[self.delegate passcodeView] class] isSubclassOfClass:objc_getClass("SBUIPasscodeLockViewWithKeyboard")]) {
        [[self.delegate passcodeView] setBackgroundAlpha:0.735];
        [[self.delegate passcodeView] _xen_layoutForHidingViews];
    };
    
    [UIView animateWithDuration:0.3 animations:^{
        //[self setFrame:CGRectMake(self.frame.origin.x, -SCREEN_HEIGHT, self.frame.size.width, self.frame.size.height)];
        
        [self.delegate passcodeView].alpha = 1.0;
        [self.delegate passcodeView].transform = CGAffineTransformMakeScale(1.0, 1.0);
        if ([XENResources blurredPasscodeBackground])
            [self.delegate setWallpaperBlurWithPercent:1.0];
        [self.delegate setAlphaToExtraViews:0.0];
        [self.delegate adjustSidersForUnlockPercent:1.0];
            
        [self.delegate componentsView].alpha = 0.0;
        
        [XENResources applyFadeToControllers:0.0];
        
        self.alpha = 0.0;
    } completion:^(BOOL finished) {
        // TODO: Make sure everything is good for the passcode showing, maybe set some views to hidden
        [XENResources resetLockscreenDimTimer];
        [self.delegate componentsView].hidden = YES;
        [self.delegate setHiddenToExtraViews:YES];
        self.hidden = YES;
        
        actualDifference = 0;
        
        _showingPasscode = YES;
        [XENResources setSlideUpPasscodeVisible:YES];
    }];
}

-(BOOL)isDragging {
    return _isDragging;
}

CGFloat difference;
CGFloat speed;
CGFloat direction;
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    _isDragging = YES;
    
    [self.delegate didStartTouch];
    
    CGPoint point = [[touches anyObject] locationInView:self.superview];
    difference = point.y;
    
    // TODO: Reset passcode view?
    
    XENlog(@"Device is locked: %d", [self.delegate isLocked]);
    
    [XENResources cancelLockscreenDimTimer];
    
    if ([[[self.delegate passcodeView] class] isSubclassOfClass:objc_getClass("SBUIPasscodeLockViewWithKeyboard")]) {
        [[self.delegate passcodeView] setBackgroundAlpha:0.735];
        [[self.delegate passcodeView] _xen_layoutForHidingViews];
    };
    
    if ([[self.delegate passcodeView] respondsToSelector:@selector(becomeFirstResponder)]) {
        [self.delegate setPasscodeIsFirstResponder:YES];
    }
    
    if ([self.delegate isLocked]) {
        [self.delegate passcodeView].hidden = NO;
        [self.delegate passcodeView].alpha = 0.0;
        if ([UIDevice currentDevice].systemVersion.floatValue >= 10) {
            [self.delegate passcodeView].transform = CGAffineTransformIdentity;
            [self.delegate passcodeView].frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
        }
        [self.delegate passcodeView].alpha = 0.0;
        [self.delegate passcodeView].transform = CGAffineTransformMakeScale(0.6, 0.6);
        [self.delegate wallpaperView].hidden = NO;
        if ([XENResources blurredPasscodeBackground])
            [self.delegate setWallpaperBlurWithPercent:0.0];
    }
    
    [UIView animateWithDuration:0.125 animations:^{
        self.upImageView.transform = CGAffineTransformMakeScale(1.0, 1.0);
    }];
}

CGFloat actualDifference;
-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    CGPoint pointInView = [[touches anyObject] locationInView:self.superview];
    
    CGFloat yTarget = pointInView.y - difference;
    actualDifference = yTarget;
    if (yTarget < -SCREEN_HEIGHT)
        yTarget = -SCREEN_HEIGHT;
    else if (yTarget > 0)
        yTarget = 0;
    
    NSArray *touchesArray = [touches allObjects];
    UITouch *touch;
    CGPoint ptTouch;
    CGPoint ptPrevious;
    
    touch = [touchesArray firstObject];
    ptTouch = [touch locationInView:self.superview];
    ptPrevious = [touch previousLocationInView:self.superview];
    
    NSTimeInterval interval = [[NSDate date] timeIntervalSinceDate:_lastTouchTime];
    _lastTouchTime = nil;
    _lastTouchTime = [NSDate date];
    
    CGFloat xMove = ptTouch.x - ptPrevious.x;
    CGFloat yMove = ptTouch.y - ptPrevious.y;
    CGFloat distance = sqrt ((xMove * xMove) + (yMove * yMove)); // Gotta love some pythagoras
    
    speed = distance / interval;
    
    if (yMove < 0)
        direction = kXENArrowUp;
    else
        direction = kXENArrowDown;
    
    CGFloat alpha = 1.0f - (yTarget/-SCREEN_HEIGHT*1.2);
    
    /*CGFloat bgalpha = 1.0;
    if (pointInView.y < SCREEN_HEIGHT/2) {
        bgalpha = -(1.0-(((pointInView.y+(SCREEN_HEIGHT/2))/SCREEN_HEIGHT)*2));
    }*/
    
    CGFloat passtransform = 1.0-(pointInView.y*(0.4/SCREEN_HEIGHT));
    
    [UIView animateWithDuration:0.0 animations:^{
        self.frame = CGRectMake(self.frame.origin.x, yTarget, self.frame.size.width, self.frame.size.height);
        
        if ([self.delegate isLocked]) {
            // Animate to passcode view
            [self.delegate passcodeView].alpha = 1.0-alpha;
            [self.delegate passcodeView].transform = CGAffineTransformMakeScale(passtransform, passtransform);
            if ([XENResources blurredPasscodeBackground])
                [self.delegate setWallpaperBlurWithPercent:1.0-alpha];
        } else {
            // Animate to icons (?)
            [self.delegate setDarkeningViewToAlpha:1.0-alpha];
        }
        
        // General animations
        [XENResources applyFadeToControllers:alpha];
        [self.delegate componentsView].alpha = alpha;
        [self.delegate setAlphaToExtraViews:alpha];
        [self.delegate adjustSidersForUnlockPercent:1.0-alpha];
    }];
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
    _isDragging = NO;
    BOOL unlock = NO;
    
    [UIView animateWithDuration:0.125 animations:^{
        self.upImageView.transform = CGAffineTransformMakeScale(0.88, 0.88);
    }];
    
    CGPoint endPoint = [[touches anyObject] locationInView:self.superview];
    CGFloat yTarget = endPoint.y - difference;
    
    if (yTarget > (-SCREEN_HEIGHT/2)-20)
        yTarget = 0;
    else {
        yTarget = -SCREEN_HEIGHT;
        unlock = YES;
    }
    
    CGFloat duration = 0.3;
    
    if (speed > 750 && direction == kXENArrowUp && actualDifference < -20) {
        yTarget = -SCREEN_HEIGHT;
        unlock = YES;
        
        /*if (IS_IPAD) {
            yTarget = ((is_IOS7) || (is_IOS6) ? -ls.iPadRotationSuperview.bounds.size.height : -ls.iPadRotationSuperview.frame.size.height);
        }*/
        
        //float distanceFromTop = [UIApplication sharedApplication].keyWindow.frame.size.height-(-yTarget);
        //duration = distanceFromTop/speed; // always returns 0...
        duration = 0.15; // TODO: fixme
    }
    
    if (yTarget == 0 && unlock)
        unlock = NO;
    
    if (unlock && ![self.delegate isLocked]) {
        if ([XENResources attemptToUnlockDeviceWithoutPasscode] && [UIDevice currentDevice].systemVersion.floatValue >= 10.0) {
            [UIView animateWithDuration:0.1 animations:^{
                
            }];
        }
    }
    
    [UIView animateWithDuration:(yTarget < 0 ? duration : 0.45) animations:^{
        [self setFrame:CGRectMake(self.frame.origin.x, yTarget, self.frame.size.width, self.frame.size.height)];
        
        if (unlock) {
            if ([self.delegate isLocked]) {
                [self.delegate passcodeView].alpha = 1.0;
                [self.delegate passcodeView].transform = CGAffineTransformMakeScale(1.0, 1.0);
                if ([XENResources blurredPasscodeBackground])
                    [self.delegate setWallpaperBlurWithPercent:1.0];
            } else {
                [self.delegate setDarkeningViewToAlpha:1.0];
            }
            
            [self.delegate componentsView].alpha = 0.0;
            [self.delegate setAlphaToExtraViews:0.0];
            [self.delegate adjustSidersForUnlockPercent:1.0];
        } else {
            if ([self.delegate isLocked]) {
                [self.delegate passcodeView].alpha = 0.0;
                [self.delegate passcodeView].transform = CGAffineTransformMakeScale(0.6, 0.6);
                if ([XENResources blurredPasscodeBackground])
                    [self.delegate setWallpaperBlurWithPercent:0.0];
            } else {
                [self.delegate setDarkeningViewToAlpha:0.0];
            }
            
            [self.delegate componentsView].alpha = 1.0;
            [self.delegate setAlphaToExtraViews:1.0];
            [self.delegate adjustSidersForUnlockPercent:0.0];
        }
    } completion:^(BOOL finished) {
        if (unlock) {
            if ([self.delegate isLocked]) {
                // TODO: Make sure everything is good for the passcode showing, maybe set some views to hidden
                [XENResources resetLockscreenDimTimer];
                [self.delegate componentsView].hidden = YES;
                [self.delegate setHiddenToExtraViews:YES];
                self.hidden = YES;
                
                [self.delegate setScrollEnabled:NO];
                
                [self.delegate setPasscodeIsFirstResponder:YES];
                
                _showingPasscode = YES;
                [XENResources setSlideUpPasscodeVisible:YES];
            } else {
                
                // TODO: Re-think how we handle animations for when unlocking without passcode
            }
        } else {
            [XENResources resetLockscreenDimTimer];
            
            // TODO: Reset final things for returning back to home controller
            if (![XENResources useSlideToUnlockMode])
                [self.delegate passcodeView].hidden = YES;
            //[self.delegate wallpaperView].hidden = YES;
            
            _showingPasscode = NO;
            [XENResources setSlideUpPasscodeVisible:NO];
        }
        
        actualDifference = 0;
    }];
}

-(void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    // Called on eg phone call
    XENlog(@"Touches cancelled...");
    
    _isDragging = NO;
    self.hidden = NO;
    [self.delegate componentsView].hidden = NO;
    [self.delegate setHiddenToExtraViews:NO];
    [self.delegate setScrollEnabled:YES];
    [self.delegate setBlurRequired:NO forRequester:@"passcode"];
    
    [UIView animateWithDuration:0.125 animations:^{
        self.upImageView.transform = CGAffineTransformMakeScale(0.88, 0.88);
    }];
    
    [UIView animateWithDuration:0.3 animations:^{
        [self setFrame:CGRectMake(self.frame.origin.x, 0, self.frame.size.width, self.frame.size.height)];
        
        // Use same animations here as for failing to unlock
        [self.delegate componentsView].alpha = 1.0;
        [self.delegate passcodeView].alpha = 0.0;
        [self.delegate passcodeView].transform = CGAffineTransformMakeScale(0.6, 0.6);
        if ([XENResources blurredPasscodeBackground])
            [self.delegate setWallpaperBlurWithPercent:0.0];
        [self.delegate setAlphaToExtraViews:1.0];
        [self.delegate setDarkeningViewToAlpha:0.0];
        [self.delegate adjustSidersForUnlockPercent:0.0];
        self.alpha = 1.0;
    } completion:^(BOOL finished) {
        [self.delegate passcodeView].hidden = YES;
        //[self.delegate wallpaperView].hidden = YES;
        _showingPasscode = NO;
        [XENResources setSlideUpPasscodeVisible:NO];
        
        [self.delegate setPasscodeIsFirstResponder:NO];
    }];
}

-(BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    CGRect frame = self.upImageView.frame;
    frame.size = CGSizeMake(frame.size.width+60, SCREEN_HEIGHT*0.2);
    
    frame.origin = CGPointMake(frame.origin.x-30, frame.origin.y-15);
    
    if (CGRectContainsPoint(frame, point)) {
        return YES;
    } else if (_isDragging) {
        return YES;
    } else {
        return NO;
    }
}

-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if (CGRectContainsPoint(self.upImageView.frame, [touch locationInView:self]))
        return YES;
    else
        return NO;
}

-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

-(void)rotateToOrientation:(UIInterfaceOrientation)orientation  {
    self.upwardsSlidingView.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
    self.upImageView.center = CGPointMake(SCREEN_WIDTH/2, SCREEN_HEIGHT*0.9);
    _lockGlyph.center = self.upImageView.center;
}

-(void)dealloc {
    [self.upImageView removeFromSuperview];
    self.upImageView = nil;
    
    [self.upwardsSlidingView removeFromSuperview];
    self.upwardsSlidingView = nil;
    
    _lastTouchTime = nil;
    
    for (UIView *view in self.subviews) {
        [view removeFromSuperview];
    }
}

@end
