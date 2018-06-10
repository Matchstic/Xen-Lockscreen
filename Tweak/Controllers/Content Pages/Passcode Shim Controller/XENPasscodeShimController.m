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

#import "XENPasscodeShimController.h"
#import "XENHomeViewController.h"

@interface XENPasscodeShimController ()

@end

@implementation XENPasscodeShimController

-(void)loadView {
    self.view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)];
    self.view.backgroundColor = [UIColor clearColor];
    self.view.tag = 12345;
    self.view.userInteractionEnabled = YES;
    
    _darkBG = [[UIView alloc] initWithFrame:self.view.bounds];
    _darkBG.backgroundColor = [UIColor blackColor];
    _darkBG.alpha = 0.0;
    _darkBG.hidden = YES;
    _darkBG.userInteractionEnabled = NO;
    
    [self.view addSubview:_darkBG];
}

-(void)setPasscodeView:(UIView *)passcodeView {
    if (!passcodeView) {
        [_passcodeView removeFromSuperview];
        passcodeView = nil;
        
        XENlog(@"REMOVED PASSCODE VIEW!");
    } else {
        _passcodeView = passcodeView;
        [self.view addSubview:_passcodeView];
    
        XENlog(@"ADDED PASSCODE VIEW!");
    }
}

-(BOOL)wantsBlurredBackground {
    // TODO: Check if Login is installed. If so, defer to that for blurring.
    
    return [XENResources isPasscodeLocked] && [XENResources blurredPasscodeBackground];
}

-(NSString*)uniqueIdentifier {
    return @"com.matchstic.passcode";
}

-(void)willMoveToControllerAfterScrollingEnds {
    XENlog(@"******** Trying to unlock...!");
    if ([XENResources attemptToUnlockDeviceWithoutPasscode] && [UIDevice currentDevice].systemVersion.floatValue >= 10.0) {
        //[UIView animateWithDuration:0.2 animations:^{
            _darkBG.alpha = 0.0;
        [XENResources setSlideUpPasscodeVisible:NO];
        //}];
    }
}

-(void)setupBackground {
    // Hell fucking yes. Time to drop background view onto LS BEHIND the scroll view.
    
    if ([UIDevice currentDevice].systemVersion.floatValue < 10.0) {
        UIView *superview = self.view.superview.superview;
        [superview insertSubview:_darkBG belowSubview:self.view.superview];
    } else {
        UIView *superview = self.view.superview.superview.superview;
        [superview insertSubview:_darkBG belowSubview:self.view.superview.superview];
    }
}

-(void)setPasscodeIsFirstResponder:(BOOL)arg1 {
    if ([UIDevice currentDevice].systemVersion.floatValue < 10) {
        if (arg1)
            [self.passcodeView becomeFirstResponder];
        else
            [self.passcodeView resignFirstResponder];
    } else {
        UIView *passcodeView = self._iOS10PasscodeView;
        if (arg1)
            [passcodeView becomeFirstResponder];
        else
            [passcodeView resignFirstResponder];
    }
}

-(void)movingToControllerWithPercent:(CGFloat)percent {
    if (percent == 1.0 && !_firstResponder) {
        [self setPasscodeIsFirstResponder:YES];
        _firstResponder = YES;
        [XENResources setSlideUpPasscodeVisible:YES];
    } else if (percent == 0.0 && _firstResponder) {
        [self setPasscodeIsFirstResponder:NO];
        _firstResponder = NO;
        [XENResources setSlideUpPasscodeVisible:NO];
    }
    
    if (![XENResources isPasscodeLocked]) {
        if (percent > 0 && !_setupForDisplay) {
            _setupForDisplay = YES;
        
            if (![XENResources isLoadedInEditMode])
                [self setupBackground];
        
            // Make sure the background layer is ready to be displayed.
            _darkBG.hidden = NO;
            _darkBG.alpha = 0.0;
        }
        
        _darkBG.alpha = percent;
    
        if (percent == 0.0) {
            // Hide again
            _setupForDisplay = NO;
            _darkBG.hidden = YES;
        } else if (percent == 1.0) {
            // La fin.
        }
    } else {
        // And ensure our passcode UI is present and correct.
        if (self.passcodeView.superview != self.view) {
            [self.view addSubview:self.passcodeView];
        }
    }
}

-(XENDeviceSupport)supportedDevices {
    return kSupportsAll;
}

-(void)resetViewForUnlock {
    [super resetViewForUnlock];
    
    [_darkBG removeFromSuperview];
    _darkBG = nil;
    
    _setupForDisplay = NO;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
