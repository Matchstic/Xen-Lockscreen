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
#import "XENReactiveButton.h"
#import "XENLegibilityLabel.h"

#warning Private functions used here; SBLockScreenFullscreenBulletinViewController

// In theory works up to 9.3.3.

@interface XENFullscreenBulletinViewController : UIViewController {
    NSString *_notifTitle;
    NSString *_subtitle;
    UIView *_containerView;
    UIVisualEffectView *_effectView;
}

@property (nonatomic, strong) XENReactiveButton *dismissButton;
@property (nonatomic, strong) XENReactiveButton *snoozeButton;
@property (nonatomic, strong) XENLegibilityLabel *titleLabel;
@property (nonatomic, strong) XENLegibilityLabel *subtitleLabel;
@property (nonatomic, strong) SBLockScreenFullscreenBulletinViewController *bulletinController;

-(void)setupWithFullscreenBulletinNotification:(id)notification title:(id)title andSubtitle:(id)subtitle;
-(void)rotateToOrient:(int)orientation;

@end
