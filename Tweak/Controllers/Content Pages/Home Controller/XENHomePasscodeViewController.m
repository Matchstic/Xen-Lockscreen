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

#import "XENHomePasscodeViewController.h"
#import <objc/runtime.h>

@interface SBUIPasscodeLockViewFactory : NSObject

+ (void)_commonInitPasscodeView:(id)arg1 forStyle:(int)arg2;
+ (id)_defaultPasscodeBiometricResource;
+ (id)_passcodeLockViewForStyle:(int)arg1 withLightStyle:(bool)arg2;
+ (void)_warmupKBDIfNecessary;
+ (id)installTonightPasscodeLockViewForUsersCurrentStyle;
+ (SBUIPasscodeLockViewBase*)lightPasscodeLockViewForStyle:(int)arg1;
+ (SBUIPasscodeLockViewBase*)lightPasscodeLockViewForUsersCurrentStyle;
+ (SBUIPasscodeLockViewBase*)passcodeLockViewForStyle:(int)arg1;
+ (SBUIPasscodeLockViewBase*)passcodeLockViewForUsersCurrentStyle;
+ (void)setPasscodeBiometricResource:(id)arg1;

@end

@interface SBDashBoardAction : NSObject
+ (id)actionWithType:(long long)arg1;
@property(retain, nonatomic) SBLockScreenActionContext *context;
@end

@interface SpringBoard (Passcode2)
@property(readonly, nonatomic) SBFUserAuthenticationController *authenticationController;
@end

@interface SBDashBoardBackgroundView : UIView
@property(nonatomic) long long backgroundStyle;
@end

@interface SBTelephonyManager : NSObject
+ (id)sharedTelephonyManager;
- (_Bool)emergencyCallSupported;
@end

@interface SBLockScreenManager (Emergency)
- (void)passcodeEntryAlertViewControllerWantsEmergencyCall:(id)arg1;
@end

@interface XENHomePasscodeViewController ()

@end

@implementation XENHomePasscodeViewController

-(void)loadView {
    self.view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)];
    
    _passcodeLockView = [objc_getClass("SBUIPasscodeLockViewFactory") passcodeLockViewForUsersCurrentStyle];
    
    SBFUserAuthenticationController *auth = [(SpringBoard*)[UIApplication sharedApplication] authenticationController];
    [_passcodeLockView _noteDeviceHasBeenUnlockedOnceSinceBoot:[auth hasAuthenticatedAtLeastOnceSinceBoot]];
    
    [_passcodeLockView setBackgroundAlpha:0.0];
    [_passcodeLockView setScreenOn:YES];
    [_passcodeLockView setDelegate:self];
    _passcodeLockView.frame = self.view.bounds;
    
    BOOL supportsEmergency = [[objc_getClass("SBTelephonyManager") sharedTelephonyManager] emergencyCallSupported];
    [_passcodeLockView setShowsEmergencyCallButton:supportsEmergency];
    
    _internalPasscode = [[objc_getClass("SBDashBoardPasscodeViewController") alloc] init];
    
    [self.view addSubview:_passcodeLockView];
    
    _backgroundView = [[objc_getClass("SBDashBoardBackgroundView") alloc] initWithFrame:self.view.bounds];
    _backgroundView.backgroundStyle = 6;
    _backgroundView.alpha = 1.0;
    
    [self.view sendSubviewToBack:_backgroundView];
}

-(void)viewDidLayoutSubviews {
    _passcodeLockView.frame = self.view.bounds;
    _backgroundView.frame = self.view.bounds;
}

-(void)rotateToOrientation:(int)orient {
    self.view.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
    _passcodeLockView.frame = self.view.bounds;
    _backgroundView.frame = self.view.bounds;
}

-(id)_xen_passcodeLockView {
    return _passcodeLockView;
}

-(id)_xen_backgroundView {
    return _backgroundView;
}

-(void)setDelegate:(id<SBDashBoardPasscodeViewControllerDelegate>)delegate {
    _delegate = delegate;
    _internalPasscode.delegate = delegate;
}

// Call these two to ensure biometric etc works as expected.
-(void)didBecomeUserVisible {
    
}

-(void)didEndUserVisible {
    
}

-(void)setFauxBackgroundBlurAlpha:(CGFloat)alpha {
    
}

// Imported methods that really we should inherit.
-(void)sendAction:(SBDashBoardAction*)action {
    [_internalPasscode sendAction:action];
}

-(void)dismiss {
    [_internalPasscode dismiss];
}

- (void)_passcodeLockViewPasscodeEntered:(id <SBUIPasscodeLockView>)arg1 viaMesa:(_Bool)arg2 {
    [_internalPasscode _passcodeLockViewPasscodeEntered:arg1 viaMesa:arg2];
}

- (void)passcodeLockViewPasscodeEnteredViaMesa:(id <SBUIPasscodeLockView>)arg1 {
    [self _passcodeLockViewPasscodeEntered:arg1 viaMesa:YES];
}

- (void)passcodeLockViewEmergencyCallButtonPressed:(id <SBUIPasscodeLockView>)arg1 {
    //SBDashBoardAction *action = [objc_getClass("SBDashBoardAction") actionWithType:2];
    //[self sendAction:action];
    
    [[objc_getClass("SBLockScreenManager") sharedInstance] passcodeEntryAlertViewControllerWantsEmergencyCall:self];
}

- (void)passcodeLockViewCancelButtonPressed:(id <SBUIPasscodeLockView>)arg1 {
    SBDashBoardAction *action = [objc_getClass("SBDashBoardAction") actionWithType:4];
    [self sendAction:action];
    
    [self.delegate passcodeViewControllerDidCancelPasscodeEntry:self];
    [self dismiss];
}

- (void)passcodeLockViewPasscodeEntered:(id <SBUIPasscodeLockView>)arg1 {
    [self _passcodeLockViewPasscodeEntered:arg1 viaMesa:NO];
}

- (void)passcodeLockViewPasscodeDidChange:(id <SBUIPasscodeLockView>)arg1 {
    SBFUserAuthenticationController *auth = [(SpringBoard*)[UIApplication sharedApplication] authenticationController];
    
    if ([[arg1 passcode] length] != 0) {
        [auth notePasscodeEntryBegan];
    } else {
        [auth notePasscodeEntryCancelled];
    }
    
    SBDashBoardAction *action = [objc_getClass("SBDashBoardAction") actionWithType:4];
    [self sendAction:action];
}

@end
