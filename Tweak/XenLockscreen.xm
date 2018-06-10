/*
 *  Xen: fancy pants for the lockscreen
*/

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

#import "PrivateHeaders.h"
#import "XENDashBoardPageViewController.h"
#import "XENScrollViewController.h"
#import "XENDashBoardViewController.h"
#import "XENHomeViewController.h"
#import "XENTogglesViewController.h"
#import "XENTogglesIpadViewController.h"
#import "XENSetupWindow.h"
#import "XENLaunchpadContactsHeaders.h"
#include <dlfcn.h>
#include <time.h>
#import <notify.h>
#include "MediaRemote.h"
#include <time.h>
#include <substrate.h>

#define USE_PEEK 1

#pragma mark Comment in/out for Simulator support!

//%config(generator=internal);

/*
 Other steps to compile for actual device again:
 1. Make CydiaSubstrate linking required
 2. Turn on symbol stripping
 3. Change build target
 */

@interface XENAccelerometerHandler : NSObject
@property (nonatomic, readwrite) BOOL isUpdating;
-(instancetype)initWithThreshold:(CGFloat)threshold;
-(void)startMonitoringWithCallback:(void (^)(void))callback;
-(void)pauseMonitoring;
@end

@interface IS2System : NSObject
+ (void)respring;
@end

static int lastProximityState;
static double lastProximityTimestamp;
static BOOL shouldBeInPeekMode;
static BOOL peekIsVisble;
static BOOL pauseMonitoring;
static XENAccelerometerHandler *accelHandler;
static NSTimer *peekTimer;

static time_t lastTouchTime = time(NULL);
static NSTimer *checkShowWelcome;
static NSTimer *_significantChangeTimer;
static BOOL shownWelcomeToday = NO;

static AVFlashlight *_sharedFlashlight;

static XENScrollViewController *baseXenController;
static BOOL dontAllowScrollViewOffsetChange;
static BOOL dontScrollForLockPages;
static BOOL isLaunchpadLaunching;

static XENSetupWindow *setupWindow;

#if USE_PEEK==1
static void beginMonitoringProximity();
static void endMonitoringProximity();
static void restoreLLSleep();
static void disableLLSleep();
#endif

static void showContentEditPanel(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo);

#pragma mark Inject UI via runtime

@interface SpringBoard (Extra)
-(void)_xen_setupMidnightTimer;
@end

%hook SpringBoard

-(void)applicationDidFinishLaunching:(id)arg1 {
    %orig;
    
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 11.0 || [[UIDevice currentDevice].systemVersion floatValue] < 9.0) {
        // We don't support iOS 11 and above, or below iOS 9.
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Xen Lockscreen"
                                                        message:@"Only iOS versions 9.0 through to 10.2 are supported by this tweak."
                                                       delegate:self
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
        
        return;
    }
    
    // Let XENResources know what state the license is in. Only will affect the GUI in setup, doesn't matter if spoofed.
    
    // Handle welcome controller stuff
    checkShowWelcome = [NSTimer scheduledTimerWithTimeInterval:120.0 target:self selector:@selector(checkIfShouldShowWelcome:) userInfo:nil repeats:YES];
    
    //time_t currentTime = time(NULL);
    NSDateComponents *components = [[NSCalendar currentCalendar] components:(NSCalendarUnitHour | NSCalendarUnitMinute) fromDate:[NSDate date]];
    NSInteger hour = [components hour];
    
    if (hour >= [XENResources welcomeAdjustedTimeForFire] + 1) { // give some leeway
        shownWelcomeToday = YES;
    } else {
        shownWelcomeToday = NO; // user soon to sleep
    }
    
    lastTouchTime = time(NULL);
    
    [self _xen_setupMidnightTimer];
    
    [XENResources reloadSettings];
    
    if (![XENResources hasDisplayedSetupUI]) {
        if (![[NSFileManager defaultManager] fileExistsAtPath:@"/tmp/com.matchstic.xen.reboot_flag"])
            [[NSFileManager defaultManager] createFileAtPath:@"/tmp/com.matchstic.xen.reboot_flag" contents:[NSData data] attributes:nil];
        
        // Show setup UI!
        setupWindow = [XENSetupWindow sharedInstance];
        
        setupWindow.hidden = NO;
        [setupWindow makeKeyAndVisible];
        setupWindow.frame = CGRectMake(0, 0, SCREEN_MIN_LENGTH, SCREEN_MAX_LENGTH);
        
        SBLockScreenManager *man = [objc_getClass("SBLockScreenManager") sharedInstance];
        
        if ([man respondsToSelector:@selector(setBioUnlockingDisabled:forRequester:)]) {
            [man setBioUnlockingDisabled:YES forRequester:@"com.matchstic.xen.setup"];
        } else if ([man respondsToSelector:@selector(setBiometricAutoUnlockingDisabled:forReason:)]) {
            [man setBiometricAutoUnlockingDisabled:YES forReason:@"com.matchstic.xen.setup"];
        }
    }
}

// Wee bit extra for Cycript abusing!
%new
+(id)XEN_ivarNamed:(NSString*)varName withinObject:(id)object {
#if TARGET_IPHONE_SIMULATOR==0
    return MSHookIvar<id>(object, [varName UTF8String]);
#else
    return nil;
#endif
}

%new
-(void)_xen_setupMidnightTimer {
    NSCalendar *gregorian = [NSCalendar currentCalendar];
    NSDateComponents *todayComponents = [gregorian components:(NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear) fromDate:[NSDate date]];
    NSInteger theDay = [todayComponents day];
    NSInteger theMonth = [todayComponents month];
    NSInteger theYear = [todayComponents year];
    
    NSDateComponents *components = [[NSDateComponents alloc] init];
    [components setDay:theDay];
    [components setMonth:theMonth];
    [components setYear:theYear];
    NSDate *thisDate = [gregorian dateFromComponents:components];
    
    // now build a NSDate object for the next day
    NSDateComponents *offsetComponents = [[NSDateComponents alloc] init];
    [offsetComponents setDay:1];
    NSDate *nextDate = [gregorian dateByAddingComponents:offsetComponents toDate:thisDate options:0];
    
    _significantChangeTimer = [NSTimer scheduledTimerWithTimeInterval:[nextDate timeIntervalSinceDate:[NSDate date]] target:self selector:@selector(_xen_midnightTimerFired:) userInfo:nil repeats:NO];
}

%new
-(void)_xen_midnightTimerFired:(id)sender {
    shownWelcomeToday = NO;
    
    [self _xen_setupMidnightTimer];
}

%new
-(void)checkIfShouldShowWelcome:(id)sender {
    if (![XENResources enabled] || ![XENResources useWelcomeController]) {
        return;
    }
    
    if (shownWelcomeToday) {
        return;
    }
    
    time_t currentTime = time(NULL);
    
    NSDateComponents *components = [[NSCalendar currentCalendar] components:(NSCalendarUnitHour | NSCalendarUnitMinute) fromDate:[NSDate date]];
    NSInteger hour = [components hour];
    
    // Can only start to show welcome if display off for 2 hours+ and it's past the user's adjusted time.
    if (difftime(currentTime, lastTouchTime) >= (60*60*2) && hour >= [XENResources welcomeAdjustedTimeForFire] && ![XENResources getScreenOnState] && baseXenController) {
        shownWelcomeToday = YES;
        [baseXenController.homeViewController showWelcomeController];
    }
}

%end

#pragma mark Inject (<= iOS 9)

%group SpringBoard

%hook SBLockScreenScrollView

-(id)initWithFrame:(CGRect)frame {
    id original = %orig;
    
    [XENResources reloadSettings];
    
    if ([XENResources enabled]) {
        XENlog(@"Injecting Xen UI");
        object_setClass(original, objc_getClass("XENScrollView"));

        baseXenController = [[XENScrollViewController alloc] init];
        [baseXenController configureWithScrollView:original];
        
        lastTouchTime = time(NULL);
    }
    
    return original;
}

%end

%hook XENScrollView

-(void)setDelegate:(id)delegate {
    // Only allow us to control this scrollview
    if ([delegate isKindOfClass:[XENScrollViewController class]] && [XENResources enabled]) {
        %orig;
    } else if (![XENResources enabled]) {
        %orig;
    }
}

-(void)addSubview:(UIView*)subview {
    if ([XENResources enabled] && subview.tag != 12345) {
        [baseXenController addViewFromOriginalLockscreen:subview];
    } else {
        %orig;
    }
}

// Prevent touches cancelling for things like the up arrow
- (BOOL)touchesShouldCancelInContentView:(UIView *)view {
    BOOL orig = %orig;
    
    for (NSValue *value in [XENResources dontCancelTouchesInTheseViews]) {
        UIView *view2 = [value nonretainedObjectValue];
        
        if (!view2) {
            XENlog(@"ERROR: Could not verify against view. Were cancel touch views reset?");
            continue;
        }
        
        orig = ([view isEqual:view2]) ? NO : orig;
    }
    
    return orig;
}

-(void)setContentOffset:(CGFloat)offset {
    // Prevents Apple's layoutSubviews from fucking us over. Also same for LockPages
    if (!dontAllowScrollViewOffsetChange && !dontScrollForLockPages)
        %orig;
    
    dontScrollForLockPages = NO;
}

%end

%hook SBLockScreenViewController

-(void)addChildViewController:(UIViewController *)childController {
    if ([XENResources enabled]) {
        [(UIViewController*)[baseXenController homeViewController] addChildViewController:childController];
    } else {
        %orig;
    }
}

%end

#pragma mark Inject (iOS 10+)

/*
 * It can be assumed that +availableForConfiguration is a per-respring flag to Apple as to whether to load
 * a given page. You will need to manually handle cases when your pages can be hidden.
 */

%hook SBDashBoardViewController

- (id)initWithPageViewControllers:(NSArray*)arg1 mainPageViewController:(SBDashBoardPageViewController*)arg2 legibilityProvider:(id)arg3 {
    NSMutableArray *newArray = [NSMutableArray array];
    [newArray addObjectsFromArray:arg1];
    
    for (XENBaseViewController *contr in [XENResources availableViewControllers]) {
        XENDashBoardPageViewController *pageCont = [[objc_getClass("XENDashBoardPageViewController") alloc] init];
        pageCont.xenController = contr;
        
        [newArray addObject:pageCont];
    }
    
    id original = %orig(newArray, arg2, arg3);
    
    if (original) {
        [XENResources setLsViewController:original];
    
        // Legibility stuff
        [[NSNotificationCenter defaultCenter] addObserver:original
                                             selector:@selector(_updateLegibilitySettings)
                                                 name:@"XENWallpaperChanged"
                                               object:nil];
    }
    
    return original;
}

-(void)_setAllowedPageViewControllers:(NSArray*)controllers {
    // This is where we can set our ordering of pages! Neat, huh.
    
    if ([XENResources enabled]) {
        XENlog(@"Arranging pages...");
        
        NSArray *originalOrder = controllers;
        NSMutableArray *newOrder = [NSMutableArray array];
        NSArray *enabled = [XENResources enabledControllerIdentifiers];
    
        for (NSString *identifier in enabled) {
            SBDashBoardPageViewController *controller = [self _xen_fetchWithIdentifier:identifier andArray:originalOrder];
            if (controller)
                [newOrder addObject:controller];
        
            // Re-add views if necessary after unlocking.
            if ([controller respondsToSelector:@selector(_xen_addViewIfNeeded)]) {
                [(XENDashBoardPageViewController*)controller _xen_addViewIfNeeded];
            }
        }
        
        // TODO: Of those in originalOrder not in newOrder, we should unload their view. (TODO)
        
        %orig(newOrder);
    } else {
        /* 
         * When Xen is disabled, all pages are added regardless. Thus, the order must end up
         * representing all non-Xen pages, yet still maintain the order it came in with.
         *
         * To do this, we will iterate over the array coming in, and strip out any objects of class
         * XENDashBoardPageViewController
         *
         * Note: After the allowed controllers has it's order modified once, it will not become invalidated.
         * Thus, any previous changes to the array will remain present here when toggling Xen off when 
         * SpringBoard is running.
         */
        
        NSMutableArray *newOrder = [NSMutableArray array];
        for (id object in controllers) {
            if (![object isKindOfClass:objc_getClass("XENDashBoardPageViewController")]) {
                [newOrder addObject:object];
            }
        }
        
        // We now have the pages we want, but we should then arrange them back into the original order.
        // I do not know how other tweaks will handle this just yet, but as such:
        // TODO: Check with angelXwind how LockPages will provide its ordering so we can handle it here. (TODO)
        // TODO: Check how RTL support is handled for the original lockscreen layout. (TODO)
        
        NSMutableArray *finalOrder = [NSMutableArray array];
        NSArray *enabled = @[@"com.apple.today", @"com.apple.main", @"com.apple.camera"];
        
        for (NSString *identifier in enabled) {
            SBDashBoardPageViewController *controller = [self _xen_fetchWithIdentifier:identifier andArray:newOrder];
            if (controller)
                [finalOrder addObject:controller];
        }
        
        %orig(finalOrder);
    }
}

- (void)loadView {
    [XENResources reloadSettings];
    
    // This is where the magic happens.
    if ([XENResources enabled]) {
        XENlog(@"Injecting Xen UI");
        baseXenController = [[XENDashBoardViewController alloc] init];
        [baseXenController configureWithScrollView:nil];
        [baseXenController configureControllersForLock];
    }
    
    %orig;
}

- (void)viewWillAppear:(_Bool)arg1 {
    [XENResources reloadSettings];
    
    // This is a sanity check.
    if (!baseXenController && [XENResources enabled]) {
        XENlog(@"Injecting Xen UI");
        baseXenController = [[XENDashBoardViewController alloc] init];
        [baseXenController configureWithScrollView:nil];
        [baseXenController configureControllersForLock];
    }
    
    %orig;
}

%new
-(id)_xen_fetchWithIdentifier:(NSString*)identifier andArray:(NSArray*)array {
    for (SBDashBoardPageViewController *controller in array) {
        if ([[controller _xen_identifier] isEqualToString:identifier])
            return controller;
    }
    
    return nil;
}

%end

%hook SBLockScreenToAppsWorkspaceTransaction

// Note that this will also get hooked on iOS 9.
- (void)_didComplete {
    %orig;
    
    if ([UIDevice currentDevice].systemVersion.floatValue >= 10) {
        XENlog(@"Unloading Xen UI");
        baseXenController = nil;
    
        [XENResources readyResourcesForNewLock];
    }
}

%end

#pragma mark Give the Apple controllers an identifier. (iOS 10+)

%hook SBDashBoardPageViewController

%new
-(NSString*)_xen_identifier {
    return @"com.apple.BASE";
}

%new
-(NSString*)_xen_name {
    return @"BASE_VIEW";
}

%end

%hook SBDashBoardTodayPageViewController

%new
-(NSString*)_xen_identifier {
    return @"com.apple.today";
}

%new
-(NSString*)_xen_name {
    return [XENResources localisedStringForKey:@"NC Widgets" value:@"NC Widgets"];
}

-(void)viewDidLayoutSubviews {
    %orig;
    
    BOOL enabled = [[XENResources enabledControllerIdentifiers] containsObject:[self _xen_identifier]];
    self.view.hidden = !enabled;
    self.view.userInteractionEnabled = enabled;
}

%end

%hook SBDashBoardCameraPageViewController

%new
-(NSString*)_xen_identifier {
    return @"com.apple.camera";
}

%new
-(NSString*)_xen_name {
    return [XENResources localisedStringForKey:@"Camera" value:@"Camera"];
}

-(void)viewDidLayoutSubviews {
    %orig;
    
    BOOL enabled = [[XENResources enabledControllerIdentifiers] containsObject:[self _xen_identifier]];
    self.view.hidden = !enabled;
    self.view.userInteractionEnabled = enabled;
}

// This is to ensure the page scrolls correctly when on the far left end.
- (void)aggregateAppearance:(SBDashBoardAppearance*)arg1 {
    %orig;
    
    if ([XENResources enabled] && [XENResources iOS10CameraEnabled] && [XENResources iOS10CameraPosition] == 0) {
        SBDashBoardComponent *slideableContent = nil;
    
        for (SBDashBoardComponent *comp in arg1.components) {
            if (comp.type == 5) {
                slideableContent = comp;
                break;
            }
        }

        [slideableContent setOffset:CGPointMake(-slideableContent.offset.x, 0)];
    }
}

%end

%hook SBDashBoardMainPageViewController
// Always enabled!

%new
-(NSString*)_xen_identifier {
    return @"com.apple.main";
}

%new
-(NSString*)_xen_name {
    return [XENResources localisedStringForKey:@"Unlock" value:@"Unlock"];
}

-(void)viewDidLayoutSubviews {
    %orig;
    
    baseXenController.homeViewController.view.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
    
    // Add to view as needed.
    if (![[self.view.subviews lastObject] isEqual:baseXenController.homeViewController.view]) {
        XENlog(@"Placing Xen's Home controller to the top of Apple's Main controller.");
        [self.view addSubview:baseXenController.homeViewController.view];
    }
}

%end

#pragma mark Runtime subclass for Xen's Page Views. (iOS 10+)

%hook XENDashBoardPageViewController

%property (nonatomic, retain) XENBaseViewController *xenController;
%property (nonatomic) BOOL xenVisible;

+ (unsigned long long)requiredCapabilities {
    return 0;
}

+ (_Bool)isAvailableForConfiguration {
    return YES;
}

- (void)didTransitionToVisible:(_Bool)arg1 {
    if (arg1)
        [self.xenController willMoveToControllerAfterScrollingEnds];
    else
        [self.xenController movingToControllerWithPercent:0.0];
    
    self.xenVisible = arg1;
}

- (void)updateTransitionToVisible:(_Bool)arg1 progress:(double)arg2 mode:(long long)arg3 {    
    if (!arg1 && arg2 != 1.0 && !self.xenVisible) {
        // If we're offscreen, yet recieving 0,0,0,... we can assume that the user was swiping to us, and
        // chose to go the other way. Thus, we only work with 0,0,0,... if we are visible, and progress != 1.0.
        
        return;
    }
    
    if (!arg1) arg2 = 1.0 - arg2; // Switch over when not being visible.
    [self.xenController movingToControllerWithPercent:arg2];
    
    // More of a sanity check than anything; ensure that the UI is definitely visible.
    if (arg1 && !self.xenController.view.superview) {
        [self.view addSubview:self.xenController.view];
    }
}

// This is to remove the dateView and pageControl on our pages.
- (void)aggregateAppearance:(SBDashBoardAppearance*)arg1 {
    %orig;
    
    SBDashBoardComponent *dateView = [[objc_getClass("SBDashBoardComponent") dateView] hidden:YES];
    [arg1 addComponent:dateView];
    
    SBDashBoardComponent *pageControl = [[objc_getClass("SBDashBoardComponent") pageControl] hidden:YES];
    [arg1 addComponent:pageControl];
}

- (void)aggregateBehavior:(SBDashBoardBehavior*)arg1 {
    %orig;
    
    if ([arg1 respondsToSelector:@selector(setScrollingStrategy:)])
        arg1.scrollingStrategy = 3;
    else if ([arg1 respondsToSelector:@selector(setScrollingMode:)])
        arg1.scrollingMode = 3;
}

%new
-(void)_xen_addViewIfNeeded {
    [self.view addSubview:self.xenController.view];
}

-(void)loadView {
    %orig;
    
    [self.view addSubview:self.xenController.view];
}

-(void)viewDidAppear:(BOOL)animated {
    %orig;
    
    [self.xenController viewDidAppear:animated];
}

-(void)viewDidLoad {
    %orig;
    
    [self.xenController viewDidLoad];
}

-(void)viewWillAppear:(BOOL)animated {
    %orig;
    
    [self.xenController viewWillAppear:animated];
}

-(void)viewDidDisappear:(BOOL)animated {
    %orig;
    
    [self.xenController viewDidDisappear:animated];
}

-(void)viewDidLayoutSubviews {
    %orig;
    
    self.xenController.view.transform = CGAffineTransformIdentity;
    self.xenController.view.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
    
    BOOL enabled = [[XENResources enabledControllerIdentifiers] containsObject:[self.xenController uniqueIdentifier]];
    self.view.hidden = !enabled;
    self.view.userInteractionEnabled = enabled;
    self.view.clipsToBounds = YES;
}

-(long long)backgroundStyle {
    /* Styles:
     * 1 - no blur
     * 2 - slight dark tint
     * 3 - blur no tint
     * 4 - light blur
     * 5 - vibrantly dark blur
     * 6 - dark blur like NC
     */
    
    return [self.xenController wantsBlurredBackground] ? 6 : 1;
}

%new
-(NSString*)_xen_identifier {
    return [self.xenController uniqueIdentifier];
}

%new
-(NSString*)_xen_name {
    return [self.xenController name];
}

%end

#pragma mark Allow touches in the lockscreen clock region (iOS 10+, Activator)
// It appears this is caused by Activator. For crying out loud, rpetrich!

%hook SBFLockScreenDateView

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    if ([UIDevice currentDevice].systemVersion.floatValue >= 10 && [XENResources enabled]) {
        // If the current page has requested the dateView to be hidden, then we will disallow
        // any touches here.
        
        SBDashBoardViewController *cont = [XENResources lsViewController];
        if (![cont isKindOfClass:objc_getClass("SBDashBoardViewController")]) {
            return %orig;
        }
        
        if (cont.lastSettledPageIndex != [cont _indexOfMainPage]) {
            return nil;
        }
    }
    
    return %orig;
}

%end

#pragma mark Allow an unlock to occur without Home button being clicked. (iOS 10+)

static BOOL maybeClickingHomeToUnlock = NO;

/*
 * Note that unlocking with Launchpad doesn't require this it seems!
 */

%hook SBDashBoardViewController

- (_Bool)canUIUnlockFromSource:(int)arg1 {
    BOOL orig = %orig;
    
    if ([XENResources enabled] && (arg1 == 1337 || isLaunchpadLaunching)) {
            return YES;
    } else if ([XENResources enabled] && [XENResources slideToUnlockModeDirection] != 3 && maybeClickingHomeToUnlock) {
        /*
         * Here, we should allow the user to still click Home after unlocking has occured via 
         * biometric means. This will correctly allow the flow they have now become accustomed
         * to, and will lead to less complaints to us.
         */
        
        //return [objc_getClass("SBFUserAuthenticationController") _isInBioUnlockState];
        return NO;
    }
    
    return orig;
}

%end

#pragma mark Disable Press Home to Unlock if needed (iOS 10+)

/*
 * The below method is what calls unlockUI:fromSource: as of 10.1.1.
 *
 * Clicking the Home button also leads to the passcode UI, so we also kill that behaviour too.
 */
%hook SBHomeHardwareButtonActions

- (void)performSinglePressUpActions {
    maybeClickingHomeToUnlock = YES;
    %orig;
    maybeClickingHomeToUnlock = NO;
}

%end

/*
 * It appears the showPasscodeRecognizer actually handles biometric monitoring.
 * If we adjust its state instead, we may be able to provide Touch ID correctly 
 * for modes not Click Home.
 */
%hook SBDashBoardHomeButtonShowPasscodeRecognizer

- (unsigned long long)_state {
    // States:
    // 0 - Default?
    // 1 - InitializedFromHomeButtonPress
    // 2 - MinimumTimeToShowPasscodePassed - finger on initially but hasn't yet lifted
    // 3 - Bio match failure or requires passcode (e.g., after boot), or "Finger Off After Minimum Timer Has Passed"
    // 4 - Authenticated
    
    return %orig;
}

%end

#pragma mark Prevent touches cancelling for things like the up arrow (iOS 10+)

%hook SBHorizontalScrollFailureRecognizer

- (_Bool)_isOutOfBounds:(struct CGPoint)arg1 forAngle:(double)arg2 {
    return [XENResources enabled] ? NO : %orig;
}

%end

%hook SBPagedScrollView

- (BOOL)touchesShouldCancelInContentView:(UIView *)view {
    BOOL orig = %orig;
    
    if ([XENResources enabled] && [baseXenController isDraggingSlideUpArrow] && [XENResources slideToUnlockModeDirection] == 1) {
        return NO;
    }
    
    return orig;
}

%end

#pragma mark Notify that locking has finished

@interface SpringBoard (Testing)
- (void)_publishFakeLockScreenNotificationsWithCount:(unsigned long long)arg1 completion:(id)arg2;
@end

%hook SBLockScreenManager

- (void)lockUIFromSource:(int)source withOptions:(id)options {
    isLaunchpadLaunching = NO;
    [XENResources hideContentEditWindow];
    
    %orig;
    
    XENlog(@"locking UI from source.");
    if ([XENResources enabled]) {
        [baseXenController postLockScreenInit];
        [baseXenController prepareForScreenUndim];
    }
}

%end

%hook SBLockScreenView

-(void)layoutSubviews {
    dontAllowScrollViewOffsetChange = YES;
    %orig;
    dontAllowScrollViewOffsetChange = NO;

    if ([XENResources enabled]) {
        [baseXenController postLockScreenInit];
        [XENResources setLockscreenView:self];
        
        [self _xen_relayoutDateView];
    }
}

#pragma mark Relayout notifications UI (<= iOS 9)

- (void)_layoutNotificationView {
    %orig;
    
    if ([XENResources enabled])
        [baseXenController invalidateNotificationFrame];
}

%end

#pragma mark Handle rotation! (<= iOS 9)

%hook SBLockScreenViewController

- (void)willRotateToInterfaceOrientation:(long long)interfaceOrientation duration:(double)duration {
    %orig;
    
    if ([XENResources enabled]) {
        // Set UI to masksToBounds.
        [baseXenController setUIMaskedForRotation:YES];
        
        [UIView animateWithDuration:duration animations:^{
            [baseXenController rotateToOrientation:(int)interfaceOrientation];
        }];
    }
}

- (void)didRotateFromInterfaceOrientation:(long long)arg1 {
    %orig;
    
    if ([XENResources enabled]) {
        // Set UI to not masksToBounds.
        [baseXenController setUIMaskedForRotation:NO];
    }
}

%end

%hook SBLockScreenView

- (void)resetContentOffsetToCurrentPage {
    if ([XENResources enabled]) {
        XENlog(@"resetContentOffsetToCurrentPage");
    } else {
        %orig;
    }
}

%end

#pragma mark Handle rotation! (iOS 10+)

%hook SBDashBoardViewController

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    if ([XENResources enabled]) {
        [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
            // In reality, our UI only cares if it is landscape or portrait. The type for each doesn't
            // matter. Therefore, we can do:
            
            int orientation = 1; // Portrait.
            if (size.width == SCREEN_MAX_LENGTH) {
                orientation = 3;
            }
        
            [baseXenController rotateToOrientation:(int)orientation];
        } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        }];
    }
    
    %orig;
}

%end

#pragma mark Adjust notification view position on iPad when grouped. (<= iOS 9)

%hook SBFLockScreenMetrics

+ (UIEdgeInsets)notificationListInsets {
    UIEdgeInsets orig = %orig;
    
    if ([XENResources enabled] && [XENResources useGroupedNotifications] && IS_IPAD && (orient3 > 2)) {
        orig.top += 20; // Better placement when in iPad landscape
    } else if ([XENResources enabled] && [XENResources useGroupedNotifications] && SCREEN_MAX_LENGTH <= 568) {
        orig.top += 20; // Give some more space to smaller displays.
    }
    
    return orig;
}

%end

#pragma mark Adjust notification view position on iPad when grouped. (iOS 10+)

// SBFDashBoardViewMetrics
//+ (double)dateBaselineToListY;
//+ (double)timeLabelBaselineY;
//+ (double)timeSubtitleBaselineY;
//+ (double)listMinY;

#pragma mark Adjust page control image for slide to unlock. (iOS 10+)

%hook SBDashBoardPageControl

- (void)_setIndicatorImage:(_UILegibilityView*)arg1 toEnabled:(_Bool)arg2 index:(long long)arg3 {
    if ([XENResources enabled]) {
        BOOL stul = [XENResources slideToUnlockModeDirection] == 0 && arg3 == 0;
        BOOL stur = [XENResources slideToUnlockModeDirection] == 2 && arg3 == self.numberOfPages-1;
        
        if (stul || stur) {
            UIImage *img = [self _xen_unlockIndicatorImage:arg2];
            [arg1 setImage:img shadowImage:nil];
            [arg1 sizeToFit];
            
            return;
        }
        
        // Handle camera indicator if needed.
        if ([XENResources iOS10CameraEnabled]) {
            int pos = [XENResources iOS10CameraPosition];
            
            BOOL caml = pos == 0 && arg3 == 0;
            BOOL camr = pos == 1 && arg3 == self.numberOfPages-1;
            
            if (caml || camr) {
                UIImage *img = [self _cameraIndicatorImage:arg2];
                [arg1 setImage:img shadowImage:nil];
                [arg1 sizeToFit];
                
                return;
            }
        } else {
            int pos = [XENResources iOS10CameraPosition];
            
            BOOL caml = pos == 0 && arg3 == 0;
            BOOL camr = pos == 1 && arg3 == self.numberOfPages-1;
            
            if (caml || camr) {
                UIImage *img = [self _pageIndicatorImage:arg2];
                [arg1 setImage:img shadowImage:nil];
                [arg1 sizeToFit];
                
                return;
            }
        }
    }
    
    %orig;
}

%new
- (id)_xen_unlockIndicatorImage:(BOOL)arg1 {
    // Arg1 denotes enabled state.
    
    // Image is 8pt x 9 pt.
    UIImage *image = [XENResources themedImageWithName:@"PageControlUnlock"];
    UIColor *imageColor = nil;
    if (arg1) {
        imageColor = [self _currentPageIndicatorColor];
    } else {
        imageColor = [self _pageIndicatorColor];
    }
    
    return [image _flatImageWithColor:imageColor];
}

%end

#pragma mark Fix issues with our scroll view caused by Apple (iOS 9.0 - 9.3)

%hook SBLockScreenView

// Not required as of iOS 10.
- (void)_adjustTopAndBottomGrabbersForPercentScrolled:(CGFloat)percentScrolled {
    if (![XENResources enabled]) {
        %orig;
    }
}

- (void)scrollViewDidEndDecelerating:(id)scrollView {
    if (![XENResources enabled]) %orig;
}
- (void)scrollViewDidEndDragging:(id)scrollView willDecelerate:(BOOL)decelerate {
    if (![XENResources enabled]) %orig;
}
- (void)scrollViewDidEndScrollingAnimation:(id)scrollView {
    if (![XENResources enabled]) %orig;
}
- (void)scrollViewDidScroll:(id)scrollView {
    if (![XENResources enabled]) %orig;
}
- (void)scrollViewWillBeginDragging:(id)scrollView {
    if (![XENResources enabled]) %orig;
}
- (void)scrollViewWillEndDragging:(id)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(CGPoint *)offset {
    if (![XENResources enabled]) %orig;
}

- (void)_slideToUnlockFailureGestureRecognizerChanged {
    if (![XENResources enabled]) %orig;
}

%end

%hook SBSlideToUnlockFailureRecognizer

- (BOOL)_isOutOfBoundsVertically:(CGPoint)boundsVertically {
    BOOL orig = %orig;
    
    if ([XENResources enabled] && [baseXenController onHomePage]) {
        return NO;
    }
    
    return orig;
}

%end

// Not required as of iOS 10.
%hook SBLockScreenViewController

- (BOOL)isBounceEnabledForPresentingController:(id)fp8 locationInWindow:(CGPoint)fp12 {
    return ([XENResources enabled] ? NO : %orig);
}

%end

// Not required as of iOS 10.
%hook SBLockScreenBounceAnimator

- (void)_handleTapGesture:(id)arg1 {
    //Do not handle tap gesture
    if (![XENResources enabled]) {
        %orig;
    }
}

%end

#pragma mark Destroy UI on unlock (iOS 9.0 - 9.3)

%hook SBLockScreenViewController

-(void)_releaseLockScreenView {
    %orig;
    
    baseXenController = nil;
    
    [XENResources readyResourcesForNewLock];
    
    // Handle Peek if necessary
    if ([XENResources peekEnabled] && [XENResources enabled]) {
        if (accelHandler.isUpdating)
            [accelHandler pauseMonitoring];
    
        [peekTimer invalidate];
        peekTimer = nil;
    
        shouldBeInPeekMode = NO;
        peekIsVisble = NO;
        pauseMonitoring = YES;
    }
}

%end

%hook SBLockScreenManager

- (void)_finishUIUnlockFromSource:(int)source withOptions:(id)options {
    %orig;
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:@"/tmp/com.matchstic.xen.reboot_flag"])
        [[NSFileManager defaultManager] createFileAtPath:@"/tmp/com.matchstic.xen.reboot_flag" contents:[NSData data] attributes:nil];
    
    if ([XENResources enabled]) {
        [baseXenController notifyUnlockWillBegin];
    }
}

%end

#pragma mark Notify ourselves that the passcode cancel button was tapped (<= iOS 9)

%hook SBLockScreenViewController

- (void)passcodeLockViewCancelButtonPressed:(id)arg1 {
    %orig;
    [baseXenController passcodeCancelButtonWasTapped];
}

%end

#pragma mark Notify ourselves that the passcode cancel button was tapped (iOS 10+)

%hook SBDashBoardPasscodeViewController

- (void)passcodeLockViewCancelButtonPressed:(id)arg1 {
    %orig;
    
    [baseXenController passcodeCancelButtonWasTapped];
}

%end

#pragma mark Notify controllers that screen is now off, and begin proximity monitoring for Peek (<= iOS 9)

%hook SBLockScreenViewController

-(void)_handleDisplayTurnedOff {
    %orig;
    
    XENlog(@"Handling display turned off.");
    [XENResources setScreenOnState:NO];
    
    if ([XENResources enabled])
        [baseXenController screenDidTurnOff];
    
#if USE_PEEK==1
    if ([XENResources peekEnabled] && [XENResources enabled]) {
        if ([XENResources peekMode] == 1) { // Interval
            // Begin timer!
            peekTimer = [NSTimer scheduledTimerWithTimeInterval:60.0 * [XENResources peekIntervalDuration] target:self selector:@selector(_xen_peekTimerDidFire:) userInfo:nil repeats:NO];
        }
        
        beginMonitoringProximity();
    }
#endif
}

%new
-(void)_xen_peekTimerDidFire:(id)sender {
    #if USE_PEEK==1
    // End monitoring
    shouldBeInPeekMode = NO;
    pauseMonitoring = YES;
    
    //endMonitoringProximity();
    restoreLLSleep();
    
    if (accelHandler.isUpdating)
        [accelHandler pauseMonitoring];
    
    [peekTimer invalidate];
    peekTimer = nil;
    
    XENlog(@"We should have now finished that interval for Peek.");
    #endif
}

%end

#pragma mark Notify controllers that screen is now off, and begin proximity monitoring for Peek (iOS 10+)

/*%hook SBLockScreenManager

- (void)_handleBacklightLevelChanged:(NSNotification*)arg1 {
    %orig;
    
    if ([UIDevice currentDevice].systemVersion.floatValue >= 10.0 && [XENResources enabled]) {
#warning We may have issues with armv7 here due to floatValue.
        NSDictionary *userInfo = arg1.userInfo;
        CGFloat newBacklight = [[userInfo objectForKey:@"SBBacklightNewFactorKey"] floatValue];
        
        if (newBacklight == 0.0) {
            [baseXenController screenDidTurnOff];
            
            // Handle Peek if needed!
        }
    }
}

%end*/

%hook SBDashBoardViewController

- (void)setInScreenOffMode:(_Bool)arg1 forAutoUnlock:(_Bool)arg2 {
    %orig;
    
    if (arg1) {
        // Display off!
        [baseXenController screenDidTurnOff];
    } else {
        // Display on!
    }
}

%end

#pragma mark Remove camera from lockscreen (<= iOS 9)

%hook SBLockScreenViewController

-(void)_addCameraGrabberIfNecessary {
    if (![XENResources enabled] || ![XENResources hideCameraGrabber]) {
        %orig;
    }
}

%end

#pragma mark Remove STU view if necessary (<= iOS 9)

%hook SBLockScreenView

-(void)_layoutSlideToUnlockView {
    if (![XENResources enabled] || [XENResources useSlideToUnlockMode]) {
        %orig;
    } else if ([XENResources enabled] && ![XENResources useSlideToUnlockMode]) {
#if TARGET_IPHONE_SIMULATOR==0
        UIView *_stuView = MSHookIvar<UIView*>(self, "_slideToUnlockView");
        _stuView.frame = CGRectZero;
#endif
    }
}

%end

#pragma mark Remove PHTU view if necessary (iOS 10+)

%hook SBUICallToActionLabel

- (void)setText:(id)arg1 forLanguage:(id)arg2 animated:(BOOL)arg3 {
    // 3 denotes to use Press Home to Unlock.
    if ([XENResources enabled] && [XENResources slideToUnlockModeDirection] != 3) {
        if ([XENResources useSlideToUnlockMode]) {
            %orig([XENResources localisedStringForKey:@"Slide to unlock" value:@"Slide to unlock"], arg2, arg3);
        } else {
            %orig(@"", arg2, arg3);
        }
    } else {
        %orig;
    }
}

%end

#pragma mark Hide STU chevron for left/right mode (<= iOS 9)

%hook _UIGlintyStringView

- (double)_chevronWidthWithPadding {
    if ([XENResources enabled]/* && [XENResources useSlideToUnlockMode] && [XENResources slideToUnlockModeDirection] != 1*/) {
        return 0.0;
    } else {
        return %orig;
    }
}

-(int)chevronStyle {
    return ([XENResources enabled]/* && [XENResources useSlideToUnlockMode] && [XENResources slideToUnlockModeDirection] != 1*/) ? 0 : %orig;
}

-(void)setChevronStyle:(int)style {
    if ([XENResources enabled]/* && [XENResources useSlideToUnlockMode]&& [XENResources slideToUnlockModeDirection] != 1*/)
        style = 0;
        
    %orig(style);
}

- (double)_chevronPadding {
    return ([XENResources enabled]/* && [XENResources useSlideToUnlockMode] && [XENResources slideToUnlockModeDirection] != 1*/) ? 0 : %orig;
}

- (id)_chevronImageForStyle:(long long)arg1 {
    return ([XENResources enabled]/* && [XENResources useSlideToUnlockMode] && [XENResources slideToUnlockModeDirection] != 1*/) ? nil : %orig;
}

- (CGRect)chevronFrame {
    return ([XENResources enabled]/* && [XENResources useSlideToUnlockMode] && [XENResources slideToUnlockModeDirection] != 1*/) ? CGRectZero : %orig;
}

%end

#pragma mark Adjust original lockscreen blur (iOS 9.0 - 9.3)

%hook SBLockScreenView

-(void)_setCurrentBlurRadius:(CGFloat)radius {
    %orig([XENResources enabled] ? 0.0 : radius);
}

%end

%hook SBLockOverlayStyleProperties

-(CGFloat)tintAlpha {
    return [XENResources enabled] ? 0.0 : %orig;
}

%end

#pragma mark Same sized status bar (<= iOS 9)

%hook SBLockScreenViewController

-(int)statusBarStyle {
    return [XENResources enabled] ? 0 : %orig;
}

%end

#pragma mark Same sized status bar (iOS 10+)

%hook SBDashBoardViewController

- (long long)statusBarStyle {
    return [XENResources enabled] ? 0 : %orig;
}

%end

#pragma mark Prevent colour changes of UI when light wallpaper selected (<= iOS 9)

%hook SBLockScreenViewController

- (id)_effectiveLegibilitySettings {
    return [XENResources enabled] ? [self _wallpaperLegibilitySettings] : %orig;
}

- (void)_updateLegibility {
    %orig;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"XENLegibibilityDidChange" object:nil];
}

- (void)wallpaperLegibilitySettingsDidChange:(id)wallpaperLegibilitySettings forVariant:(int)variant {
    %orig;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"XENLegibibilityDidChange" object:nil];
}

%end

#pragma mark Prevent colour changes of UI when light wallpaper selected (iOS 10+)

%hook SBDashBoardLegibilityProvider

- (void)wallpaperLegibilitySettingsDidChange:(id)arg1 forVariant:(long long)arg2 {
    %orig;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"XENLegibibilityDidChange" object:nil];
}

- (id)currentLegibilitySettings {
    return [XENResources enabled] ? [self _wallpaperLegibilitySettings] : %orig;
}

%end

%hook SBDashBoardViewController

- (void)_updateLegibilitySettings {
    %orig;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"XENLegibibilityDidChange" object:nil];
}

%end

#pragma mark Legibility settings for fullscreen/combined artwork mode (<= iOS 9)

%hook SBLockScreenViewController

- (id)initWithNibName:(id)nibName bundle:(id)bundle {
    id orig = %orig;
    
    if (orig && [XENResources enabled]) {
        [[NSNotificationCenter defaultCenter] addObserver:orig
                                                 selector:@selector(_updateLegibility)
                                                     name:@"XENWallpaperChanged"
                                                   object:nil];
        [XENResources setLsViewController:self];
    }
    
    return orig;
}

-(_UILegibilitySettings*)_wallpaperLegibilitySettings {
    if ([XENResources enabled] && peekIsVisble) {
        _UILegibilitySettings *settings = [[objc_getClass("_UILegibilitySettings") alloc] initWithContentColor:[UIColor blackColor] contrast:0.5];
        return settings;
    }
    
    if ([XENResources enabled] && [baseXenController.musicFullscreenController hasArtwork]) {
        // We can create our own legibility settings! :O
        UIColor *colour = [baseXenController.musicFullscreenController averageArtworkColour];
        
        _UILegibilitySettings *settings = [[objc_getClass("_UILegibilitySettings") alloc] initWithContentColor:colour contrast:0.3];
        
        return settings;
    } else {
        return %orig;
    }
}

%end

#pragma mark Legibility settings for fullscreen/combined artwork mode (iOS 10+) (Needs verification)

%hook SBDashBoardLegibilityProvider

- (id)_wallpaperLegibilitySettings {
    if ([XENResources enabled] && peekIsVisble) {
        _UILegibilitySettings *settings = [[objc_getClass("_UILegibilitySettings") alloc] initWithContentColor:[UIColor blackColor] contrast:0.5];
        return settings;
    }
    
    if ([XENResources enabled] && [baseXenController.musicFullscreenController hasArtwork]) {
        // We can create our own legibility settings! :O
        UIColor *colour = [baseXenController.musicFullscreenController averageArtworkColour];
        
        _UILegibilitySettings *settings = [[objc_getClass("_UILegibilitySettings") alloc] initWithContentColor:colour contrast:0.3];
        
        return settings;
    } else {
        return %orig;
    }
}

%end

#pragma mark Notification cell styling (<= iOS 9)

@interface SBLockScreenNotificationCell (EH)
-(void)_xen_addBlurIfNecessary;
@end

%hook SBLockScreenNotificationCell

-(id)initWithStyle:(int)style reuseIdentifier:(id)identifier {
    SBLockScreenNotificationCell *orig = %orig;
    
    [orig _xen_addBlurIfNecessary];
    
    if ([XENResources enabled]) {
        // Ensure all tap related shizzle works
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(fireOffTappedEventToDelegate:)];
        tap.delaysTouchesBegan = YES;
        tap.delegate = self;
        
        for (UIGestureRecognizer *gesture in self.contentScrollView.gestureRecognizers) {
            [gesture requireGestureRecognizerToFail:tap];
        }
        
        [self.contentScrollView addGestureRecognizer:tap];
        self.contentScrollView.delaysContentTouches = NO;
        self.contentScrollView.userInteractionEnabled = YES;
        
        self.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    return orig;
}

%new
-(void)_xen_addBlurIfNecessary {
    _UIBackdropView *backdrop = (_UIBackdropView*)[self viewWithTag:1337];
    
    if (!backdrop && [XENResources enabled] && [XENResources useXENNotificationUI]) {
        _UIBackdropViewSettings *settings = [objc_getClass("_UIBackdropViewSettings") settingsForPrivateStyle:([XENResources shouldUseDarkColouration] ? 1 : 2060)];
        _UIBackdropView *view = [[objc_getClass("_UIBackdropView") alloc] initWithFrame:CGRectMake(20, 0, self.realContentView.frame.size.width - 40, self.realContentView.frame.size.height - 5) autosizesToFitSuperview:NO settings:settings];
        [view setBlurQuality:@"low"];
        view.layer.cornerRadius = 12.5;
        view.layer.masksToBounds = YES;
        view.tag = 1337;
        
        UIView *darkener = [[UIView alloc] initWithFrame:view.bounds];
        darkener.backgroundColor = [XENResources effectiveLegibilityColor];
        darkener.alpha = 0.15;
        darkener.tag = 13375;
        darkener.hidden = YES;
        [view addSubview:darkener];
        
        [self.realContentView insertSubview:view atIndex:0];
    }
}

-(void)setContentAlpha:(CGFloat)alpha {
    if ([XENResources enabled] && [XENResources useGroupedNotifications]) {
        //[self viewWithTag:1337].alpha = alpha;
        %orig(1.0);
    } else {
        %orig;
    }
}

-(void)setAlpha:(CGFloat)alpha {
    if ([XENResources enabled] && [XENResources useGroupedNotifications]) {
        //[self viewWithTag:1337].alpha = alpha;
        BOOL prev = self.layer.allowsGroupOpacity;
        self.layer.allowsGroupOpacity = NO;
        %orig(1.0);
        self.layer.allowsGroupOpacity = prev;
    } else {
        %orig;
    }
}

-(void)layoutSubviews {
    %orig;
    
    if ([XENResources enabled]) {
        // Layout our cell
        self.iconView.hidden = [XENResources useGroupedNotifications] && ![XENResources usingWatchNotificationsCompatibilityMode] ? YES : NO;
        
        // Fix content scroll view for tappable-ness
        self.contentScrollView.scrollEnabled = NO;
        
        // ColorBanners. CBRGradientView
    
        _UIBackdropView *backdrop = (_UIBackdropView*)[self viewWithTag:1337];
        [self _xen_addBlurIfNecessary];
        if ([XENResources useXENNotificationUI]) {
            backdrop.frame = CGRectMake(self.realContentView.frame.size.width * 0.05, 5, self.realContentView.frame.size.width * 0.9, self.realContentView.frame.size.height - 8);
            UIView *dark = [backdrop viewWithTag:13375];
            dark.frame = backdrop.bounds;
            
            if ([XENResources shouldUseDarkColouration]) {
                dark.hidden = NO;
                dark.backgroundColor = [XENResources effectiveLegibilityColor];
            }
            
            _UIBackdropViewSettings *settings = [objc_getClass("_UIBackdropViewSettings") settingsForPrivateStyle:([XENResources shouldUseDarkColouration] ? 1 : 2060)];
            [backdrop transitionToSettings:settings];
            
            // Also, let's fix the ColorBanners shite.
            // it's on the real content view.
            
            if ([[NSFileManager defaultManager] fileExistsAtPath:@"/Library/MobileSubstrate/DynamicLibraries/ColorBanners.dylib"]) {
            UIView *colorBanner = nil;
            for (UIView *view in self.realContentView.subviews) {
                if ([[view class] isEqual:objc_getClass("CBRGradientView")]) {
                    colorBanner = view;
                    break;
                }
            }
            
            if (colorBanner) {
                long tag = colorBanner.tag;
                colorBanner.tag = 1337;
                colorBanner.frame = CGRectMake(0, 0, backdrop.frame.size.width, backdrop.frame.size.height);
                colorBanner.layer.cornerRadius = 12.5;
                colorBanner.layer.masksToBounds = YES;
                colorBanner.tag = tag;
                
                // To fix an unhealthy UI issue we'll jump to grabbing the colorBanner off the backdrop.
                [backdrop.contentView insertSubview:colorBanner atIndex:0];
            } else {
                // It might be on the backdrop?
                
                colorBanner = [backdrop.contentView.subviews firstObject];
                if ([[colorBanner class] isEqual:objc_getClass("CBRGradientView")]) {
                    long tag = colorBanner.tag;
                    colorBanner.tag = 1337;
                    colorBanner.frame = CGRectMake(0, 0, backdrop.frame.size.width, backdrop.frame.size.height);
                    colorBanner.layer.cornerRadius = 12.5;
                    colorBanner.layer.masksToBounds = YES;
                    colorBanner.tag = tag;
                }
            }
            }
        } else {
            if (backdrop) {
                if ([[NSFileManager defaultManager] fileExistsAtPath:@"/Library/MobileSubstrate/DynamicLibraries/ColorBanners.dylib"]) {
                    // Pull colorBanner off the backdrop.
                    UIView *colorBanner = [backdrop.contentView.subviews firstObject];
                    if ([[colorBanner class] isEqual:objc_getClass("CBRGradientView")]) {
                        long tag = colorBanner.tag;
                        colorBanner.tag = 1337;
                        colorBanner.frame = CGRectMake(0, 0, self.realContentView.frame.size.width, self.realContentView.frame.size.height);
                        colorBanner.layer.cornerRadius = 0;
                        colorBanner.layer.masksToBounds = YES;
                        colorBanner.tag = tag;
                        
                        [self.realContentView insertSubview:colorBanner atIndex:0];
                    }
                }
                
                [backdrop removeFromSuperview];
            }
        }
        
        // First up, we generate the height needed for this notification.
        
    
        // Move text left
        CGFloat finalX = (self.realContentView.frame.size.width * 0.05) + ([XENResources useGroupedNotifications] ? 20 : 40);
        CGFloat moveLeft = self.primaryLabel.frame.origin.x - finalX;
        
        if ([XENResources useGroupedNotifications]) {
            finalX = [XENResources useXENNotificationUI] ? (self.realContentView.frame.size.width * 0.05) + 20 : self.primaryLabel.frame.origin.x - 20;
            moveLeft = [XENResources useXENNotificationUI] ? self.primaryLabel.frame.origin.x - finalX : - 20;
        } else {
            finalX = [XENResources useXENNotificationUI] ? (self.realContentView.frame.size.width * 0.05) + 40 : self.primaryLabel.frame.origin.x;
            moveLeft = [XENResources useXENNotificationUI] ? 25 : 0;
        }
        
#if TARGET_IPHONE_SIMULATOR==0
        UILabel *unlockLabel = MSHookIvar<UILabel*>(self, "_unlockTextLabel");
        unlockLabel.frame = CGRectMake(finalX, unlockLabel.frame.origin.y + ([XENResources useXENNotificationUI] ? 6 : 0), unlockLabel.frame.size.width, unlockLabel.frame.size.height);
        
        if ([XENResources useXENNotificationUI])
            unlockLabel.textColor = [UIColor whiteColor];
        else {
            unlockLabel.textColor = [self _vibrantTextColor];
        }
#endif
        
        CGFloat additionalWidthReductionForDismissButton = 0;
        CGFloat evenMoreReductionForAttachmentView = 0;
        
        if (self.attachmentView && [XENResources useXENNotificationUI]) {
            self.attachmentView.frame = CGRectMake(self.attachmentView.frame.origin.x - 20, self.attachmentView.frame.origin.y, self.attachmentView.frame.size.width, self.attachmentView.frame.size.height);
            
            evenMoreReductionForAttachmentView = 20;
        }
        
        CGFloat finalReduction = additionalWidthReductionForDismissButton + evenMoreReductionForAttachmentView + ([XENResources useXENNotificationUI] ? 7 : 0);
        
        // Set frames
        CGFloat primaryLabelWidth = self.primaryLabel.frame.size.width;
        
        if ([XENResources useXENNotificationUI]) {
            CGFloat maxPrimaryLabelWidth = ((self.realContentView.frame.size.width * 0.9) - 40) - self.relevanceDateLabel.frame.size.width - 5;
            
            if (![XENResources useGroupedNotifications]) {
                maxPrimaryLabelWidth -= 20;
            }
            
            primaryLabelWidth = (self.primaryLabel.frame.size.width + 3 > maxPrimaryLabelWidth) ? maxPrimaryLabelWidth : self.primaryLabel.frame.size.width + 3;
        }
        
        self.primaryLabel.frame = CGRectMake(finalX, self.primaryLabel.frame.origin.y + ([XENResources useXENNotificationUI] ? 3 : 0), primaryLabelWidth, self.primaryLabel.frame.size.height);
        self.secondaryLabel.frame = CGRectMake(finalX, self.secondaryLabel.frame.origin.y + ([XENResources useXENNotificationUI] ? 5 : 0), self.secondaryLabel.frame.size.width - moveLeft - finalReduction + 3, self.secondaryLabel.frame.size.height);
        self.subtitleLabel.frame = CGRectMake(finalX, self.subtitleLabel.frame.origin.y + ([XENResources useXENNotificationUI] ? 5 : 0), self.subtitleLabel.frame.size.width - finalReduction + 3, self.subtitleLabel.frame.size.height);
        self.relevanceDateLabel.frame = CGRectMake(self.primaryLabel.frame.size.width + self.primaryLabel.frame.origin.x + 5, self.relevanceDateLabel.frame.origin.y + ([XENResources useXENNotificationUI] ? 3 : 0), self.relevanceDateLabel.frame.size.width, self.relevanceDateLabel.frame.size.height);
        self.eventDateLabel.frame = CGRectMake(self.primaryLabel.frame.size.width + self.primaryLabel.frame.origin.x + 5, self.eventDateLabel.frame.origin.y + ([XENResources useXENNotificationUI] ? 3 : 0), self.eventDateLabel.frame.size.width, self.eventDateLabel.frame.size.height);
        
        // icon view if not using grouped notifications
        if (![XENResources useGroupedNotifications] && [XENResources useXENNotificationUI]) {
            self.iconView.center = CGPointMake((self.realContentView.frame.size.width * 0.05) + 20, (backdrop.frame.size.height / 2) + 5);
        }
    }
}

- (id)_vibrantTextColor {
    return ([XENResources enabled] && [XENResources useXENNotificationUI]) ? [UIColor whiteColor] : %orig;
}

%new
-(UILabel*)XENUnlockTextLabel {
#if TARGET_IPHONE_SIMULATOR==1
    return nil;
#else
    return MSHookIvar<UILabel*>(self, "_unlockTextLabel");
#endif
}

%new
-(void)fireOffTappedEventToDelegate:(UITapGestureRecognizer*)sender {
    [self.delegate handleActionFromTappedCellWithContext:self.lockScreenActionContext];
}

%new
-(void)handleLongPressGesture:(UIGestureRecognizer*)gesture {
    UIView *view = [[[self viewWithTag:1337] subviews] firstObject];
    
    if (gesture.state == UIGestureRecognizerStateBegan) {
        XENlog(@"Starting long press gesture...");
        [UIView animateWithDuration:0.15 animations:^{
            view.alpha = 0.75;
        }];
    } else if (gesture.state == UIGestureRecognizerStateEnded || gesture.state == UIGestureRecognizerStateCancelled) {
        XENlog(@"Ending long press gesture...");
        [UIView animateWithDuration:0.15 animations:^{
            view.alpha = 0.0;
        }];
    }
}

%new
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    if ([[otherGestureRecognizer class] isKindOfClass:[UITapGestureRecognizer class]]) {
        return YES;
    }
    
    return YES;
}

%new
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    return YES;
}

%new
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    return YES;
}

%end

%hook SBLockScreenNotificationListView

- (id)initWithFrame:(struct CGRect)frame {
    self = %orig;

    if ([XENResources enabled] && [XENResources useXENNotificationUI]) {
#if TARGET_IPHONE_SIMULATOR==0
        UITableView *notificationsTableView = MSHookIvar<UITableView*>(self, "_tableView");
        notificationsTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
#endif
    }
    
    return self;
}

-(SBLockScreenNotificationCell*)tableView:(UITableView*)view cellForRowAtIndexPath:(NSIndexPath*)indexPath {
    SBLockScreenNotificationCell *cell = %orig;
    
    if ([XENResources enabled]) {
        // No matter what UI we use, it'll always be tapping rather than swiping

        NSString *originalText = [cell XENUnlockTextLabel].text;
        
        if ((originalText && ![originalText isEqualToString:@""]) || [XENResources useXENNotificationUI])
            [cell _updateUnlockText:[XENResources tapToOpenTextForBundleIdentifier:[self XENBundleIdentifierForIndexPath:indexPath]]];
    }
    
    return cell;
}

%new
-(void)_xen_reloadSeparatorStyleForSetup {
#if TARGET_IPHONE_SIMULATOR==0
    UITableView *notificationsTableView = MSHookIvar<UITableView*>(self, "_tableView");
    if ([XENResources useXENNotificationUI])
        notificationsTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    else
        notificationsTableView.separatorStyle = 1;
#endif
}

%end

%hook SBLockScreenNotificationCell

+(CGFloat)rowHeightForTitle:(id)title subtitle:(id)subtitle body:(id)body maxLines:(unsigned)lines attachmentSize:(CGSize)size secondaryContentSize:(CGSize)size6 datesVisible:(BOOL)visible rowWidth:(CGFloat)width includeUnlockActionText:(BOOL)text {
    if ([XENResources enabled] && [XENResources useXENNotificationUI]) {
        width *= 0.9;
        width -= 14; // 14px margin for text.
        
        return %orig(title, subtitle, body, lines, size, size6, visible, width, YES);
    } else {
        return %orig;
    }
}

-(void)_updateUnlockText:(NSString*)text {
    if ([XENResources enabled] && [XENResources useXENNotificationUI] && ([text isEqualToString:@""] || !text)) {
        // Don't set.
    } else {
        %orig;
    }
}

%end

%hook SBLockScreenBulletinCell

+(CGFloat)rowHeightForTitle:(id)title subtitle:(id)subtitle body:(id)body maxLines:(unsigned)lines attachmentSize:(CGSize)size secondaryContentSize:(CGSize)size6 datesVisible:(BOOL)visible rowWidth:(CGFloat)width includeUnlockActionText:(BOOL)text {
    if ([XENResources enabled] && [XENResources useXENNotificationUI]) {
        width *= 0.9;
        width -= 14; // 20px margin for text.
        
        return %orig(title, subtitle, body, lines, size, size6, visible, width, YES);
    } else {
        return %orig;
    }
}

-(void)_updateUnlockText:(NSString*)text {
    if ([XENResources enabled] && [XENResources useXENNotificationUI] && ([text isEqualToString:@""] || !text)) {
        // Don't set.
    } else {
        %orig;
    }
}

%end

// Resolve issues with the actionbutton cells that like to use vibrancy.

%hook SBTableViewCellActionButton

- (void)setBackgroundColor:(id)color withBlendMode:(int)blendMode {
    if (![XENResources enabled]) {
        %orig;
    } else {
        %orig(color, ([XENResources blurBehindNotifications] ? blendMode : 0));
    }
    
}

%end

#pragma mark Notification cell styling (iOS 10+) (TODO)

/*
 * On iOS 10, the stock notifications look eerily similar to Xen's Custom style. Thus, we should
 * modify that slightly to achieve Custom, and also provide iOS 9 Styling.
 *
 * Interestingly, the notification list view is now in fact a UICollectionView, on the controller
 * NCNotificationPriorityListViewController. 
 *
 * To theme a cell, we're probably best to subclass NCNotificationListCell for each style. The stock
 * UI is used both within the LS and NC, so modifying that directly will be a right pain. Just vend out
 * the appropriate style from collectionView:cellForIndexPath:
 */

#pragma mark Sorting out shizzle for grouping of notifications (<= iOS 9)

%hook SBLockScreenNotificationListView

-(CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath {
    if ([XENResources enabled]) {
        // Here is where we shall ensure that notifications show or not via indexPath
        if ([XENResources useGroupedNotifications]) {
            if ([XENResources usingPriorityHubCompatiblityMode]) {
                // Allow Priority Hub to handle whether to hide or show, then act accordingly
                CGFloat original = %orig;
                return original == 0 ? 0 : %orig + ([XENResources useXENNotificationUI] ? 10 : 0);
            } else {
                // Check if this indexPath can be shown. If not, return 0, otherwise %orig + whatever
                return [self XENShouldShowIndexPath:indexPath] ? %orig + ([XENResources useXENNotificationUI] ? 10 : 0) : 0;
            }
        } else {
            // No need to worry about groupings
            return %orig + ([XENResources useXENNotificationUI] ? 10 : 0);
        }
    } else {
        return %orig;
    }
}

%new
-(NSString*)XENBundleIdentifierForIndexPath:(NSIndexPath*)indexPath {
#if TARGET_IPHONE_SIMULATOR==0
    SBAwayListItem *listItem = [MSHookIvar<id>(self, "_model") listItemAtIndexPath:indexPath];

    return [XENResources identifierForListItem:listItem];
#else
    return nil;
#endif
}

%new
-(BOOL)XENShouldShowIndexPath:(NSIndexPath*)indexPath {
    NSString *bundleIdentifier = [self XENBundleIdentifierForIndexPath:indexPath];
    return [bundleIdentifier isEqualToString:[XENResources currentlyShownNotificationAppIdentifier]];
}

%end

#pragma mark Sorting out grouping of notifications (iOS 10+) (TODO)

/*
 * As prior noted, Apple no longer uses a table view for the notifications (breaking a 10 year tradition).
 *
 * We need a method in which cell sizings are also reduced to 0 in height. Data source is a NCNotificationPriorityList
 *
 * On the lockscreen, it is ALWAYS one section, so it's a just a multitude of cells really.
 */


%hook NCNotificationPriorityListViewController

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    CGSize size = %orig;
    
    if ([XENResources enabled]) {
        // Here is where we shall ensure that notifications show or not via indexPath
        if ([XENResources useGroupedNotifications]) {
            if ([XENResources usingPriorityHubCompatiblityMode]) {
                // Allow Priority Hub to handle whether to hide or show, then act accordingly
                size.height = size.height == 0 ? 0 : [self _xen_heightForCurrentCellStyling:size.height];
            } else {
                // Check if this indexPath can be shown. If not, return 0, otherwise %orig + whatever
                size.height = [self _xen_shouldShowIndexPath:indexPath] ? [self _xen_heightForCurrentCellStyling:size.height] : 0;
            }
        } else {
            // No need to worry about groupings
            size.height = [self _xen_heightForCurrentCellStyling:size.height];
        }
    }
    
    return size;
}

%new
-(CGFloat)_xen_heightForCurrentCellStyling:(CGFloat)defaultHeight {
    /*if ([XENResources useiOS9NotificationUI]) {
        defaultHeight -= 10;
    }*/
    
    // Changes are only needed to height for the iOS 9 styling, and that's just due to margins.
    
    return defaultHeight;
}

%new
-(NSString*)_xen_bundleIdentifierForIndexPath:(NSIndexPath*)indexPath {
    NCNotificationRequest *listItem = [self.notificationRequestList requestAtIndex:indexPath.item];
    return [XENResources identifierForListItem:listItem];
}

%new
-(BOOL)_xen_shouldShowIndexPath:(NSIndexPath*)indexPath {
    NSString *bundleIdentifier = [self _xen_bundleIdentifierForIndexPath:indexPath];
    return [bundleIdentifier isEqualToString:[XENResources currentlyShownNotificationAppIdentifier]];
}

%end

#pragma mark Notifications hooks for our collection view (<= iOS 9)

%hook SBLockScreenNotificationListController

//Called when a new notification is added to the notification list
- (void)_updateModelAndViewForAdditionOfItem:(SBAwayListItem*)item {
    %orig;
    
    if ([XENResources enabled]) {
        NSString *appID = [XENResources identifierForListItem:item];
        
        [XENResources cacheNotificationForListItem:item];
            
        [baseXenController.homeViewController updateNotificationsViewWithBundleIdentifier:appID];
    }
}

- (void)_updateModelForRemovalOfItem:(SBAwayListItem*)item updateView:(BOOL)update {
    %orig;

    if ([XENResources enabled]) {
        NSString *appID = [XENResources identifierForListItem:item];
                    
        [baseXenController.homeViewController removeBundleIdentfierFromNotificationsView:appID];
    }
}

%new
-(NSArray*)_xen_listItems {
#if TARGET_IPHONE_SIMULATOR==0
    return MSHookIvar<NSMutableArray*>(self, "_listItems");
#else
    return [NSArray array];
#endif
}

%end

%hook SBLockScreenNotificationListView

- (void)layoutSubviews {
    %orig;
    
    if ([XENResources enabled])
        [XENResources setNotificationListView:self];
}

%end

#pragma mark Notifications hooks for our collection view (iOS 10+) (Needs verification)

%hook NCNotificationPriorityList

- (unsigned long long)insertNotificationRequest:(NCNotificationRequest*)request {
    if ([XENResources enabled]) {
        XENlog(@"GOT REQUEST! %@", request);
        
        NSString *appID = [XENResources identifierForListItem:request];
        
        [XENResources cacheNotificationForListItem:request];
        
        [baseXenController.homeViewController updateNotificationsViewWithBundleIdentifier:appID];
    }
    
    return %orig;
}

- (unsigned long long)removeNotificationRequest:(NCNotificationRequest*)request {
    if ([XENResources enabled]) {
        NSString *appID = [XENResources identifierForListItem:request];
        
        [baseXenController.homeViewController removeBundleIdentfierFromNotificationsView:appID];
    }
    
    return %orig;
}

%end

#pragma mark Prevent scaling bug on notification list view (<= iOS 9) (Needed on iOS 10?)

%hook SBLockScreenNotificationListView

// Use bounds to set size to avoid issues when using transforms
- (void)setFrame:(CGRect)frame {
    CGFloat transform = self.transform.a;
    
    if (transform != 1.0) {
        self.bounds = frame;
    } else {
        %orig;
    }
}

-(BOOL)hidden {
    if ([XENResources enabled] && [XENResources useGroupedNotifications] && ![XENResources usingPriorityHubCompatiblityMode]) {
        return ([XENResources currentlyShownNotificationAppIdentifier] == nil || [[XENResources currentlyShownNotificationAppIdentifier] isEqualToString:@""]);
    } else {
        return %orig;
    }
}

-(void)setHidden:(BOOL)hidden {
    if ([XENResources enabled] && [XENResources useGroupedNotifications] && ![XENResources usingPriorityHubCompatiblityMode] && ([XENResources currentlyShownNotificationAppIdentifier] == nil || [[XENResources currentlyShownNotificationAppIdentifier] isEqualToString:@""])) {
        %orig(YES);
    } else {
        %orig;
    }
}

%end

#pragma mark Fix being unable to tap things like notifications (iOS 9.2 - 9.3)

/*
 * Note that this is NOT needed on iOS 10+.
 */

%hook SBLockScreenViewController

-(void)_addDeviceInformationTextView {
    %orig;
    
    // Disable touches goddamit.
#if TARGET_IPHONE_SIMULATOR==0
    UIViewController *infoViewController = MSHookIvar<UIViewController*>(self, "_deviceInformationTextViewController");
    infoViewController.view.userInteractionEnabled = NO;
#endif
}

%end

#pragma mark Clock postion when grouped notifications are enabled (<= iOS 9)

%hook SBFLockScreenDateView

-(void)setFrame:(CGRect)original {
    if ([XENResources enabled] && [XENResources useGroupedNotifications] && ![XENResources usingPriorityHubCompatiblityMode]) {
        //original.origin.y = NOTIFICATION_CLOCK_MOVE_Y;
        // Make doubly sure of where we are.
        
        id lsView = nil;
        if ([[XENResources lsViewController] respondsToSelector:@selector(lockScreenView)])
            lsView = [[XENResources lsViewController] lockScreenView];
        else if ([[XENResources lsViewController] respondsToSelector:@selector(dashBoardView)])
            lsView = [[XENResources lsViewController] dashBoardView];
            
        SBFLockScreenDateView *dateView = nil;
        
        if (lsView) {
#if TARGET_IPHONE_SIMULATOR==0
            dateView = MSHookIvar<SBFLockScreenDateView*>(lsView, "_dateView");
#endif
        }
        
        if (self == dateView) {
            // TODO: Need to handle for iOS 10! (TODO)
            original.origin.y -= [XENResources calculateAdditionalOffsetForDateView:self withCurrentOffset:[self timeBaselineOffsetFromOrigin]];
        }
    }
    
    %orig(original);
}

%end

%hook SBLockScreenBatteryChargingView

-(void)setFrame:(CGRect)original {
    if ([XENResources enabled] && [XENResources useGroupedNotifications] && ![XENResources usingPriorityHubCompatiblityMode]) {
        //original.origin.y = -NOTIFICATION_CHARGING_MOVE_Y;
        original.origin.y -= [XENResources calculateAdditionalOffsetForDateView:nil withCurrentOffset:0.0];
    }
    
    %orig(original);
}

%end

#pragma mark Clock postion when grouped notifications are enabled (iOS 10+) (TODO)

// iOS 10
// We can do this with SBDashBoardView's dateViewOffset. positive y gives movement up.

/*
 * Not overly sure how we're going to do this, as the metrics class has changed.
 */

#pragma mark Allow tapping of cell (<= iOS 9)

%hook SBLockScreenNotificationListView

%new
-(void)handleActionFromTappedCellWithContext:(id)context {
    [self.delegate handleLockScreenActionWithContext:context];
}

%end

%hook SBLockScreenNotificationTableView

-(void)setAllowsSelection:(BOOL)orig {
    %orig([XENResources enabled] ? YES : orig);
}

%end

#pragma mark Allow tapping of cell (iOS 10+) (TODO)

/*
 * On iOS 10, Apple nicely allows us to slide to open a notification *without* actually sliding the 
 * lockscreen. So, we offer that as an option!
 */

#pragma mark Plugin view handling (iOS 9.0 - 9.3)

%hook SBLockScreenView

- (void)setPluginView:(UIView*)arg1 presentationStyle:(unsigned int)arg2 notificationBehavior:(unsigned int)arg3 {
    %orig;
    
    // Awesome. Now we can get plugin views in Xen!
    
    XENlog(@"Inserting plugin view %@", arg1);
    if ([XENResources enabled]) {
        // Ensure frame is in the right place
        
        // Add into Xen or not.
        
        if ([[arg1 class] isEqual:[objc_getClass("_NowPlayingArtView") class]]) {
            //XENlog(@"Preventing addition of default music view");
        } else if ([[arg1 class] isEqual:[objc_getClass("WebCydgetLockScreenView") class]]) {
            //XENlog(@"Preventing addition of Cydget for us instead");
        } else {
            [baseXenController.homeViewController addPluginViewToView:arg1];
        }
    }
}

%end

#pragma mark Fullscreen bulletin handling (<= iOS 9)

%hook SBSystemLocalNotificationAlert

- (void)willDeactivateForReason:(int)arg1 {
    %orig;
    
    if ([XENResources enabled]) {
        [baseXenController.homeViewController removeFullscreenBulletin];
    }
}

%end

%hook SBLockScreenFullscreenBulletinViewController

-(void)setBulletinItem:(id)item {
    %orig;
    
    if ([XENResources enabled]) {
        [baseXenController.homeViewController addFullscreenBulletinWithNotification:self title:nil andSubtitle:nil];
    }
}

- (void)performSnoozeAction {
    %orig;
    
    if ([XENResources enabled]) {
        [baseXenController.homeViewController removeFullscreenBulletin];
    }
}

- (void)performDismissAction {
    %orig;
    
    if ([XENResources enabled]) {
        [baseXenController.homeViewController removeFullscreenBulletin];
    }
}

-(void)lockButtonPressed:(id)arg1 {
    %orig;
    
    if ([XENResources enabled]) {
        [baseXenController.homeViewController removeFullscreenBulletin];
    }
}

- (void)viewDidAppear:(BOOL)view {
    %orig;
    
    if ([XENResources enabled]) {
        self.view.hidden = YES;
    }
}

%end

#pragma mark Fullscreen bulletin handling (iOS 10+) (TODO)

#pragma mark Move to passcode view when appropriate (<= iOS 9)

%hook SBLockScreenView

-(void)scrollToPage:(int)page animated:(BOOL)animated completion:(id)completion {
    XENlog(@"Trying to scroll to page %d, with completion", page);
    
    if (peekIsVisble && [XENResources peekEnabled] && [XENResources enabled]) {
        // In peek... Shouldn't do anything?
        return;
    }
    
    int adjustedPage = page;
    if ([self respondsToSelector:@selector(lockScreenPageForPageNumber:)] && page == [self lockScreenPageForPageNumber:0])
        adjustedPage = 0;
    else if ([self respondsToSelector:@selector(lockScreenPageForPageNumber:)] && page == [self lockScreenPageForPageNumber:1])
        adjustedPage = 1;
    
    if ([XENResources enabled] && adjustedPage == 0) {
        [baseXenController.homeViewController scrollToPage:adjustedPage completion:nil];
        
        // Going to passcode. If we're using Up unlocking, make sure to also scroll to home controller.
        if (![XENResources useSlideToUnlockMode]) {
            [baseXenController moveToHomeController:YES];
        }
        
        [completion invoke];
    } else if ([XENResources enabled] && adjustedPage == 1) {
        // Wants to go to middle.
        %orig;
        
        [baseXenController moveToHomeController:NO];
    } else {
        %orig;
    }
}

%end

#pragma mark Move to passcode view when appropriate (iOS 10+)

%hook SBDashBoardViewController

- (void)setPasscodeLockVisible:(_Bool)arg1 animated:(_Bool)arg2 completion:(id)arg3 {
    XENlog(@"Trying to set passcode visible: %d, with completion", arg1);
    
    if (peekIsVisble && [XENResources peekEnabled] && [XENResources enabled]) {
        // In peek... Shouldn't do anything?
        return;
    }
    
    if ([XENResources enabled] && [XENResources useSlideToUnlockMode]) {
        /*
         * We should show the passcode UI as appropriate.
         *
         * Note that we only follow this path of exectution when using Slide to Unlock.
         * The reason for this is that visually, slide up also has the same visuals as
         * Click Home for displaying the passcode throughout the UI.
         */
        
        if (arg1) {
            [baseXenController.homeViewController scrollToPage:0 completion:nil];
        
            // Going to passcode. If we're using Up unlocking, make sure to also scroll to home controller.
            if (![XENResources useSlideToUnlockMode]) {
                [baseXenController moveToHomeController:arg2];
            }
        }
        
        // Coming back away from the passcode is achieved by simply calling screenDidTurnOff from elsewhere.
        
        [arg3 invoke];
    } else if ([XENResources enabled] && ![XENResources useSlideToUnlockMode] && [XENResources slideToUnlockModeDirection] != 3) {
        /*
         * When using slide up to unlock, we have a small conundrum. We should allow Apple's default passcode
         * to be displayed for the most part, though we should prevent it showing when we have our own 
         * passcode UI visible.
         */
        
        if (![XENResources isSlideUpPasscodeVisible]) {
            %orig;
        }
    } else {
        /*
         * The default behaviour is to present a NEW instance of SBDashBoardPasscodeViewController
         * if isUnlockDisabled is not YES, and if the currently presented modal controller is not
         * the passcode UI.
         *
         * Thus, the iOS 9 technique of getting passcode enabled state as being when the passcode 
         * view is added may not be appropriate any longer. It's likely we need another hook for 
         * when the UILock flag is set.
         *
         * Furthermore, Touch ID authentication has now changed. There are now TWO ways unlocking 
         * can occur using it:
         * 
         * 1. The user authenticates, and then clicks Home to unlock.
         * 2. Accessibility setting for no click needed is enabled, and the old method applies.
         *
         * We allow the newer approach to still apply for just Home, and we ensure
         * that the user can use the alternative mode of unlocking.
         */
        %orig;
    }
}

%end

%hook SBFUserAuthenticationController

- (void)_setSecureMode:(bool)arg1 postNotification:(bool)arg2 {
    %orig;
    
    if ([UIDevice currentDevice].systemVersion.floatValue >= 10.0 && [XENResources enabled] && [XENResources slideToUnlockModeDirection] != 3) {
        
        if (arg1 && ![XENResources isPasscodeLocked]) {
            // Add the passcode UI seeing as we're locked now.
            [baseXenController.homeViewController addPasscodeViewiOS10];
        }
    }
    
    [XENResources setIsPasscodeLocked:arg1];
}

%end

%hook SBDashBoardPasscodeViewController

%new
-(SBUIPasscodeLockViewBase*)_xen_passcodeLockView {
#if TARGET_IPHONE_SIMULATOR==0
    return MSHookIvar<SBUIPasscodeLockViewBase*>(self, "_passcodeLockView");
#else
    return nil;
#endif
}

%new
-(UIView*)_xen_backgroundView {
#if TARGET_IPHONE_SIMULATOR==0
    return MSHookIvar<SBUIPasscodeLockViewBase*>(self, "_backgroundView");
#else
    return nil;
#endif
}

%end

#pragma mark Force resting authentication for Touch ID when needed (iOS 10+)

%hook SBDashBoardMesaUnlockBehaviorConfiguration

-(BOOL)_isAccessibilityRestingUnlockPreferenceEnabled {
    [XENResources reloadSettings];
    if ([XENResources enabled] && [XENResources slideToUnlockModeDirection] != 3) {
        return YES;
    }
    
    return %orig;
}

%end

#pragma mark Bounce up slider on failed Touch ID (<= iOS 9)

%hook SBLockScreenManager

-(void)biometricEventMonitor:(id)monitor handleBiometricEvent:(unsigned)event {
    if (event == 9 && [XENResources enabled]) {
        //XENlog(@"Failed to match finger");
        [baseXenController moveToHomeController:YES];
        [baseXenController.homeViewController bounce];
        
        if (peekIsVisble && [XENResources peekEnabled] && [XENResources enabled] && !lastProximityState) {
            [(SpringBoard*)[UIApplication sharedApplication] _xen_hidePeekUIWithEvent:kPeekEventOther];
        }
    } else if (event == 10 && [XENResources enabled]) {
        // failed to match finger - 7.1
        //XENlog(@"Failed to match finger");
        [baseXenController moveToHomeController:YES];
        [baseXenController.homeViewController bounce];
        
        if (peekIsVisble && [XENResources peekEnabled] && [XENResources enabled] && !lastProximityState) {
            [(SpringBoard*)[UIApplication sharedApplication] _xen_hidePeekUIWithEvent:kPeekEventOther];
        }
    }
    
    %orig;
}

%end

#pragma mark Bounce up slider on failed Touch ID (iOS 10+)

%hook SBDashBoardViewController

- (void)handleBiometricEvent:(unsigned long long)event {
    if (event == 9 && [XENResources enabled]) {
        XENlog(@"Failed to match finger (9)");
        [baseXenController moveToHomeController:YES];
        [baseXenController.homeViewController bounce];
        
        if (peekIsVisble && [XENResources peekEnabled] && [XENResources enabled] && !lastProximityState) {
            [(SpringBoard*)[UIApplication sharedApplication] _xen_hidePeekUIWithEvent:kPeekEventOther];
        }
    } else if (event == 10 && [XENResources enabled]) {
        // failed to match finger - 7.1
        XENlog(@"Failed to match finger (10)");
        [baseXenController moveToHomeController:YES];
        [baseXenController.homeViewController bounce];
        
        if (peekIsVisble && [XENResources peekEnabled] && [XENResources enabled] && !lastProximityState) {
            [(SpringBoard*)[UIApplication sharedApplication] _xen_hidePeekUIWithEvent:kPeekEventOther];
        }
    } else if ([XENResources enabled]) {
        XENlog(@"Recieved biometric event: %d", event);
    }
    
    %orig;
}

%end

#pragma mark Subclass for launching Launchpad apps (iOS 9+)

%hook XENShortcutModule

-(BOOL)isRestricted {
    return [XENResources requirePasscodeForLaunchpad];
}

- (void)activateAppWithDisplayID:(id)displayID url:(id)url {
    isLaunchpadLaunching = YES;
    %orig;
}

// iOS 10+.
- (void)activateAppWithDisplayID:(id)displayID url:(id)url unlockIfNecessary:(bool)arg3 {
    isLaunchpadLaunching = YES;
    
    SBControlCenterSystemAgent *agent = [[objc_getClass("SBControlCenterSystemAgent") alloc] init];
    [agent activateAppWithDisplayID:displayID url:url unlockIfNecessary:arg3];
}

%end

#pragma mark Override activation settings for apps on Launchpad (iOS 9+)

%hook SBApplication

- (BOOL)boolForActivationSetting:(unsigned)activationSetting {
    BOOL orig = %orig;
    
    if (isLaunchpadLaunching && [XENResources enabled] && [UIDevice currentDevice].systemVersion.floatValue < 10.0) {
        // It's very likely we're launching from Launchpad here.
        switch (activationSetting) {
            case 3:
            case 31:
            case 34:
                return YES;
            default:
                break;
        }
    }
    
    return orig;
}

%end

// This magic here allows us to launch an app not sanctioned by Apple on the LS.
%hook SBWorkspaceTransaction

-(void)_performDeviceCoherencyCheck {
    if (![XENResources enabled]) {
        %orig;
        return;
    }
    
    if (!isLaunchpadLaunching && [XENResources enabled]) {
        %orig;
    }
}

%end

%hook SBAlertToAppsWorkspaceTransaction

-(void)_performDeviceCoherencyCheck {
    if (![XENResources enabled]) {
        %orig;
        return;
    }
    
    if (!isLaunchpadLaunching && [XENResources enabled]) {
        %orig;
    }
}

%end

// Needed on iOS 10.
%hook SBMainWorkspace

- (_Bool)_preflightTransitionRequest:(id)arg1 {
    if (isLaunchpadLaunching && [XENResources enabled] && [UIDevice currentDevice].systemVersion.floatValue >= 10.0) {
        // It's very likely we're launching from Launchpad here.
        return YES;
    }
    
    return %orig;
}

%end

#pragma mark Correct view controller for UIAlertController in Launchpad Quick Dialer. (iOS 9+)

%hook CNContactGridViewController

- (id)viewControllerForActionsView:(id)arg1 {
    // Check if we're on a Xen view.
    if (self.view.superview.tag == 1337) {
        // On Xen.
        return [XENResources lsViewController];
    } else {
        return %orig;
    }
}

%end

#pragma mark Avoid assert() calls for Quick Dialer. (iOS 9+)

/*
 * We need to prevent iOS from killing SpringBoard when a contact isn't quite perfect.
 */

%hook CNContact

- (void)assertKeyIsAvailable:(id)arg1 {
    if (!baseXenController && ![XENResources isLoadedInEditMode]) {
        %orig;
    }
}

- (void)assertKeysAreAvailable:(id)arg1 {
    if (!baseXenController && ![XENResources isLoadedInEditMode]) {
        %orig;
    }
}

%end

#pragma mark Handle passcode etc for Quick Dialer. (iOS 9+)

/*
 * The idea here is that we redirect the calls to openURL in CNPropertyAction and
 * subclasses through to our handler in XENResources. This opens up the passcode UI
 * if appropriate, and goes from there.
 */

%hook CNPropertyAction

- (void)performActionForItem:(id)arg1 sender:(id)arg2 {
    if (baseXenController) {
        [XENResources setShouldOverrideNextURLLaunch:YES];
    }
    
    %orig;
}

%end

%hook CNPropertySendMessageAction

- (void)performActionForItem:(id)arg1 sender:(id)arg2 {
    if (baseXenController) {
        [XENResources setShouldOverrideNextURLLaunch:YES];
    }
    
    %orig;
}

%end

%hook CNPropertyFaceTimeAction

- (void)performActionForItem:(id)arg1 sender:(id)arg2 {
    if (baseXenController) {
        [XENResources setShouldOverrideNextURLLaunch:YES];
    }
    
    %orig;
}

%end

%hook SpringBoard

- (BOOL)openURL:(id)arg1 {
    if (baseXenController && [XENResources shouldOverrideNextURLLaunch]) {
        [XENResources setShouldOverrideNextURLLaunch:NO];
        
        [XENResources openURLWithPasscodeIfNeeded:arg1];
        return YES;
    } else {
        [XENResources setShouldOverrideNextURLLaunch:NO];
        return %orig;
    }
}

%end

%hook LSApplicationWorkspace

- (BOOL)openURL:(id)arg1 withOptions:(id)arg2 {
    if (baseXenController && [XENResources shouldOverrideNextURLLaunch]) {
        [XENResources setShouldOverrideNextURLLaunch:NO];
        
        [XENResources openURLWithPasscodeIfNeeded:arg1];
        return YES;
    } else {
        [XENResources setShouldOverrideNextURLLaunch:NO];
        return %orig;
    }
}

%end

#pragma mark "Peek" at current time, and notifications.
// This is an idea from Nokia's Glance, and using some of Elijah F's FaceOff7 code.

/*
 * For iOS 10, we will only need to hook into SBLiftToWakeManager.
 *
 * Thus, the majority of the following hooks MUST be disabled on 10 or higher; we only need to
 * display our Quick Glance UI if needed.
 */

// Handle iOS 10+ first pls.

/*%hook SBLiftToWakeController

// Simply reset Peek for when display turns off.
- (void)_screenTurnedOff {
    [(SpringBoard*)[UIApplication sharedApplication] _xen_hidePeekUIWithEvent:kPeekEventOther];
    peekIsVisibleiOS10 = NO;
    
    %orig;
}

%end

// May need to override the default support for Lift to Wake?

%hook SBIdleTimerDefaults

-(bool)supportLiftToWake {
    if ([XENResources peekEnabled] && [XENResources enabled]) {
        return YES;
    }
    
    return %orig;
}

%end

%hook CMWakeGestureManager

-(bool)isWakeGestureAvailable {
    if ([XENResources peekEnabled] && [XENResources enabled]) {
        return YES;
    }
    
    return %orig;
}

%end

%hook SBLiftToWakeManager

- (void)liftToWakeController:(id)arg1 didObserveTransition:(long long)arg2 {
    %orig;
    
    XENlog(@"LIFT TO WAKE DID OBSERVE TRANSITION: %llu", arg2);
}

%end*/

// And now onto iOS 9...

#include "IOHIDEventSystem.h"

typedef uint32_t IOPMAssertionID;
enum {
    kIOPMAssertionLevelOff = 0,
    kIOPMAssertionLevelOn = 255
};
typedef uint32_t IOPMAssertionLevel;
IOReturn (*IOPMAssertionCreateWithName)(CFStringRef, IOPMAssertionLevel, CFStringRef, IOPMAssertionID*);
IOReturn (*IOPMAssertionRelease)(IOPMAssertionID);

%hook SBPluginManager

-(Class)loadPluginBundle:(NSBundle*)bundle {
#if USE_PEEK==1
    if ([[bundle bundleIdentifier] isEqualToString:@"com.apple.mobilephone.incomingcall"] && [bundle isLoaded] && peekIsVisble && [XENResources peekEnabled] && [XENResources enabled]) {
        XENlog(@"We should hide the UI for Peek this screen on event (incoming call).");
        [(SpringBoard*)[UIApplication sharedApplication] _xen_hidePeekUIWithEvent:kPeekEventOther];
    }
#endif
    
    return %orig;
}
               
%end

%hook SBLockScreenNotificationListController

- (void)turnOnScreenIfNecessaryForItem:(id)arg1 withCompletion:(void (^)(void))completion {
#if USE_PEEK==1
    if (shouldBeInPeekMode && lastProximityState && [XENResources peekEnabled] && [XENResources enabled]) {
        completion();
        return;
    }
#endif
    
    %orig;
}

%end

%hook SBLockScreenViewController

- (void)_handleDisplayTurnedOnWhileUILocked:(id)locked {
    XENlog(@"Handle display turned on: %@", locked);
    [XENResources setScreenOnState:YES];
    
    [baseXenController makeDamnSureThatHomeIsInMiddleBeforeScreenOn];
    
    %orig;
    
#if USE_PEEK==1
    if (shouldBeInPeekMode && !peekIsVisble && [XENResources peekEnabled] && [XENResources enabled]) {
        if (accelHandler.isUpdating)
            [accelHandler pauseMonitoring];
        
        [peekTimer invalidate];
        peekTimer = nil;
        
        shouldBeInPeekMode = NO;
        peekIsVisble = NO;
        pauseMonitoring = YES;
        
        restoreLLSleep();
    }
    
    if (accelHandler.isUpdating && [XENResources enabled])
        [accelHandler pauseMonitoring];
#endif
}

- (void)_setMediaControlsVisible:(BOOL)visible {
#if USE_PEEK==1
    if ([XENResources enabled]) {
        if ((peekIsVisble && visible && [XENResources peekEnabled]) || (!peekIsVisble || ![XENResources peekEnabled])) %orig;
    } else {
        %orig;
    }
#elif USE_PEEK==0
    %orig;
#endif
}

-(void)handleMenuButtonTap {
#if USE_PEEK==1
    if (peekIsVisble && [XENResources peekEnabled] && [XENResources enabled]) {
        XENlog(@"Menu button was pressed. If in Peek mode, we should hide it.");
        [(SpringBoard*)[UIApplication sharedApplication] _xen_hidePeekUIWithEvent:kPeekEventButtonPress];
    } else {
        %orig;
    }
#elif USE_PEEK==0
    %orig;
#endif
}

%end

%hook SpringBoard

- (BOOL)_handlePhysicalButtonEvent:(UIPhysicalButtonsEvent*)arg1 {
    if ([[NSFileManager defaultManager] fileExistsAtPath:@"/Library/MobileSubstrate/DynamicLibraries/LockPages.dylib"])
        dontScrollForLockPages = YES;
    
#if USE_PEEK==1
    if (peekIsVisble && [XENResources peekEnabled] && [XENResources enabled]) {
        /*
         104 - lock button
         103 - volume down
         102 - volume up
         101 - home
         */
        
        XENlog(@"A physical button (%llu) was pressed. If in Peek mode, we should hide it.", arg1._triggeringPhysicalButton.type);
        
        if (arg1._triggeringPhysicalButton.type != 104) {
            [self _xen_hidePeekUIWithEvent:kPeekEventButtonPress];
            return (arg1._triggeringPhysicalButton.type == 101 ? YES : %orig); // Don't handle HID event if Home button.
        }
    }
#endif
    
    return %orig;
}

- (void)setStatusBarHidden:(BOOL)arg1 withAnimation:(long long)arg2 {
#if USE_PEEK==1
    if (peekIsVisble && ![XENResources peekShowStatusBar] && [XENResources peekEnabled] && [XENResources enabled]) {
        %orig(YES, arg2);
    } else {
        %orig;
    }
#elif USE_PEEK==0
    %orig;
#endif
}

%new
-(void)_xen_showPeekUI {
#if USE_PEEK==1
    // Handle cases where we should ignore the Peek trigger.
    if (lastProximityState) {
        // No Peek allowed if still proximate!
        return;
    } else if ((time(NULL) - lastProximityTimestamp) < 1.5) {
        // Give the user a little time (1.5s) to move their phone out of a potential triggering position.
        return;
    }
    
    // Handle differences between available Peek UI modes.
    if ([XENResources peekShowDarkUI]) {
        XENlog(@"Showing peek UI");
        
        peekIsVisble = YES;
    
        if (shouldBeInPeekMode)
            [baseXenController.homeViewController initialisePeekInterfaceIfEnabled];
    } else {
        XENlog(@"Showing lockscreen directly.");
    }
    
    // Reset sleep disable assertion.
    shouldBeInPeekMode = NO;
    restoreLLSleep();
    
    // Stop monitoring the accelerometer.
    pauseMonitoring = YES;
    [accelHandler pauseMonitoring];
    
    // Bring up display.
    [XENResources turnOnDisplay];
    [XENResources resetLockscreenDimTimer];
    
    [peekTimer invalidate];
    peekTimer = nil;
#endif
}

%new
-(void)_xen_hidePeekUIWithEvent:(XENPeekEvent)event {
#if USE_PEEK==1
    XENlog(@"Hiding peek UI");
    
    // Peek triggering cancelled, we can stop monitoring the accelerometer.
    pauseMonitoring = YES;
    if (accelHandler.isUpdating)
        [accelHandler pauseMonitoring];
    
    shouldBeInPeekMode = NO;
    peekIsVisble = NO;
    
    [baseXenController.homeViewController hidePeekInterfaceForEvent:event];
#endif
}

%end

%hook SBAlertWindow

- (void)sendEvent:(UIEvent *)event {
    // Handle the screen idle timer.
    // TODO: Move this out of the Peek stuff. (TODO)
    UITouch *touch = [event.allTouches anyObject];
    if (touch.phase == UITouchPhaseBegan) {
        [XENResources cancelLockscreenDimTimer];
    } else if (touch.phase == UITouchPhaseEnded || touch.phase == UITouchPhaseCancelled) {
        [XENResources resetLockscreenDimTimer];
        lastTouchTime = time(NULL);
    }
    
    %orig;
}

%end

typedef uint32_t IOPMAssertionID;
typedef uint32_t IOPMAssertionLevel;

static IOPMAssertionID noSleepAssertion;

static void restoreLLSleep() {
#if USE_PEEK==1
    void *IOKit = dlopen("/System/Library/Frameworks/IOKit.framework/IOKit", RTLD_NOW|RTLD_GLOBAL);
    IOPMAssertionRelease = (IOReturn (*)(IOPMAssertionID)) dlsym(IOKit, "IOPMAssertionRelease");
    IOReturn status = IOPMAssertionRelease(noSleepAssertion);
    if (status != kIOReturnSuccess) {
        XENlog(@"Failed to restore system sleep: %d", status);
    } else {
        XENlog(@"Restored system sleep");
    }
    
    dlclose(IOKit);
#endif
}

static void disableLLSleep() {
#if USE_PEEK==1
    void *IOKit = dlopen("/System/Library/Frameworks/IOKit.framework/IOKit", RTLD_NOW|RTLD_GLOBAL);
    IOPMAssertionCreateWithName = (IOReturn (*)(CFStringRef, IOPMAssertionLevel, CFStringRef, IOPMAssertionID *)) dlsym(IOKit, "IOPMAssertionCreateWithName");
    IOReturn status = IOPMAssertionCreateWithName(CFSTR("NoIdleSleepAssertion"),
                                          0xff, CFSTR("Disabling sleep for Xen's Peek feature"), &noSleepAssertion);
    
    if (status != kIOReturnSuccess || !noSleepAssertion) {
        XENlog(@"Failed to prevent system sleep: %d", status);
    } else {
        XENlog(@"Prevented system sleep");
    }
    
    dlclose(IOKit);
#endif
}

static void handleProximityNear(CFNotificationCenterRef center, void *observer, CFStringRef name,
                                 const void *object,CFDictionaryRef userInfo) {
#if USE_PEEK==1
    lastProximityState = YES;
    baseXenController.homeViewController.touchStealingWindow.isProximate = lastProximityState;
#endif
}

static void handleProximityFar(CFNotificationCenterRef center, void *observer, CFStringRef name,
                               const void *object,CFDictionaryRef userInfo) {
#if USE_PEEK==1
    lastProximityState = NO;
    baseXenController.homeViewController.touchStealingWindow.isProximate = lastProximityState;
#endif
}

static void beginMonitoringProximity() {
#if USE_PEEK==1
    XENlog(@"Device is now locked. Begin monitoring proximity state, and accelerometer too.");
    
    // Reset states.
    lastProximityState = NO;
    lastProximityTimestamp = time(NULL);
    
    shouldBeInPeekMode = YES;
    peekIsVisble = NO;
    
    // Restart monitoring accelerometer.
    pauseMonitoring = NO;
    [accelHandler pauseMonitoring];
    accelHandler = nil;
    accelHandler = [[XENAccelerometerHandler alloc] initWithThreshold:[XENResources peekSensitivity]];
    
    /*
     * Since there is great confusion:
     * Monitoring is done off the accelerometer. If proximate when triggered, ignore the trigger. Simple.
     * If not stopped when unlocking, next trigger will stop it.
     */
    [accelHandler startMonitoringWithCallback:^{
        if (!pauseMonitoring) {
            [(SpringBoard*)[UIApplication sharedApplication] _xen_showPeekUI];
        } else if (!baseXenController) {
            [accelHandler pauseMonitoring];
        }
    }];
    
    // Hide any existing Peek UI if needed.
    [baseXenController.homeViewController hidePeekInterfaceForEvent:kPeekEventOther];
    
    // Enable the proximity sensor and disable sleep.
    // TODO: This really should be switched over to use BackBoardServices.framework. (TODO)
    notify_post("com.matchstic.xen/enableProx");
    
    disableLLSleep();
#endif
}

static void endMonitoringProximity() {
#if USE_PEEK==1
    // End monitoring the proximity sensor.
    // TODO: This really should be switched over to use BackBoardServices.framework. (TODO)
    notify_post("com.matchstic.xen/disableProx");
#endif
}

%end

%group backboardd

@interface BKProximitySensorInterface : NSObject
+(id)sharedInstance;
-(int)requestedMode;
-(void)enableProximityDetectionWithMode:(int)arg1;
-(void)disableProximityDetection;
-(void)setPocketTouchesExpected:(BOOL)arg1;
@end

static void disableProximityMonitoring(CFNotificationCenterRef center, void *observer, CFStringRef name,
                                      const void *object,CFDictionaryRef userInfo) {
#if USE_PEEK==1
    XENlog(@"Disabling proximity monitoring...");
    
    [[%c(BKProximitySensorInterface) sharedInstance] disableProximityDetection];
    [[%c(BKProximitySensorInterface) sharedInstance] setPocketTouchesExpected:NO];
#endif
}

static void enableProximityMonitoring(CFNotificationCenterRef center, void *observer, CFStringRef name,
                                       const void *object,CFDictionaryRef userInfo) {
#if USE_PEEK==1
    XENlog(@"Enabling proximity monitoring...");
    
    /*
     * Modes:
     * 0 == not a mode
     * 1 == same as 2, I think
     * 2 == enable, but disable interaction on views currently shown
     * 255 == disable; used internally by -disableProximityDetection
     */
    
    if ([[%c(BKProximitySensorInterface) sharedInstance] requestedMode] != 2) {
        [[%c(BKProximitySensorInterface) sharedInstance] setPocketTouchesExpected:NO];
        [[%c(BKProximitySensorInterface) sharedInstance] enableProximityDetectionWithMode:2];
    }
#endif
}

#if TARGET_IPHONE_SIMULATOR==0
typedef void(*IOHIDEventSystemCallback)(void* target, void* refcon, IOHIDServiceRef service, IOHIDEventRef event);

static Boolean (*ori_IOHIDEventSystemOpen)(IOHIDEventSystemRef, IOHIDEventSystemCallback,void *,void *,void *);
static void (*ori_IOHIDEventCallback)(void *a, void *b, __IOHIDService *c, __IOHIDEvent *e) = NULL;

static void __IOHIDEventCallback(void *a, void *b, __IOHIDService *c, __IOHIDEvent *e) {
    ori_IOHIDEventCallback(a, b, c, e);
    
    if (IOHIDEventGetType(e) == kIOHIDEventTypeProximity) { // Proximity Event Received
        int proximityValue = IOHIDEventGetIntegerValue(e, (IOHIDEventField)kIOHIDEventFieldProximityDetectionMask); // Get the value of the ProximityChanged Field (0 or 64)
        BOOL proximate = proximityValue == 0 ? NO : YES;
        
        // Fire off notification dependant on proximate
        XENlog(@"Firing off notification that proximity changed!");
        notify_post(proximate ? "com.matchstic.xen/proxNear" : "com.matchstic.xen/proxFar");
    }
}

MSHook(Boolean, IOHIDEventSystemOpen, IOHIDEventSystemRef system, IOHIDEventSystemCallback callback, void *a, void *b, void *c) {
    ori_IOHIDEventCallback = callback;
    MSHookFunction(callback, __IOHIDEventCallback, &ori_IOHIDEventCallback);
    return ori_IOHIDEventSystemOpen(system, callback, a, b, c);
}
#endif

%end

#pragma mark Ensure that grabbers don't move at all when scrolling (iOS 9.0 - 9.3)
// Note that the grabbers aren't visible on the iOS 10 LS.

%group SpringBoard

%hook SBLockScreenView

- (void)_layoutGrabberView:(id)view atTop:(BOOL)top percentScrolled:(CGFloat)scrolled {
    %orig(view, top, [XENResources enabled] ? 0.0 : scrolled);
}

%end

#pragma mark Lockscreen dim duration adjustments (iOS 9.0 - 9.3)

%hook SBBacklightController

- (double)defaultLockScreenDimInterval {
    return ([XENResources enabled] ? [XENResources lockScreenIdleTime] : %orig);
}

- (double)defaultLockScreenDimIntervalWhenNotificationsPresent {
    return ([XENResources enabled] ? [XENResources lockScreenIdleTime] : %orig);
}

%end

#pragma mark Lockscreen dim duration adjustments (iOS 10+)

%hook SBManualIdleTimer

- (id)initWithInterval:(double)arg1 userEventInterface:(id)arg2 {
    if (baseXenController && [XENResources enabled]) {
        arg1 = [XENResources lockScreenIdleTime];
    }
    
    if (setupWindow) {
        arg1 = 1000;
    }
    
    return %orig(arg1, arg2);
}

%end

#pragma mark Hide original artwork if necessary (<= iOS 9) (Needed on iOS 10?)

/*
 * I'm going to assume that Apple didn't change the plugin view for artwork on iOS 10.
 * However, this does need validation at runtime.
 */

// SBDashBoardMediaArtworkViewController, presented to SBDashBoardMainPageContentViewController

@interface _NowPlayingArtView : UIView
@end

%hook _NowPlayingArtView

-(void)layoutSubviews {
    %orig;
    
    BOOL shouldHide = [XENResources enabled] && ([XENResources mediaArtworkStyle] == 0 || [XENResources mediaArtworkStyle] == 2);
    
    if (shouldHide) {
        self.hidden = YES;
    }
}

%end

#pragma mark Prevent blur from emergency dialer popping up (<= iOS 9) (Needed on iOS 10?)

%hook SBLockScreenView

- (void)_showFakeWallpaperBlurWithAlpha:(CGFloat)alpha withFactory:(id)factory {
    %orig([XENResources enabled] ? 0.0 : alpha, factory);
}

%end

#pragma mark Ensure that touches are passed through the notifications collection view (iOS 9+)

%hook UICollectionView

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *orig = %orig;
    
    if (self.tag != 1337123) {
        return orig;
    }
    
    return ([orig isEqual:self] ? nil : orig);
}

%end

#pragma mark Toggles page, fix colourations. (<= iOS 9)

%hook MPUSystemMediaControlsViewController

%new
-(MPUSystemMediaControlsView*)_xen_mediaView {
#if TARGET_IPHONE_SIMULATOR==0
    return MSHookIvar<MPUSystemMediaControlsView*>(self, "_mediaControlsView");
#else
    return nil;
#endif
}

%end

@interface SBUIControlCenterButton (Eh)
@property (nonatomic) id delegate;
@end

%hook SBUIControlCenterButton

- (id)initWithFrame:(CGRect)arg1 {
    // Add white background to button for legibility.
    SBUIControlCenterButton *orig = %orig;
    
    // Check if called from Xen.
    if ([XENResources isTogglesConfiguring]) {
        UIView *whitebg = [[UIView alloc] initWithFrame:arg1];
        whitebg.hidden = YES;
        whitebg.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.35];
        whitebg.tag = 1337;
        whitebg.userInteractionEnabled = NO;
    
        [orig insertSubview:whitebg atIndex:0];
        
        UIImageView *glyph = [[UIImageView alloc] initWithFrame:arg1];
        glyph.hidden = YES;
        glyph.backgroundColor = [UIColor clearColor];
        glyph.tag = 13379;
        glyph.userInteractionEnabled = NO;
        
        [orig insertSubview:glyph atIndex:1];
        
        if (![XENResources shouldUseDarkColouration]) {
            if (![XENResources blurredBackground]) {
                if (!UIAccessibilityIsReduceTransparencyEnabled()) {
                    // Running on user-toggled no blur.
                    
                } else {
#if TARGET_IPHONE_SIMULATOR==0
                    MSHookIvar<UIVisualEffect*>(self, "_normalStateEffect") = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
#endif
                }
            } else {
#if TARGET_IPHONE_SIMULATOR==0
                MSHookIvar<UIVisualEffect*>(self, "_normalStateEffect") = [UIVibrancyEffect effectForBlurEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]];
#endif
            }
            
#if TARGET_IPHONE_SIMULATOR==0
            MSHookIvar<UIVisualEffect*>(self, "_highlightedStateEffect") = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
#endif

            // Kill the grayscale filter view.
            //_UIVisualEffectFilterView * _grayscaleSubview;
#if TARGET_IPHONE_SIMULATOR==0
            UIVisualEffectView *effectView = MSHookIvar<UIVisualEffectView*>(self, "_backgroundEffectView");
            if (effectView) {
                UIView *grayscale = MSHookIvar<UIView*>(effectView, "_grayscaleSubview");
                
                if (grayscale) {
                    grayscale.hidden = YES;
                    [grayscale removeFromSuperview];
                }
            }
#endif
        } else {
#if TARGET_IPHONE_SIMULATOR==0
            MSHookIvar<UIVisualEffect*>(self, "_highlightedStateEffect") = [UIVibrancyEffect effectForBlurEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]];
#endif
        }
        
        [orig _updateForStateChange];
    }
    
    return orig;
}

- (id)_backgroundImage {
    UIImage *orig = %orig;
    if ([self viewWithTag:1337] != nil && ![object_getClass(self.delegate) isEqual:objc_getClass("SBCCButtonLikeSectionView")]) {
        // Check for if we should have an alternate background.
        UIImage *img = [XENResources backgroundForTogglesIsCircle:[self isCircleButton]];
        
        if (img) {
            orig = img;
            UIView *whitebg = [self viewWithTag:1337];
            whitebg.alpha = 0.0;
            whitebg.hidden = YES;
        }
    }
    
    return orig;
}

- (id)_glyphImageForState:(int)arg1 {
    UIImage *glyph = %orig;
    
    NSString *name = @"";
    if ([[self class] isEqual:objc_getClass("SBControlCenterButton")]) {
#if TARGET_IPHONE_SIMULATOR==0
        name = MSHookIvar<NSString*>(self, "_identifier");
#endif
    }
    
    UIImage *tempGlyph = [XENResources glyphForToggleWithName:name andState:arg1];
    BOOL fullColour = NO;
    
    if ([XENResources enabled] && tempGlyph && [self viewWithTag:1337] != nil) {
        glyph = tempGlyph;
        fullColour = [XENResources togglesGlyphsAreFullColour];
    }
    
    if ([XENResources enabled] && [XENResources togglesGlyphTintForState:arg1 isCircle:[self isCircleButton]] && [self viewWithTag:1337] != nil) {
        [[self viewWithTag:13379] setTintColor:[XENResources togglesGlyphTintForState:arg1 isCircle:[self isCircleButton]]];
#if TARGET_IPHONE_SIMULATOR==0
        [MSHookIvar<UIImageView*>(self, "_glyphImageView") setHidden:YES];
#endif
        [[self viewWithTag:13379] setHidden:NO];
        
        // Load up custom image at this point!
        UIImage *img = [glyph imageWithRenderingMode:(fullColour ? UIImageRenderingModeAlwaysOriginal : UIImageRenderingModeAlwaysTemplate)];
        
        [(UIImageView*)[self viewWithTag:13379] setImage:img];
        
        return img;
    }
    
    return glyph;
}

-(void)layoutSubviews {
    %orig;
    
    UIView *whitebg = [self viewWithTag:1337];
    whitebg.frame = self.bounds;
    //whitebg.frame = CGRectZero;
    
    // If on a buttonlike view, abort!
    //if ([object_getClass(self.delegate) isEqual:objc_getClass("SBCCButtonLikeSectionView")]) {
    if ([XENResources blurredBackground] || [object_getClass(self.delegate) isEqual:objc_getClass("SBCCButtonLikeSectionView")]) {
        whitebg.alpha = 0.0;
        whitebg.hidden = YES;
    } else {
        // Format the frames.
        whitebg.layer.cornerRadius = [self isCircleButton] ? whitebg.frame.size.height/2 : 12.5;
    }
    
    if ([XENResources enabled] && [XENResources togglesGlyphTintForState:0 isCircle:[self isCircleButton]] && whitebg) {
        // Hide original glyph image
#if TARGET_IPHONE_SIMULATOR==0
        [MSHookIvar<UIImageView*>(self, "_glyphImageView") setHidden:YES];
        [[self viewWithTag:13379] setHidden:NO];
        [[self viewWithTag:13379] setFrame:[MSHookIvar<UIImageView*>(self, "_glyphImageView") frame]];
#endif
    }
    
    if (whitebg) {
        [self _updateEffects];
    }
}

- (void)_updateEffects {
    %orig;
    
    if ([self viewWithTag:1337] != nil) {
       // MSHookIvar<UIVisualEffect*>(self, "_normalStateEffect") = [objc_getClass("SBUIControlCenterVisualEffect") effectWithStyle:0];        //MSHookIvar<UIVisualEffect*>(self, "_highlightedStateEffect") = [objc_getClass("SBUIControlCenterVisualEffect") effectWithStyle:1];
        //MSHookIvar<UIVisualEffect*>(self, "_highlightedStateEffect") = [UIVibrancyEffect effectForBlurEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]];
        
        if (![XENResources shouldUseDarkColouration]) {
            if (![XENResources blurredBackground]) {
                if (!UIAccessibilityIsReduceTransparencyEnabled()) {
                    // Running on user-toggled no blur.
                    
                } else {
#if TARGET_IPHONE_SIMULATOR==0
                    MSHookIvar<UIVisualEffect*>(self, "_normalStateEffect") = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
#endif
                }
            } else {
#if TARGET_IPHONE_SIMULATOR==0
                MSHookIvar<UIVisualEffect*>(self, "_normalStateEffect") = [UIVibrancyEffect effectForBlurEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]];
#endif
            }
#if TARGET_IPHONE_SIMULATOR==0
            MSHookIvar<UIVisualEffect*>(self, "_highlightedStateEffect") = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
#endif
            
            // Kill the grayscale filter view.
            //_UIVisualEffectFilterView * _grayscaleSubview;
#if TARGET_IPHONE_SIMULATOR==0
            UIVisualEffectView *effectView = MSHookIvar<UIVisualEffectView*>(self, "_backgroundEffectView");
            if (effectView) {
                UIView *grayscale = MSHookIvar<UIView*>(effectView, "_grayscaleSubview");
                
                if (grayscale) {
                    grayscale.hidden = YES;
                    [grayscale removeFromSuperview];
                }
            }
#endif
        } else {
#if TARGET_IPHONE_SIMULATOR==0
            MSHookIvar<UIVisualEffect*>(self, "_highlightedStateEffect") = [UIVibrancyEffect effectForBlurEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]];
#endif
        }
    }
}

- (void)_updateForStateChange {
    %orig;
    
    if ([self viewWithTag:1337] != nil) {
        UIView *whitebg = [self viewWithTag:1337];
        if ([[self superview].class isEqual:objc_getClass("SBCCButtonLikeSectionView")]) {
            whitebg.hidden = YES;
        } else {
            //whitebg.hidden = [self _currentState] != 0;
            whitebg.hidden = YES;
        }
        
        // Kill the grayscale filter view.
        //_UIVisualEffectFilterView * _grayscaleSubview;
#if TARGET_IPHONE_SIMULATOR==0
        UIVisualEffectView *effectView = MSHookIvar<UIVisualEffectView*>(self, "_backgroundEffectView");
        if (effectView) {
            UIView *grayscale = MSHookIvar<UIView*>(effectView, "_grayscaleSubview");
            
            if (grayscale) {
                grayscale.hidden = YES;
                [grayscale removeFromSuperview];
            }
        }
        
        if (![XENResources blurredBackground]) {
            effectView.alpha = [self _currentState] != 0 ? 0.85 : 1.0;
            whitebg.hidden = [self _currentState] != 0;
            whitebg.alpha = 1.0;
        } else if (![XENResources shouldUseDarkColouration]) {
            // Ensures it's not as harsh.
            effectView.alpha = [self _currentState] != 0 ? 0.75 : 1.0;
        }
#endif
    }
}

%end

%hook SBCCButtonLikeSectionView

- (id)initWithFrame:(CGRect)arg1 {
    // Add white background to button for legibility.
    UIView *orig = %orig;
    
    if ([XENResources isTogglesConfiguring]) {
        UIView *whitebg = [[UIView alloc] initWithFrame:arg1];
        whitebg.hidden = YES;
        whitebg.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.35];
        whitebg.tag = 1337;
        whitebg.userInteractionEnabled = NO;
        
        [orig insertSubview:whitebg atIndex:0];
        
#if TARGET_IPHONE_SIMULATOR==0
        UILabel *label2 = MSHookIvar<UILabel*>(orig, "_label");
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
        label.hidden = YES;
        label.font = label2.font;
        label.backgroundColor = label2.backgroundColor;
        label.userInteractionEnabled = NO;
        label.alpha = 1.0;
        label.tag = 13379;
        
        [orig insertSubview:label atIndex:1];
#endif
        
        if (![XENResources shouldUseDarkColouration]) {
            if (![XENResources blurredBackground] && !UIAccessibilityIsReduceTransparencyEnabled()) {
                //MSHookIvar<UIVisualEffect*>(self, "_normalStateEffect") = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
            } else {
#if TARGET_IPHONE_SIMULATOR==0
                MSHookIvar<UIVisualEffect*>(self, "_normalStateEffect") = [UIVibrancyEffect effectForBlurEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]];
                MSHookIvar<UIVisualEffect*>(self, "_highlightedStateEffect") = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
#endif
            }
        } else {
#if TARGET_IPHONE_SIMULATOR==0
            MSHookIvar<UIVisualEffect*>(self, "_highlightedStateEffect") = [UIVibrancyEffect effectForBlurEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]];
#endif
        }
        
        [self _updateBackgroundForStateChange];
    }
    
    return (SBCCButtonLikeSectionView*)orig;
}

- (void)_updateEffects {
    %orig;
    
    if ([self viewWithTag:1337] != nil) {
        if (![XENResources shouldUseDarkColouration]) {
            if (![XENResources blurredBackground] && !UIAccessibilityIsReduceTransparencyEnabled()) {
                //MSHookIvar<UIVisualEffect*>(self, "_normalStateEffect") = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
            } else {
#if TARGET_IPHONE_SIMULATOR==0
                MSHookIvar<UIVisualEffect*>(self, "_normalStateEffect") = [UIVibrancyEffect effectForBlurEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]];
                MSHookIvar<UIVisualEffect*>(self, "_highlightedStateEffect") = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
#endif
            }
        } else {
#if TARGET_IPHONE_SIMULATOR==0
            MSHookIvar<UIVisualEffect*>(self, "_highlightedStateEffect") = [UIVibrancyEffect effectForBlurEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]];
#endif
        }
    }
}

-(void)layoutSubviews {
    %orig;
    
    UIView *whitebg = [self viewWithTag:1337];
    if ([XENResources blurredBackground]) {
        whitebg.frame = CGRectZero;
    } else {
        whitebg.frame = self.bounds;
        // Nicely do stuff.
    }
    
    if ([XENResources enabled] && [XENResources togglesGlyphTintForState:0 isCircle:NO] && whitebg) {
            // Hide original glyph image
#if TARGET_IPHONE_SIMULATOR==0
        UILabel *label = MSHookIvar<UILabel*>(self, "_label");
        [label setHidden:YES];
        [[self viewWithTag:13379] setHidden:NO];
        [[self viewWithTag:13379] setFrame:label.frame];

        [(UILabel*)[self viewWithTag:13379] setTextColor:[XENResources togglesGlyphTintForState:0 isCircle:NO]];
        [(UILabel*)[self viewWithTag:13379] setText:label.text];
        [(UILabel*)[self viewWithTag:13379] setFont:label.font];
#endif
    }
    
    if ([XENResources backgroundForTogglesAirStuff] && whitebg) {
        whitebg.alpha = 0.0;
        whitebg.hidden = YES;
        
#if TARGET_IPHONE_SIMULATOR==0
        [MSHookIvar<UIView*>(self, "_vibrantDarkenLayer") setHidden:YES];
#endif
    }
    
    if (whitebg)
        [self _updateBackgroundForStateChange];
}

- (id)_backgroundImageWithRoundCorners:(unsigned)roundCorners {
    UIImage *orig = %orig;
    if ([self viewWithTag:1337] != nil) {
        // Check for if we should have an alternate background.
        UIImage *img = [XENResources backgroundForTogglesAirStuff];
        if (img) {
            orig = img;
            UIView *whitebg = [self viewWithTag:1337];
            whitebg.alpha = 0.0;
            whitebg.hidden = YES;
        }
    }
    
    return orig;
}

- (void)setSelected:(BOOL)selected {
    %orig;
    
    if ([self viewWithTag:1337] != nil) {
        UIView *whitebg = [self viewWithTag:1337];
        if (![XENResources blurredBackground])
            whitebg.hidden = selected != 0;
        else
            whitebg.hidden = YES;
    }
}

- (void)buttonTapped:(id)tapped {
    %orig;
}

%end

%hook SBCCBrightnessSectionController

-(BOOL)_shouldDarkenBackground {
    // Fix dark colouration on Toggles brightness slider.
    if ([self.view.superview.class isEqual:objc_getClass("_UIVisualEffectContentView")] || [self xen_slider].tag == 1337) {
        return NO;
    }
    
    return %orig;
}

%new
-(SBUIControlCenterSlider*)xen_slider {
#if TARGET_IPHONE_SIMULATOR==0
    return MSHookIvar<SBUIControlCenterSlider*>(self, "_slider");
#else
    return nil;
#endif
}

%end

%hook SBUIControlCenterSlider

-(id)_valueImageForImage:(id)arg1 state:(long long)arg2 {
    if (self.tag == 1337) {
        return %orig(arg1, 1);
    } else {
        return %orig;
    }
}

-(void)setAdjusting:(BOOL)arg1 {
    %orig(self.tag == 1337 ? YES : arg1);
}

%end

#pragma mark Toggles page subclass (iOS 10+)

/*
 * On iOS 10+, we now simply display the CC pages in a scrolling view.
 * To achieve this, it may be best to subclass the existing CCUIControlCenterViewController, which
 * will grant us access to all pages, even those added by other tweaks. 
 *
 * To do this, we will override the existing scroll view and make it vertical, change the 
 * computed frames of the pages from this subclass, hide the darkening mask view and page control,
 * along with anything else that is required to correctly display the pages.
 *
 * Pages are loaded and sorted with visibility in viewDidLoad. Call that CC did present as needed before use.
 * Also, make our page this subclass's delegate.
 */

%hook XENControlCenterViewController

-(id)init {
    id orig = %orig;
    
    if (orig) {
        // Remove observers for NSNotifications, as we don't need them.
        [[NSNotificationCenter defaultCenter] removeObserver:orig];
    }
    
    return orig;
}

-(void)_layoutScrollView {
    // Do nothing.
}

- (void)_addContentViewController:(id)arg1 {
    // TODO: Let delegate know of changes?
    %orig;    
}

- (id)controlCenterSystemAgent {
    return [[objc_getClass("SBControlCenterController") sharedInstance] controlCenterSystemAgentForControlCenterViewController:self];
}

%end

#pragma mark Dismiss Content page editor on physical button press (<= iOS 9)

@interface SpringBoard (ExtraEh)
-(void)xen_dismissContentEditor;
@end

%hook SpringBoard

- (void)_handleMenuButtonEvent {
    [self xen_dismissContentEditor];
    %orig;
}

- (void)handleMenuDoubleTap {
    [self xen_dismissContentEditor];
    %orig;
}

%new
-(void)xen_dismissContentEditor {
    [UIView animateWithDuration:0.0 animations:^{
        [XENResources contentEditWindow].alpha = 0.0;
    } completion:^(BOOL finished) {
        [XENResources hideContentEditWindow];
    }];
}

%end

#pragma mark Dismiss Content page editor on physical button press (iOS 10+)

@interface SBDashBoardViewController (ExtraEh)
-(void)xen_dismissContentEditor;
@end

%hook SBDashBoardViewController

- (_Bool)handleMenuButtonTap {
    [self xen_dismissContentEditor];
    return %orig;
}

- (_Bool)handleMenuButtonHeld {
    [self xen_dismissContentEditor];
    return %orig;
}

%new
-(void)xen_dismissContentEditor {
    [UIView animateWithDuration:0.0 animations:^{
        [XENResources contentEditWindow].alpha = 0.0;
    } completion:^(BOOL finished) {
        [XENResources hideContentEditWindow];
    }];
}


%end

#pragma mark Suppress CC if appropriate (<= iOS 9)

%hook SBLockScreenViewController

-(BOOL)suppressesControlCenter {
    if ([XENResources enabled] && ![XENResources shouldProvideCC])
        return YES;
    else
        return %orig;
}

%end

%hook SBLockScreenView

- (void)_layoutGrabberView:(UIView*)view atTop:(BOOL)top {
    if (!top && [XENResources enabled] && (![XENResources shouldProvideCC] || [XENResources hideCCGrabber])) {
        view.hidden = YES;
        view.alpha = 0.0;
    } else if (!top && [XENResources enabled] && [XENResources shouldProvideCC]) {
        view.hidden = NO;
        view.alpha = 1.0;
        %orig;
    } else if (top && [XENResources enabled] && ([XENResources hideNCGrabber] || [XENResources isLoadedInEditMode])) {
        view.hidden = YES;
        view.alpha = 0.0;
    } else {
        %orig;
    }
}

// TODO: MOVE THIS! (TODO)
%new
-(void)_xen_relayoutDateView {
    // Layout once more please.
#if TARGET_IPHONE_SIMULATOR==0
    SBFLockScreenDateView *_dateView = MSHookIvar<SBFLockScreenDateView*>(self, "_dateView");
    
    CGFloat baseY = [objc_getClass("SBFLockScreenMetrics") dateViewBaselineY];
    baseY -= [_dateView timeBaselineOffsetFromOrigin];
    
    [_dateView setFrame:CGRectMake(_dateView.frame.origin.x, baseY, _dateView.frame.size.width, _dateView.frame.size.height)];
#endif
}

%end

#pragma mark Suppress CC if appropriate (iOS 10+) (TODO, should we even do this?)

/*%hook SBDashBoardViewController

-(BOOL)suppressesControlCenter {
    if ([XENResources enabled] && ![XENResources shouldProvideCC])
        return YES;
    else
        return %orig;
}

%end*/

#pragma mark Fix flashlight in CC and Xen. (iOS 9+)

%hook AVFlashlight

-(id)init {
    if (!_sharedFlashlight) {
        _sharedFlashlight = %orig;
    }
    
    return _sharedFlashlight;
}

%end

#pragma mark Allow theming of the majority of UI elements (<= iOS 9) (What can we use on 10 too?)

@interface UIVisualEffectView (Extra)
-(void)setEffect:(id)effect;
@end

@interface SBUIControlCenterSlider (Extra)
-(void)_xen_postLayout;
@end

@interface UIImageView (Private)
- (void)_setDefaultRenderingMode:(int)arg1;
@end

%hook SBUIControlCenterSlider // If on Xen, then we should disable the effect view?

-(void)layoutSubviews {
    %orig;
    
    if ([XENResources isViewOnXen:self] && baseXenController) {
        for (UIView *view in self.subviews) {
            if ([[view class] isEqual:[UIVisualEffectView class]]) {
                [(UIVisualEffectView*)view setEffect:nil];
            }
        }
    
#if TARGET_IPHONE_SIMULATOR==0
        [self addSubview:MSHookIvar<UIView*>(self, "_thumbView")];
#endif
        
        // XXX: I removed a method call that would set the track images at this point.
        
#if TARGET_IPHONE_SIMULATOR==0
        if ([XENResources togglesGlyphTintForState:1 isCircle:YES]) {
            [MSHookIvar<UIImageView*>(self, "_maxValueImageView") setTintColor:[XENResources togglesGlyphTintForState:1 isCircle:YES]];
            [MSHookIvar<UIImageView*>(self, "_maxValueImageView") _setDefaultRenderingMode:2];
            [MSHookIvar<UIImageView*>(self, "_minValueImageView") setTintColor:[XENResources togglesGlyphTintForState:1 isCircle:YES]];
            [MSHookIvar<UIImageView*>(self, "_minValueImageView") _setDefaultRenderingMode:2];
        }
#endif
        
    }
}

// It is unknown if these changes will work as expected. Oh well, users will say so.
-(void)setMaximumTrackImage:(UIImage*)image forState:(int)state {
    if (self.tag == 1337 && baseXenController) {
        UIImage *max = [[XENResources themedImageWithName:@"SliderMax"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 0, 5)];
        if (max)
            image = max;
    }
    
    %orig(image, state);
}

-(void)setMinimumTrackImage:(UIImage*)image forState:(int)state {
    if (self.tag == 1337 && baseXenController) {
        UIImage *max = [[XENResources themedImageWithName:@"SliderMin"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 5, 0, 0)];
        if (max)
            image = max;
    }
    
    %orig(image, state);
}

-(void)setThumbImage:(UIImage*)image forState:(int)state {
    if (self.tag == 1337 && baseXenController) {
        UIImage *thumb = [XENResources themedImageWithName:@"SliderThumb"];
        if (thumb)
            image = thumb;
    }
    
    %orig(image, state);
}

%new
-(void)_xen_setTrackImagesForCurrentTheme {
    if (self.tag == 1337 && baseXenController) {
        UIImage *max = [[XENResources themedImageWithName:@"SliderMax"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 0, 5)];
        if (max)
            [self setMaximumTrackImage:max forState:UIControlStateNormal];
        
        UIImage *min = [[XENResources themedImageWithName:@"SliderMin"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 5, 0, 0)];
        if (min)
            [self setMinimumTrackImage:min forState:UIControlStateNormal];
        
        UIImage *thumb = [XENResources themedImageWithName:@"SliderThumb"];
        if (thumb) {
            [self setThumbImage:thumb forState:UIControlStateHighlighted];
            [self setThumbImage:thumb forState:UIControlStateNormal];
        }
    }
}

%end

@interface MPVolumeController : NSObject
- (float)setVolumeValue:(float)arg1;
- (float)volumeValue;
@end

@interface MPUMediaControlsVolumeView (Private)
- (id)_createVolumeSliderView;
- (void)_xen_postLayout;
@property (nonatomic, readonly) MPVolumeController *volumeController;
@end

// provide a custom slider here!
%hook MPUMediaControlsVolumeView

-(void)layoutSubviews {
    %orig;
    
#if TARGET_IPHONE_SIMULATOR==0
    if ([XENResources enabled] && MSHookIvar<int>(self, "_style") != 1 && !self.slider.hidden && [XENResources themedImageWithName:@"SliderThumb"] && baseXenController) {
        // Create a new slider!
        self.slider.tag = 1;
        self.slider.hidden = YES;
        
        SBUIControlCenterSlider *slider = [[objc_getClass("SBUIControlCenterSlider") alloc] init];
        slider.tag = 1337;
        [slider setMinimumValueImage:self.slider.minimumValueImage];
        [slider setMaximumValueImage:self.slider.maximumValueImage];
        [slider setValue:self.slider.value];
        [slider setAdjusting:YES];
        [slider _xen_setTrackImagesForCurrentTheme];
        
        // Set up targets.
        [slider addTarget:self action:@selector(_xen_volumeChangeStarted:) forControlEvents:0x1];
        [slider addTarget:self action:@selector(_xen_volumeValueChanged:) forControlEvents:0x1000];
        [slider addTarget:self action:@selector(_xen_volumeStoppedChange:) forControlEvents:0x1c0];
        
        [self insertSubview:slider aboveSubview:self.slider];
    }
#endif
    
    if (self.slider.hidden && baseXenController) {
        SBUIControlCenterSlider *slider = (SBUIControlCenterSlider*)[self viewWithTag:1337];
        slider.frame = self.slider.frame;
    }
}

-(void)updateSystemVolumeLevel {
    %orig;
    
    SBUIControlCenterSlider *slider = (SBUIControlCenterSlider*)[self viewWithTag:1337];
    [slider setValue:[self.volumeController volumeValue]];
}

- (void)volumeController:(id)arg1 volumeValueDidChange:(float)arg2 {
    %orig;
    
    SBUIControlCenterSlider *slider = (SBUIControlCenterSlider*)[self viewWithTag:1337];
    [slider setValue:[self.volumeController volumeValue]];
}

%new
-(void)_xen_volumeChangeStarted:(id)sender {
    //SBUIControlCenterSlider *slider = (SBUIControlCenterSlider*)[self viewWithTag:1337];
}

%new
-(void)_xen_volumeValueChanged:(id)sender {
    SBUIControlCenterSlider *slider = (SBUIControlCenterSlider*)[self viewWithTag:1337];
    
    [self.volumeController setVolumeValue:slider.value];
}

%new
-(void)_xen_volumeStoppedChange:(id)sender {
}

%end

%hook SBLockScreenViewController

// Force a refresh of media controls each lock; fixes delayed update.
-(void)_addMediaControls {
#if TARGET_IPHONE_SIMULATOR==0
    MSHookIvar<NSObject*>(self, "_mediaControlsViewController") = nil;
#endif
    %orig;
}

%end

%hook MPUSystemMediaControlsViewController

- (id)_imageForTransportButtonWithControlType:(int)arg1 {
    UIImage *orig = %orig;
    
#if TARGET_IPHONE_SIMULATOR==0
    if ([XENResources enabled] && MSHookIvar<int>(self, "_style") != 1 && baseXenController) {
        UIImage *maybeNewImage;
        // like/ban - 6
        // rewind 1
        // play/pause 3
        // forward 4
        // share 8
    
        switch (arg1) {
            case 1:
                maybeNewImage = [XENResources themedImageWithName:@"MusicRewind"];
                break;
            case 3: {
                MPUTransportControlMediaRemoteController* cont = MSHookIvar<MPUTransportControlMediaRemoteController*>(self, "_transportControlMediaRemoteController");
                BOOL playing = [cont isPlaying];
                    
                if (playing) {
                    maybeNewImage = [XENResources themedImageWithName:@"MusicPause"];
                } else {
                    maybeNewImage = [XENResources themedImageWithName:@"MusicPlay"];
                }
                break;
            } case 4:
                maybeNewImage = [XENResources themedImageWithName:@"MusicForward"];
                break;
            default:
                break;
        }
    
        if (maybeNewImage) {
            orig = maybeNewImage;
        }
    }
#endif
    
    return orig;
}

%end

// Weather icons etc - Can do later

#pragma mark Hide Lockscreen Clock (iOS 9+)

%hook SBFLockScreenDateView

-(void)layoutSubviews {
    %orig;
    
    if ([XENResources enabled] && [XENResources hideClock]) {
        self.hidden = YES;
    }
}

-(void)setHidden:(BOOL)hidden {
    ([XENResources enabled] && [XENResources hideClock] ? %orig(YES) : %orig);
}

%end

// Also hide mini charging text.
// TODO: Port to iOS 10. (TODO)

%hook SBLockScreenViewController

- (BOOL)_shouldShowChargingText {
    return ([XENResources enabled] && [XENResources hideClock] ? NO : %orig);
}

%end

#pragma mark Hide page control dots (iOS 10+)

%hook SBDashBoardView

- (void)_layoutPageControl {
    %orig;
    
    if ([XENResources enabled] && [XENResources hidePageControlDots]) {
#if TARGET_IPHONE_SIMULATOR==0
        UIView *control = MSHookIvar<UIView*>(self, "_pageControl");
        control.hidden = YES;
        control.userInteractionEnabled = NO;
#endif
    }
}

%end

#pragma mark Fix views for toggles when using iPad (<= iOS 9)

BOOL iPadOverruleIdiom = NO;

%hook UIDevice

- (int)userInterfaceIdiom {
    if (iPadOverruleIdiom) {
        return UIUserInterfaceIdiomPhone;
    } else {
        return %orig;
    }
}

%end

@interface SBCCButtonLayoutView : UIView @end

%hook SBCCButtonLayoutView

- (void)layoutSubviews {
    if ([XENResources isViewOnXen:self]) {
        iPadOverruleIdiom = YES;
    }
    
    %orig;
    
    iPadOverruleIdiom = NO;
}

-(CGFloat)interButtonPadding {
    return ([XENResources isViewOnXen:self] ? 20 : %orig);
}

%end

%hook SBCCButtonLikeSectionSplitView

- (UIEdgeInsets)_landscapeInsetsForSection {
    if ([XENResources isViewOnXen:self]) {
        iPadOverruleIdiom = YES;
    }
    
    UIEdgeInsets orig = %orig;
    
    iPadOverruleIdiom = NO;
    
    return orig;
}

- (BOOL)_useLandscapeBehavior {
    if ([XENResources isViewOnXen:self]) {
        return NO;
    }
    
    return %orig;
}

%end

%hook SBCCButtonLikeSectionView

- (BOOL)_shouldUseButtonAppearance {
    if ([self viewWithTag:1337]) {
        return YES;
    }
    return %orig;
}

%end

#pragma mark Welcome View Shizzle (iOS 9+) (Needs verification)

%hook EKBBTodayProvider

- (void)_refreshUpcomingEventBulletin {
    %orig;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"com.matchstic.xen/refreshWelcomeView" object:nil];
}

- (void)_refreshBirthdayBulletin {
    %orig;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"com.matchstic.xen/refreshWelcomeView" object:nil];
}

%end

%hook UIVisualEffectView

-(UIView*)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *view = %orig;
    if ([view isEqual:self] && self.tag == 1337) {
        view = nil;
    }
    
    return view;
}

%end

#pragma mark LockPages hooks (iOS 9.0 - 9.3) (Is this required on iOS 10?)
#import "XENLockPagesController.h"

%hook LPPageController

- (int)calculateStartIndex:(id)arg1 {
    if ([XENResources enabled]) {
        int i = (int)[[XENResources enabledControllerIdentifiers] indexOfObject:@"com.matchstic.home"];
        
        return i;
    } else {
        return %orig;
    }
}

- (long long)realPageCount {
    if ([XENResources enabled]) {
        return (long long)[XENResources enabledControllerIdentifiers].count;
    } else {
        return %orig;
    }
}

- (id)pageAtOffset:(double)arg1 {
    if ([XENResources enabled]) {
        XENBaseViewController *controller = [baseXenController controllerAtOffset:arg1];
        
        if ([[controller class] isEqual:[XENLockPagesController class]]) {
            return [(XENLockPagesController*)controller LPPage];
        } else {
            return nil;
        }
    } else {
        return %orig;
    }
}

- (id)pageAtAbsoluteIndex:(unsigned long long)arg1 {
    if ([XENResources enabled]) {
        if (arg1 >= [XENResources enabledControllerIdentifiers].count) {
            // ABORT
            return nil;
        }
        
        NSString *identifier = [[XENResources enabledControllerIdentifiers] objectAtIndex:arg1];
        
        if ([identifier hasPrefix:@"lockpages"]) {
            XENLockPagesController *controller = [XENResources controllerWithIdentifier:identifier];
            return [(XENLockPagesController*)controller LPPage];
        } else {
            return nil;
        }
    } else {
        return %orig;
    }
}

- (void)layoutLockScreenView:(id)arg1 {
    dontAllowScrollViewOffsetChange = YES;
    dontScrollForLockPages = YES;
    %orig;
    dontAllowScrollViewOffsetChange = NO;
    
    [XENResources relayourLockPagesControllers];
}

- (void)layoutPages {
    dontAllowScrollViewOffsetChange = YES;
    %orig;
    dontAllowScrollViewOffsetChange = NO;
}

- (void)addPage:(id)arg1 {
    %orig;
    
    [XENResources didSortLockPages];
    [baseXenController invalidateControllersForLockPages];
}

%new
-(id)_xen_sortedPages {
#if TARGET_IPHONE_SIMULATOR==0
    return MSHookIvar<NSMutableArray*>(self, "_sortedPages");
#else
    return [NSArray array];
#endif
}

%end

%hook LPPage

- (_Bool)supportsBackgroundAlpha {
    return [XENResources enabled] ? NO : %orig;
}

%end

%hook SBLockScreenView

-(void)lp_updateUnderlayAlpha:(CGFloat)arg1 {
    %orig([XENResources enabled] ? 0.0 : arg1);
}

-(void)lp_updateUnderlayForCurrentScroll {
    if (![XENResources enabled])
        %orig;
}

%end

#pragma mark Check that device has been unlocked since boot

%hook SBUIPasscodeLockViewBase

- (void)_noteDeviceHasBeenUnlockedOnceSinceBoot:(BOOL)arg1 {
    %orig;
    
    [XENResources setUnlockedSinceBoot:arg1];
}

%end

//#pragma mark Hooks needed to get the NC widgets page working.
// TODO: Uh, do we need this now? (iOS 9.0 - 9.3)

static BOOL xenRequestVisible = NO;

%hook SBNotificationCenterController

-(BOOL)isVisible {
    return (xenRequestVisible ? YES : %orig);
}

- (BOOL)shouldRequestWidgetRemoteViewControllers {
    return (xenRequestVisible ? YES : %orig);
}

%new
+(void)_xen_setRequestVisible:(BOOL)visible {
    xenRequestVisible = visible;
}

%end

#pragma mark Hooks needed to get the NC widgets page working. (iOS 9.0 - 9.3) (Necessary?)

%hook SBNotificationCenterLayoutViewController

%new
-(NSSet*)xen_defaultEnabledIDs {
#if TARGET_IPHONE_SIMULATOR==0
    return MSHookIvar<NSSet*>(self, "_defaultEnabledIDs");
#else
    return [NSSet set];
#endif
}

%new
-(NSMutableDictionary *)xen_identifiersToDatums {
#if TARGET_IPHONE_SIMULATOR==0
    return MSHookIvar<NSMutableDictionary*>(self, "_identifiersToDatums");
#else
    return [NSMutableDictionary dictionary];
#endif
}

%new
-(NSMutableDictionary *)xen_dataSourceIdentifiersToDatumIdentifiers {
#if TARGET_IPHONE_SIMULATOR==0
    return MSHookIvar<NSMutableDictionary*>(self, "_dataSourceIdentifiersToDatumIdentifiers");
#else
    return [NSMutableDictionary dictionary];
#endif
}

%end

#pragma mark Fix awful backgrounds on passcode (iOS 9.0 - 9.3)

%hook SBUIPasscodeLockViewBase

- (void)_setLuminosityBoost:(double)arg1 {
    %orig([XENResources enabled] ? 0.5 : arg1);
}

%new
-(void)_xen_layoutForHidingViews {
}

%end

%hook SBUIPasscodeLockViewWithKeyboard

%new
-(void)_xen_layoutForHidingViews {
#if TARGET_IPHONE_SIMULATOR==0
    if ([UIDevice currentDevice].systemVersion.floatValue < 10) {
    MSHookIvar<UIView*>(self, "_emergencyCallLeftFiller").hidden = YES;
    MSHookIvar<UIView*>(self, "_emergencyCallRightFiller").hidden = YES;
    MSHookIvar<UIView*>(self, "_emergencyCallToTopFiller").hidden = YES;
    MSHookIvar<UIView*>(self, "_entryFieldToBottomFiller").hidden = YES;
    
    MSHookIvar<UIView*>(self, "_statusFieldToTopOrEmergencyCallBottomFiller").hidden = YES;
    MSHookIvar<UIView*>(self, "_statusFieldBackground").hidden = YES;
    
    UIView *entry = MSHookIvar<UIView*>(self, "_alphaEntryField");
    
    if (entry) {
        MSHookIvar<UIView*>(entry, "_leftPaddingView").hidden = YES;
        MSHookIvar<UIView*>(entry, "_rightPaddingView").hidden = YES;
        
        MSHookIvar<UIView*>(entry, "_textField").backgroundColor = [UIColor clearColor];
    }
    
    UIView *_emergencyCallButton = MSHookIvar<UIView*>(self, "_emergencyCallButton");
    
    if (_emergencyCallButton) {
        MSHookIvar<UIView*>(_emergencyCallButton, "_ringView").hidden = YES;
    }
    }
#endif
}

%end

%hook SBUIPasscodeTextField

-(CGFloat)alpha {
    return [XENResources enabled] && [UIDevice currentDevice].systemVersion.floatValue < 10 ? 1.0 : %orig;
}

-(void)setAlpha:(CGFloat)alpha {
    %orig([XENResources enabled] && [UIDevice currentDevice].systemVersion.floatValue < 10 ? 1.0 : alpha);
}

-(UIColor*)backgroundColor {
    return [XENResources enabled] && [UIDevice currentDevice].systemVersion.floatValue < 10 ? [UIColor clearColor] : %orig;
}

-(void)setBackgroundColor:(UIColor*)color {
    %orig([XENResources enabled] && [UIDevice currentDevice].systemVersion.floatValue < 10 ? [UIColor clearColor] : color);
}

%end

#pragma mark Fix ColorBanners

@interface CBRGradientView : UIView
@end

%hook CBRGradientView

-(void)setFrame:(CGRect)frame {
    // Don't mess with our UI, biatch!
    if (baseXenController && [XENResources enabled] && [XENResources useXENNotificationUI] && self.tag != 1337) {
        return;
    }
    
    %orig;
}

%end

#pragma mark Settings handling

static void handlePeekSettingsChanged() {
    #if USE_PEEK==1
    if (![XENResources peekEnabled]) {
        // Remove assertions, and cleanup as much as possible :/
        restoreLLSleep();
        
        lastProximityState = NO;
        pauseMonitoring = YES;
        
        if (accelHandler.isUpdating)
            [accelHandler pauseMonitoring];
        
        shouldBeInPeekMode = NO;
        peekIsVisble = NO;
        
        XENlog(@"Handled Peek settings changed. Hopefully we didn't kill touchscreen handling :/");
    }
    #endif
}

static void showContentEditPanel(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    [XENResources setLoadingInAsEditMode:YES];
    [XENResources setIsLoadedEditFromSetup:NO];
    
    UIView *view = nil;
    if ([UIDevice currentDevice].systemVersion.floatValue <= 10.0) {
        view = [[objc_getClass("SBLockScreenView") alloc] initWithFrame:CGRectMake(0, 0, SCREEN_MIN_LENGTH,SCREEN_MAX_LENGTH)];
    } else {
        UIViewController *vc = [[objc_getClass("XENDashBoardArrangementController") alloc] init];
        view = vc.view;
        
        [XENResources cacheArrangementController:vc];
    }
    
    // Set the UI's orientation correctly, please.
    int orientation = (int)[UIApplication sharedApplication].statusBarOrientation;
    [XENResources setCurrentOrientation:orientation];
    
    UIWindow *contentEditWindow = [XENResources contentEditWindow];
    contentEditWindow.frame = CGRectMake(0, SCREEN_MAX_LENGTH, SCREEN_MIN_LENGTH, SCREEN_MAX_LENGTH);
    [contentEditWindow addSubview:view];
    
    [contentEditWindow makeKeyAndVisible];
    
    [XENResources moveUpDownWallpaperWindow:NO];
    UIWindow *wallpaperWindow = [XENResources wallpapeWindow];
    wallpaperWindow.frame = CGRectMake(0, SCREEN_MAX_LENGTH, SCREEN_MIN_LENGTH, SCREEN_MAX_LENGTH);
    
    [UIView animateWithDuration:0.25 animations:^{
        contentEditWindow.frame = CGRectMake(0, 0, SCREEN_MIN_LENGTH, SCREEN_MAX_LENGTH);
        wallpaperWindow.frame = CGRectMake(0, 0, SCREEN_MIN_LENGTH, SCREEN_MAX_LENGTH);
    }];
}

static void XENSettingsChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    [XENResources reloadSettings];
#if USE_PEEK==1
    handlePeekSettingsChanged();
#endif
}

%end // THIS IS THE %GROUP SPRINGBOARD END!!

#pragma mark Setup UI stuff
// Annoyingly, this must all be ungrouped for when Xen does not load.

%hook SpringBoard

%new
-(void)_xen_relayoutAfterSetupContentEditorDisplayed {
    // Handles re-laying out the controllers after setup has modified them whilst locked.
    [baseXenController handleReconfigureFromSetup];
}

%new
-(void)_xen_releaseSetupUI {
    setupWindow.hidden = YES;
    [setupWindow resignKeyWindow];
    [setupWindow resignFirstResponder];
    
    setupWindow = nil;
    
    
    SBLockScreenManager *man = [objc_getClass("SBLockScreenManager") sharedInstance];
    
    if ([man respondsToSelector:@selector(setBioUnlockingDisabled:forRequester:)]) {
        [man setBioUnlockingDisabled:NO forRequester:@"com.matchstic.xen.setup"];
    } else if ([man respondsToSelector:@selector(setBiometricAutoUnlockingDisabled:forReason:)]) {
        [man setBiometricAutoUnlockingDisabled:NO forReason:@"com.matchstic.xen.setup"];
    }
}

%new
-(void)_xen_finaliseAfterSetup {
    [baseXenController finaliseEverythingForPostSetup];
}

%end

%hook SBLockScreenViewController

-(BOOL)suppressesSiri {
    return ([XENResources enabled] && setupWindow) ? YES : %orig;
}

%end

%hook SBBacklightController

- (void)_lockScreenDimTimerFired {
    if ([XENResources enabled] && setupWindow) {
        return;
    }
    
    %orig;
}

%end

#pragma mark Constructor

%ctor {
    BOOL sb = [[[NSBundle mainBundle] bundleIdentifier] isEqualToString:@"com.apple.springboard"];
    BOOL prefs = [[[NSBundle mainBundle] bundleIdentifier] isEqualToString:@"com.apple.Preferences"];
    
    if (sb) {
        // Subclass SBLockScreenScrollView at runtime.
        Class $XENScrollView = objc_allocateClassPair(objc_getClass("SBLockScreenScrollView"), "XENScrollView", 0);
        objc_registerClassPair($XENScrollView);
    
        if ([[UIDevice currentDevice].systemVersion floatValue] < 10.0) {
            Class $XENShortcutModule = objc_allocateClassPair(objc_getClass("SBCCShortcutModule"), "XENShortcutModule", 0);
            objc_registerClassPair($XENShortcutModule);
        } else {
            // iOS 10+ now has the CC in it's own framework.
            Class $XENShortcutModule = objc_allocateClassPair(objc_getClass("CCUIShortcutModule"), "XENShortcutModule", 0);
            objc_registerClassPair($XENShortcutModule);
            
            // For LS pages
            Class $XENDashBoardPageViewController = objc_allocateClassPair(objc_getClass("SBDashBoardPageViewController"), "XENDashBoardPageViewController", 0);
            objc_registerClassPair($XENDashBoardPageViewController);
            
            // For CC
            Class $XENControlCenterViewController = objc_allocateClassPair(objc_getClass("CCUIControlCenterViewController"), "XENControlCenterViewController", 0);
            objc_registerClassPair($XENControlCenterViewController);
        }
    }

    %init;
    
    if (sb) {
        if ([[UIDevice currentDevice].systemVersion floatValue] >= 11.0 || [[UIDevice currentDevice].systemVersion floatValue] < 9.0) {
            // We don't support iOS 11 and above, or below iOS 9.
            return;
        }
        
        dlopen("/System/Library/SpringBoardPlugins/NowPlayingArtLockScreen.lockbundle/NowPlayingArtLockScreen", 2);
        
        %init(SpringBoard);
        
        CFNotificationCenterRef r = CFNotificationCenterGetDarwinNotifyCenter();
        CFNotificationCenterAddObserver(r, NULL, XENSettingsChanged, CFSTR("com.matchstic.xen/settingschanged"), NULL, 0);
#if USE_PEEK==1
        CFNotificationCenterAddObserver(r, NULL, &handleProximityFar, CFSTR("com.matchstic.xen/proxFar"), NULL, 0);
        CFNotificationCenterAddObserver(r, NULL, &handleProximityNear, CFSTR("com.matchstic.xen/proxNear"), NULL, 0);
#endif
        CFNotificationCenterAddObserver(r, NULL, showContentEditPanel, CFSTR("com.matchstic.xen/showcontentedit"), NULL, 0);
        
    } else if (!prefs && [[UIDevice currentDevice].systemVersion floatValue] <= 9.3) {
        // We don't want to be loading into backboardd when on iOS 10+, as we simply don't need to.
        #if USE_PEEK==1
        %init(backboardd);
        
#if TARGET_IPHONE_SIMULATOR==0
        MSHookFunction(IOHIDEventSystemOpen, $IOHIDEventSystemOpen, &ori_IOHIDEventSystemOpen);
#endif
        
        CFNotificationCenterRef r = CFNotificationCenterGetDarwinNotifyCenter();
        CFNotificationCenterAddObserver(r, NULL, &disableProximityMonitoring, CFSTR("com.matchstic.xen/disableProx"), NULL, 0);
        CFNotificationCenterAddObserver(r, NULL, &enableProximityMonitoring, CFSTR("com.matchstic.xen/enableProx"), NULL, 0);
        #endif
    }
}
