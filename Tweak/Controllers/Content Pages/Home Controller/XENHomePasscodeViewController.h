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

@class SBUIPasscodeLockView;
@class XENHomePasscodeViewController;
@class SBDashBoardBackgroundView;

@protocol SBUIPasscodeLockViewDelegate <NSObject>

@optional
- (void)passcodeLockViewPasscodeEnteredViaMesa:(id <SBUIPasscodeLockView>)arg1;
- (void)passcodeLockViewEmergencyCallButtonPressed:(id <SBUIPasscodeLockView>)arg1;
- (void)passcodeLockViewCancelButtonPressed:(id <SBUIPasscodeLockView>)arg1;
- (void)passcodeLockViewPasscodeEntered:(id <SBUIPasscodeLockView>)arg1;
- (void)passcodeLockViewPasscodeDidChange:(id <SBUIPasscodeLockView>)arg1;
@end

@protocol SBDashBoardPasscodeViewControllerDelegate
- (void)passcodeViewController:(XENHomePasscodeViewController *)arg1 didCompletePasscodeEntry:(BOOL)arg2;
- (void)passcodeViewControllerDidCancelPasscodeEntry:(XENHomePasscodeViewController *)arg1;
- (void)passcodeViewControllerDidBeginPasscodeEntry:(XENHomePasscodeViewController *)arg1;
@end



@interface XENHomePasscodeViewController : UIViewController <SBUIPasscodeLockViewDelegate> {
    _Bool _attemptingUnlock;
    SBUIPasscodeLockViewBase *_passcodeLockView;
    SBDashBoardBackgroundView *_backgroundView;
    SBDashBoardPasscodeViewController *_internalPasscode;
}

@property(nonatomic) __weak id <SBDashBoardPasscodeViewControllerDelegate> delegate;

- (void)_passcodeLockViewPasscodeEntered:(id)arg1 viaMesa:(_Bool)arg2;
-(id)_xen_passcodeLockView;
-(id)_xen_backgroundView;
-(void)rotateToOrientation:(int)orient;

@end
