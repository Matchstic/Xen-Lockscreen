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
 * This class handles merging pre-existing code for SBLockScreenViewController into
 * SpringBoard's fancy new SBDashBoardViewController.
 *
 * Things such as the original scroll view delegate can be scrapped, along with the blur
 * wallpaper, seeing as Apple has nicely allows us to borrow from their implementation of
 * that.
 *
 * Note that this class is created once, and now simply acts as wrapper betwen old hooks.
 * NO views are to be added to this class, nor its held lockscreenScrollView property.
*/

#import "XENDashBoardViewController.h"
#import "XENHomeViewController.h"

@interface XENDashBoardViewController ()

@end

@interface SBLockScreenManager (EH)
- (id)lockScreenViewController;
@end

__strong static id _sharedHome = nil;

@implementation XENDashBoardViewController

-(instancetype)init {
    self = [super init];
    
    if (self) {
        static dispatch_once_t p = 0;
        dispatch_once(&p, ^{
            _sharedHome = [[XENHomeViewController alloc] init];
        });
        
        self.homeViewController = _sharedHome;
    }
    
    return self;
}

-(void)configureWithScrollView:(UIScrollView*)scrollView {
    self.homeViewController.delegate = self;
    
    self.dashBoardView = [(SBDashBoardViewController*)[XENResources lsViewController] dashBoardView];
    self.lockscreenScrollView = self.dashBoardView.scrollView;
}

-(void)configureOrientation {
    /*
     * For devices that cannot rotate at the lockscreen, we should force this as portrait.
     *
     * Otherwise, we can get into the weird issue where we retrieve an orientation of
     * landscape, but a device in portrait. This occurs when the Homescreen can rotate,
     * but the lockscreen cannot; the user is in landscape Homescreen, and in-app, and
     * locking the device leads to SpringBoard staying in landscape at this call.
     */
    
    BOOL canRotate = [[[objc_getClass("SBLockScreenManager") sharedInstance] lockScreenViewController] shouldAutorotate];
    
    int orientation = canRotate ? [UIApplication sharedApplication].statusBarOrientation : 1;
    [XENResources setCurrentOrientation:orientation];
}

-(void)configureControllersForLock {
    // Make sure we initialise our UI with the right orientation.
    
    [self configureOrientation];
    
    for (NSString *identifier in [XENResources enabledControllerIdentifiers]) {
        XENBaseViewController *contr = [XENResources controllerWithIdentifier:identifier];
        contr.view.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
        [contr configureViewForLock];
    }
    
    self.homeViewController.view.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
    [self.homeViewController configureViewForLock];
}

-(void)configureControllersForUnlock {
    // Only need to do Home here.
    [self.homeViewController resetViewForUnlock];
}

-(void)handleReconfigureFromSetup {
    [XENResources clearFadeOnHomeArrowUp];
    [XENResources clearDontTouchViews];
    
    [XENResources setIsPageEditInSetup:NO];
    [XENResources setIsLoadedEditFromSetup:NO];
    
    for (NSString *identifier in self.enabledIdentifiers) {
        XENBaseViewController *controller = [XENResources controllerWithIdentifier:identifier];
        [controller resetViewForSetupDone];
    }
    
    // TODO: iOS 10.
    //[[(SBLockScreenViewController*)[XENResources lsViewController] lockScreenView] layoutSubviews];
    //[[(SBLockScreenViewController*)[XENResources lsViewController] lockScreenView] _xen_relayoutDateView];
    //[[(SBLockScreenViewController*)[XENResources lsViewController] lockScreenView] _layoutSlideToUnlockView];
    
    /*
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
    
    if (!([XENResources mediaArtworkStyle] == 2 || [XENResources mediaArtworkStyle] == 3) && self.musicFullscreenController) {
        [self.musicFullscreenController.view removeFromSuperview];
        [self.musicFullscreenController prepareForDeconstruct];
        self.musicFullscreenController = nil;
    } else if (([XENResources mediaArtworkStyle] == 2 || [XENResources mediaArtworkStyle] == 3) && !self.musicFullscreenController) {
        [self _setupFullscreenMusicController];
    }*/
    
    [self moveToHomeController:NO];
}

-(void)_setupFullscreenMusicController {
    self.musicFullscreenController = nil;
    self.musicFullscreenController = [[XENMusicFullscreenController alloc] init];
    
    [self.dashBoardView insertSubview:self.musicFullscreenController.view atIndex:0];
}

-(void)finaliseEverythingForPostSetup {
    [XENResources setPreferenceKey:@"hasDisplayedSetupUI" withValue:@YES andPost:YES];
    [XENResources resetLockscreenDimTimer];
}

-(void)_initialiseViews {
    if (!_initialised) {
        // Setup the views provided by this class.
        
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

-(UIScrollView*)lockscreenScrollView {
    SBDashBoardViewController *vc = [XENResources lsViewController];
    SBDashBoardView *view = [vc dashBoardView];
    return view.scrollView;
}

-(void)prepareForScreenUndim {}

-(void)postLockScreenInit {
    [self _initialiseViews];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"XENLegibibilityDidChange" object:nil];
}

-(void)adjustFramesForControllerAddingToScrollView:(BOOL)add {}
-(void)adjustFramesForLockPages {}

-(void)notifyUnlockWillBegin {
    for (NSString *identifier in self.enabledIdentifiers) {
        XENBaseViewController *controller = [XENResources controllerWithIdentifier:identifier];
        
        [controller notifyUnlockWillBegin];
    }
    
    [self.homeViewController notifyUnlockWillBegin];
}

-(void)screenDidTurnOff {
    for (NSString *identifier in self.enabledIdentifiers) {
        XENBaseViewController *controller = [XENResources controllerWithIdentifier:identifier];
        [controller resetForScreenOff];
    }
    
    [self.homeViewController resetForScreenOff];
}

-(void)moveToHomeController:(BOOL)animated {
    SBDashBoardViewController *vc = (SBDashBoardViewController*)[XENResources lsViewController];
    long long index = [vc _indexOfMainPage];
    
    [vc activatePage:index animated:animated withCompletion:^{}];
}

-(void)makeDamnSureThatHomeIsInMiddleBeforeScreenOn {
    [self moveToHomeController:NO];
}

-(void)rotateToOrientation:(int)orient {
    [XENResources setCurrentOrientation:orient];
    _isRotating = YES;
    
    // Note that we also need to handle the frames of each page here too.
    
    // Send message to all controllers.
    int currentPage = (int)(self.lockscreenScrollView.contentOffset.x/self.lockscreenScrollView.bounds.size.width);
    
    XENlog(@"Rotating with current page: %d", currentPage);
    
    for (NSString *identifier in self.enabledIdentifiers) {
        XENBaseViewController *controller = [XENResources controllerWithIdentifier:identifier];
        controller.view.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
        [controller rotateToOrientation:orient];
    }
    
    self.homeViewController.view.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
    [self.homeViewController rotateToOrientation:orient];
    
    if (self.musicFullscreenController) {
        [self.musicFullscreenController rotateToOrient:orient];
    }
    
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

-(BOOL)onHomePage {
    int i = 0;
    for (NSString *identifier in self.enabledIdentifiers) {
        if ([identifier isEqualToString:@"com.apple.main"]) {
            break;
        }
        
        i++;
    }
    
    int currentPage = (int)(self.lockscreenScrollView.contentOffset.x/self.lockscreenScrollView.frame.size.width);
    
    return currentPage == i;
}

-(void)dealloc {
    XENlog(@"*** XENDashBoardViewController -- dealloc");
    
    [self configureControllersForUnlock];
    
    [self.pageArrangementController.view removeFromSuperview];
    self.pageArrangementController = nil;
    
    [self.musicFullscreenController.view removeFromSuperview];
    [self.musicFullscreenController prepareForDeconstruct];
    self.musicFullscreenController = nil;
    
    [_slideLeft removeFromSuperview];
    _slideLeft = nil;
    
    [_slideRight removeFromSuperview];
    _slideRight = nil;
    
    [XENResources setFakeSBStatusBarAlphaIfNecessary:0.0 withDuration:0.2];
}

@end
