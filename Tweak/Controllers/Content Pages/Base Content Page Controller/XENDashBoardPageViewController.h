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

#import "XENBaseViewController.h"

@interface XENDashBoardPageViewController : UIViewController

+ (unsigned long long)requiredCapabilities;
+ (_Bool)isAvailableForConfiguration;

- (void)setXenController:(id)contr;
- (XENBaseViewController*)xenController;
- (void)setXenVisible:(BOOL)arg1;
- (BOOL)xenVisible;
- (void)didTransitionToVisible:(_Bool)arg1;
- (void)updateTransitionToVisible:(_Bool)arg1 progress:(double)arg2 mode:(long long)arg3;
- (NSString*)_xen_identifier;
- (void)_xen_addViewIfNeeded;

@end
