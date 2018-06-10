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

/*
 * To initialise this controller:
 
 -init
 -_loadPages
 -_addOrRemovePagesBasedOnVisibility
 -setRevealPercentage:1.0
 -controlCenterWillPresent
 -sortedVisibleViewControllers
 
 * To retrieve a controller's frame:
 
 */

#import <UIKit/UIKit.h>

@protocol CCUIControlCenterPageContentProviding

@required

- (id)delegate;
- (void)setDelegate:(id)arg1;

@optional

- (UIEdgeInsets)contentInsets;
- (void)controlCenterDidScrollToThisPage:(bool)arg1;
- (bool)dismissModalFullScreenIfNeeded;
- (bool)wantsVisible;

@end

@interface CCUIControlCenterPageContainerViewController : UIViewController
@property (nonatomic, readonly) UIViewController<CCUIControlCenterPageContentProviding> *contentViewController;
@property (nonatomic, retain) id delegate;
@end

@interface CCUIControlCenterViewController : UIViewController

//@property (nonatomic) <CCUIControlCenterViewControllerDelegate> *delegate;
@property (nonatomic, readonly) unsigned long long numberOfActivePages;

// To init...
- (id)init;
- (void)_loadPages;
- (void)_addOrRemovePagesBasedOnVisibility;
@property (nonatomic) double revealPercentage;
@property (getter=isPresented, nonatomic) bool presented;
- (void)controlCenterWillBeginTransition;
- (void)controlCenterWillPresent;
- (void)controlCenterWillFinishTransitionOpen:(bool)arg1 withDuration:(double)arg2;
- (void)controlCenterDidFinishTransition;
- (id)sortedVisibleViewControllers;
- (id)viewControllers;
- (NSArray*)contentViewControllers;

- (CGRect)_frameForChildViewController:(id)arg1;
- (long long)_currentOrientation;

- (UIEdgeInsets)_marginEdgeInsets;
- (UIEdgeInsets)_marginInsetsForContentViewController:(id)arg1;
- (double)contentHeightForContainerView:(id)arg1;
- (double)contentHeightForOrientation:(long long)arg1;

- (UIEdgeInsets)marginInsetForContainerView:(id)arg1;
- (UIEdgeInsets)pageInsetForContainerView:(id)arg1;


@end

@interface XENControlCenterViewController : CCUIControlCenterViewController
@end
