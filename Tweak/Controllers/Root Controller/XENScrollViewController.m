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

#import "XENScrollViewController.h"
#import "XENBaseViewController.h"
#import "XENHomeViewController.h"

@interface XENScrollViewController ()

@end

@implementation XENScrollViewController

#pragma mark Setup of UI

-(void)configureWithScrollView:(UIScrollView*)scrollView {
    [XENResources setCurrentOrientation:[[UIApplication sharedApplication] statusBarOrientation]];
    
    self.lockscreenScrollView = scrollView;
    self.lockscreenScrollView.delegate = self;
    
    //XENlog(@"Configuring for scrollView, %@", scrollView);
    
    // Load up our controllers as necessary
    [self adjustFramesForControllerAddingToScrollView:YES];
    
    self.homeViewController = [XENResources controllerWithIdentifier:@"com.matchstic.home"];
    self.homeViewController.delegate = self;
    
    XENlog(@"Finished initial scroll view configuration.");
    
    if (![XENResources isLoadedInEditMode]) {
        [[self.homeViewController.view viewWithTag:9876] removeFromSuperview];
        [[self.homeViewController.view viewWithTag:98765] removeFromSuperview];
        
        [self handleViewManagement:SCREEN_WIDTH * [self.enabledIdentifiers indexOfObject:@"com.matchstic.home"]];
        
        // Setup content offset.
        int i = (int)[self.enabledIdentifiers indexOfObject:@"com.matchstic.home"];
        
        [self.lockscreenScrollView setContentOffset:CGPointMake(SCREEN_WIDTH * i, 0) animated:NO];
        _lastKnownScrollPosition = self.lockscreenScrollView.contentOffset.x;
        
        _currentPage = i;
    }
}

-(void)handleReconfigureFromSetup {
    [XENResources clearFadeOnHomeArrowUp];
    [XENResources clearDontTouchViews];
    
    [XENResources setIsPageEditInSetup:NO];
    [XENResources setIsLoadedEditFromSetup:NO];
    
    for (NSString *identifier in self.enabledIdentifiers) {
        XENBaseViewController *controller = [XENResources controllerWithIdentifier:identifier];
        [controller resetViewForSetupDone];
        [controller.view removeFromSuperview];
    }
    
    _enabledIdentifiers = nil;
    
    // TODO: iOS 10.
    [[(SBLockScreenViewController*)[XENResources lsViewController] lockScreenView] layoutSubviews];
    [[(SBLockScreenViewController*)[XENResources lsViewController] lockScreenView] _xen_relayoutDateView];
    [[(SBLockScreenViewController*)[XENResources lsViewController] lockScreenView] _layoutSlideToUnlockView];
    
    [self adjustFramesForControllerAddingToScrollView:YES];
    [self adjustFramesForLockPages];
    
    if ([XENResources slideToUnlockModeDirection] == 2) {
        [self.homeViewController layoutPasscodeForLockPages];
    }
    
    [self postLockScreenInit];
    
    NSUInteger i = [self.enabledIdentifiers indexOfObject:@"com.matchstic.home"];
    [self handleViewManagement:SCREEN_WIDTH * i];
    
    [UIView performWithoutAnimation:^{
        [self adjustSidersForSlideEndedFinalOffset:SCREEN_WIDTH * i];
    }];
    
    [XENResources reloadNotificationListView]; // Re-layout already present Apple notification cells.
    [XENResources reloadNotificationListViewSeparators];
    
    [XENResources notificationListView].transform = CGAffineTransformMakeScale(1.0, 1.0);
    
    if ([XENResources useGroupedNotifications]) {
        // Hide the damn thing.
        [XENResources notificationListView].alpha = 0.0;
        [XENResources notificationListView].hidden = YES;
    } else {
        [XENResources notificationListView].alpha = 1.0;
        [XENResources notificationListView].hidden = NO;
    }
    
    // Handle notifications blur.
    if ([XENResources allNotificationBundleIdentifiers].count > 0) {
        if ([XENResources blurBehindNotifications]) {
            [self.homeViewController setBlurRequired:YES forRequester:@"com.matchstic.xen.notifications"];
        } else {
            [self.homeViewController setBlurRequired:NO forRequester:@"com.matchstic.xen.notifications"];
        }
    }

    if (!([XENResources mediaArtworkStyle] == 2 || [XENResources mediaArtworkStyle] == 3) && self.musicFullscreenController) {
        [self.musicFullscreenController.view removeFromSuperview];
        [self.musicFullscreenController prepareForDeconstruct];
        self.musicFullscreenController = nil;
    } else if (([XENResources mediaArtworkStyle] == 2 || [XENResources mediaArtworkStyle] == 3) && !self.musicFullscreenController) {
        [self _setupFullscreenMusicController];
    }
    
    [self moveToHomeController:NO];
}

-(void)finaliseEverythingForPostSetup {
    [XENResources setPreferenceKey:@"hasDisplayedSetupUI" withValue:@YES andPost:YES];
    [XENResources resetLockscreenDimTimer];
}

-(void)handleViewManagement:(CGFloat)currentOffset {
    // Handle view management if possible.
    // If view index <= current-2 || >= current+2 , hide it.
    // If index == current-1 || == current+1 , show it.
    
    int page = _currentPage;
    
    NSArray *identifiers = self.enabledIdentifiers;
    for (int i = 0; i < identifiers.count; i++) {
        XENBaseViewController *controller = [XENResources controllerWithIdentifier:identifiers[i]];
        
        if ([controller.uniqueIdentifier isEqualToString:@"com.matchstic.home"]) {
            continue;
        }
        
        if (i <= page - 2|| i >= page + 2) {
            if (controller.view.superview) {
                [controller.view removeFromSuperview];
                [controller notifyPreemptiveRemoval];
            }
        } else {
            if (!controller.view.superview) {
                [self.lockscreenScrollView addSubview:controller.view];
                [controller notifyPreemptiveAddition];
                
                // Reset frame?
                CGFloat val = SCREEN_WIDTH*i;
                
                if (controller.view.frame.origin.x != val)
                    controller.view.frame = CGRectMake(val, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
                
                //[self.lockscreenScrollView setNeedsDisplay];
            }
        }
    }
}

-(void)_setupLockscreenAgainIfNeeded {
    CGFloat contentWidth = SCREEN_WIDTH * self.enabledIdentifiers.count;
    
    if (self.lockscreenScrollView.contentSize.width != contentWidth)
        self.lockscreenScrollView.contentSize = CGSizeMake(contentWidth, SCREEN_HEIGHT);
    
    if (self.lockscreenScrollView.showsHorizontalScrollIndicator)
        self.lockscreenScrollView.showsHorizontalScrollIndicator = NO;
    
    if (self.lockscreenScrollView.showsVerticalScrollIndicator)
        self.lockscreenScrollView.showsVerticalScrollIndicator = NO;
    
    if (!self.lockscreenScrollView.pagingEnabled)
        self.lockscreenScrollView.pagingEnabled = YES;
    
    if (self.lockscreenScrollView.backgroundColor != [UIColor clearColor])
        self.lockscreenScrollView.backgroundColor = [UIColor clearColor];
    
    if (!self.lockscreenScrollView.alwaysBounceHorizontal)
        self.lockscreenScrollView.alwaysBounceHorizontal = YES;
    
    if (self.lockscreenScrollView.clipsToBounds)
        self.lockscreenScrollView.clipsToBounds = NO;
    
    if (self.lockscreenScrollView.scrollsToTop)
        self.lockscreenScrollView.scrollsToTop = NO;
    
    if (!self.lockscreenScrollView.multipleTouchEnabled)
        self.lockscreenScrollView.multipleTouchEnabled = YES;
}

-(void)_initialiseViews {
    if (!_initialised) {
        // Setup the views provided by this class.
    
        if (!wallpaperBlurView) {
            // Add wallpaper view!
            
            if (![XENResources blurredBackground]) {
                wallpaperBlurView = (_UIBackdropView*)[[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)];
                wallpaperBlurView.alpha = 0.0;
                wallpaperBlurView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.75];
                wallpaperBlurView.userInteractionEnabled = NO;
            } else {
                _UIBackdropViewSettings *settings = [objc_getClass("_UIBackdropViewSettings") settingsForPrivateStyle:1];
            
                wallpaperBlurView = [[objc_getClass("_UIBackdropView") alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT) autosizesToFitSuperview:NO settings:settings];
                [wallpaperBlurView setBlurRadius:0.0];
                wallpaperBlurView.alpha = 0.0;
            
                wallpaperBlurView.userInteractionEnabled = NO;
            }
            
            [self.lockscreenScrollView.superview insertSubview:wallpaperBlurView belowSubview:self.lockscreenScrollView];
            
            [XENResources setWallpaperBlurView:wallpaperBlurView];
            [XENResources setWallpaperBlurPercentage:0.0 withDuration:0.0];
        }
        
        if (([XENResources mediaArtworkStyle] == 2 || [XENResources mediaArtworkStyle] == 3) && !self.musicFullscreenController && self.lockscreenScrollView.superview && ![XENResources isLoadedInEditMode]) {
            [self _setupFullscreenMusicController];
        }
        
        if ([XENResources isLoadedInEditMode] && !self.pageArrangementController) {
            // Open page arrangement
            self.pageArrangementController = [[XENPageArrangementController alloc] init];
            self.pageArrangementController.delegate = self;
            
            [self.lockscreenScrollView.superview addSubview:self.pageArrangementController.view];
            //[self.pageArrangementController endTransitionToArrangementWithVelocity:0];
        } else {
            [self.homeViewController layoutNotificationsControllerIfAppropriate];
        }
        
        if (![XENResources hideSlideIndicators] && !_slideLeft && ![XENResources isLoadedInEditMode]) {
            // Build left and right siders. Initial frame must be offscreen, then adjust using ended move.
            _slideLeft = [XENBlurBackedImageProvider sider];
            _slideLeft.frame = CGRectMake(-_slideLeft.frame.size.width, -_slideLeft.frame.size.height, _slideLeft.frame.size.width, _slideLeft.frame.size.height);
            
            [[self.lockscreenScrollView superview] addSubview:_slideLeft];
            
            _slideRight = [XENBlurBackedImageProvider sider];
            _slideRight.frame = CGRectMake(-_slideRight.frame.size.width, -_slideRight.frame.size.height, _slideRight.frame.size.width, _slideRight.frame.size.height);
            
            [[self.lockscreenScrollView superview] addSubview:_slideRight];
            
            self.homeViewController.leftSider = _slideLeft;
            self.homeViewController.rightSider = _slideRight;
            
            [UIView performWithoutAnimation:^{
                [self adjustSidersForSlideEndedFinalOffset:self.lockscreenScrollView.contentOffset.x];
            }];
        }
        
        _initialised = YES;
    }
}

-(void)configureControllersForLock {}

-(void)postLockScreenInit {
    [self _setupLockscreenAgainIfNeeded];
    [self _initialiseViews];
    
    [self adjustFramesForLockPages];
    [XENResources relayourLockPagesControllers];
    
    // Ensure passcode view is added appropriately if going right.
    if ([XENResources slideToUnlockModeDirection] == 2) {
        [self.homeViewController layoutPasscodeForLockPages];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"XENLegibibilityDidChange" object:nil];
}

-(void)_setupFullscreenMusicController {
    self.musicFullscreenController = nil;
    self.musicFullscreenController = [[XENMusicFullscreenController alloc] init];
    
    // TODO: This needs to be on the wallpaper view so we can effectively grab the legibility settings from it.
    [self.lockscreenScrollView.superview insertSubview:self.musicFullscreenController.view belowSubview:wallpaperBlurView];
}

-(void)prepareForScreenUndim {
    int i = 0;
    for (NSString *identifier in self.enabledIdentifiers) {
        if ([identifier isEqualToString:@"com.matchstic.home"]) {
            break;
        }
        
        i++;
    }
    
    _currentPage = i;
    
    [self.lockscreenScrollView setContentOffset:CGPointMake(SCREEN_WIDTH * i, 0) animated:NO];
    _lastKnownScrollPosition = self.lockscreenScrollView.contentOffset.x;
    
    [XENResources setWallpaperBlurPercentage:([self.homeViewController wantsBlurredBackground] ? 1.0 : 0.0) withDuration:0.0];
    
    XENlog(@"Preparing for screen undim");
    
    for (NSString *identifiers in self.enabledIdentifiers) {
        XENBaseViewController *controller = [XENResources controllerWithIdentifier:identifiers];
        
        if (![identifiers isEqualToString:@"com.matchstic.home"]) {
            [controller movingToControllerWithPercent:0.0];
        }
    }
    
    [self adjustFramesForLockPages];
    [XENResources relayourLockPagesControllers];
}

-(void)addViewFromOriginalLockscreen:(UIView*)view {
    [(XENHomeViewController*)self.homeViewController addComponentToView:view];
}

-(void)adjustFramesForControllerAddingToScrollView:(BOOL)add {
    if ([XENResources isPageEditInSetup] || [XENResources isLoadedInEditMode]) {
        return;
    }
    
    int i = 0;
    for (NSString *identifier in self.enabledIdentifiers) {
        XENBaseViewController *controller = [XENResources controllerWithIdentifier:identifier];
        
        if (!controller.view) {
            [controller loadView];
        }
        
        controller.view.transform = CGAffineTransformMakeScale(1.0, 1.0);
        //controller.view.userInteractionEnabled = ![identifier isEqualToString:@"com.matchstic.passcode"];
        controller.view.userInteractionEnabled = YES;
        controller.view.frame = CGRectMake(SCREEN_WIDTH*i, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
        controller.view.layer.borderWidth = 0;
        controller.view.layer.cornerRadius = 0;
        controller.view.layer.borderColor = [UIColor clearColor].CGColor;
        
        if (add) {
            XENlog(@"Adding XEN controller: %@", controller);
            [controller configureViewForLock]; // No need to worry about backing view I think, just subviews here.
            XENlog(@"Configured...");
            
            UIView *backerFromEdit = [controller.view viewWithTag:1999];
            if (backerFromEdit) {
                [backerFromEdit removeFromSuperview];
            }
            
            BOOL canActuallyAdd = [identifier isEqualToString:@"com.matchstic.home"] || [identifier isEqualToString:@"com.matchstic.passcode"];
            
            if (canActuallyAdd)
                [self.lockscreenScrollView addSubview:controller.view];
        }
        
        i++;
    }
}

-(void)adjustFramesForLockPages {
    if ([XENResources isPageEditInSetup]) {
        return;
    }
    
    int i = 0;
    for (NSString *identifier in self.enabledIdentifiers) {
        XENBaseViewController *controller = [XENResources controllerWithIdentifier:identifier];
        
        controller.view.transform = CGAffineTransformMakeScale(1.0, 1.0);
        controller.view.userInteractionEnabled = YES;//![identifier isEqualToString:@"com.matchstic.passcode"];
        controller.view.frame = CGRectMake(SCREEN_WIDTH*i, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
        controller.view.layer.borderWidth = 0;
        controller.view.layer.cornerRadius = 0;
        controller.view.layer.borderColor = [UIColor clearColor].CGColor;

        if ([identifier hasPrefix:@"lockpages"]) {
            XENlog(@"Adding XEN controller: %@", controller);
            
            UIView *backerFromEdit = [controller.view viewWithTag:9876];
            if (backerFromEdit) {
                [backerFromEdit removeFromSuperview];
            }
            
            [self.lockscreenScrollView addSubview:controller.view];
        }
        
        i++;
    }
}

-(void)screenDidTurnOff {
    for (NSString *identifier in self.enabledIdentifiers) {
        XENBaseViewController *controller = [XENResources controllerWithIdentifier:identifier];
        [controller resetForScreenOff];
    }
    
    //[self relayoutControllerViewsForReturningTransition];
    
    [self prepareForScreenUndim];
}

-(void)moveToHomeController:(BOOL)animated {
    if (![self onHomePage]) {
        int i = (int)[self.enabledIdentifiers indexOfObject:@"com.matchstic.home"];
        
        _currentPage = i;
        
        [UIView animateWithDuration:0.4 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            [self.lockscreenScrollView setContentOffset:CGPointMake(SCREEN_WIDTH * i, 0) animated:animated];
        } completion:^(BOOL finished) {
            
        }];
        
        if (![self.homeViewController wantsBlurredBackground]) {
            [XENResources setWallpaperBlurPercentage:0.0 withDuration:0.4];
        }
        
        _lastKnownScrollPosition = self.lockscreenScrollView.contentOffset.x;
        
        [self adjustSidersForSlideEndedFinalOffset:SCREEN_WIDTH * i];
    }
}

-(void)passcodeCancelButtonWasTapped {
    if ([XENResources useSlideToUnlockMode]) {
        [self moveToHomeController:YES];
        [self.homeViewController handleReturningFromPasscodeView];
    } else {
        [self.homeViewController passcodeWasCancelled];
    }
}

-(NSArray*)enabledIdentifiers {
    if (!_enabledIdentifiers) {
        _enabledIdentifiers = [XENResources enabledControllerIdentifiers];
    }
    
    return _enabledIdentifiers;
}

-(void)makeDamnSureThatHomeIsInMiddleBeforeScreenOn {
    int page = (int)[self.enabledIdentifiers indexOfObject:@"com.matchstic.home"];
    _currentPage = page;
    
    [UIView performWithoutAnimation:^{
        [self.lockscreenScrollView setContentOffset:CGPointMake(SCREEN_WIDTH * page, 0) animated:NO];
        [self handleViewManagement:SCREEN_WIDTH * [self.enabledIdentifiers indexOfObject:@"com.matchstic.home"]];
    }];
}

#pragma mark Rotation handling

-(void)setUIMaskedForRotation:(BOOL)arg1 {
    // Send message to all controllers.
    int currentPage = (int)(self.lockscreenScrollView.contentOffset.x/self.lockscreenScrollView.bounds.size.width);
    
    NSArray *identifiers = self.enabledIdentifiers;
    for (int i = 0; i < identifiers.count; i++) {
        XENBaseViewController *controller = [XENResources controllerWithIdentifier:identifiers[i]];
        
        [UIView performWithoutAnimation:^{
            if (arg1 && i != currentPage) {
                controller.view.alpha = 0.0;
            } else {
                controller.view.alpha = 1.0;
            }
        }];
    }
}

-(void)rotateToOrientation:(int)orient {
    [XENResources setCurrentOrientation:orient];
    _isRotating = YES;
    
    // Send message to all controllers.
    int currentPage = (int)(self.lockscreenScrollView.contentOffset.x/self.lockscreenScrollView.bounds.size.width);
    
    XENlog(@"Rotating with current page: %d", currentPage);
    
    _ignoreBlurNeeded = YES;
    self.lockscreenScrollView.contentSize = CGSizeMake(SCREEN_WIDTH * self.enabledIdentifiers.count, SCREEN_HEIGHT);
    self.lockscreenScrollView.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
    [UIView performWithoutAnimation:^{
        [self.lockscreenScrollView setContentOffset:CGPointMake(SCREEN_WIDTH * currentPage, 0) animated:NO];
        _lastKnownScrollPosition = self.lockscreenScrollView.contentOffset.x;
        _ignoreBlurNeeded = NO;
        
        for (NSString *identifiers in self.enabledIdentifiers) {
            XENBaseViewController *controller = [XENResources controllerWithIdentifier:identifiers];
            
            if (![identifiers isEqualToString:@"com.matchstic.home"]) {
                [controller movingToControllerWithPercent:0.0];
            }
        }
    }];
    
    [self adjustFramesForControllerAddingToScrollView:NO];
    
    for (NSString *identifier in self.enabledIdentifiers) {
        XENBaseViewController *controller = [XENResources controllerWithIdentifier:identifier];
        [controller rotateToOrientation:orient];
    }
    
    if (self.musicFullscreenController) {
        [self.musicFullscreenController rotateToOrient:orient];
    }
    
    wallpaperBlurView.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
    
    // Sort out siders.
    if (!_adjustingSlides) {
        if (currentPage != 0) {
            // Can allow _slideLeft back into place
            _slideLeft.center = CGPointMake(-(_slideLeft.frame.size.width*0.1), SCREEN_HEIGHT*0.9);
        }
    
        if (currentPage < self.enabledIdentifiers.count-1) {
            // Can allow _slideRight back too!
            _slideRight.center = CGPointMake(SCREEN_WIDTH + (_slideRight.frame.size.width*0.1), SCREEN_HEIGHT*0.9);
        }
    }
    
    _isRotating = NO;
}

-(void)invalidateNotificationFrame {
    [self.homeViewController invalidateNotificationFrame];
}

#pragma mark UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView.isDragging) {
        _fromDrag = YES;
    }
    
    // Here, we calculate the current blur percentage, and percentage of closeness to each controller.
    CGFloat currentToOffset = [self nearestScreenWidthMultipleWithLowerBound:(scrollView.contentOffset.x < _lastKnownScrollPosition) forOffset:scrollView.contentOffset.x];
    CGFloat currentFromOffset = [self nearestScreenWidthMultipleWithLowerBound:(scrollView.contentOffset.x > _lastKnownScrollPosition) forOffset:scrollView.contentOffset.x];
    
    // Used for blur calc
    CGFloat distanceTo = currentToOffset - scrollView.contentOffset.x;
    if (distanceTo < 0) distanceTo = -distanceTo;
    
    // used for moving... calc
    CGFloat distanceFrom = scrollView.contentOffset.x - currentFromOffset;
    if (distanceFrom < 0) distanceFrom = -distanceFrom;
    
    BOOL needingBlur = [[self controllerAtOffset:currentToOffset] wantsBlurredBackground];
    BOOL neededBlur = [[self controllerAtOffset:currentFromOffset] wantsBlurredBackground];
    
    if (currentFromOffset == currentToOffset) {
        // At this point, we have arrived at the final offset.
        neededBlur = NO;
        needingBlur = [[self controllerAtOffset:currentToOffset] wantsBlurredBackground];
    }
    
    if (!_ignoreBlurNeeded) {
        if ((neededBlur && !needingBlur) || (!neededBlur && needingBlur)) {
            // We should calculate the current percent for the blur.
            CGFloat blurPercent = (needingBlur ? 1.0 - (distanceTo / SCREEN_WIDTH) : (distanceTo / SCREEN_WIDTH));
            [XENResources setWallpaperBlurPercentage:blurPercent withDuration:0.01];
        } else {
            // The blur is already at the correct level, no need to adjust.
        }
    }
    
    // Handle moving to and from controllers. This is *really* important when it comes to handling memory usage of views, and
    // also for battery usage; finish operations until showing onscreen again, and obviously vice versa.
    
    if (!_isRotating) {
        if (currentFromOffset != currentToOffset) {
            [[self controllerAtOffset:currentToOffset] movingToControllerWithPercent:1.0-(distanceTo/SCREEN_WIDTH)];
            [[self controllerAtOffset:currentFromOffset] movingToControllerWithPercent:1.0-(distanceFrom/SCREEN_WIDTH)];
        } else {
            // Arrived at final destination.
            [[self controllerAtOffset:currentToOffset] movingToControllerWithPercent:1.0];
            _currentPage = (int)(currentToOffset/self.lockscreenScrollView.frame.size.width);
        
            if (currentToOffset + SCREEN_WIDTH <= self.lockscreenScrollView.contentSize.width)
                [[self controllerAtOffset:currentToOffset + SCREEN_WIDTH] movingToControllerWithPercent:0.0];
            if (currentToOffset - SCREEN_WIDTH >= 0) {
                [[self controllerAtOffset:currentToOffset - SCREEN_WIDTH] movingToControllerWithPercent:0.0];
            }
        }
    }
    
    [self handleViewManagement:scrollView.contentOffset.x];
    
    _lastKnownScrollPosition = scrollView.contentOffset.x;
}

-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {}
-(void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {}
-(void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView {}
-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [self adjustSidersForSlideBegin];
}
-(void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    
    if (!_ignoreBlurNeeded && _fromDrag) {
        XENBaseViewController *controller = [self controllerAtOffset:targetContentOffset->x];
        [controller willMoveToControllerAfterScrollingEnds];
        [self adjustSidersForSlideEndedFinalOffset:targetContentOffset->x];
    }
}

-(CGFloat)nearestScreenWidthMultipleWithLowerBound:(BOOL)getLowerBound forOffset:(CGFloat)offset {
    // handle extremes
    if (offset < 0) return 0;
    if (offset > self.lockscreenScrollView.contentSize.width - SCREEN_WIDTH) return self.lockscreenScrollView.contentSize.width - SCREEN_WIDTH;
    
    if ((int)offset % (int)SCREEN_WIDTH == 0) {
        // Goddamn it. This offset is bang on the money.
        return offset;
    }
    
    CGFloat result = (getLowerBound ? 0 : self.lockscreenScrollView.contentSize.width - SCREEN_WIDTH);
    
    while ((getLowerBound ? offset > result + SCREEN_WIDTH : result - SCREEN_WIDTH > offset)) {
        result += (getLowerBound ? SCREEN_WIDTH : -SCREEN_WIDTH);
    }
    
    return result;
}

-(XENBaseViewController*)controllerAtOffset:(CGFloat)offset {
    int page = (int)(offset/self.lockscreenScrollView.frame.size.width);
    if (self.enabledIdentifiers.count < page + 1)
        return nil;
    
    NSString *identifier = [self.enabledIdentifiers objectAtIndex:page];
    
    return [XENResources controllerWithIdentifier:identifier];
}

-(BOOL)onHomePage {
    int i = 0;
    for (NSString *identifier in self.enabledIdentifiers) {
        if ([identifier isEqualToString:@"com.matchstic.home"]) {
            break;
        }
        
        i++;
    }
    
    int currentPage = (int)(self.lockscreenScrollView.contentOffset.x/self.lockscreenScrollView.frame.size.width);
    
    return currentPage == i;
}

-(void)notifyUnlockWillBegin {
    for (NSString *identifier in self.enabledIdentifiers) {
        XENBaseViewController *controller = [XENResources controllerWithIdentifier:identifier];
        
        [controller notifyUnlockWillBegin];
    }
}

-(BOOL)isDraggingSlideUpArrow {
    return [self.homeViewController isDraggingSlideUpArrow];
}

#pragma mark XENHomeDelegate

-(void)addWallpaperView:(UIView *)wallpaperView {
    [self.lockscreenScrollView.superview insertSubview:wallpaperView belowSubview:self.lockscreenScrollView];
}

-(void)setScrollEnabled:(BOOL)enabled {
    self.lockscreenScrollView.scrollEnabled = enabled;
}

#pragma mark Siders

-(void)adjustSidersForSlideBegin {
    CGRect leftToRect = _slideLeft.frame;
    CGRect rightToRect = _slideRight.frame;
    
    leftToRect.origin.x = -_slideLeft.frame.size.width;
    rightToRect.origin.x = SCREEN_WIDTH + _slideRight.frame.size.width;
    
    [UIView animateWithDuration:0.15 animations:^{
        _slideRight.frame = rightToRect;
        _slideLeft.frame = leftToRect;
    }];
}

-(void)adjustSidersForSlideEndedFinalOffset:(CGFloat)offset {
    if (_adjustingSlides) return;
    
    CGPoint leftToRect = _slideLeft.center;
    CGPoint rightToRect = _slideRight.center;
    
    if ((int)(offset/self.lockscreenScrollView.frame.size.width) != 0) {
        // Can allow _slideLeft back into place
        leftToRect = CGPointMake(-(_slideLeft.frame.size.width*0.1), SCREEN_HEIGHT*0.9);
    }
    
    if ((int)(offset/self.lockscreenScrollView.frame.size.width) < self.enabledIdentifiers.count-1) {
        // Can allow _slideRight back too!
        rightToRect = CGPointMake(SCREEN_WIDTH + (_slideRight.frame.size.width*0.1), SCREEN_HEIGHT*0.9);
    }
    
    [UIView animateWithDuration:0.15 animations:^{
        _slideLeft.center = leftToRect;
        _slideRight.center = rightToRect;
    }];
}

-(void)adjustSidersForUnlockPercent:(CGFloat)percent {
    // 1.0 == fully showing unlock.
    // 0.0 == normal.
    BOOL leftOnscreen = [self currentPage] != 0;
    BOOL rightOnscreen = [self currentPage] < self.enabledIdentifiers.count-1;
    
    // Calculate new centers.
    CGPoint leftCenter = CGPointMake(-(_slideLeft.frame.size.width*0.1), SCREEN_HEIGHT*0.9);
    CGPoint rightCenter = CGPointMake(SCREEN_WIDTH + (_slideRight.frame.size.width*0.1), SCREEN_HEIGHT*0.9);
    
    if (leftOnscreen) {
        // Handle left first.
        CGFloat shown1 = (_slideLeft.frame.size.width/2)-(_slideLeft.frame.size.width*0.1);
        CGFloat shown2 = shown1 * (1.0-percent);
        
        CGFloat diff = shown1 - shown2;
        
        leftCenter.x -= diff;
    }
    
    if (rightOnscreen) {
        CGFloat shown1 = (_slideRight.frame.size.width/2)-(_slideRight.frame.size.width*0.1);
        CGFloat shown2 = shown1 * (1.0-percent);
        
        CGFloat diff = shown1-shown2;
        
        rightCenter.x += diff;
    }
    
    _slideLeft.center = leftCenter;
    _slideRight.center = rightCenter;
    
    _adjustingSlides = (percent > 0);
}

-(void)adjustSidesForFullscreenWithAlpha:(CGFloat)alpha {
    _slideRight.alpha = alpha;
    _slideLeft.alpha = alpha;
}

-(int)currentPage {
    return (int)(self.lockscreenScrollView.contentOffset.x/self.lockscreenScrollView.frame.size.width);
}

-(void)invalidateControllersForLockPages {
    _enabledIdentifiers = nil;
    
    XENlog(@"Invalidated page arrangement due to LockPages");
    
    if (self.pageArrangementController) {
        [self.pageArrangementController invalidateForLockPages];
    }
}

#pragma mark View shit

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)dealloc {
    XENlog(@"*** XENScrollViewController -- dealloc");
    
    [self.pageArrangementController.view removeFromSuperview];
    self.pageArrangementController = nil;
    
    [self.musicFullscreenController.view removeFromSuperview];
    [self.musicFullscreenController prepareForDeconstruct];
    self.musicFullscreenController = nil;
    
    [wallpaperBlurView removeFromSuperview];
    wallpaperBlurView = nil;
    
    [_slideLeft removeFromSuperview];
    _slideLeft = nil;
    
    [_slideRight removeFromSuperview];
    _slideRight = nil;
    
    [XENResources setFakeSBStatusBarAlphaIfNecessary:0.0 withDuration:0.2];
}

@end
