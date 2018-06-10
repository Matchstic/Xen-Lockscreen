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

#import "XENHomeViewController.h"
#import "KTCenterFlowLayout.h"
#import "XENTouchPassThroughView.h"
#import "XENPasscodeShimController.h"

@interface CAFilter : NSObject
+(NSArray*)filterTypes;
+(CAFilter*)filterWithType:(NSString*)type;
+(CAFilter*)filterWithName:(NSString*)name;
@end

@interface XENHomeViewController ()

@end

@implementation XENHomeViewController

-(void)addPasscodeView:(UIView *)passcodeView {
    isLocked = YES;
    [XENResources setIsPasscodeLocked:YES];
    
    self.passcodeView = passcodeView;
    
    if (![XENResources useSlideToUnlockMode] && [XENResources slideToUnlockModeDirection] != 3) {
        //[self.view insertSubview:passcodeView aboveSubview:wallpaperBlurView];
        [self.view insertSubview:passcodeView aboveSubview:_darkeningView];
        
        passcodeView.hidden = YES;
        passcodeView.alpha = 0.0;
    } else {
        XENPasscodeShimController *shim = (XENPasscodeShimController*)[XENResources controllerWithIdentifier:@"com.matchstic.passcode"];
        shim.passcodeView = passcodeView;
        
        if ([UIDevice currentDevice].systemVersion.floatValue >= 10) {
            SBUIPasscodeLockViewBase *passcode = [self.iOS10PasscodeController _xen_passcodeLockView];
            shim._iOS10PasscodeView = passcode;
        }
        
        passcodeView.hidden = NO;
        passcodeView.alpha = 1.0;
    }
    
    passcodeView.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
    
    if ([passcodeView respondsToSelector:@selector(resetForScreenOff)])
        [(SBUIPasscodeLockViewBase*)passcodeView resetForScreenOff];
    else {
        passcodeView = [self.iOS10PasscodeController _xen_passcodeLockView];
        [(SBUIPasscodeLockViewBase*)passcodeView resetForScreenOff];
    }
    
    [(SBUIPasscodeLockViewBase*)passcodeView _evaluateLuminance];
    
    if ([[passcodeView class] isSubclassOfClass:objc_getClass("SBUIPasscodeLockViewWithKeyboard")]) {
        [(SBUIPasscodeLockViewBase*)passcodeView setBackgroundAlpha:0.735];
        [(SBUIPasscodeLockViewBase*)passcodeView _xen_layoutForHidingViews];
    }
}

-(void)addPasscodeViewiOS10 {
    if ([UIDevice currentDevice].systemVersion.floatValue < 10) {
        @throw @"This should not be called on older iOS versions than 10.0";
    }
    
    XENHomePasscodeViewController *p = [[XENHomePasscodeViewController alloc] init];
    p.delegate = self;
    self.iOS10PasscodeController = (SBDashBoardPasscodeViewController*)p;
    
    // iOS 10's passcodeViewController has a UIView as base, which *contains* a SBUIPasscodeLockViewBase.
    UIView *passcodeView = [self.iOS10PasscodeController view];
    [self addPasscodeView:passcodeView];
    
    _iOS10PasscodeBackgroundView = [self.iOS10PasscodeController _xen_backgroundView];
    // We handle this differently based upon unlock method!
    
    if (![XENResources useSlideToUnlockMode] && [XENResources slideToUnlockModeDirection] != 3) {
        _iOS10PasscodeBackgroundView.transform = CGAffineTransformIdentity;
        _iOS10PasscodeBackgroundView.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
        _iOS10PasscodeBackgroundView.alpha = 0.0;
        _iOS10PasscodeBackgroundView.hidden = YES;
        
        [self.view insertSubview:_iOS10PasscodeBackgroundView belowSubview:self.passcodeView];
    } else {
        [_iOS10PasscodeBackgroundView removeFromSuperview];
    }
    
    // And the background colouration too.
    SBUIPasscodeLockViewBase *passcode = [self.iOS10PasscodeController _xen_passcodeLockView];
    if ([passcode respondsToSelector:@selector(setCustomBackgroundColor:)]) {
        [passcode setCustomBackgroundColor:[UIColor clearColor]];
    }
}

-(void)passcodeViewControllerDidCancelPasscodeEntry:(XENHomePasscodeViewController *)arg1 {
    [self passcodeWasCancelled];
}

-(void)addComponentToView:(UIView*)view {
    XENlog(@"***** ADDING COMPONENT %@", view);
    
    // Handle views added to the default LS.
    
    if ([view isKindOfClass:objc_getClass("SBUIPasscodeLockViewBase")]) {
        [self addPasscodeView:view];
    } else if ([view isKindOfClass:objc_getClass("SBLockOverlayView")]) {
        [self.view addSubview:view];
    } else if ([view isKindOfClass:objc_getClass("PKGlyphView")] && ![XENResources useSlideToUnlockMode] && [XENResources slideToUnlockModeDirection] != 3) {
        [self.arrowView setLockGlyph:view];
        view.userInteractionEnabled = NO;
        [XENResources preventScrollViewCancelling:view];
    } else if ([view isKindOfClass:objc_getClass("JLUJellyLockView")] && ![XENResources useSlideToUnlockMode] && [XENResources slideToUnlockModeDirection] != 3) {
        [self.arrowView removeFromSuperview];
        [XENResources preventScrollViewCancelling:view];
        
        _usingJellyLock = YES;
        
        [self.componentsView addSubview:view];
    } else {
        [self.componentsView addSubview:view];
    }
}

#pragma mark UI related methods

-(void)loadView {
    self.view = [[XENTouchPassThroughView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)];
    self.view.backgroundColor = [UIColor clearColor];
    self.view.tag = 12345;
    self.view.clipsToBounds = YES;
    
    _darkeningView = [[XENTouchPassThroughView alloc] initWithFrame:self.view.bounds];
    _darkeningView.backgroundColor = [UIColor blackColor];
    _darkeningView.alpha = 0.0;
    _darkeningView.userInteractionEnabled = NO;
    [self.view addSubview:_darkeningView];
    
    self.componentsView = [[XENTouchPassThroughView alloc] initWithFrame:CGRectMake(-SCREEN_WIDTH, 0, SCREEN_WIDTH*2, SCREEN_HEIGHT)];
    self.componentsView.backgroundColor = [UIColor clearColor];
    
    [self.view addSubview:self.componentsView];
    
    // Notifications, ONLY if we're using grouped AND not Priority Hub
    BOOL showNotifsNormally = [XENResources useGroupedNotifications] && ![XENResources usingPriorityHubCompatiblityMode];
    BOOL showNotifsForPeek = ![XENResources useGroupedNotifications] && [XENResources peekEnabled] && [XENResources peekShowNotifications];
    if (showNotifsNormally || showNotifsForPeek) {
        [XENResources resetNotificationBundleIdentifiers];
        
        self.notificationsController = [[XENNotificationsCollectionViewController alloc] initWithCollectionViewLayout:[self layoutForNotificationsController]];
        [self.view addSubview:self.notificationsController.collectionView];
        
        if (showNotifsForPeek) {
            self.notificationsController.collectionView.hidden = YES;
            self.notificationsController.collectionView.userInteractionEnabled = NO;
            self.notificationsController.collectionView.alpha = 1.0;
        } else {
            self.notificationsController.collectionView.hidden = NO;
        }
        
        [self.notificationsController.collectionView reloadData];
        [self.notificationsController relayoutForChangeInDataSource:YES andIndex:0];
        
        for (NSString *bundleIdentifier in [XENResources allNotificationBundleIdentifiers]) {
            [self.notificationsController updateCount:[XENResources countOfNotificationsForBundleIdentifier:bundleIdentifier] forCellWithBundleIdentifier:bundleIdentifier];
        }
    }
    
    // Arrow view.
    if (![XENResources useSlideToUnlockMode] && [XENResources slideToUnlockModeDirection] != 3) {
        self.arrowView = [[XENHomeArrowView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)];
        self.arrowView.delegate = self;
        
        [XENResources preventScrollViewCancelling:self.arrowView];
        [XENResources preventScrollViewCancelling:self.arrowView.upwardsSlidingView];
    
        [self.view addSubview:self.arrowView];
    }
    
    self.welcomeController = [[XENWelcomeController alloc] init];
    int initialCount = 0;
    
    for (NSString *str in [XENResources allNotificationBundleIdentifiers]) {
        initialCount += [XENResources countOfNotificationsForBundleIdentifier:str];
    }
    
    [self.welcomeController setInitialNotifCount:initialCount];
    
    self.welcomeController.view.hidden = YES;
    self.welcomeController.view.alpha = 0.0;
    self.welcomeController.delegate = self;
    
    [self.view insertSubview:self.welcomeController.view aboveSubview:self.componentsView];
}

-(BOOL)timeIs24HourFormat {
    NSDateFormatter *formatter = [NSDateFormatter new];
    [formatter setDateStyle:NSDateFormatterNoStyle];
    [formatter setTimeStyle:NSDateFormatterShortStyle];
    NSString *dateString = [formatter stringFromDate:[NSDate date]];
    NSRange amRange = [dateString rangeOfString:[formatter AMSymbol]];
    NSRange pmRange = [dateString rangeOfString:[formatter PMSymbol]];
    BOOL is24Hour = amRange.location == NSNotFound && pmRange.location == NSNotFound;
    return is24Hour;
}

-(void)_showPasscode {
    if ([XENResources isPasscodeLocked]) {
        if (![XENResources useSlideToUnlockMode] && [XENResources slideToUnlockModeDirection] != 3) {
            [self.arrowView showPasscodeView];
            
            UIScrollView *scroll = (UIScrollView*)self.view.superview;
            [scroll setContentOffset:CGPointMake(self.view.frame.origin.x, 0) animated:YES];
        } else if ([XENResources slideToUnlockModeDirection] != 3) {
            // Make damn sure the shim is displaying the passcode.
            XENPasscodeShimController *shim = (XENPasscodeShimController*)[XENResources controllerWithIdentifier:@"com.matchstic.passcode"];
            [shim.view addSubview:shim.passcodeView];
            
            if (![[XENResources lsViewController] isKindOfClass:objc_getClass("SBDashBoardViewController")]) {
                switch ([XENResources slideToUnlockModeDirection]) {
                case 0: {
                    // Going left!
                    UIScrollView *scroll = (UIScrollView*)self.view.superview;
                    [scroll setContentOffset:CGPointMake(0, 0) animated:YES];
                    break;
                    
                } case 2: {
                    // Going right!
                    UIScrollView *scroll = (UIScrollView*)self.view.superview;
                    [scroll setContentOffset:CGPointMake(scroll.contentSize.width - SCREEN_WIDTH, 0) animated:YES];
                    break;
                    
                } default:
                    break;
                }
            } else {
                long long index = [XENResources slideToUnlockModeDirection] == 0 ? 0 : [XENResources enabledControllerIdentifiers].count-1;
                
                SBDashBoardViewController *vc = (SBDashBoardViewController*)[XENResources lsViewController];
                [vc activatePage:index animated:YES withCompletion:^{}];
            }
        }
    }
}

-(void)scrollToPage:(int)page completion:(id)completion {
    if (page == 0) {
        if ([XENResources isPasscodeLocked]) {
            if (![XENResources useSlideToUnlockMode] && [XENResources slideToUnlockModeDirection] != 3) {
                [self.arrowView showPasscodeView];
            } else if ([XENResources slideToUnlockModeDirection] != 3) {
                if (![[XENResources lsViewController] isKindOfClass:objc_getClass("SBDashBoardViewController")]) {
                    switch ([XENResources slideToUnlockModeDirection]) {
                    case 0: {
                        // Going left!
                        UIScrollView *scroll = (UIScrollView*)self.view.superview;
                        [scroll setContentOffset:CGPointMake(0, 0) animated:YES];
                        break;
                        
                    } case 2: {
                        // Going right!
                        UIScrollView *scroll = (UIScrollView*)self.view.superview;
                        [scroll setContentOffset:CGPointMake(scroll.contentSize.width - SCREEN_WIDTH, 0) animated:YES];
                        break;
                        
                    } default:
                        break;
                    }
                } else {
                    long long index = [XENResources slideToUnlockModeDirection] == 0 ? 0 : [XENResources enabledControllerIdentifiers].count-1;
                    
                    SBDashBoardViewController *vc = (SBDashBoardViewController*)[XENResources lsViewController];
                    [vc activatePage:index animated:YES withCompletion:^{}];
                }
            }
        } else
            [XENResources attemptToUnlockDeviceWithoutPasscode];
    }
}

-(BOOL)isDraggingSlideUpArrow {
    return [self.arrowView isDragging];
}

-(void)handleReturningFromPasscodeView {
    // Kill things like currently set notification action contexts
    [XENResources setLockscreenActionContext:nil];
}

-(void)adjustSidersForUnlockPercent:(CGFloat)percent {
    [self.delegate adjustSidersForUnlockPercent:percent];
}

#pragma mark Inherited things

+(BOOL)supportsCurrentiOSVersion {
    // The Xen home controller is added manually to Apple's Main controller as of iOS 10.
    return [UIDevice currentDevice].systemVersion.floatValue < 10;
}

-(NSString*)name {
    return [XENResources localisedStringForKey:@"Unlock" value:@"Unlock"];
}

-(NSString*)uniqueIdentifier {
    return @"com.matchstic.home";
}

-(void)passcodeWasCancelled {
    if (![XENResources useSlideToUnlockMode] && [XENResources slideToUnlockModeDirection] != 3)
        [self.arrowView touchesCancelled:nil withEvent:nil];
    else if ([XENResources useSlideToUnlockMode] && [UIDevice currentDevice].systemVersion.floatValue >= 10) {
        SBDashBoardViewController *vc = (SBDashBoardViewController*)[XENResources lsViewController];
        long long index = [vc _indexOfMainPage];
        
        [vc activatePage:index animated:YES withCompletion:^{}];
    }
    
    [self handleReturningFromPasscodeView];
    
    // TODO: We also need to ensure that any existing unlock contexts are cleared.
    // Handle both biometric, and plain unlock.
}

-(void)resetForScreenOff {
    // Reset arrow view
    [self passcodeWasCancelled];
    
    if ([XENResources useGroupedNotifications] && ![XENResources usingPriorityHubCompatiblityMode] && !_showingWelcome)
        [self.notificationsController resetForScreenOff];
}

-(XENDeviceSupport)supportedDevices {
    return kSupportsAll;
}

-(BOOL)wantsBlurredBackground {
    // If music playing for style 1, or a notification is showing with non-custom UI, yeah, we want blur. Initially setting those
    // before a scroll is handled by their respective shizzle.
    
    return [_blurRequests count] > 0;
}

-(void)rotateToOrientation:(int)orient {
    //self.view.frame = CGRectMake(self.view.frame, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
    self.componentsView.frame = CGRectMake(-SCREEN_WIDTH, 0, SCREEN_WIDTH*2, SCREEN_HEIGHT);
    self.arrowView.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
    _darkeningView.frame = self.view.bounds;
    self.peekBackgroundView.frame = self.view.bounds;
    
    [self.fullscreenBulletinController rotateToOrient:orient];
    [self.arrowView rotateToOrientation:orient];
    [self.notificationsController rotateToOrient:orient];
    [self.welcomeController rotateToOrient:orient];
    [(XENHomePasscodeViewController*)self.iOS10PasscodeController rotateToOrientation:orient];
    
    // Make damn sure the passcode is situated correctly.
    self.passcodeView.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
}

-(void)addChildViewController:(UIViewController *)childController {
    if ([childController isKindOfClass:[objc_getClass("SBLockScreenFullscreenBulletinViewController") class]]) {
        return;
    }
    
    [super addChildViewController:childController];
    
    [self addComponentToView:childController.view];
}

-(void)layoutNotificationsControllerIfAppropriate {
    if (self.notificationsController.collectionView.frame.size.height == 0) {
        [self.notificationsController relayoutForChangeInDataSource:YES andIndex:0];
    }
}

-(void)layoutPasscodeForLockPages {
    if ([XENResources useSlideToUnlockMode]) {
        self.passcodeView.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
        
        // Make damn sure the shim is displaying the passcode.
        XENPasscodeShimController *shim = (XENPasscodeShimController*)[XENResources controllerWithIdentifier:@"com.matchstic.passcode"];
        [shim.view addSubview:shim.passcodeView];
    }
}

#pragma mark XENArrowDelegate

-(void)didStartTouch {
    if ([UIDevice currentDevice].systemVersion.floatValue >= 10 && !self.iOS10PasscodeController && [self isLocked]) {
        [self addPasscodeViewiOS10];
    }
    
    if (!self.passcodeView)
        return;
    
    // Ensure passcode view is added to UI.
    if (![XENResources useSlideToUnlockMode] && [XENResources slideToUnlockModeDirection] != 3) {
        //[self.view insertSubview:passcodeView aboveSubview:wallpaperBlurView];
        
        UIView *above = [UIDevice currentDevice].systemVersion.floatValue >= 10 ? _iOS10PasscodeBackgroundView : _darkeningView;
        
        [self.view insertSubview:self.passcodeView aboveSubview:above];
        self.passcodeView.alpha = 0.0;
    }
}

-(BOOL)isLocked {
    return [XENResources isPasscodeLocked];
}

-(SBUIPasscodeLockViewBase*)passcodeView {
    if (_passcodeView) {
        return (SBUIPasscodeLockViewBase*)_passcodeView;
    }
    
    SBUIPasscodeLockViewBase *firstView = nil;
    
    for (UIView *view in self.view.subviews) {
        if ([view isKindOfClass:objc_getClass("SBUIPasscodeLockViewBase")]) {
            firstView = (SBUIPasscodeLockViewBase*)view;
            break;
        }
    }
    
    return firstView;
}

-(void)invalidateNotificationFrame {
    [self.notificationsController invalidateRawYOrigin];
}

-(void)setScrollEnabled:(BOOL)enabled {
    [self.delegate setScrollEnabled:enabled];
}

-(void)setWallpaperBlurWithPercent:(CGFloat)percentage {
    if (percentage > 1.0) percentage = 1.0;
    if (percentage < 0.0) percentage = 0.0;
    
    // Handle subview modification as necessary. Frames are not a problem, as it's the same co-ordinates for size, and 0,0
    if (percentage > 0.0 && [self wallpaperView].superview != self.view) {
        // Steal wallpaper view
        [self.view insertSubview:[self wallpaperView] belowSubview:[self passcodeView]];
    } else if (percentage == 0.0 && [self wallpaperView].superview == self.view) {
        // Give back wallpaper view
        [self.delegate addWallpaperView:[self wallpaperView]];
    }
    
    // Handle wallpaper blur - no need to change if already needing blur
    if (![self wantsBlurredBackground]) {
        [XENResources setWallpaperBlurPercentage:percentage withDuration:0.0];
    }
    
    // Handle darkening wallpaper blur for passcode.
    [[[self wallpaperView] viewWithTag:1337] setAlpha:percentage];
}

-(UIView*)wallpaperView {
    return [XENResources wallpaperBlurView];
}

-(void)setAlphaToExtraViews:(CGFloat)alpha {
    if ([[XENResources currentlyShownNotificationAppIdentifier] isEqualToString:@""] || ![XENResources currentlyShownNotificationAppIdentifier])
        [self.notificationsController setAlpha:alpha];
    
    self.notificationsController.fullscrenNotifButton.alpha = alpha;
    
    if (_showingWelcome) {
        [self.welcomeController setAlpha:alpha];
    }
    
    if (_iOS10PasscodeBackgroundView && ![XENResources useSlideToUnlockMode] && [XENResources slideToUnlockModeDirection] != 3) {
        CGFloat inverted = 1.0-alpha;
        
        _iOS10PasscodeBackgroundView.alpha = inverted;
        
        if (inverted > 0.0 && _iOS10PasscodeBackgroundView.hidden) {
            _iOS10PasscodeBackgroundView.hidden = NO;
        } else if (inverted == 0.0 && !_iOS10PasscodeBackgroundView.hidden) {
            _iOS10PasscodeBackgroundView.userInteractionEnabled = NO;
        }
    }
}

-(void)setHiddenToExtraViews:(BOOL)hidden {
    BOOL showNotifsPeek = ![XENResources useGroupedNotifications] && [XENResources peekShowNotifications];

    if (!showNotifsPeek && !_showingWelcome)
        self.notificationsController.collectionView.hidden = hidden;
    
    if (_showingWelcome) {
        self.welcomeController.view.hidden = hidden;
    }
}

-(void)setDarkeningViewToAlpha:(CGFloat)alpha {
    _darkeningView.alpha = alpha;
}

-(void)setPasscodeIsFirstResponder:(BOOL)arg1 {
    if ([UIDevice currentDevice].systemVersion.floatValue < 10) {
        if (arg1)
            [self.passcodeView becomeFirstResponder];
        else
            [self.passcodeView resignFirstResponder];
    } else {
        UIView *passcodeView = [self.iOS10PasscodeController _xen_passcodeLockView];
        if (arg1)
            [passcodeView becomeFirstResponder];
        else
            [passcodeView resignFirstResponder];
    }
}

#pragma mark Blur delegate

-(void)setBlurRequired:(BOOL)required forRequester:(NSString*)requester {
    if (!_blurRequests) {
        _blurRequests = [NSMutableArray array];
    }
    
    if (required) {
        [self showBlurIfNecessary];
        if (![_blurRequests containsObject:requester])
            [_blurRequests addObject:requester];
    } else {
        [_blurRequests removeObject:requester];
        [self removeBlurIfNecessary];
    }
}

-(void)showBlurIfNecessary {
    if ([_blurRequests count] == 0 && [self.delegate onHomePage]) {
        [XENResources setWallpaperBlurPercentage:1.0 withDuration:0.25];
    }
}

-(void)removeBlurIfNecessary {
    if ([_blurRequests count] == 0 && [self.delegate onHomePage]) {
        [XENResources setWallpaperBlurPercentage:0.0 withDuration:0.25];
    }
}

#pragma mark Creating and maintaining UICollectionViewLayout

-(UICollectionViewFlowLayout*)layoutForNotificationsController {
    KTCenterFlowLayout *notifLayout = [[KTCenterFlowLayout alloc] init];
    notifLayout.scrollDirection = UICollectionViewScrollDirectionVertical;
    notifLayout.itemSize = CGSizeMake(NOTIFICATION_CELL_WIDTH, NOTIFICATION_ICON_SIZE);
    notifLayout.minimumInteritemSpacing = 0;
    notifLayout.minimumLineSpacing = 30;
    
    return notifLayout;
}

-(void)updateNotificationsViewWithBundleIdentifier:(NSString*)bundleIdentifier {
    if (!bundleIdentifier) {
        XENlog(@"Not adding this bundleIdentifier to notifications, as it is nil...");
        return;
    }
    
    BOOL didMinimise = NO;
    if (![XENResources getScreenOnState] && ![bundleIdentifier isEqualToString:[XENResources currentlyShownNotificationAppIdentifier]] && ![[XENResources currentlyShownNotificationAppIdentifier] isEqualToString:@""]) {
        // Now minimise, as a new notification arrived when display is off.
        didMinimise = YES;
        [self.notificationsController removeFullscreenNotification:nil];
    }
    
    if ([XENResources addNotificationBundleIdentifier:bundleIdentifier] && self.notificationsController) {
        // Add new group at index 0
        @try {
            [self.notificationsController relayoutForChangeInDataSource:YES andIndex:0];
            [self.notificationsController.collectionView insertItemsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:0]]];
        } @catch (NSException *e) {
            XENlog(@"Exception handled when adding a notification: %@", e.reason);
        }
    }
    
    // Make sure count is set correctly too now.
    [self.notificationsController updateCount:[XENResources countOfNotificationsForBundleIdentifier:bundleIdentifier] forCellWithBundleIdentifier:bundleIdentifier];
    
    if ([XENResources autoExpandNotifications] && !didMinimise && !_showingWelcome) {
        // Breaks if minimise occured beforehand
        [self.notificationsController autoOpenIfNecessary:bundleIdentifier];
    }
    
    [self.welcomeController didRecieveNewNotification];
    
    // Blur underneath notifications if necessary
    if ([XENResources allNotificationBundleIdentifiers].count > 0 && [XENResources blurBehindNotifications]) {
        [self setBlurRequired:YES forRequester:@"com.matchstic.xen.notifications"];
    }
}

-(void)removeBundleIdentfierFromNotificationsView:(NSString*)bundleIdentifier {
    int index = [XENResources removeNotificationBundleIdentifier:bundleIdentifier];
    
    if (index >= 0 && self.notificationsController) {
        // Remove group at this index, or die trying.
        @try {
        [self.notificationsController relayoutForChangeInDataSource:NO andIndex:index];
        [self.notificationsController.collectionView deleteItemsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:index inSection:0]]];
        } @catch (NSException *e) {
            // WTF?
            XENlog(@"Caught exception when removing a bundle identifier: %@", e);
        }
        
        // Hide fullscreen notification if necessary
        if ([bundleIdentifier isEqualToString:[XENResources currentlyShownNotificationAppIdentifier]]) {
            [self.notificationsController removeFullscreenNotification:nil];
        }
    }
    
    [self.notificationsController updateCount:[XENResources countOfNotificationsForBundleIdentifier:bundleIdentifier] forCellWithBundleIdentifier:bundleIdentifier];
    
    [self.welcomeController didRemoveNotification];
    
    // Remove blur if necessary
    if ([XENResources allNotificationBundleIdentifiers].count == 0 && [XENResources blurBehindNotifications]) {
        [self setBlurRequired:NO forRequester:@"com.matchstic.xen.notifications"];
    }
}

#pragma mark Plugin view

-(void)addPluginViewToView:(UIView *)pluginView {
    [self.pluginView removeFromSuperview];
    self.pluginView = nil;
    
    self.pluginView = pluginView;
    
    BOOL underPasscode = ![XENResources useSlideToUnlockMode] && [XENResources slideToUnlockModeDirection] != 3;
    [self.view insertSubview:pluginView belowSubview:([self passcodeView] != nil && underPasscode ? [self passcodeView] : self.componentsView)];
}

#pragma mark Fullscreen bulletin controller

-(void)addFullscreenBulletinWithNotification:(id)notification title:(id)title andSubtitle:(id)subtitle {
    if (self.fullscreenBulletinController) {
        [self.fullscreenBulletinController.view removeFromSuperview];
        self.fullscreenBulletinController = nil;
    }
    
    self.fullscreenBulletinController = [[XENFullscreenBulletinViewController alloc] init];
    [self.fullscreenBulletinController setupWithFullscreenBulletinNotification:notification title:title andSubtitle:subtitle];
    [self.fullscreenBulletinController loadView];
    self.fullscreenBulletinController.view.alpha = 0.0;
    
    [[[self.view superview] superview] addSubview:self.fullscreenBulletinController.view];
    
    if (![XENResources getScreenOnState]) {
        // Minimise current notification
        [self.notificationsController removeFullscreenNotification:nil];
    }
    
    [self setBlurRequired:YES forRequester:@"fullscreen-notif"];
    
    [UIView animateWithDuration:0.3 animations:^{
        self.fullscreenBulletinController.view.alpha = 1.0;
        self.view.superview.alpha = 0.0;
        [self.delegate adjustSidesForFullscreenWithAlpha:0.2];
    } completion:^(BOOL finished) {
        [XENResources resetLockscreenDimTimer];
    }];
}

-(void)removeFullscreenBulletin {
    [UIView animateWithDuration:0.3 animations:^{
        self.fullscreenBulletinController.view.alpha = 0.0;
        self.view.superview.alpha = 1.0;
        [self.delegate adjustSidesForFullscreenWithAlpha:1.0];
        [self setBlurRequired:NO forRequester:@"fullscreen-notif"];
    } completion:^(BOOL finished) {
        [self.fullscreenBulletinController.view removeFromSuperview];
        self.fullscreenBulletinController = nil;
        
        [XENResources resetLockscreenDimTimer];
    }];
}

-(void)bounce {
    [self.arrowView bounce];
}

#pragma mark Handle Peek UI

-(void)hidePeekInterfaceForEvent:(XENPeekEvent)event {
    if (inPeek || event == kPeekEventUnlock) {
        if (event == kPeekEventButtonPress) {
            [XENResources resetLockscreenDimTimer];
        }
    
        self.arrowView.hidden = NO;
        
        self.touchStealingWindow.userInteractionEnabled = NO;
        self.touchStealingWindow.hidden = YES;
        [self.touchStealingWindow resignKeyWindow];
        self.touchStealingWindow = nil;
        
        self.view.layer.filters = nil;
        
        self.pluginView.hidden = NO;
        if (!_showingWelcome)
            self.notificationsController.view.hidden = NO;
    
        SBLockScreenView *lockscreenView = [self findLockscreenView:self.view];
        [lockscreenView setBottomGrabberHidden:NO forRequester:self];
        [lockscreenView setTopGrabberHidden:NO forRequester:self];
        [lockscreenView setBottomLeftGrabberHidden:NO forRequester:self];
        
        if (![XENResources useGroupedNotifications] || [XENResources usingPriorityHubCompatiblityMode]) {
            if (!_showingWelcome)
                [XENResources notificationListView].hidden = NO;
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"XENWallpaperChanged" object:nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"XENLegibibilityDidChange" object:nil];
        
        [UIView animateWithDuration:(event == kPeekEventButtonPress ? 0.2 : 0.01) animations:^{
            self.arrowView.alpha = 1.0;
            self.peekBackgroundView.alpha = 0.0;
            self.pluginView.alpha = 1.0;
            
            self.leftSider.alpha = 1.0;
            self.rightSider.alpha = 1.0;
            
            if (![XENResources peekShowStatusBar]) {
                [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];
            }
            
            if (![XENResources peekShowNotifications]) {
                self.notificationsController.view.alpha = 1.0;
            }
            
            if (![XENResources useGroupedNotifications] || [XENResources usingPriorityHubCompatiblityMode]) {
                [XENResources notificationListView].alpha = 1.0;
            }
            
            if (![XENResources useGroupedNotifications] && [XENResources peekShowNotifications]) {
                self.notificationsController.collectionView.alpha = 0.0;
            }
        } completion:^(BOOL finished) {
            if (finished) {
                [self.peekBackgroundView removeFromSuperview];
                self.peekBackgroundView = nil;
                
                inPeek = NO;
                
                if (![XENResources useGroupedNotifications] && [XENResources peekShowNotifications]) {
                    self.notificationsController.collectionView.hidden = YES;
                }
            }
        }];
    }
}

-(SBLockScreenView*)findLockscreenView:(UIView*)input {
    SBLockScreenView *view = (SBLockScreenView*)input;
    
    while (![[view class] isEqual:[objc_getClass("SBLockScreenView") class]] && view != nil) {
        view = (SBLockScreenView*)view.superview;
    }
    
    return view;
}

-(void)initialisePeekInterfaceIfEnabled {
    inPeek = YES;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"XENWallpaperChanged" object:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"XENLegibibilityDidChange" object:nil];
    
    [self.peekBackgroundView removeFromSuperview];
    self.peekBackgroundView = nil;
    
    self.peekBackgroundView = [[UIView alloc] initWithFrame:self.view.bounds];
    self.peekBackgroundView.backgroundColor = [UIColor blackColor];
    
    [self.view insertSubview:self.peekBackgroundView atIndex:0];
    
    // Hide arrow, grabbers, and status bar
    self.arrowView.hidden = YES;
    self.arrowView.alpha = 0.0;
    
    if (![XENResources peekShowStatusBar]) {
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationNone];
    }
    
    self.pluginView.alpha = 0.0;
    self.pluginView.hidden = YES;
    
    if (![XENResources peekShowNotifications]) {
        self.notificationsController.view.alpha = 0.0;
        self.notificationsController.view.hidden = YES;
    }
    
    if (![XENResources useGroupedNotifications] || [XENResources usingPriorityHubCompatiblityMode]) {
        [XENResources notificationListView].hidden = YES;
        [XENResources notificationListView].alpha = 0.0;
    }
    
    if (![XENResources useGroupedNotifications] && [XENResources peekShowNotifications]) {
        self.notificationsController.collectionView.hidden = NO;
        self.notificationsController.collectionView.alpha = 1.0;
    }
    
    SBLockScreenView *lockscreenView = [self findLockscreenView:self.view];
    [lockscreenView setBottomGrabberHidden:YES forRequester:self];
    [lockscreenView setTopGrabberHidden:YES forRequester:self];
    [lockscreenView setBottomLeftGrabberHidden:YES forRequester:self];
    
    self.leftSider.alpha = 0.0;
    self.rightSider.alpha = 0.0;
    
    // Greyscale mask
    
    // Prevent touch.
    self.touchStealingWindow.userInteractionEnabled = NO;
    self.touchStealingWindow.hidden = YES;
    self.touchStealingWindow = nil;
    
    self.touchStealingWindow = [[XENTouchEatingWindow alloc] initWithFrame:self.view.bounds];
    self.touchStealingWindow.backgroundColor = [UIColor clearColor];
    self.touchStealingWindow.userInteractionEnabled = YES;
    self.touchStealingWindow.windowLevel = 1075;
    
    UIPanGestureRecognizer *gesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleWindowTouch:)];
    gesture.delaysTouchesBegan = NO;
    gesture.minimumNumberOfTouches = 1;
    
    [self.touchStealingWindow addGestureRecognizer:gesture];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleWindowTap:)];
    tap.delaysTouchesBegan = NO;
    [self.touchStealingWindow addGestureRecognizer:tap];
    
    CAFilter* filter = [CAFilter filterWithName:@"colorMonochrome"];
    [filter setValue:[NSNumber numberWithFloat:-0.2] forKey:@"inputBias"];
    [filter setValue:[NSNumber numberWithFloat:1] forKey:@"inputAmount"];
    self.view.layer.filters = [NSArray arrayWithObject:filter];
    
    [self.touchStealingWindow makeKeyAndVisible];
}

-(void)handleWindowTouch:(UIPanGestureRecognizer*)sender {
    if (sender.state == UIGestureRecognizerStateBegan) {
        [(SpringBoard*)[UIApplication sharedApplication] _xen_hidePeekUIWithEvent:kPeekEventButtonPress];
    }
}

-(void)handleWindowTap:(UITapGestureRecognizer*)tap {
    [(SpringBoard*)[UIApplication sharedApplication] _xen_hidePeekUIWithEvent:kPeekEventButtonPress];
}

#pragma mark Welcome controller

-(void)showWelcomeController {
    if (!_showingWelcome) {
        _showingWelcome = YES;
        self.welcomeController.view.hidden = NO;
        [self.welcomeController prepareForDisplay];
        
        // Also, need to hide the notifications!
        dispatch_async(dispatch_get_main_queue(), ^{
            self.welcomeController.view.alpha = 1.0;
            [self hideNotificationsForWelcome];
            
            [self.welcomeController.view setNeedsDisplay];
        });
        
        [self setBlurRequired:YES forRequester:@"welcome"];
    }
}

-(void)hideNotificationsForWelcome {
    // Hiding isn't too much of an issue
    if ([XENResources useGroupedNotifications] && ![XENResources usingPriorityHubCompatiblityMode]) {
        [self.notificationsController removeFullscreenNotification:nil];
        
        // Should now be back in minimised. Hide that now.
        self.notificationsController.collectionView.alpha = 0.0;
        self.notificationsController.collectionView.hidden = YES;
    } else {
        // Just hide notification table view
        [XENResources notificationListView].hidden = YES;
        [XENResources notificationListView].alpha = 0.0;
    }
}

-(void)showNotificationsForWelcome {
    if ([XENResources useGroupedNotifications] && ![XENResources usingPriorityHubCompatiblityMode]) {
        self.notificationsController.collectionView.hidden = NO;
        [UIView animateWithDuration:0.3 animations:^{
            self.notificationsController.collectionView.alpha = 1.0;
        }];
    } else {
        // Just hide notification table view
        [XENResources notificationListView].hidden = NO;
        [UIView animateWithDuration:0.3 animations:^{
            [XENResources notificationListView].alpha = 1.0;
        }];
    }
}

-(void)hideWelcomeController {
    if (_showingWelcome) {
        _showingWelcome = NO;

        // Also, bring back notifications!
        [self showNotificationsForWelcome];
    
        [UIView animateWithDuration:0.3 animations:^{
            [self.welcomeController setAlpha:0.0];
            //self.componentsView.alpha = 1.0;
            //self.arrowView.alpha = 1.0;
        } completion:^(BOOL finished) {
            [self.welcomeController prepareForHiding];
            self.welcomeController.view.hidden = YES;
            
             //[self.delegate setScrollEnabled:YES];
        }];
        
        [self setBlurRequired:NO forRequester:@"welcome"];
    }
}

#pragma mark Navigation shit

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)deconstruct {
    self.touchStealingWindow.hidden = YES;
    [self.touchStealingWindow resignKeyWindow];
    self.touchStealingWindow = nil;
}

// View management
-(void)configureViewForLock {
    XENlog(@"Configuring home controller for new lock.");
    BOOL didLoad = !self.isViewLoaded;
    self._allowGeometryChange = YES;
    
    [super configureViewForLock];
    
    // Setup anything we destroyed upon unlock, along with Darwin notifications etc.
    
    if (didLoad) {
        // Already loaded everything freshly.
        return;
    }
    
    // Welcome controller
    int initialCount = 0;
    
    for (NSString *str in [XENResources allNotificationBundleIdentifiers]) {
        initialCount += [XENResources countOfNotificationsForBundleIdentifier:str];
    }
    
    [self.welcomeController setInitialNotifCount:initialCount];
    
    self.welcomeController.view.hidden = YES;
    self.welcomeController.view.alpha = 0.0;
    
    // Up arrow.
    
    [XENResources preventScrollViewCancelling:self.arrowView];
    [XENResources preventScrollViewCancelling:self.arrowView.upwardsSlidingView];
    self.arrowView.hidden = NO;
    self.arrowView.alpha = 1.0;
    
    // Peek.
    
    _darkeningView.alpha = 0.0;
    _darkeningView.userInteractionEnabled = NO;
    inPeek = NO;
    
    // Notifications.
    BOOL showNotifsNormally = [XENResources useGroupedNotifications] && ![XENResources usingPriorityHubCompatiblityMode];
    BOOL showNotifsForPeek = ![XENResources useGroupedNotifications] && [XENResources peekEnabled] && [XENResources peekShowNotifications];
    if ((showNotifsNormally || showNotifsForPeek) && !self.notificationsController) {
        [XENResources resetNotificationBundleIdentifiers];
        
        self.notificationsController = [[XENNotificationsCollectionViewController alloc] initWithCollectionViewLayout:[self layoutForNotificationsController]];
        [self.view addSubview:self.notificationsController.collectionView];
        
        if (showNotifsForPeek) {
            self.notificationsController.collectionView.hidden = YES;
            self.notificationsController.collectionView.userInteractionEnabled = NO;
            self.notificationsController.collectionView.alpha = 1.0;
        } else {
            self.notificationsController.collectionView.hidden = NO;
        }
        
        [self.notificationsController.collectionView reloadData];
        [self.notificationsController relayoutForChangeInDataSource:YES andIndex:0];
        
        for (NSString *bundleIdentifier in [XENResources allNotificationBundleIdentifiers]) {
            [self.notificationsController updateCount:[XENResources countOfNotificationsForBundleIdentifier:bundleIdentifier] forCellWithBundleIdentifier:bundleIdentifier];
        }
    }
    
    // Reload up arrow.
    if (![XENResources useSlideToUnlockMode] && [XENResources slideToUnlockModeDirection] != 3 && !self.arrowView) {
        self.arrowView = [[XENHomeArrowView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)];
        self.arrowView.delegate = self;
        
        [XENResources preventScrollViewCancelling:self.arrowView];
        [XENResources preventScrollViewCancelling:self.arrowView.upwardsSlidingView];
        
        [self.view addSubview:self.arrowView];
    }
    
    // Reload content view region.
    self.componentsView.frame = CGRectMake(-SCREEN_WIDTH, 0, SCREEN_WIDTH*2, SCREEN_HEIGHT);
    _darkeningView.frame = self.view.bounds;
    
    XENlog(@"Finished Home configure");
}

-(void)resetViewForUnlock {
    XENlog(@"Resetting Home for unlock.");
    
    [self deconstruct];
    
    [self.pluginView removeFromSuperview];
    self.pluginView = nil;
    
    for (UIView *view in self.componentsView.subviews) {
        [view removeFromSuperview];
    }
    
    // Reset notifications controller.
    [self.notificationsController.view removeFromSuperview];
    self.notificationsController = nil;
    
    [self.welcomeController setAlpha:0.0];
    [self.welcomeController prepareForHiding];
    self.welcomeController.view.hidden = YES;
    [self setBlurRequired:NO forRequester:@"welcome"];
    
    self.view.layer.filters = nil;
    
    [self.peekBackgroundView removeFromSuperview];
    self.peekBackgroundView = nil;
    
    [_blurRequests removeAllObjects];
    
    // TODO: Is this necessary?!
    [self.passcodeView removeFromSuperview];
    self.passcodeView = nil;
    
    [self.fullscreenBulletinController.view removeFromSuperview];
    self.fullscreenBulletinController = nil;
    
    [self passcodeWasCancelled];
    
    [self.arrowView removeFromSuperview];
    self.arrowView = nil;
    
    _showingWelcome = NO;
    inPeek = NO;
    isLocked = NO;
    [XENResources setIsPasscodeLocked:NO];
    
    if ([UIDevice currentDevice].systemVersion.floatValue >= 10) {
        if (![XENResources useSlideToUnlockMode] && [XENResources slideToUnlockModeDirection] != 3) {
            [self.passcodeView removeFromSuperview];
            self.passcodeView = nil;
        } else {
            XENPasscodeShimController *shim = (XENPasscodeShimController*)[XENResources controllerWithIdentifier:@"com.matchstic.passcode"];
            shim.passcodeView = nil;
        }
        
        self.passcodeView = nil;
        [_iOS10PasscodeBackgroundView removeFromSuperview];
        
        [self.iOS10PasscodeController removeFromParentViewController];
        self.iOS10PasscodeController = nil;
    }
    
    self._debugIsReset = YES;
}

-(void)resetViewForSetupDone {
    [self deconstruct];
    
    // Reset notifications controller.
    [self.notificationsController.view removeFromSuperview];
    self.notificationsController = nil;
    
    [self.welcomeController setAlpha:0.0];
    [self.welcomeController prepareForHiding];
    self.welcomeController.view.hidden = YES;
    [self setBlurRequired:NO forRequester:@"welcome"];
    
    self.view.layer.filters = nil;
    
    [self.peekBackgroundView removeFromSuperview];
    self.peekBackgroundView = nil;
    
    [_blurRequests removeAllObjects];
    
    [self.fullscreenBulletinController.view removeFromSuperview];
    self.fullscreenBulletinController = nil;
    
    [self passcodeWasCancelled];
    
    [self.arrowView removeFromSuperview];
    self.arrowView = nil;
    
    _showingWelcome = NO;
    inPeek = NO;
    isLocked = NO;
    [XENResources setIsPasscodeLocked:NO];
    
    self._debugIsReset = YES;
    
    // Configure passcode UI.
    if (self.passcodeView) {
        [self addPasscodeView:self.passcodeView];
    }
}

-(void)resetViewForSettingsChange:(NSDictionary*)oldSettings :(NSDictionary*)newSettings {
    // No worries about notifs, as that's reconstructed per lock.
    // Same with Peek.
    
    // This is extremely important in setup to be implemented.
    /*
     Notifications
     Up arrow
     Passcode
     Welcome Controller
     */
    
    
}

-(void)dealloc {
    [_darkeningView removeFromSuperview];
    _darkeningView = nil;
    
    _blurRequests = nil;
    
    self.touchStealingWindow.hidden = YES;
    [self.touchStealingWindow resignKeyWindow];
    self.touchStealingWindow = nil;
    
    [self.componentsView removeFromSuperview];
    self.componentsView = nil;
    
    [self.arrowView removeFromSuperview];
    self.arrowView = nil;
    
    [self.peekBackgroundView removeFromSuperview];
    self.peekBackgroundView = nil;
    
    for (UIView *view in self.view.subviews) {
        [view removeFromSuperview];
    }
}

@end
