#line 1 "/Users/matt/iOS/Projects/Xen-Lockscreen/Tweak/XenLockscreen.xm"







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


#include <substrate.h>
#if defined(__clang__)
#if __has_feature(objc_arc)
#define _LOGOS_SELF_TYPE_NORMAL __unsafe_unretained
#define _LOGOS_SELF_TYPE_INIT __attribute__((ns_consumed))
#define _LOGOS_SELF_CONST const
#define _LOGOS_RETURN_RETAINED __attribute__((ns_returns_retained))
#else
#define _LOGOS_SELF_TYPE_NORMAL
#define _LOGOS_SELF_TYPE_INIT
#define _LOGOS_SELF_CONST
#define _LOGOS_RETURN_RETAINED
#endif
#else
#define _LOGOS_SELF_TYPE_NORMAL
#define _LOGOS_SELF_TYPE_INIT
#define _LOGOS_SELF_CONST
#define _LOGOS_RETURN_RETAINED
#endif

@class SBLockOverlayStyleProperties; @class UIVisualEffectView; @class SBLockScreenFullscreenBulletinViewController; @class SBDashBoardMesaUnlockBehaviorConfiguration; @class SBDashBoardHomeButtonShowPasscodeRecognizer; @class BKProximitySensorInterface; @class SBDashBoardPageControl; @class UICollectionView; @class XENScrollView; @class XENShortcutModule; @class EKBBTodayProvider; @class CBRGradientView; @class SBPagedScrollView; @class SBUIPasscodeLockViewWithKeyboard; @class SBDashBoardPageViewController; @class SBCCButtonLayoutView; @class CNPropertyFaceTimeAction; @class SBLockScreenNotificationTableView; @class SBBacklightController; @class SBPluginManager; @class SBDashBoardLegibilityProvider; @class SBLockScreenToAppsWorkspaceTransaction; @class SBTableViewCellActionButton; @class SBSlideToUnlockFailureRecognizer; @class UIDevice; @class LPPage; @class SBFLockScreenMetrics; @class AVFlashlight; @class SBLockScreenView; @class _UIGlintyStringView; @class SBAlertWindow; @class SBSystemLocalNotificationAlert; @class SBNotificationCenterController; @class SBLockScreenViewController; @class SBCCButtonLikeSectionSplitView; @class SBDashBoardView; @class MPUSystemMediaControlsViewController; @class _NowPlayingArtView; @class LSApplicationWorkspace; @class SBLockScreenManager; @class NCNotificationPriorityList; @class SBUIControlCenterSlider; @class SBDashBoardViewController; @class SBCCBrightnessSectionController; @class SBLockScreenNotificationCell; @class SBLockScreenNotificationListController; @class CNPropertyAction; @class SBHomeHardwareButtonActions; @class SBNotificationCenterLayoutViewController; @class SBLockScreenBatteryChargingView; @class SBDashBoardCameraPageViewController; @class SBFUserAuthenticationController; @class SBManualIdleTimer; @class NCNotificationPriorityListViewController; @class SBUICallToActionLabel; @class XENDashBoardPageViewController; @class SBCCButtonLikeSectionView; @class SBDashBoardMainPageViewController; @class SBMainWorkspace; @class SBHorizontalScrollFailureRecognizer; @class SBApplication; @class SBAlertToAppsWorkspaceTransaction; @class LPPageController; @class SBDashBoardTodayPageViewController; @class SBUIPasscodeLockViewBase; @class SBLockScreenBounceAnimator; @class CNPropertySendMessageAction; @class SBLockScreenScrollView; @class SBLockScreenBulletinCell; @class XENControlCenterViewController; @class SBDashBoardPasscodeViewController; @class CNContact; @class MPUMediaControlsVolumeView; @class SBUIControlCenterButton; @class SBWorkspaceTransaction; @class SBUIPasscodeTextField; @class CNContactGridViewController; @class SpringBoard; @class SBLockScreenNotificationListView; @class SBFLockScreenDateView; 
static void (*_logos_orig$_ungrouped$SpringBoard$applicationDidFinishLaunching$)(_LOGOS_SELF_TYPE_NORMAL SpringBoard* _LOGOS_SELF_CONST, SEL, id); static void _logos_method$_ungrouped$SpringBoard$applicationDidFinishLaunching$(_LOGOS_SELF_TYPE_NORMAL SpringBoard* _LOGOS_SELF_CONST, SEL, id); static id _logos_meta_method$_ungrouped$SpringBoard$XEN_ivarNamed$withinObject$(_LOGOS_SELF_TYPE_NORMAL Class _LOGOS_SELF_CONST, SEL, NSString*, id); static void _logos_method$_ungrouped$SpringBoard$_xen_setupMidnightTimer(_LOGOS_SELF_TYPE_NORMAL SpringBoard* _LOGOS_SELF_CONST, SEL); static void _logos_method$_ungrouped$SpringBoard$_xen_midnightTimerFired$(_LOGOS_SELF_TYPE_NORMAL SpringBoard* _LOGOS_SELF_CONST, SEL, id); static void _logos_method$_ungrouped$SpringBoard$checkIfShouldShowWelcome$(_LOGOS_SELF_TYPE_NORMAL SpringBoard* _LOGOS_SELF_CONST, SEL, id); static void _logos_method$_ungrouped$SpringBoard$_xen_relayoutAfterSetupContentEditorDisplayed(_LOGOS_SELF_TYPE_NORMAL SpringBoard* _LOGOS_SELF_CONST, SEL); static void _logos_method$_ungrouped$SpringBoard$_xen_releaseSetupUI(_LOGOS_SELF_TYPE_NORMAL SpringBoard* _LOGOS_SELF_CONST, SEL); static void _logos_method$_ungrouped$SpringBoard$_xen_finaliseAfterSetup(_LOGOS_SELF_TYPE_NORMAL SpringBoard* _LOGOS_SELF_CONST, SEL); static BOOL (*_logos_orig$_ungrouped$SBLockScreenViewController$suppressesSiri)(_LOGOS_SELF_TYPE_NORMAL SBLockScreenViewController* _LOGOS_SELF_CONST, SEL); static BOOL _logos_method$_ungrouped$SBLockScreenViewController$suppressesSiri(_LOGOS_SELF_TYPE_NORMAL SBLockScreenViewController* _LOGOS_SELF_CONST, SEL); static void (*_logos_orig$_ungrouped$SBBacklightController$_lockScreenDimTimerFired)(_LOGOS_SELF_TYPE_NORMAL SBBacklightController* _LOGOS_SELF_CONST, SEL); static void _logos_method$_ungrouped$SBBacklightController$_lockScreenDimTimerFired(_LOGOS_SELF_TYPE_NORMAL SBBacklightController* _LOGOS_SELF_CONST, SEL); 
static __inline__ __attribute__((always_inline)) __attribute__((unused)) Class _logos_static_class_lookup$BKProximitySensorInterface(void) { static Class _klass; if(!_klass) { _klass = objc_getClass("BKProximitySensorInterface"); } return _klass; }
#line 85 "/Users/matt/iOS/Projects/Xen-Lockscreen/Tweak/XenLockscreen.xm"


static void _logos_method$_ungrouped$SpringBoard$applicationDidFinishLaunching$(_LOGOS_SELF_TYPE_NORMAL SpringBoard* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, id arg1) {
    _logos_orig$_ungrouped$SpringBoard$applicationDidFinishLaunching$(self, _cmd, arg1);
    
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 11.0 || [[UIDevice currentDevice].systemVersion floatValue] < 9.0) {
        
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Xen Lockscreen"
                                                        message:@"Only iOS versions 9.0 through to 10.2 are supported by this tweak."
                                                       delegate:self
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
        
        return;
    }
    
    
    
    
    checkShowWelcome = [NSTimer scheduledTimerWithTimeInterval:120.0 target:self selector:@selector(checkIfShouldShowWelcome:) userInfo:nil repeats:YES];
    
    
    NSDateComponents *components = [[NSCalendar currentCalendar] components:(NSCalendarUnitHour | NSCalendarUnitMinute) fromDate:[NSDate date]];
    NSInteger hour = [components hour];
    
    if (hour >= [XENResources welcomeAdjustedTimeForFire] + 1) { 
        shownWelcomeToday = YES;
    } else {
        shownWelcomeToday = NO; 
    }
    
    lastTouchTime = time(NULL);
    
    [self _xen_setupMidnightTimer];
    
    [XENResources reloadSettings];
    
    if (![XENResources hasDisplayedSetupUI]) {
        if (![[NSFileManager defaultManager] fileExistsAtPath:@"/tmp/com.matchstic.xen.reboot_flag"])
            [[NSFileManager defaultManager] createFileAtPath:@"/tmp/com.matchstic.xen.reboot_flag" contents:[NSData data] attributes:nil];
        
        
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



static id _logos_meta_method$_ungrouped$SpringBoard$XEN_ivarNamed$withinObject$(_LOGOS_SELF_TYPE_NORMAL Class _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, NSString* varName, id object) {
#if TARGET_IPHONE_SIMULATOR==0
    return MSHookIvar<id>(object, [varName UTF8String]);
#else
    return nil;
#endif
}


static void _logos_method$_ungrouped$SpringBoard$_xen_setupMidnightTimer(_LOGOS_SELF_TYPE_NORMAL SpringBoard* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
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
    
    
    NSDateComponents *offsetComponents = [[NSDateComponents alloc] init];
    [offsetComponents setDay:1];
    NSDate *nextDate = [gregorian dateByAddingComponents:offsetComponents toDate:thisDate options:0];
    
    _significantChangeTimer = [NSTimer scheduledTimerWithTimeInterval:[nextDate timeIntervalSinceDate:[NSDate date]] target:self selector:@selector(_xen_midnightTimerFired:) userInfo:nil repeats:NO];
}


static void _logos_method$_ungrouped$SpringBoard$_xen_midnightTimerFired$(_LOGOS_SELF_TYPE_NORMAL SpringBoard* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, id sender) {
    shownWelcomeToday = NO;
    
    [self _xen_setupMidnightTimer];
}


static void _logos_method$_ungrouped$SpringBoard$checkIfShouldShowWelcome$(_LOGOS_SELF_TYPE_NORMAL SpringBoard* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, id sender) {
    if (![XENResources enabled] || ![XENResources useWelcomeController]) {
        return;
    }
    
    if (shownWelcomeToday) {
        return;
    }
    
    time_t currentTime = time(NULL);
    
    NSDateComponents *components = [[NSCalendar currentCalendar] components:(NSCalendarUnitHour | NSCalendarUnitMinute) fromDate:[NSDate date]];
    NSInteger hour = [components hour];
    
    
    if (difftime(currentTime, lastTouchTime) >= (60*60*2) && hour >= [XENResources welcomeAdjustedTimeForFire] && ![XENResources getScreenOnState] && baseXenController) {
        shownWelcomeToday = YES;
        [baseXenController.homeViewController showWelcomeController];
    }
}



#pragma mark Inject (<= iOS 9)

static SBLockScreenScrollView* (*_logos_orig$SpringBoard$SBLockScreenScrollView$initWithFrame$)(_LOGOS_SELF_TYPE_INIT SBLockScreenScrollView*, SEL, CGRect) _LOGOS_RETURN_RETAINED; static SBLockScreenScrollView* _logos_method$SpringBoard$SBLockScreenScrollView$initWithFrame$(_LOGOS_SELF_TYPE_INIT SBLockScreenScrollView*, SEL, CGRect) _LOGOS_RETURN_RETAINED; static void (*_logos_orig$SpringBoard$XENScrollView$setDelegate$)(_LOGOS_SELF_TYPE_NORMAL XENScrollView* _LOGOS_SELF_CONST, SEL, id); static void _logos_method$SpringBoard$XENScrollView$setDelegate$(_LOGOS_SELF_TYPE_NORMAL XENScrollView* _LOGOS_SELF_CONST, SEL, id); static void (*_logos_orig$SpringBoard$XENScrollView$addSubview$)(_LOGOS_SELF_TYPE_NORMAL XENScrollView* _LOGOS_SELF_CONST, SEL, UIView*); static void _logos_method$SpringBoard$XENScrollView$addSubview$(_LOGOS_SELF_TYPE_NORMAL XENScrollView* _LOGOS_SELF_CONST, SEL, UIView*); static BOOL (*_logos_orig$SpringBoard$XENScrollView$touchesShouldCancelInContentView$)(_LOGOS_SELF_TYPE_NORMAL XENScrollView* _LOGOS_SELF_CONST, SEL, UIView *); static BOOL _logos_method$SpringBoard$XENScrollView$touchesShouldCancelInContentView$(_LOGOS_SELF_TYPE_NORMAL XENScrollView* _LOGOS_SELF_CONST, SEL, UIView *); static void (*_logos_orig$SpringBoard$XENScrollView$setContentOffset$)(_LOGOS_SELF_TYPE_NORMAL XENScrollView* _LOGOS_SELF_CONST, SEL, CGFloat); static void _logos_method$SpringBoard$XENScrollView$setContentOffset$(_LOGOS_SELF_TYPE_NORMAL XENScrollView* _LOGOS_SELF_CONST, SEL, CGFloat); static void (*_logos_orig$SpringBoard$SBLockScreenViewController$addChildViewController$)(_LOGOS_SELF_TYPE_NORMAL SBLockScreenViewController* _LOGOS_SELF_CONST, SEL, UIViewController *); static void _logos_method$SpringBoard$SBLockScreenViewController$addChildViewController$(_LOGOS_SELF_TYPE_NORMAL SBLockScreenViewController* _LOGOS_SELF_CONST, SEL, UIViewController *); static void (*_logos_orig$SpringBoard$SBLockScreenViewController$willRotateToInterfaceOrientation$duration$)(_LOGOS_SELF_TYPE_NORMAL SBLockScreenViewController* _LOGOS_SELF_CONST, SEL, long long, double); static void _logos_method$SpringBoard$SBLockScreenViewController$willRotateToInterfaceOrientation$duration$(_LOGOS_SELF_TYPE_NORMAL SBLockScreenViewController* _LOGOS_SELF_CONST, SEL, long long, double); static void (*_logos_orig$SpringBoard$SBLockScreenViewController$didRotateFromInterfaceOrientation$)(_LOGOS_SELF_TYPE_NORMAL SBLockScreenViewController* _LOGOS_SELF_CONST, SEL, long long); static void _logos_method$SpringBoard$SBLockScreenViewController$didRotateFromInterfaceOrientation$(_LOGOS_SELF_TYPE_NORMAL SBLockScreenViewController* _LOGOS_SELF_CONST, SEL, long long); static BOOL (*_logos_orig$SpringBoard$SBLockScreenViewController$isBounceEnabledForPresentingController$locationInWindow$)(_LOGOS_SELF_TYPE_NORMAL SBLockScreenViewController* _LOGOS_SELF_CONST, SEL, id, CGPoint); static BOOL _logos_method$SpringBoard$SBLockScreenViewController$isBounceEnabledForPresentingController$locationInWindow$(_LOGOS_SELF_TYPE_NORMAL SBLockScreenViewController* _LOGOS_SELF_CONST, SEL, id, CGPoint); static void (*_logos_orig$SpringBoard$SBLockScreenViewController$_releaseLockScreenView)(_LOGOS_SELF_TYPE_NORMAL SBLockScreenViewController* _LOGOS_SELF_CONST, SEL); static void _logos_method$SpringBoard$SBLockScreenViewController$_releaseLockScreenView(_LOGOS_SELF_TYPE_NORMAL SBLockScreenViewController* _LOGOS_SELF_CONST, SEL); static void (*_logos_orig$SpringBoard$SBLockScreenViewController$passcodeLockViewCancelButtonPressed$)(_LOGOS_SELF_TYPE_NORMAL SBLockScreenViewController* _LOGOS_SELF_CONST, SEL, id); static void _logos_method$SpringBoard$SBLockScreenViewController$passcodeLockViewCancelButtonPressed$(_LOGOS_SELF_TYPE_NORMAL SBLockScreenViewController* _LOGOS_SELF_CONST, SEL, id); static void (*_logos_orig$SpringBoard$SBLockScreenViewController$_handleDisplayTurnedOff)(_LOGOS_SELF_TYPE_NORMAL SBLockScreenViewController* _LOGOS_SELF_CONST, SEL); static void _logos_method$SpringBoard$SBLockScreenViewController$_handleDisplayTurnedOff(_LOGOS_SELF_TYPE_NORMAL SBLockScreenViewController* _LOGOS_SELF_CONST, SEL); static void _logos_method$SpringBoard$SBLockScreenViewController$_xen_peekTimerDidFire$(_LOGOS_SELF_TYPE_NORMAL SBLockScreenViewController* _LOGOS_SELF_CONST, SEL, id); static void (*_logos_orig$SpringBoard$SBLockScreenViewController$_addCameraGrabberIfNecessary)(_LOGOS_SELF_TYPE_NORMAL SBLockScreenViewController* _LOGOS_SELF_CONST, SEL); static void _logos_method$SpringBoard$SBLockScreenViewController$_addCameraGrabberIfNecessary(_LOGOS_SELF_TYPE_NORMAL SBLockScreenViewController* _LOGOS_SELF_CONST, SEL); static int (*_logos_orig$SpringBoard$SBLockScreenViewController$statusBarStyle)(_LOGOS_SELF_TYPE_NORMAL SBLockScreenViewController* _LOGOS_SELF_CONST, SEL); static int _logos_method$SpringBoard$SBLockScreenViewController$statusBarStyle(_LOGOS_SELF_TYPE_NORMAL SBLockScreenViewController* _LOGOS_SELF_CONST, SEL); static id (*_logos_orig$SpringBoard$SBLockScreenViewController$_effectiveLegibilitySettings)(_LOGOS_SELF_TYPE_NORMAL SBLockScreenViewController* _LOGOS_SELF_CONST, SEL); static id _logos_method$SpringBoard$SBLockScreenViewController$_effectiveLegibilitySettings(_LOGOS_SELF_TYPE_NORMAL SBLockScreenViewController* _LOGOS_SELF_CONST, SEL); static void (*_logos_orig$SpringBoard$SBLockScreenViewController$_updateLegibility)(_LOGOS_SELF_TYPE_NORMAL SBLockScreenViewController* _LOGOS_SELF_CONST, SEL); static void _logos_method$SpringBoard$SBLockScreenViewController$_updateLegibility(_LOGOS_SELF_TYPE_NORMAL SBLockScreenViewController* _LOGOS_SELF_CONST, SEL); static void (*_logos_orig$SpringBoard$SBLockScreenViewController$wallpaperLegibilitySettingsDidChange$forVariant$)(_LOGOS_SELF_TYPE_NORMAL SBLockScreenViewController* _LOGOS_SELF_CONST, SEL, id, int); static void _logos_method$SpringBoard$SBLockScreenViewController$wallpaperLegibilitySettingsDidChange$forVariant$(_LOGOS_SELF_TYPE_NORMAL SBLockScreenViewController* _LOGOS_SELF_CONST, SEL, id, int); static SBLockScreenViewController* (*_logos_orig$SpringBoard$SBLockScreenViewController$initWithNibName$bundle$)(_LOGOS_SELF_TYPE_INIT SBLockScreenViewController*, SEL, id, id) _LOGOS_RETURN_RETAINED; static SBLockScreenViewController* _logos_method$SpringBoard$SBLockScreenViewController$initWithNibName$bundle$(_LOGOS_SELF_TYPE_INIT SBLockScreenViewController*, SEL, id, id) _LOGOS_RETURN_RETAINED; static _UILegibilitySettings* (*_logos_orig$SpringBoard$SBLockScreenViewController$_wallpaperLegibilitySettings)(_LOGOS_SELF_TYPE_NORMAL SBLockScreenViewController* _LOGOS_SELF_CONST, SEL); static _UILegibilitySettings* _logos_method$SpringBoard$SBLockScreenViewController$_wallpaperLegibilitySettings(_LOGOS_SELF_TYPE_NORMAL SBLockScreenViewController* _LOGOS_SELF_CONST, SEL); static void (*_logos_orig$SpringBoard$SBLockScreenViewController$_addDeviceInformationTextView)(_LOGOS_SELF_TYPE_NORMAL SBLockScreenViewController* _LOGOS_SELF_CONST, SEL); static void _logos_method$SpringBoard$SBLockScreenViewController$_addDeviceInformationTextView(_LOGOS_SELF_TYPE_NORMAL SBLockScreenViewController* _LOGOS_SELF_CONST, SEL); static void (*_logos_orig$SpringBoard$SBLockScreenViewController$_handleDisplayTurnedOnWhileUILocked$)(_LOGOS_SELF_TYPE_NORMAL SBLockScreenViewController* _LOGOS_SELF_CONST, SEL, id); static void _logos_method$SpringBoard$SBLockScreenViewController$_handleDisplayTurnedOnWhileUILocked$(_LOGOS_SELF_TYPE_NORMAL SBLockScreenViewController* _LOGOS_SELF_CONST, SEL, id); static void (*_logos_orig$SpringBoard$SBLockScreenViewController$_setMediaControlsVisible$)(_LOGOS_SELF_TYPE_NORMAL SBLockScreenViewController* _LOGOS_SELF_CONST, SEL, BOOL); static void _logos_method$SpringBoard$SBLockScreenViewController$_setMediaControlsVisible$(_LOGOS_SELF_TYPE_NORMAL SBLockScreenViewController* _LOGOS_SELF_CONST, SEL, BOOL); static void (*_logos_orig$SpringBoard$SBLockScreenViewController$handleMenuButtonTap)(_LOGOS_SELF_TYPE_NORMAL SBLockScreenViewController* _LOGOS_SELF_CONST, SEL); static void _logos_method$SpringBoard$SBLockScreenViewController$handleMenuButtonTap(_LOGOS_SELF_TYPE_NORMAL SBLockScreenViewController* _LOGOS_SELF_CONST, SEL); static BOOL (*_logos_orig$SpringBoard$SBLockScreenViewController$suppressesControlCenter)(_LOGOS_SELF_TYPE_NORMAL SBLockScreenViewController* _LOGOS_SELF_CONST, SEL); static BOOL _logos_method$SpringBoard$SBLockScreenViewController$suppressesControlCenter(_LOGOS_SELF_TYPE_NORMAL SBLockScreenViewController* _LOGOS_SELF_CONST, SEL); static void (*_logos_orig$SpringBoard$SBLockScreenViewController$_addMediaControls)(_LOGOS_SELF_TYPE_NORMAL SBLockScreenViewController* _LOGOS_SELF_CONST, SEL); static void _logos_method$SpringBoard$SBLockScreenViewController$_addMediaControls(_LOGOS_SELF_TYPE_NORMAL SBLockScreenViewController* _LOGOS_SELF_CONST, SEL); static BOOL (*_logos_orig$SpringBoard$SBLockScreenViewController$_shouldShowChargingText)(_LOGOS_SELF_TYPE_NORMAL SBLockScreenViewController* _LOGOS_SELF_CONST, SEL); static BOOL _logos_method$SpringBoard$SBLockScreenViewController$_shouldShowChargingText(_LOGOS_SELF_TYPE_NORMAL SBLockScreenViewController* _LOGOS_SELF_CONST, SEL); static SBDashBoardViewController* (*_logos_orig$SpringBoard$SBDashBoardViewController$initWithPageViewControllers$mainPageViewController$legibilityProvider$)(_LOGOS_SELF_TYPE_INIT SBDashBoardViewController*, SEL, NSArray*, SBDashBoardPageViewController*, id) _LOGOS_RETURN_RETAINED; static SBDashBoardViewController* _logos_method$SpringBoard$SBDashBoardViewController$initWithPageViewControllers$mainPageViewController$legibilityProvider$(_LOGOS_SELF_TYPE_INIT SBDashBoardViewController*, SEL, NSArray*, SBDashBoardPageViewController*, id) _LOGOS_RETURN_RETAINED; static void (*_logos_orig$SpringBoard$SBDashBoardViewController$_setAllowedPageViewControllers$)(_LOGOS_SELF_TYPE_NORMAL SBDashBoardViewController* _LOGOS_SELF_CONST, SEL, NSArray*); static void _logos_method$SpringBoard$SBDashBoardViewController$_setAllowedPageViewControllers$(_LOGOS_SELF_TYPE_NORMAL SBDashBoardViewController* _LOGOS_SELF_CONST, SEL, NSArray*); static void (*_logos_orig$SpringBoard$SBDashBoardViewController$loadView)(_LOGOS_SELF_TYPE_NORMAL SBDashBoardViewController* _LOGOS_SELF_CONST, SEL); static void _logos_method$SpringBoard$SBDashBoardViewController$loadView(_LOGOS_SELF_TYPE_NORMAL SBDashBoardViewController* _LOGOS_SELF_CONST, SEL); static void (*_logos_orig$SpringBoard$SBDashBoardViewController$viewWillAppear$)(_LOGOS_SELF_TYPE_NORMAL SBDashBoardViewController* _LOGOS_SELF_CONST, SEL, _Bool); static void _logos_method$SpringBoard$SBDashBoardViewController$viewWillAppear$(_LOGOS_SELF_TYPE_NORMAL SBDashBoardViewController* _LOGOS_SELF_CONST, SEL, _Bool); static id _logos_method$SpringBoard$SBDashBoardViewController$_xen_fetchWithIdentifier$andArray$(_LOGOS_SELF_TYPE_NORMAL SBDashBoardViewController* _LOGOS_SELF_CONST, SEL, NSString*, NSArray*); static _Bool (*_logos_orig$SpringBoard$SBDashBoardViewController$canUIUnlockFromSource$)(_LOGOS_SELF_TYPE_NORMAL SBDashBoardViewController* _LOGOS_SELF_CONST, SEL, int); static _Bool _logos_method$SpringBoard$SBDashBoardViewController$canUIUnlockFromSource$(_LOGOS_SELF_TYPE_NORMAL SBDashBoardViewController* _LOGOS_SELF_CONST, SEL, int); static void (*_logos_orig$SpringBoard$SBDashBoardViewController$viewWillTransitionToSize$withTransitionCoordinator$)(_LOGOS_SELF_TYPE_NORMAL SBDashBoardViewController* _LOGOS_SELF_CONST, SEL, CGSize, id<UIViewControllerTransitionCoordinator>); static void _logos_method$SpringBoard$SBDashBoardViewController$viewWillTransitionToSize$withTransitionCoordinator$(_LOGOS_SELF_TYPE_NORMAL SBDashBoardViewController* _LOGOS_SELF_CONST, SEL, CGSize, id<UIViewControllerTransitionCoordinator>); static void (*_logos_orig$SpringBoard$SBDashBoardViewController$setInScreenOffMode$forAutoUnlock$)(_LOGOS_SELF_TYPE_NORMAL SBDashBoardViewController* _LOGOS_SELF_CONST, SEL, _Bool, _Bool); static void _logos_method$SpringBoard$SBDashBoardViewController$setInScreenOffMode$forAutoUnlock$(_LOGOS_SELF_TYPE_NORMAL SBDashBoardViewController* _LOGOS_SELF_CONST, SEL, _Bool, _Bool); static long long (*_logos_orig$SpringBoard$SBDashBoardViewController$statusBarStyle)(_LOGOS_SELF_TYPE_NORMAL SBDashBoardViewController* _LOGOS_SELF_CONST, SEL); static long long _logos_method$SpringBoard$SBDashBoardViewController$statusBarStyle(_LOGOS_SELF_TYPE_NORMAL SBDashBoardViewController* _LOGOS_SELF_CONST, SEL); static void (*_logos_orig$SpringBoard$SBDashBoardViewController$_updateLegibilitySettings)(_LOGOS_SELF_TYPE_NORMAL SBDashBoardViewController* _LOGOS_SELF_CONST, SEL); static void _logos_method$SpringBoard$SBDashBoardViewController$_updateLegibilitySettings(_LOGOS_SELF_TYPE_NORMAL SBDashBoardViewController* _LOGOS_SELF_CONST, SEL); static void (*_logos_orig$SpringBoard$SBDashBoardViewController$setPasscodeLockVisible$animated$completion$)(_LOGOS_SELF_TYPE_NORMAL SBDashBoardViewController* _LOGOS_SELF_CONST, SEL, _Bool, _Bool, id); static void _logos_method$SpringBoard$SBDashBoardViewController$setPasscodeLockVisible$animated$completion$(_LOGOS_SELF_TYPE_NORMAL SBDashBoardViewController* _LOGOS_SELF_CONST, SEL, _Bool, _Bool, id); static void (*_logos_orig$SpringBoard$SBDashBoardViewController$handleBiometricEvent$)(_LOGOS_SELF_TYPE_NORMAL SBDashBoardViewController* _LOGOS_SELF_CONST, SEL, unsigned long long); static void _logos_method$SpringBoard$SBDashBoardViewController$handleBiometricEvent$(_LOGOS_SELF_TYPE_NORMAL SBDashBoardViewController* _LOGOS_SELF_CONST, SEL, unsigned long long); static _Bool (*_logos_orig$SpringBoard$SBDashBoardViewController$handleMenuButtonTap)(_LOGOS_SELF_TYPE_NORMAL SBDashBoardViewController* _LOGOS_SELF_CONST, SEL); static _Bool _logos_method$SpringBoard$SBDashBoardViewController$handleMenuButtonTap(_LOGOS_SELF_TYPE_NORMAL SBDashBoardViewController* _LOGOS_SELF_CONST, SEL); static _Bool (*_logos_orig$SpringBoard$SBDashBoardViewController$handleMenuButtonHeld)(_LOGOS_SELF_TYPE_NORMAL SBDashBoardViewController* _LOGOS_SELF_CONST, SEL); static _Bool _logos_method$SpringBoard$SBDashBoardViewController$handleMenuButtonHeld(_LOGOS_SELF_TYPE_NORMAL SBDashBoardViewController* _LOGOS_SELF_CONST, SEL); static void _logos_method$SpringBoard$SBDashBoardViewController$xen_dismissContentEditor(_LOGOS_SELF_TYPE_NORMAL SBDashBoardViewController* _LOGOS_SELF_CONST, SEL); static void (*_logos_orig$SpringBoard$SBLockScreenToAppsWorkspaceTransaction$_didComplete)(_LOGOS_SELF_TYPE_NORMAL SBLockScreenToAppsWorkspaceTransaction* _LOGOS_SELF_CONST, SEL); static void _logos_method$SpringBoard$SBLockScreenToAppsWorkspaceTransaction$_didComplete(_LOGOS_SELF_TYPE_NORMAL SBLockScreenToAppsWorkspaceTransaction* _LOGOS_SELF_CONST, SEL); static NSString* _logos_method$SpringBoard$SBDashBoardPageViewController$_xen_identifier(_LOGOS_SELF_TYPE_NORMAL SBDashBoardPageViewController* _LOGOS_SELF_CONST, SEL); static NSString* _logos_method$SpringBoard$SBDashBoardPageViewController$_xen_name(_LOGOS_SELF_TYPE_NORMAL SBDashBoardPageViewController* _LOGOS_SELF_CONST, SEL); static NSString* _logos_method$SpringBoard$SBDashBoardTodayPageViewController$_xen_identifier(_LOGOS_SELF_TYPE_NORMAL SBDashBoardTodayPageViewController* _LOGOS_SELF_CONST, SEL); static NSString* _logos_method$SpringBoard$SBDashBoardTodayPageViewController$_xen_name(_LOGOS_SELF_TYPE_NORMAL SBDashBoardTodayPageViewController* _LOGOS_SELF_CONST, SEL); static void (*_logos_orig$SpringBoard$SBDashBoardTodayPageViewController$viewDidLayoutSubviews)(_LOGOS_SELF_TYPE_NORMAL SBDashBoardTodayPageViewController* _LOGOS_SELF_CONST, SEL); static void _logos_method$SpringBoard$SBDashBoardTodayPageViewController$viewDidLayoutSubviews(_LOGOS_SELF_TYPE_NORMAL SBDashBoardTodayPageViewController* _LOGOS_SELF_CONST, SEL); static NSString* _logos_method$SpringBoard$SBDashBoardCameraPageViewController$_xen_identifier(_LOGOS_SELF_TYPE_NORMAL SBDashBoardCameraPageViewController* _LOGOS_SELF_CONST, SEL); static NSString* _logos_method$SpringBoard$SBDashBoardCameraPageViewController$_xen_name(_LOGOS_SELF_TYPE_NORMAL SBDashBoardCameraPageViewController* _LOGOS_SELF_CONST, SEL); static void (*_logos_orig$SpringBoard$SBDashBoardCameraPageViewController$viewDidLayoutSubviews)(_LOGOS_SELF_TYPE_NORMAL SBDashBoardCameraPageViewController* _LOGOS_SELF_CONST, SEL); static void _logos_method$SpringBoard$SBDashBoardCameraPageViewController$viewDidLayoutSubviews(_LOGOS_SELF_TYPE_NORMAL SBDashBoardCameraPageViewController* _LOGOS_SELF_CONST, SEL); static void (*_logos_orig$SpringBoard$SBDashBoardCameraPageViewController$aggregateAppearance$)(_LOGOS_SELF_TYPE_NORMAL SBDashBoardCameraPageViewController* _LOGOS_SELF_CONST, SEL, SBDashBoardAppearance*); static void _logos_method$SpringBoard$SBDashBoardCameraPageViewController$aggregateAppearance$(_LOGOS_SELF_TYPE_NORMAL SBDashBoardCameraPageViewController* _LOGOS_SELF_CONST, SEL, SBDashBoardAppearance*); static NSString* _logos_method$SpringBoard$SBDashBoardMainPageViewController$_xen_identifier(_LOGOS_SELF_TYPE_NORMAL SBDashBoardMainPageViewController* _LOGOS_SELF_CONST, SEL); static NSString* _logos_method$SpringBoard$SBDashBoardMainPageViewController$_xen_name(_LOGOS_SELF_TYPE_NORMAL SBDashBoardMainPageViewController* _LOGOS_SELF_CONST, SEL); static void (*_logos_orig$SpringBoard$SBDashBoardMainPageViewController$viewDidLayoutSubviews)(_LOGOS_SELF_TYPE_NORMAL SBDashBoardMainPageViewController* _LOGOS_SELF_CONST, SEL); static void _logos_method$SpringBoard$SBDashBoardMainPageViewController$viewDidLayoutSubviews(_LOGOS_SELF_TYPE_NORMAL SBDashBoardMainPageViewController* _LOGOS_SELF_CONST, SEL); static unsigned long long (*_logos_meta_orig$SpringBoard$XENDashBoardPageViewController$requiredCapabilities)(_LOGOS_SELF_TYPE_NORMAL Class _LOGOS_SELF_CONST, SEL); static unsigned long long _logos_meta_method$SpringBoard$XENDashBoardPageViewController$requiredCapabilities(_LOGOS_SELF_TYPE_NORMAL Class _LOGOS_SELF_CONST, SEL); static _Bool (*_logos_meta_orig$SpringBoard$XENDashBoardPageViewController$isAvailableForConfiguration)(_LOGOS_SELF_TYPE_NORMAL Class _LOGOS_SELF_CONST, SEL); static _Bool _logos_meta_method$SpringBoard$XENDashBoardPageViewController$isAvailableForConfiguration(_LOGOS_SELF_TYPE_NORMAL Class _LOGOS_SELF_CONST, SEL); static void (*_logos_orig$SpringBoard$XENDashBoardPageViewController$didTransitionToVisible$)(_LOGOS_SELF_TYPE_NORMAL XENDashBoardPageViewController* _LOGOS_SELF_CONST, SEL, _Bool); static void _logos_method$SpringBoard$XENDashBoardPageViewController$didTransitionToVisible$(_LOGOS_SELF_TYPE_NORMAL XENDashBoardPageViewController* _LOGOS_SELF_CONST, SEL, _Bool); static void (*_logos_orig$SpringBoard$XENDashBoardPageViewController$updateTransitionToVisible$progress$mode$)(_LOGOS_SELF_TYPE_NORMAL XENDashBoardPageViewController* _LOGOS_SELF_CONST, SEL, _Bool, double, long long); static void _logos_method$SpringBoard$XENDashBoardPageViewController$updateTransitionToVisible$progress$mode$(_LOGOS_SELF_TYPE_NORMAL XENDashBoardPageViewController* _LOGOS_SELF_CONST, SEL, _Bool, double, long long); static void (*_logos_orig$SpringBoard$XENDashBoardPageViewController$aggregateAppearance$)(_LOGOS_SELF_TYPE_NORMAL XENDashBoardPageViewController* _LOGOS_SELF_CONST, SEL, SBDashBoardAppearance*); static void _logos_method$SpringBoard$XENDashBoardPageViewController$aggregateAppearance$(_LOGOS_SELF_TYPE_NORMAL XENDashBoardPageViewController* _LOGOS_SELF_CONST, SEL, SBDashBoardAppearance*); static void (*_logos_orig$SpringBoard$XENDashBoardPageViewController$aggregateBehavior$)(_LOGOS_SELF_TYPE_NORMAL XENDashBoardPageViewController* _LOGOS_SELF_CONST, SEL, SBDashBoardBehavior*); static void _logos_method$SpringBoard$XENDashBoardPageViewController$aggregateBehavior$(_LOGOS_SELF_TYPE_NORMAL XENDashBoardPageViewController* _LOGOS_SELF_CONST, SEL, SBDashBoardBehavior*); static void _logos_method$SpringBoard$XENDashBoardPageViewController$_xen_addViewIfNeeded(_LOGOS_SELF_TYPE_NORMAL XENDashBoardPageViewController* _LOGOS_SELF_CONST, SEL); static void (*_logos_orig$SpringBoard$XENDashBoardPageViewController$loadView)(_LOGOS_SELF_TYPE_NORMAL XENDashBoardPageViewController* _LOGOS_SELF_CONST, SEL); static void _logos_method$SpringBoard$XENDashBoardPageViewController$loadView(_LOGOS_SELF_TYPE_NORMAL XENDashBoardPageViewController* _LOGOS_SELF_CONST, SEL); static void (*_logos_orig$SpringBoard$XENDashBoardPageViewController$viewDidAppear$)(_LOGOS_SELF_TYPE_NORMAL XENDashBoardPageViewController* _LOGOS_SELF_CONST, SEL, BOOL); static void _logos_method$SpringBoard$XENDashBoardPageViewController$viewDidAppear$(_LOGOS_SELF_TYPE_NORMAL XENDashBoardPageViewController* _LOGOS_SELF_CONST, SEL, BOOL); static void (*_logos_orig$SpringBoard$XENDashBoardPageViewController$viewDidLoad)(_LOGOS_SELF_TYPE_NORMAL XENDashBoardPageViewController* _LOGOS_SELF_CONST, SEL); static void _logos_method$SpringBoard$XENDashBoardPageViewController$viewDidLoad(_LOGOS_SELF_TYPE_NORMAL XENDashBoardPageViewController* _LOGOS_SELF_CONST, SEL); static void (*_logos_orig$SpringBoard$XENDashBoardPageViewController$viewWillAppear$)(_LOGOS_SELF_TYPE_NORMAL XENDashBoardPageViewController* _LOGOS_SELF_CONST, SEL, BOOL); static void _logos_method$SpringBoard$XENDashBoardPageViewController$viewWillAppear$(_LOGOS_SELF_TYPE_NORMAL XENDashBoardPageViewController* _LOGOS_SELF_CONST, SEL, BOOL); static void (*_logos_orig$SpringBoard$XENDashBoardPageViewController$viewDidDisappear$)(_LOGOS_SELF_TYPE_NORMAL XENDashBoardPageViewController* _LOGOS_SELF_CONST, SEL, BOOL); static void _logos_method$SpringBoard$XENDashBoardPageViewController$viewDidDisappear$(_LOGOS_SELF_TYPE_NORMAL XENDashBoardPageViewController* _LOGOS_SELF_CONST, SEL, BOOL); static void (*_logos_orig$SpringBoard$XENDashBoardPageViewController$viewDidLayoutSubviews)(_LOGOS_SELF_TYPE_NORMAL XENDashBoardPageViewController* _LOGOS_SELF_CONST, SEL); static void _logos_method$SpringBoard$XENDashBoardPageViewController$viewDidLayoutSubviews(_LOGOS_SELF_TYPE_NORMAL XENDashBoardPageViewController* _LOGOS_SELF_CONST, SEL); static long long (*_logos_orig$SpringBoard$XENDashBoardPageViewController$backgroundStyle)(_LOGOS_SELF_TYPE_NORMAL XENDashBoardPageViewController* _LOGOS_SELF_CONST, SEL); static long long _logos_method$SpringBoard$XENDashBoardPageViewController$backgroundStyle(_LOGOS_SELF_TYPE_NORMAL XENDashBoardPageViewController* _LOGOS_SELF_CONST, SEL); static NSString* _logos_method$SpringBoard$XENDashBoardPageViewController$_xen_identifier(_LOGOS_SELF_TYPE_NORMAL XENDashBoardPageViewController* _LOGOS_SELF_CONST, SEL); static NSString* _logos_method$SpringBoard$XENDashBoardPageViewController$_xen_name(_LOGOS_SELF_TYPE_NORMAL XENDashBoardPageViewController* _LOGOS_SELF_CONST, SEL); static UIView * (*_logos_orig$SpringBoard$SBFLockScreenDateView$hitTest$withEvent$)(_LOGOS_SELF_TYPE_NORMAL SBFLockScreenDateView* _LOGOS_SELF_CONST, SEL, CGPoint, UIEvent *); static UIView * _logos_method$SpringBoard$SBFLockScreenDateView$hitTest$withEvent$(_LOGOS_SELF_TYPE_NORMAL SBFLockScreenDateView* _LOGOS_SELF_CONST, SEL, CGPoint, UIEvent *); static void (*_logos_orig$SpringBoard$SBFLockScreenDateView$setFrame$)(_LOGOS_SELF_TYPE_NORMAL SBFLockScreenDateView* _LOGOS_SELF_CONST, SEL, CGRect); static void _logos_method$SpringBoard$SBFLockScreenDateView$setFrame$(_LOGOS_SELF_TYPE_NORMAL SBFLockScreenDateView* _LOGOS_SELF_CONST, SEL, CGRect); static void (*_logos_orig$SpringBoard$SBFLockScreenDateView$layoutSubviews)(_LOGOS_SELF_TYPE_NORMAL SBFLockScreenDateView* _LOGOS_SELF_CONST, SEL); static void _logos_method$SpringBoard$SBFLockScreenDateView$layoutSubviews(_LOGOS_SELF_TYPE_NORMAL SBFLockScreenDateView* _LOGOS_SELF_CONST, SEL); static void (*_logos_orig$SpringBoard$SBFLockScreenDateView$setHidden$)(_LOGOS_SELF_TYPE_NORMAL SBFLockScreenDateView* _LOGOS_SELF_CONST, SEL, BOOL); static void _logos_method$SpringBoard$SBFLockScreenDateView$setHidden$(_LOGOS_SELF_TYPE_NORMAL SBFLockScreenDateView* _LOGOS_SELF_CONST, SEL, BOOL); static void (*_logos_orig$SpringBoard$SBHomeHardwareButtonActions$performSinglePressUpActions)(_LOGOS_SELF_TYPE_NORMAL SBHomeHardwareButtonActions* _LOGOS_SELF_CONST, SEL); static void _logos_method$SpringBoard$SBHomeHardwareButtonActions$performSinglePressUpActions(_LOGOS_SELF_TYPE_NORMAL SBHomeHardwareButtonActions* _LOGOS_SELF_CONST, SEL); static unsigned long long (*_logos_orig$SpringBoard$SBDashBoardHomeButtonShowPasscodeRecognizer$_state)(_LOGOS_SELF_TYPE_NORMAL SBDashBoardHomeButtonShowPasscodeRecognizer* _LOGOS_SELF_CONST, SEL); static unsigned long long _logos_method$SpringBoard$SBDashBoardHomeButtonShowPasscodeRecognizer$_state(_LOGOS_SELF_TYPE_NORMAL SBDashBoardHomeButtonShowPasscodeRecognizer* _LOGOS_SELF_CONST, SEL); static _Bool (*_logos_orig$SpringBoard$SBHorizontalScrollFailureRecognizer$_isOutOfBounds$forAngle$)(_LOGOS_SELF_TYPE_NORMAL SBHorizontalScrollFailureRecognizer* _LOGOS_SELF_CONST, SEL, struct CGPoint, double); static _Bool _logos_method$SpringBoard$SBHorizontalScrollFailureRecognizer$_isOutOfBounds$forAngle$(_LOGOS_SELF_TYPE_NORMAL SBHorizontalScrollFailureRecognizer* _LOGOS_SELF_CONST, SEL, struct CGPoint, double); static BOOL (*_logos_orig$SpringBoard$SBPagedScrollView$touchesShouldCancelInContentView$)(_LOGOS_SELF_TYPE_NORMAL SBPagedScrollView* _LOGOS_SELF_CONST, SEL, UIView *); static BOOL _logos_method$SpringBoard$SBPagedScrollView$touchesShouldCancelInContentView$(_LOGOS_SELF_TYPE_NORMAL SBPagedScrollView* _LOGOS_SELF_CONST, SEL, UIView *); static void (*_logos_orig$SpringBoard$SBLockScreenManager$lockUIFromSource$withOptions$)(_LOGOS_SELF_TYPE_NORMAL SBLockScreenManager* _LOGOS_SELF_CONST, SEL, int, id); static void _logos_method$SpringBoard$SBLockScreenManager$lockUIFromSource$withOptions$(_LOGOS_SELF_TYPE_NORMAL SBLockScreenManager* _LOGOS_SELF_CONST, SEL, int, id); static void (*_logos_orig$SpringBoard$SBLockScreenManager$_finishUIUnlockFromSource$withOptions$)(_LOGOS_SELF_TYPE_NORMAL SBLockScreenManager* _LOGOS_SELF_CONST, SEL, int, id); static void _logos_method$SpringBoard$SBLockScreenManager$_finishUIUnlockFromSource$withOptions$(_LOGOS_SELF_TYPE_NORMAL SBLockScreenManager* _LOGOS_SELF_CONST, SEL, int, id); static void (*_logos_orig$SpringBoard$SBLockScreenManager$biometricEventMonitor$handleBiometricEvent$)(_LOGOS_SELF_TYPE_NORMAL SBLockScreenManager* _LOGOS_SELF_CONST, SEL, id, unsigned); static void _logos_method$SpringBoard$SBLockScreenManager$biometricEventMonitor$handleBiometricEvent$(_LOGOS_SELF_TYPE_NORMAL SBLockScreenManager* _LOGOS_SELF_CONST, SEL, id, unsigned); static void (*_logos_orig$SpringBoard$SBLockScreenView$layoutSubviews)(_LOGOS_SELF_TYPE_NORMAL SBLockScreenView* _LOGOS_SELF_CONST, SEL); static void _logos_method$SpringBoard$SBLockScreenView$layoutSubviews(_LOGOS_SELF_TYPE_NORMAL SBLockScreenView* _LOGOS_SELF_CONST, SEL); static void (*_logos_orig$SpringBoard$SBLockScreenView$_layoutNotificationView)(_LOGOS_SELF_TYPE_NORMAL SBLockScreenView* _LOGOS_SELF_CONST, SEL); static void _logos_method$SpringBoard$SBLockScreenView$_layoutNotificationView(_LOGOS_SELF_TYPE_NORMAL SBLockScreenView* _LOGOS_SELF_CONST, SEL); static void (*_logos_orig$SpringBoard$SBLockScreenView$resetContentOffsetToCurrentPage)(_LOGOS_SELF_TYPE_NORMAL SBLockScreenView* _LOGOS_SELF_CONST, SEL); static void _logos_method$SpringBoard$SBLockScreenView$resetContentOffsetToCurrentPage(_LOGOS_SELF_TYPE_NORMAL SBLockScreenView* _LOGOS_SELF_CONST, SEL); static void (*_logos_orig$SpringBoard$SBLockScreenView$_adjustTopAndBottomGrabbersForPercentScrolled$)(_LOGOS_SELF_TYPE_NORMAL SBLockScreenView* _LOGOS_SELF_CONST, SEL, CGFloat); static void _logos_method$SpringBoard$SBLockScreenView$_adjustTopAndBottomGrabbersForPercentScrolled$(_LOGOS_SELF_TYPE_NORMAL SBLockScreenView* _LOGOS_SELF_CONST, SEL, CGFloat); static void (*_logos_orig$SpringBoard$SBLockScreenView$scrollViewDidEndDecelerating$)(_LOGOS_SELF_TYPE_NORMAL SBLockScreenView* _LOGOS_SELF_CONST, SEL, id); static void _logos_method$SpringBoard$SBLockScreenView$scrollViewDidEndDecelerating$(_LOGOS_SELF_TYPE_NORMAL SBLockScreenView* _LOGOS_SELF_CONST, SEL, id); static void (*_logos_orig$SpringBoard$SBLockScreenView$scrollViewDidEndDragging$willDecelerate$)(_LOGOS_SELF_TYPE_NORMAL SBLockScreenView* _LOGOS_SELF_CONST, SEL, id, BOOL); static void _logos_method$SpringBoard$SBLockScreenView$scrollViewDidEndDragging$willDecelerate$(_LOGOS_SELF_TYPE_NORMAL SBLockScreenView* _LOGOS_SELF_CONST, SEL, id, BOOL); static void (*_logos_orig$SpringBoard$SBLockScreenView$scrollViewDidEndScrollingAnimation$)(_LOGOS_SELF_TYPE_NORMAL SBLockScreenView* _LOGOS_SELF_CONST, SEL, id); static void _logos_method$SpringBoard$SBLockScreenView$scrollViewDidEndScrollingAnimation$(_LOGOS_SELF_TYPE_NORMAL SBLockScreenView* _LOGOS_SELF_CONST, SEL, id); static void (*_logos_orig$SpringBoard$SBLockScreenView$scrollViewDidScroll$)(_LOGOS_SELF_TYPE_NORMAL SBLockScreenView* _LOGOS_SELF_CONST, SEL, id); static void _logos_method$SpringBoard$SBLockScreenView$scrollViewDidScroll$(_LOGOS_SELF_TYPE_NORMAL SBLockScreenView* _LOGOS_SELF_CONST, SEL, id); static void (*_logos_orig$SpringBoard$SBLockScreenView$scrollViewWillBeginDragging$)(_LOGOS_SELF_TYPE_NORMAL SBLockScreenView* _LOGOS_SELF_CONST, SEL, id); static void _logos_method$SpringBoard$SBLockScreenView$scrollViewWillBeginDragging$(_LOGOS_SELF_TYPE_NORMAL SBLockScreenView* _LOGOS_SELF_CONST, SEL, id); static void (*_logos_orig$SpringBoard$SBLockScreenView$scrollViewWillEndDragging$withVelocity$targetContentOffset$)(_LOGOS_SELF_TYPE_NORMAL SBLockScreenView* _LOGOS_SELF_CONST, SEL, id, CGPoint, CGPoint *); static void _logos_method$SpringBoard$SBLockScreenView$scrollViewWillEndDragging$withVelocity$targetContentOffset$(_LOGOS_SELF_TYPE_NORMAL SBLockScreenView* _LOGOS_SELF_CONST, SEL, id, CGPoint, CGPoint *); static void (*_logos_orig$SpringBoard$SBLockScreenView$_slideToUnlockFailureGestureRecognizerChanged)(_LOGOS_SELF_TYPE_NORMAL SBLockScreenView* _LOGOS_SELF_CONST, SEL); static void _logos_method$SpringBoard$SBLockScreenView$_slideToUnlockFailureGestureRecognizerChanged(_LOGOS_SELF_TYPE_NORMAL SBLockScreenView* _LOGOS_SELF_CONST, SEL); static void (*_logos_orig$SpringBoard$SBLockScreenView$_layoutSlideToUnlockView)(_LOGOS_SELF_TYPE_NORMAL SBLockScreenView* _LOGOS_SELF_CONST, SEL); static void _logos_method$SpringBoard$SBLockScreenView$_layoutSlideToUnlockView(_LOGOS_SELF_TYPE_NORMAL SBLockScreenView* _LOGOS_SELF_CONST, SEL); static void (*_logos_orig$SpringBoard$SBLockScreenView$_setCurrentBlurRadius$)(_LOGOS_SELF_TYPE_NORMAL SBLockScreenView* _LOGOS_SELF_CONST, SEL, CGFloat); static void _logos_method$SpringBoard$SBLockScreenView$_setCurrentBlurRadius$(_LOGOS_SELF_TYPE_NORMAL SBLockScreenView* _LOGOS_SELF_CONST, SEL, CGFloat); static void (*_logos_orig$SpringBoard$SBLockScreenView$setPluginView$presentationStyle$notificationBehavior$)(_LOGOS_SELF_TYPE_NORMAL SBLockScreenView* _LOGOS_SELF_CONST, SEL, UIView*, unsigned int, unsigned int); static void _logos_method$SpringBoard$SBLockScreenView$setPluginView$presentationStyle$notificationBehavior$(_LOGOS_SELF_TYPE_NORMAL SBLockScreenView* _LOGOS_SELF_CONST, SEL, UIView*, unsigned int, unsigned int); static void (*_logos_orig$SpringBoard$SBLockScreenView$scrollToPage$animated$completion$)(_LOGOS_SELF_TYPE_NORMAL SBLockScreenView* _LOGOS_SELF_CONST, SEL, int, BOOL, id); static void _logos_method$SpringBoard$SBLockScreenView$scrollToPage$animated$completion$(_LOGOS_SELF_TYPE_NORMAL SBLockScreenView* _LOGOS_SELF_CONST, SEL, int, BOOL, id); static void (*_logos_orig$SpringBoard$SBLockScreenView$_layoutGrabberView$atTop$percentScrolled$)(_LOGOS_SELF_TYPE_NORMAL SBLockScreenView* _LOGOS_SELF_CONST, SEL, id, BOOL, CGFloat); static void _logos_method$SpringBoard$SBLockScreenView$_layoutGrabberView$atTop$percentScrolled$(_LOGOS_SELF_TYPE_NORMAL SBLockScreenView* _LOGOS_SELF_CONST, SEL, id, BOOL, CGFloat); static void (*_logos_orig$SpringBoard$SBLockScreenView$_showFakeWallpaperBlurWithAlpha$withFactory$)(_LOGOS_SELF_TYPE_NORMAL SBLockScreenView* _LOGOS_SELF_CONST, SEL, CGFloat, id); static void _logos_method$SpringBoard$SBLockScreenView$_showFakeWallpaperBlurWithAlpha$withFactory$(_LOGOS_SELF_TYPE_NORMAL SBLockScreenView* _LOGOS_SELF_CONST, SEL, CGFloat, id); static void (*_logos_orig$SpringBoard$SBLockScreenView$_layoutGrabberView$atTop$)(_LOGOS_SELF_TYPE_NORMAL SBLockScreenView* _LOGOS_SELF_CONST, SEL, UIView*, BOOL); static void _logos_method$SpringBoard$SBLockScreenView$_layoutGrabberView$atTop$(_LOGOS_SELF_TYPE_NORMAL SBLockScreenView* _LOGOS_SELF_CONST, SEL, UIView*, BOOL); static void _logos_method$SpringBoard$SBLockScreenView$_xen_relayoutDateView(_LOGOS_SELF_TYPE_NORMAL SBLockScreenView* _LOGOS_SELF_CONST, SEL); static void (*_logos_orig$SpringBoard$SBLockScreenView$lp_updateUnderlayAlpha$)(_LOGOS_SELF_TYPE_NORMAL SBLockScreenView* _LOGOS_SELF_CONST, SEL, CGFloat); static void _logos_method$SpringBoard$SBLockScreenView$lp_updateUnderlayAlpha$(_LOGOS_SELF_TYPE_NORMAL SBLockScreenView* _LOGOS_SELF_CONST, SEL, CGFloat); static void (*_logos_orig$SpringBoard$SBLockScreenView$lp_updateUnderlayForCurrentScroll)(_LOGOS_SELF_TYPE_NORMAL SBLockScreenView* _LOGOS_SELF_CONST, SEL); static void _logos_method$SpringBoard$SBLockScreenView$lp_updateUnderlayForCurrentScroll(_LOGOS_SELF_TYPE_NORMAL SBLockScreenView* _LOGOS_SELF_CONST, SEL); static UIEdgeInsets (*_logos_meta_orig$SpringBoard$SBFLockScreenMetrics$notificationListInsets)(_LOGOS_SELF_TYPE_NORMAL Class _LOGOS_SELF_CONST, SEL); static UIEdgeInsets _logos_meta_method$SpringBoard$SBFLockScreenMetrics$notificationListInsets(_LOGOS_SELF_TYPE_NORMAL Class _LOGOS_SELF_CONST, SEL); static void (*_logos_orig$SpringBoard$SBDashBoardPageControl$_setIndicatorImage$toEnabled$index$)(_LOGOS_SELF_TYPE_NORMAL SBDashBoardPageControl* _LOGOS_SELF_CONST, SEL, _UILegibilityView*, _Bool, long long); static void _logos_method$SpringBoard$SBDashBoardPageControl$_setIndicatorImage$toEnabled$index$(_LOGOS_SELF_TYPE_NORMAL SBDashBoardPageControl* _LOGOS_SELF_CONST, SEL, _UILegibilityView*, _Bool, long long); static id _logos_method$SpringBoard$SBDashBoardPageControl$_xen_unlockIndicatorImage$(_LOGOS_SELF_TYPE_NORMAL SBDashBoardPageControl* _LOGOS_SELF_CONST, SEL, BOOL); static BOOL (*_logos_orig$SpringBoard$SBSlideToUnlockFailureRecognizer$_isOutOfBoundsVertically$)(_LOGOS_SELF_TYPE_NORMAL SBSlideToUnlockFailureRecognizer* _LOGOS_SELF_CONST, SEL, CGPoint); static BOOL _logos_method$SpringBoard$SBSlideToUnlockFailureRecognizer$_isOutOfBoundsVertically$(_LOGOS_SELF_TYPE_NORMAL SBSlideToUnlockFailureRecognizer* _LOGOS_SELF_CONST, SEL, CGPoint); static void (*_logos_orig$SpringBoard$SBLockScreenBounceAnimator$_handleTapGesture$)(_LOGOS_SELF_TYPE_NORMAL SBLockScreenBounceAnimator* _LOGOS_SELF_CONST, SEL, id); static void _logos_method$SpringBoard$SBLockScreenBounceAnimator$_handleTapGesture$(_LOGOS_SELF_TYPE_NORMAL SBLockScreenBounceAnimator* _LOGOS_SELF_CONST, SEL, id); static void (*_logos_orig$SpringBoard$SBDashBoardPasscodeViewController$passcodeLockViewCancelButtonPressed$)(_LOGOS_SELF_TYPE_NORMAL SBDashBoardPasscodeViewController* _LOGOS_SELF_CONST, SEL, id); static void _logos_method$SpringBoard$SBDashBoardPasscodeViewController$passcodeLockViewCancelButtonPressed$(_LOGOS_SELF_TYPE_NORMAL SBDashBoardPasscodeViewController* _LOGOS_SELF_CONST, SEL, id); static SBUIPasscodeLockViewBase* _logos_method$SpringBoard$SBDashBoardPasscodeViewController$_xen_passcodeLockView(_LOGOS_SELF_TYPE_NORMAL SBDashBoardPasscodeViewController* _LOGOS_SELF_CONST, SEL); static UIView* _logos_method$SpringBoard$SBDashBoardPasscodeViewController$_xen_backgroundView(_LOGOS_SELF_TYPE_NORMAL SBDashBoardPasscodeViewController* _LOGOS_SELF_CONST, SEL); static void (*_logos_orig$SpringBoard$SBUICallToActionLabel$setText$forLanguage$animated$)(_LOGOS_SELF_TYPE_NORMAL SBUICallToActionLabel* _LOGOS_SELF_CONST, SEL, id, id, BOOL); static void _logos_method$SpringBoard$SBUICallToActionLabel$setText$forLanguage$animated$(_LOGOS_SELF_TYPE_NORMAL SBUICallToActionLabel* _LOGOS_SELF_CONST, SEL, id, id, BOOL); static double (*_logos_orig$SpringBoard$_UIGlintyStringView$_chevronWidthWithPadding)(_LOGOS_SELF_TYPE_NORMAL _UIGlintyStringView* _LOGOS_SELF_CONST, SEL); static double _logos_method$SpringBoard$_UIGlintyStringView$_chevronWidthWithPadding(_LOGOS_SELF_TYPE_NORMAL _UIGlintyStringView* _LOGOS_SELF_CONST, SEL); static int (*_logos_orig$SpringBoard$_UIGlintyStringView$chevronStyle)(_LOGOS_SELF_TYPE_NORMAL _UIGlintyStringView* _LOGOS_SELF_CONST, SEL); static int _logos_method$SpringBoard$_UIGlintyStringView$chevronStyle(_LOGOS_SELF_TYPE_NORMAL _UIGlintyStringView* _LOGOS_SELF_CONST, SEL); static void (*_logos_orig$SpringBoard$_UIGlintyStringView$setChevronStyle$)(_LOGOS_SELF_TYPE_NORMAL _UIGlintyStringView* _LOGOS_SELF_CONST, SEL, int); static void _logos_method$SpringBoard$_UIGlintyStringView$setChevronStyle$(_LOGOS_SELF_TYPE_NORMAL _UIGlintyStringView* _LOGOS_SELF_CONST, SEL, int); static double (*_logos_orig$SpringBoard$_UIGlintyStringView$_chevronPadding)(_LOGOS_SELF_TYPE_NORMAL _UIGlintyStringView* _LOGOS_SELF_CONST, SEL); static double _logos_method$SpringBoard$_UIGlintyStringView$_chevronPadding(_LOGOS_SELF_TYPE_NORMAL _UIGlintyStringView* _LOGOS_SELF_CONST, SEL); static id (*_logos_orig$SpringBoard$_UIGlintyStringView$_chevronImageForStyle$)(_LOGOS_SELF_TYPE_NORMAL _UIGlintyStringView* _LOGOS_SELF_CONST, SEL, long long); static id _logos_method$SpringBoard$_UIGlintyStringView$_chevronImageForStyle$(_LOGOS_SELF_TYPE_NORMAL _UIGlintyStringView* _LOGOS_SELF_CONST, SEL, long long); static CGRect (*_logos_orig$SpringBoard$_UIGlintyStringView$chevronFrame)(_LOGOS_SELF_TYPE_NORMAL _UIGlintyStringView* _LOGOS_SELF_CONST, SEL); static CGRect _logos_method$SpringBoard$_UIGlintyStringView$chevronFrame(_LOGOS_SELF_TYPE_NORMAL _UIGlintyStringView* _LOGOS_SELF_CONST, SEL); static CGFloat (*_logos_orig$SpringBoard$SBLockOverlayStyleProperties$tintAlpha)(_LOGOS_SELF_TYPE_NORMAL SBLockOverlayStyleProperties* _LOGOS_SELF_CONST, SEL); static CGFloat _logos_method$SpringBoard$SBLockOverlayStyleProperties$tintAlpha(_LOGOS_SELF_TYPE_NORMAL SBLockOverlayStyleProperties* _LOGOS_SELF_CONST, SEL); static void (*_logos_orig$SpringBoard$SBDashBoardLegibilityProvider$wallpaperLegibilitySettingsDidChange$forVariant$)(_LOGOS_SELF_TYPE_NORMAL SBDashBoardLegibilityProvider* _LOGOS_SELF_CONST, SEL, id, long long); static void _logos_method$SpringBoard$SBDashBoardLegibilityProvider$wallpaperLegibilitySettingsDidChange$forVariant$(_LOGOS_SELF_TYPE_NORMAL SBDashBoardLegibilityProvider* _LOGOS_SELF_CONST, SEL, id, long long); static id (*_logos_orig$SpringBoard$SBDashBoardLegibilityProvider$currentLegibilitySettings)(_LOGOS_SELF_TYPE_NORMAL SBDashBoardLegibilityProvider* _LOGOS_SELF_CONST, SEL); static id _logos_method$SpringBoard$SBDashBoardLegibilityProvider$currentLegibilitySettings(_LOGOS_SELF_TYPE_NORMAL SBDashBoardLegibilityProvider* _LOGOS_SELF_CONST, SEL); static id (*_logos_orig$SpringBoard$SBDashBoardLegibilityProvider$_wallpaperLegibilitySettings)(_LOGOS_SELF_TYPE_NORMAL SBDashBoardLegibilityProvider* _LOGOS_SELF_CONST, SEL); static id _logos_method$SpringBoard$SBDashBoardLegibilityProvider$_wallpaperLegibilitySettings(_LOGOS_SELF_TYPE_NORMAL SBDashBoardLegibilityProvider* _LOGOS_SELF_CONST, SEL); static SBLockScreenNotificationCell* (*_logos_orig$SpringBoard$SBLockScreenNotificationCell$initWithStyle$reuseIdentifier$)(_LOGOS_SELF_TYPE_INIT SBLockScreenNotificationCell*, SEL, int, id) _LOGOS_RETURN_RETAINED; static SBLockScreenNotificationCell* _logos_method$SpringBoard$SBLockScreenNotificationCell$initWithStyle$reuseIdentifier$(_LOGOS_SELF_TYPE_INIT SBLockScreenNotificationCell*, SEL, int, id) _LOGOS_RETURN_RETAINED; static void _logos_method$SpringBoard$SBLockScreenNotificationCell$_xen_addBlurIfNecessary(_LOGOS_SELF_TYPE_NORMAL SBLockScreenNotificationCell* _LOGOS_SELF_CONST, SEL); static void (*_logos_orig$SpringBoard$SBLockScreenNotificationCell$setContentAlpha$)(_LOGOS_SELF_TYPE_NORMAL SBLockScreenNotificationCell* _LOGOS_SELF_CONST, SEL, CGFloat); static void _logos_method$SpringBoard$SBLockScreenNotificationCell$setContentAlpha$(_LOGOS_SELF_TYPE_NORMAL SBLockScreenNotificationCell* _LOGOS_SELF_CONST, SEL, CGFloat); static void (*_logos_orig$SpringBoard$SBLockScreenNotificationCell$setAlpha$)(_LOGOS_SELF_TYPE_NORMAL SBLockScreenNotificationCell* _LOGOS_SELF_CONST, SEL, CGFloat); static void _logos_method$SpringBoard$SBLockScreenNotificationCell$setAlpha$(_LOGOS_SELF_TYPE_NORMAL SBLockScreenNotificationCell* _LOGOS_SELF_CONST, SEL, CGFloat); static void (*_logos_orig$SpringBoard$SBLockScreenNotificationCell$layoutSubviews)(_LOGOS_SELF_TYPE_NORMAL SBLockScreenNotificationCell* _LOGOS_SELF_CONST, SEL); static void _logos_method$SpringBoard$SBLockScreenNotificationCell$layoutSubviews(_LOGOS_SELF_TYPE_NORMAL SBLockScreenNotificationCell* _LOGOS_SELF_CONST, SEL); static id (*_logos_orig$SpringBoard$SBLockScreenNotificationCell$_vibrantTextColor)(_LOGOS_SELF_TYPE_NORMAL SBLockScreenNotificationCell* _LOGOS_SELF_CONST, SEL); static id _logos_method$SpringBoard$SBLockScreenNotificationCell$_vibrantTextColor(_LOGOS_SELF_TYPE_NORMAL SBLockScreenNotificationCell* _LOGOS_SELF_CONST, SEL); static UILabel* _logos_method$SpringBoard$SBLockScreenNotificationCell$XENUnlockTextLabel(_LOGOS_SELF_TYPE_NORMAL SBLockScreenNotificationCell* _LOGOS_SELF_CONST, SEL); static void _logos_method$SpringBoard$SBLockScreenNotificationCell$fireOffTappedEventToDelegate$(_LOGOS_SELF_TYPE_NORMAL SBLockScreenNotificationCell* _LOGOS_SELF_CONST, SEL, UITapGestureRecognizer*); static void _logos_method$SpringBoard$SBLockScreenNotificationCell$handleLongPressGesture$(_LOGOS_SELF_TYPE_NORMAL SBLockScreenNotificationCell* _LOGOS_SELF_CONST, SEL, UIGestureRecognizer*); static BOOL _logos_method$SpringBoard$SBLockScreenNotificationCell$gestureRecognizer$shouldRecognizeSimultaneouslyWithGestureRecognizer$(_LOGOS_SELF_TYPE_NORMAL SBLockScreenNotificationCell* _LOGOS_SELF_CONST, SEL, UIGestureRecognizer *, UIGestureRecognizer *); static BOOL _logos_method$SpringBoard$SBLockScreenNotificationCell$gestureRecognizerShouldBegin$(_LOGOS_SELF_TYPE_NORMAL SBLockScreenNotificationCell* _LOGOS_SELF_CONST, SEL, UIGestureRecognizer *); static BOOL _logos_method$SpringBoard$SBLockScreenNotificationCell$gestureRecognizer$shouldReceiveTouch$(_LOGOS_SELF_TYPE_NORMAL SBLockScreenNotificationCell* _LOGOS_SELF_CONST, SEL, UIGestureRecognizer *, UITouch *); static CGFloat (*_logos_meta_orig$SpringBoard$SBLockScreenNotificationCell$rowHeightForTitle$subtitle$body$maxLines$attachmentSize$secondaryContentSize$datesVisible$rowWidth$includeUnlockActionText$)(_LOGOS_SELF_TYPE_NORMAL Class _LOGOS_SELF_CONST, SEL, id, id, id, unsigned, CGSize, CGSize, BOOL, CGFloat, BOOL); static CGFloat _logos_meta_method$SpringBoard$SBLockScreenNotificationCell$rowHeightForTitle$subtitle$body$maxLines$attachmentSize$secondaryContentSize$datesVisible$rowWidth$includeUnlockActionText$(_LOGOS_SELF_TYPE_NORMAL Class _LOGOS_SELF_CONST, SEL, id, id, id, unsigned, CGSize, CGSize, BOOL, CGFloat, BOOL); static void (*_logos_orig$SpringBoard$SBLockScreenNotificationCell$_updateUnlockText$)(_LOGOS_SELF_TYPE_NORMAL SBLockScreenNotificationCell* _LOGOS_SELF_CONST, SEL, NSString*); static void _logos_method$SpringBoard$SBLockScreenNotificationCell$_updateUnlockText$(_LOGOS_SELF_TYPE_NORMAL SBLockScreenNotificationCell* _LOGOS_SELF_CONST, SEL, NSString*); static SBLockScreenNotificationListView* (*_logos_orig$SpringBoard$SBLockScreenNotificationListView$initWithFrame$)(_LOGOS_SELF_TYPE_INIT SBLockScreenNotificationListView*, SEL, struct CGRect) _LOGOS_RETURN_RETAINED; static SBLockScreenNotificationListView* _logos_method$SpringBoard$SBLockScreenNotificationListView$initWithFrame$(_LOGOS_SELF_TYPE_INIT SBLockScreenNotificationListView*, SEL, struct CGRect) _LOGOS_RETURN_RETAINED; static SBLockScreenNotificationCell* (*_logos_orig$SpringBoard$SBLockScreenNotificationListView$tableView$cellForRowAtIndexPath$)(_LOGOS_SELF_TYPE_NORMAL SBLockScreenNotificationListView* _LOGOS_SELF_CONST, SEL, UITableView*, NSIndexPath*); static SBLockScreenNotificationCell* _logos_method$SpringBoard$SBLockScreenNotificationListView$tableView$cellForRowAtIndexPath$(_LOGOS_SELF_TYPE_NORMAL SBLockScreenNotificationListView* _LOGOS_SELF_CONST, SEL, UITableView*, NSIndexPath*); static void _logos_method$SpringBoard$SBLockScreenNotificationListView$_xen_reloadSeparatorStyleForSetup(_LOGOS_SELF_TYPE_NORMAL SBLockScreenNotificationListView* _LOGOS_SELF_CONST, SEL); static CGFloat (*_logos_orig$SpringBoard$SBLockScreenNotificationListView$tableView$heightForRowAtIndexPath$)(_LOGOS_SELF_TYPE_NORMAL SBLockScreenNotificationListView* _LOGOS_SELF_CONST, SEL, UITableView*, NSIndexPath*); static CGFloat _logos_method$SpringBoard$SBLockScreenNotificationListView$tableView$heightForRowAtIndexPath$(_LOGOS_SELF_TYPE_NORMAL SBLockScreenNotificationListView* _LOGOS_SELF_CONST, SEL, UITableView*, NSIndexPath*); static NSString* _logos_method$SpringBoard$SBLockScreenNotificationListView$XENBundleIdentifierForIndexPath$(_LOGOS_SELF_TYPE_NORMAL SBLockScreenNotificationListView* _LOGOS_SELF_CONST, SEL, NSIndexPath*); static BOOL _logos_method$SpringBoard$SBLockScreenNotificationListView$XENShouldShowIndexPath$(_LOGOS_SELF_TYPE_NORMAL SBLockScreenNotificationListView* _LOGOS_SELF_CONST, SEL, NSIndexPath*); static void (*_logos_orig$SpringBoard$SBLockScreenNotificationListView$layoutSubviews)(_LOGOS_SELF_TYPE_NORMAL SBLockScreenNotificationListView* _LOGOS_SELF_CONST, SEL); static void _logos_method$SpringBoard$SBLockScreenNotificationListView$layoutSubviews(_LOGOS_SELF_TYPE_NORMAL SBLockScreenNotificationListView* _LOGOS_SELF_CONST, SEL); static void (*_logos_orig$SpringBoard$SBLockScreenNotificationListView$setFrame$)(_LOGOS_SELF_TYPE_NORMAL SBLockScreenNotificationListView* _LOGOS_SELF_CONST, SEL, CGRect); static void _logos_method$SpringBoard$SBLockScreenNotificationListView$setFrame$(_LOGOS_SELF_TYPE_NORMAL SBLockScreenNotificationListView* _LOGOS_SELF_CONST, SEL, CGRect); static BOOL (*_logos_orig$SpringBoard$SBLockScreenNotificationListView$hidden)(_LOGOS_SELF_TYPE_NORMAL SBLockScreenNotificationListView* _LOGOS_SELF_CONST, SEL); static BOOL _logos_method$SpringBoard$SBLockScreenNotificationListView$hidden(_LOGOS_SELF_TYPE_NORMAL SBLockScreenNotificationListView* _LOGOS_SELF_CONST, SEL); static void (*_logos_orig$SpringBoard$SBLockScreenNotificationListView$setHidden$)(_LOGOS_SELF_TYPE_NORMAL SBLockScreenNotificationListView* _LOGOS_SELF_CONST, SEL, BOOL); static void _logos_method$SpringBoard$SBLockScreenNotificationListView$setHidden$(_LOGOS_SELF_TYPE_NORMAL SBLockScreenNotificationListView* _LOGOS_SELF_CONST, SEL, BOOL); static void _logos_method$SpringBoard$SBLockScreenNotificationListView$handleActionFromTappedCellWithContext$(_LOGOS_SELF_TYPE_NORMAL SBLockScreenNotificationListView* _LOGOS_SELF_CONST, SEL, id); static CGFloat (*_logos_meta_orig$SpringBoard$SBLockScreenBulletinCell$rowHeightForTitle$subtitle$body$maxLines$attachmentSize$secondaryContentSize$datesVisible$rowWidth$includeUnlockActionText$)(_LOGOS_SELF_TYPE_NORMAL Class _LOGOS_SELF_CONST, SEL, id, id, id, unsigned, CGSize, CGSize, BOOL, CGFloat, BOOL); static CGFloat _logos_meta_method$SpringBoard$SBLockScreenBulletinCell$rowHeightForTitle$subtitle$body$maxLines$attachmentSize$secondaryContentSize$datesVisible$rowWidth$includeUnlockActionText$(_LOGOS_SELF_TYPE_NORMAL Class _LOGOS_SELF_CONST, SEL, id, id, id, unsigned, CGSize, CGSize, BOOL, CGFloat, BOOL); static void (*_logos_orig$SpringBoard$SBLockScreenBulletinCell$_updateUnlockText$)(_LOGOS_SELF_TYPE_NORMAL SBLockScreenBulletinCell* _LOGOS_SELF_CONST, SEL, NSString*); static void _logos_method$SpringBoard$SBLockScreenBulletinCell$_updateUnlockText$(_LOGOS_SELF_TYPE_NORMAL SBLockScreenBulletinCell* _LOGOS_SELF_CONST, SEL, NSString*); static void (*_logos_orig$SpringBoard$SBTableViewCellActionButton$setBackgroundColor$withBlendMode$)(_LOGOS_SELF_TYPE_NORMAL SBTableViewCellActionButton* _LOGOS_SELF_CONST, SEL, id, int); static void _logos_method$SpringBoard$SBTableViewCellActionButton$setBackgroundColor$withBlendMode$(_LOGOS_SELF_TYPE_NORMAL SBTableViewCellActionButton* _LOGOS_SELF_CONST, SEL, id, int); static CGSize (*_logos_orig$SpringBoard$NCNotificationPriorityListViewController$collectionView$layout$sizeForItemAtIndexPath$)(_LOGOS_SELF_TYPE_NORMAL NCNotificationPriorityListViewController* _LOGOS_SELF_CONST, SEL, UICollectionView *, UICollectionViewLayout *, NSIndexPath *); static CGSize _logos_method$SpringBoard$NCNotificationPriorityListViewController$collectionView$layout$sizeForItemAtIndexPath$(_LOGOS_SELF_TYPE_NORMAL NCNotificationPriorityListViewController* _LOGOS_SELF_CONST, SEL, UICollectionView *, UICollectionViewLayout *, NSIndexPath *); static CGFloat _logos_method$SpringBoard$NCNotificationPriorityListViewController$_xen_heightForCurrentCellStyling$(_LOGOS_SELF_TYPE_NORMAL NCNotificationPriorityListViewController* _LOGOS_SELF_CONST, SEL, CGFloat); static NSString* _logos_method$SpringBoard$NCNotificationPriorityListViewController$_xen_bundleIdentifierForIndexPath$(_LOGOS_SELF_TYPE_NORMAL NCNotificationPriorityListViewController* _LOGOS_SELF_CONST, SEL, NSIndexPath*); static BOOL _logos_method$SpringBoard$NCNotificationPriorityListViewController$_xen_shouldShowIndexPath$(_LOGOS_SELF_TYPE_NORMAL NCNotificationPriorityListViewController* _LOGOS_SELF_CONST, SEL, NSIndexPath*); static void (*_logos_orig$SpringBoard$SBLockScreenNotificationListController$_updateModelAndViewForAdditionOfItem$)(_LOGOS_SELF_TYPE_NORMAL SBLockScreenNotificationListController* _LOGOS_SELF_CONST, SEL, SBAwayListItem*); static void _logos_method$SpringBoard$SBLockScreenNotificationListController$_updateModelAndViewForAdditionOfItem$(_LOGOS_SELF_TYPE_NORMAL SBLockScreenNotificationListController* _LOGOS_SELF_CONST, SEL, SBAwayListItem*); static void (*_logos_orig$SpringBoard$SBLockScreenNotificationListController$_updateModelForRemovalOfItem$updateView$)(_LOGOS_SELF_TYPE_NORMAL SBLockScreenNotificationListController* _LOGOS_SELF_CONST, SEL, SBAwayListItem*, BOOL); static void _logos_method$SpringBoard$SBLockScreenNotificationListController$_updateModelForRemovalOfItem$updateView$(_LOGOS_SELF_TYPE_NORMAL SBLockScreenNotificationListController* _LOGOS_SELF_CONST, SEL, SBAwayListItem*, BOOL); static NSArray* _logos_method$SpringBoard$SBLockScreenNotificationListController$_xen_listItems(_LOGOS_SELF_TYPE_NORMAL SBLockScreenNotificationListController* _LOGOS_SELF_CONST, SEL); static void (*_logos_orig$SpringBoard$SBLockScreenNotificationListController$turnOnScreenIfNecessaryForItem$withCompletion$)(_LOGOS_SELF_TYPE_NORMAL SBLockScreenNotificationListController* _LOGOS_SELF_CONST, SEL, id, void (^)(void)); static void _logos_method$SpringBoard$SBLockScreenNotificationListController$turnOnScreenIfNecessaryForItem$withCompletion$(_LOGOS_SELF_TYPE_NORMAL SBLockScreenNotificationListController* _LOGOS_SELF_CONST, SEL, id, void (^)(void)); static unsigned long long (*_logos_orig$SpringBoard$NCNotificationPriorityList$insertNotificationRequest$)(_LOGOS_SELF_TYPE_NORMAL NCNotificationPriorityList* _LOGOS_SELF_CONST, SEL, NCNotificationRequest*); static unsigned long long _logos_method$SpringBoard$NCNotificationPriorityList$insertNotificationRequest$(_LOGOS_SELF_TYPE_NORMAL NCNotificationPriorityList* _LOGOS_SELF_CONST, SEL, NCNotificationRequest*); static unsigned long long (*_logos_orig$SpringBoard$NCNotificationPriorityList$removeNotificationRequest$)(_LOGOS_SELF_TYPE_NORMAL NCNotificationPriorityList* _LOGOS_SELF_CONST, SEL, NCNotificationRequest*); static unsigned long long _logos_method$SpringBoard$NCNotificationPriorityList$removeNotificationRequest$(_LOGOS_SELF_TYPE_NORMAL NCNotificationPriorityList* _LOGOS_SELF_CONST, SEL, NCNotificationRequest*); static void (*_logos_orig$SpringBoard$SBLockScreenBatteryChargingView$setFrame$)(_LOGOS_SELF_TYPE_NORMAL SBLockScreenBatteryChargingView* _LOGOS_SELF_CONST, SEL, CGRect); static void _logos_method$SpringBoard$SBLockScreenBatteryChargingView$setFrame$(_LOGOS_SELF_TYPE_NORMAL SBLockScreenBatteryChargingView* _LOGOS_SELF_CONST, SEL, CGRect); static void (*_logos_orig$SpringBoard$SBLockScreenNotificationTableView$setAllowsSelection$)(_LOGOS_SELF_TYPE_NORMAL SBLockScreenNotificationTableView* _LOGOS_SELF_CONST, SEL, BOOL); static void _logos_method$SpringBoard$SBLockScreenNotificationTableView$setAllowsSelection$(_LOGOS_SELF_TYPE_NORMAL SBLockScreenNotificationTableView* _LOGOS_SELF_CONST, SEL, BOOL); static void (*_logos_orig$SpringBoard$SBSystemLocalNotificationAlert$willDeactivateForReason$)(_LOGOS_SELF_TYPE_NORMAL SBSystemLocalNotificationAlert* _LOGOS_SELF_CONST, SEL, int); static void _logos_method$SpringBoard$SBSystemLocalNotificationAlert$willDeactivateForReason$(_LOGOS_SELF_TYPE_NORMAL SBSystemLocalNotificationAlert* _LOGOS_SELF_CONST, SEL, int); static void (*_logos_orig$SpringBoard$SBLockScreenFullscreenBulletinViewController$setBulletinItem$)(_LOGOS_SELF_TYPE_NORMAL SBLockScreenFullscreenBulletinViewController* _LOGOS_SELF_CONST, SEL, id); static void _logos_method$SpringBoard$SBLockScreenFullscreenBulletinViewController$setBulletinItem$(_LOGOS_SELF_TYPE_NORMAL SBLockScreenFullscreenBulletinViewController* _LOGOS_SELF_CONST, SEL, id); static void (*_logos_orig$SpringBoard$SBLockScreenFullscreenBulletinViewController$performSnoozeAction)(_LOGOS_SELF_TYPE_NORMAL SBLockScreenFullscreenBulletinViewController* _LOGOS_SELF_CONST, SEL); static void _logos_method$SpringBoard$SBLockScreenFullscreenBulletinViewController$performSnoozeAction(_LOGOS_SELF_TYPE_NORMAL SBLockScreenFullscreenBulletinViewController* _LOGOS_SELF_CONST, SEL); static void (*_logos_orig$SpringBoard$SBLockScreenFullscreenBulletinViewController$performDismissAction)(_LOGOS_SELF_TYPE_NORMAL SBLockScreenFullscreenBulletinViewController* _LOGOS_SELF_CONST, SEL); static void _logos_method$SpringBoard$SBLockScreenFullscreenBulletinViewController$performDismissAction(_LOGOS_SELF_TYPE_NORMAL SBLockScreenFullscreenBulletinViewController* _LOGOS_SELF_CONST, SEL); static void (*_logos_orig$SpringBoard$SBLockScreenFullscreenBulletinViewController$lockButtonPressed$)(_LOGOS_SELF_TYPE_NORMAL SBLockScreenFullscreenBulletinViewController* _LOGOS_SELF_CONST, SEL, id); static void _logos_method$SpringBoard$SBLockScreenFullscreenBulletinViewController$lockButtonPressed$(_LOGOS_SELF_TYPE_NORMAL SBLockScreenFullscreenBulletinViewController* _LOGOS_SELF_CONST, SEL, id); static void (*_logos_orig$SpringBoard$SBLockScreenFullscreenBulletinViewController$viewDidAppear$)(_LOGOS_SELF_TYPE_NORMAL SBLockScreenFullscreenBulletinViewController* _LOGOS_SELF_CONST, SEL, BOOL); static void _logos_method$SpringBoard$SBLockScreenFullscreenBulletinViewController$viewDidAppear$(_LOGOS_SELF_TYPE_NORMAL SBLockScreenFullscreenBulletinViewController* _LOGOS_SELF_CONST, SEL, BOOL); static void (*_logos_orig$SpringBoard$SBFUserAuthenticationController$_setSecureMode$postNotification$)(_LOGOS_SELF_TYPE_NORMAL SBFUserAuthenticationController* _LOGOS_SELF_CONST, SEL, bool, bool); static void _logos_method$SpringBoard$SBFUserAuthenticationController$_setSecureMode$postNotification$(_LOGOS_SELF_TYPE_NORMAL SBFUserAuthenticationController* _LOGOS_SELF_CONST, SEL, bool, bool); static BOOL (*_logos_orig$SpringBoard$SBDashBoardMesaUnlockBehaviorConfiguration$_isAccessibilityRestingUnlockPreferenceEnabled)(_LOGOS_SELF_TYPE_NORMAL SBDashBoardMesaUnlockBehaviorConfiguration* _LOGOS_SELF_CONST, SEL); static BOOL _logos_method$SpringBoard$SBDashBoardMesaUnlockBehaviorConfiguration$_isAccessibilityRestingUnlockPreferenceEnabled(_LOGOS_SELF_TYPE_NORMAL SBDashBoardMesaUnlockBehaviorConfiguration* _LOGOS_SELF_CONST, SEL); static BOOL (*_logos_orig$SpringBoard$XENShortcutModule$isRestricted)(_LOGOS_SELF_TYPE_NORMAL XENShortcutModule* _LOGOS_SELF_CONST, SEL); static BOOL _logos_method$SpringBoard$XENShortcutModule$isRestricted(_LOGOS_SELF_TYPE_NORMAL XENShortcutModule* _LOGOS_SELF_CONST, SEL); static void (*_logos_orig$SpringBoard$XENShortcutModule$activateAppWithDisplayID$url$)(_LOGOS_SELF_TYPE_NORMAL XENShortcutModule* _LOGOS_SELF_CONST, SEL, id, id); static void _logos_method$SpringBoard$XENShortcutModule$activateAppWithDisplayID$url$(_LOGOS_SELF_TYPE_NORMAL XENShortcutModule* _LOGOS_SELF_CONST, SEL, id, id); static void (*_logos_orig$SpringBoard$XENShortcutModule$activateAppWithDisplayID$url$unlockIfNecessary$)(_LOGOS_SELF_TYPE_NORMAL XENShortcutModule* _LOGOS_SELF_CONST, SEL, id, id, bool); static void _logos_method$SpringBoard$XENShortcutModule$activateAppWithDisplayID$url$unlockIfNecessary$(_LOGOS_SELF_TYPE_NORMAL XENShortcutModule* _LOGOS_SELF_CONST, SEL, id, id, bool); static BOOL (*_logos_orig$SpringBoard$SBApplication$boolForActivationSetting$)(_LOGOS_SELF_TYPE_NORMAL SBApplication* _LOGOS_SELF_CONST, SEL, unsigned); static BOOL _logos_method$SpringBoard$SBApplication$boolForActivationSetting$(_LOGOS_SELF_TYPE_NORMAL SBApplication* _LOGOS_SELF_CONST, SEL, unsigned); static void (*_logos_orig$SpringBoard$SBWorkspaceTransaction$_performDeviceCoherencyCheck)(_LOGOS_SELF_TYPE_NORMAL SBWorkspaceTransaction* _LOGOS_SELF_CONST, SEL); static void _logos_method$SpringBoard$SBWorkspaceTransaction$_performDeviceCoherencyCheck(_LOGOS_SELF_TYPE_NORMAL SBWorkspaceTransaction* _LOGOS_SELF_CONST, SEL); static void (*_logos_orig$SpringBoard$SBAlertToAppsWorkspaceTransaction$_performDeviceCoherencyCheck)(_LOGOS_SELF_TYPE_NORMAL SBAlertToAppsWorkspaceTransaction* _LOGOS_SELF_CONST, SEL); static void _logos_method$SpringBoard$SBAlertToAppsWorkspaceTransaction$_performDeviceCoherencyCheck(_LOGOS_SELF_TYPE_NORMAL SBAlertToAppsWorkspaceTransaction* _LOGOS_SELF_CONST, SEL); static _Bool (*_logos_orig$SpringBoard$SBMainWorkspace$_preflightTransitionRequest$)(_LOGOS_SELF_TYPE_NORMAL SBMainWorkspace* _LOGOS_SELF_CONST, SEL, id); static _Bool _logos_method$SpringBoard$SBMainWorkspace$_preflightTransitionRequest$(_LOGOS_SELF_TYPE_NORMAL SBMainWorkspace* _LOGOS_SELF_CONST, SEL, id); static id (*_logos_orig$SpringBoard$CNContactGridViewController$viewControllerForActionsView$)(_LOGOS_SELF_TYPE_NORMAL CNContactGridViewController* _LOGOS_SELF_CONST, SEL, id); static id _logos_method$SpringBoard$CNContactGridViewController$viewControllerForActionsView$(_LOGOS_SELF_TYPE_NORMAL CNContactGridViewController* _LOGOS_SELF_CONST, SEL, id); static void (*_logos_orig$SpringBoard$CNContact$assertKeyIsAvailable$)(_LOGOS_SELF_TYPE_NORMAL CNContact* _LOGOS_SELF_CONST, SEL, id); static void _logos_method$SpringBoard$CNContact$assertKeyIsAvailable$(_LOGOS_SELF_TYPE_NORMAL CNContact* _LOGOS_SELF_CONST, SEL, id); static void (*_logos_orig$SpringBoard$CNContact$assertKeysAreAvailable$)(_LOGOS_SELF_TYPE_NORMAL CNContact* _LOGOS_SELF_CONST, SEL, id); static void _logos_method$SpringBoard$CNContact$assertKeysAreAvailable$(_LOGOS_SELF_TYPE_NORMAL CNContact* _LOGOS_SELF_CONST, SEL, id); static void (*_logos_orig$SpringBoard$CNPropertyAction$performActionForItem$sender$)(_LOGOS_SELF_TYPE_NORMAL CNPropertyAction* _LOGOS_SELF_CONST, SEL, id, id); static void _logos_method$SpringBoard$CNPropertyAction$performActionForItem$sender$(_LOGOS_SELF_TYPE_NORMAL CNPropertyAction* _LOGOS_SELF_CONST, SEL, id, id); static void (*_logos_orig$SpringBoard$CNPropertySendMessageAction$performActionForItem$sender$)(_LOGOS_SELF_TYPE_NORMAL CNPropertySendMessageAction* _LOGOS_SELF_CONST, SEL, id, id); static void _logos_method$SpringBoard$CNPropertySendMessageAction$performActionForItem$sender$(_LOGOS_SELF_TYPE_NORMAL CNPropertySendMessageAction* _LOGOS_SELF_CONST, SEL, id, id); static void (*_logos_orig$SpringBoard$CNPropertyFaceTimeAction$performActionForItem$sender$)(_LOGOS_SELF_TYPE_NORMAL CNPropertyFaceTimeAction* _LOGOS_SELF_CONST, SEL, id, id); static void _logos_method$SpringBoard$CNPropertyFaceTimeAction$performActionForItem$sender$(_LOGOS_SELF_TYPE_NORMAL CNPropertyFaceTimeAction* _LOGOS_SELF_CONST, SEL, id, id); static BOOL (*_logos_orig$SpringBoard$SpringBoard$openURL$)(_LOGOS_SELF_TYPE_NORMAL SpringBoard* _LOGOS_SELF_CONST, SEL, id); static BOOL _logos_method$SpringBoard$SpringBoard$openURL$(_LOGOS_SELF_TYPE_NORMAL SpringBoard* _LOGOS_SELF_CONST, SEL, id); static BOOL (*_logos_orig$SpringBoard$SpringBoard$_handlePhysicalButtonEvent$)(_LOGOS_SELF_TYPE_NORMAL SpringBoard* _LOGOS_SELF_CONST, SEL, UIPhysicalButtonsEvent*); static BOOL _logos_method$SpringBoard$SpringBoard$_handlePhysicalButtonEvent$(_LOGOS_SELF_TYPE_NORMAL SpringBoard* _LOGOS_SELF_CONST, SEL, UIPhysicalButtonsEvent*); static void (*_logos_orig$SpringBoard$SpringBoard$setStatusBarHidden$withAnimation$)(_LOGOS_SELF_TYPE_NORMAL SpringBoard* _LOGOS_SELF_CONST, SEL, BOOL, long long); static void _logos_method$SpringBoard$SpringBoard$setStatusBarHidden$withAnimation$(_LOGOS_SELF_TYPE_NORMAL SpringBoard* _LOGOS_SELF_CONST, SEL, BOOL, long long); static void _logos_method$SpringBoard$SpringBoard$_xen_showPeekUI(_LOGOS_SELF_TYPE_NORMAL SpringBoard* _LOGOS_SELF_CONST, SEL); static void _logos_method$SpringBoard$SpringBoard$_xen_hidePeekUIWithEvent$(_LOGOS_SELF_TYPE_NORMAL SpringBoard* _LOGOS_SELF_CONST, SEL, XENPeekEvent); static void (*_logos_orig$SpringBoard$SpringBoard$_handleMenuButtonEvent)(_LOGOS_SELF_TYPE_NORMAL SpringBoard* _LOGOS_SELF_CONST, SEL); static void _logos_method$SpringBoard$SpringBoard$_handleMenuButtonEvent(_LOGOS_SELF_TYPE_NORMAL SpringBoard* _LOGOS_SELF_CONST, SEL); static void (*_logos_orig$SpringBoard$SpringBoard$handleMenuDoubleTap)(_LOGOS_SELF_TYPE_NORMAL SpringBoard* _LOGOS_SELF_CONST, SEL); static void _logos_method$SpringBoard$SpringBoard$handleMenuDoubleTap(_LOGOS_SELF_TYPE_NORMAL SpringBoard* _LOGOS_SELF_CONST, SEL); static void _logos_method$SpringBoard$SpringBoard$xen_dismissContentEditor(_LOGOS_SELF_TYPE_NORMAL SpringBoard* _LOGOS_SELF_CONST, SEL); static BOOL (*_logos_orig$SpringBoard$LSApplicationWorkspace$openURL$withOptions$)(_LOGOS_SELF_TYPE_NORMAL LSApplicationWorkspace* _LOGOS_SELF_CONST, SEL, id, id); static BOOL _logos_method$SpringBoard$LSApplicationWorkspace$openURL$withOptions$(_LOGOS_SELF_TYPE_NORMAL LSApplicationWorkspace* _LOGOS_SELF_CONST, SEL, id, id); static Class (*_logos_orig$SpringBoard$SBPluginManager$loadPluginBundle$)(_LOGOS_SELF_TYPE_NORMAL SBPluginManager* _LOGOS_SELF_CONST, SEL, NSBundle*); static Class _logos_method$SpringBoard$SBPluginManager$loadPluginBundle$(_LOGOS_SELF_TYPE_NORMAL SBPluginManager* _LOGOS_SELF_CONST, SEL, NSBundle*); static void (*_logos_orig$SpringBoard$SBAlertWindow$sendEvent$)(_LOGOS_SELF_TYPE_NORMAL SBAlertWindow* _LOGOS_SELF_CONST, SEL, UIEvent *); static void _logos_method$SpringBoard$SBAlertWindow$sendEvent$(_LOGOS_SELF_TYPE_NORMAL SBAlertWindow* _LOGOS_SELF_CONST, SEL, UIEvent *); static double (*_logos_orig$SpringBoard$SBBacklightController$defaultLockScreenDimInterval)(_LOGOS_SELF_TYPE_NORMAL SBBacklightController* _LOGOS_SELF_CONST, SEL); static double _logos_method$SpringBoard$SBBacklightController$defaultLockScreenDimInterval(_LOGOS_SELF_TYPE_NORMAL SBBacklightController* _LOGOS_SELF_CONST, SEL); static double (*_logos_orig$SpringBoard$SBBacklightController$defaultLockScreenDimIntervalWhenNotificationsPresent)(_LOGOS_SELF_TYPE_NORMAL SBBacklightController* _LOGOS_SELF_CONST, SEL); static double _logos_method$SpringBoard$SBBacklightController$defaultLockScreenDimIntervalWhenNotificationsPresent(_LOGOS_SELF_TYPE_NORMAL SBBacklightController* _LOGOS_SELF_CONST, SEL); static SBManualIdleTimer* (*_logos_orig$SpringBoard$SBManualIdleTimer$initWithInterval$userEventInterface$)(_LOGOS_SELF_TYPE_INIT SBManualIdleTimer*, SEL, double, id) _LOGOS_RETURN_RETAINED; static SBManualIdleTimer* _logos_method$SpringBoard$SBManualIdleTimer$initWithInterval$userEventInterface$(_LOGOS_SELF_TYPE_INIT SBManualIdleTimer*, SEL, double, id) _LOGOS_RETURN_RETAINED; static void (*_logos_orig$SpringBoard$_NowPlayingArtView$layoutSubviews)(_LOGOS_SELF_TYPE_NORMAL _NowPlayingArtView* _LOGOS_SELF_CONST, SEL); static void _logos_method$SpringBoard$_NowPlayingArtView$layoutSubviews(_LOGOS_SELF_TYPE_NORMAL _NowPlayingArtView* _LOGOS_SELF_CONST, SEL); static UIView * (*_logos_orig$SpringBoard$UICollectionView$hitTest$withEvent$)(_LOGOS_SELF_TYPE_NORMAL UICollectionView* _LOGOS_SELF_CONST, SEL, CGPoint, UIEvent *); static UIView * _logos_method$SpringBoard$UICollectionView$hitTest$withEvent$(_LOGOS_SELF_TYPE_NORMAL UICollectionView* _LOGOS_SELF_CONST, SEL, CGPoint, UIEvent *); static MPUSystemMediaControlsView* _logos_method$SpringBoard$MPUSystemMediaControlsViewController$_xen_mediaView(_LOGOS_SELF_TYPE_NORMAL MPUSystemMediaControlsViewController* _LOGOS_SELF_CONST, SEL); static id (*_logos_orig$SpringBoard$MPUSystemMediaControlsViewController$_imageForTransportButtonWithControlType$)(_LOGOS_SELF_TYPE_NORMAL MPUSystemMediaControlsViewController* _LOGOS_SELF_CONST, SEL, int); static id _logos_method$SpringBoard$MPUSystemMediaControlsViewController$_imageForTransportButtonWithControlType$(_LOGOS_SELF_TYPE_NORMAL MPUSystemMediaControlsViewController* _LOGOS_SELF_CONST, SEL, int); static SBUIControlCenterButton* (*_logos_orig$SpringBoard$SBUIControlCenterButton$initWithFrame$)(_LOGOS_SELF_TYPE_INIT SBUIControlCenterButton*, SEL, CGRect) _LOGOS_RETURN_RETAINED; static SBUIControlCenterButton* _logos_method$SpringBoard$SBUIControlCenterButton$initWithFrame$(_LOGOS_SELF_TYPE_INIT SBUIControlCenterButton*, SEL, CGRect) _LOGOS_RETURN_RETAINED; static id (*_logos_orig$SpringBoard$SBUIControlCenterButton$_backgroundImage)(_LOGOS_SELF_TYPE_NORMAL SBUIControlCenterButton* _LOGOS_SELF_CONST, SEL); static id _logos_method$SpringBoard$SBUIControlCenterButton$_backgroundImage(_LOGOS_SELF_TYPE_NORMAL SBUIControlCenterButton* _LOGOS_SELF_CONST, SEL); static id (*_logos_orig$SpringBoard$SBUIControlCenterButton$_glyphImageForState$)(_LOGOS_SELF_TYPE_NORMAL SBUIControlCenterButton* _LOGOS_SELF_CONST, SEL, int); static id _logos_method$SpringBoard$SBUIControlCenterButton$_glyphImageForState$(_LOGOS_SELF_TYPE_NORMAL SBUIControlCenterButton* _LOGOS_SELF_CONST, SEL, int); static void (*_logos_orig$SpringBoard$SBUIControlCenterButton$layoutSubviews)(_LOGOS_SELF_TYPE_NORMAL SBUIControlCenterButton* _LOGOS_SELF_CONST, SEL); static void _logos_method$SpringBoard$SBUIControlCenterButton$layoutSubviews(_LOGOS_SELF_TYPE_NORMAL SBUIControlCenterButton* _LOGOS_SELF_CONST, SEL); static void (*_logos_orig$SpringBoard$SBUIControlCenterButton$_updateEffects)(_LOGOS_SELF_TYPE_NORMAL SBUIControlCenterButton* _LOGOS_SELF_CONST, SEL); static void _logos_method$SpringBoard$SBUIControlCenterButton$_updateEffects(_LOGOS_SELF_TYPE_NORMAL SBUIControlCenterButton* _LOGOS_SELF_CONST, SEL); static void (*_logos_orig$SpringBoard$SBUIControlCenterButton$_updateForStateChange)(_LOGOS_SELF_TYPE_NORMAL SBUIControlCenterButton* _LOGOS_SELF_CONST, SEL); static void _logos_method$SpringBoard$SBUIControlCenterButton$_updateForStateChange(_LOGOS_SELF_TYPE_NORMAL SBUIControlCenterButton* _LOGOS_SELF_CONST, SEL); static SBCCButtonLikeSectionView* (*_logos_orig$SpringBoard$SBCCButtonLikeSectionView$initWithFrame$)(_LOGOS_SELF_TYPE_INIT SBCCButtonLikeSectionView*, SEL, CGRect) _LOGOS_RETURN_RETAINED; static SBCCButtonLikeSectionView* _logos_method$SpringBoard$SBCCButtonLikeSectionView$initWithFrame$(_LOGOS_SELF_TYPE_INIT SBCCButtonLikeSectionView*, SEL, CGRect) _LOGOS_RETURN_RETAINED; static void (*_logos_orig$SpringBoard$SBCCButtonLikeSectionView$_updateEffects)(_LOGOS_SELF_TYPE_NORMAL SBCCButtonLikeSectionView* _LOGOS_SELF_CONST, SEL); static void _logos_method$SpringBoard$SBCCButtonLikeSectionView$_updateEffects(_LOGOS_SELF_TYPE_NORMAL SBCCButtonLikeSectionView* _LOGOS_SELF_CONST, SEL); static void (*_logos_orig$SpringBoard$SBCCButtonLikeSectionView$layoutSubviews)(_LOGOS_SELF_TYPE_NORMAL SBCCButtonLikeSectionView* _LOGOS_SELF_CONST, SEL); static void _logos_method$SpringBoard$SBCCButtonLikeSectionView$layoutSubviews(_LOGOS_SELF_TYPE_NORMAL SBCCButtonLikeSectionView* _LOGOS_SELF_CONST, SEL); static id (*_logos_orig$SpringBoard$SBCCButtonLikeSectionView$_backgroundImageWithRoundCorners$)(_LOGOS_SELF_TYPE_NORMAL SBCCButtonLikeSectionView* _LOGOS_SELF_CONST, SEL, unsigned); static id _logos_method$SpringBoard$SBCCButtonLikeSectionView$_backgroundImageWithRoundCorners$(_LOGOS_SELF_TYPE_NORMAL SBCCButtonLikeSectionView* _LOGOS_SELF_CONST, SEL, unsigned); static void (*_logos_orig$SpringBoard$SBCCButtonLikeSectionView$setSelected$)(_LOGOS_SELF_TYPE_NORMAL SBCCButtonLikeSectionView* _LOGOS_SELF_CONST, SEL, BOOL); static void _logos_method$SpringBoard$SBCCButtonLikeSectionView$setSelected$(_LOGOS_SELF_TYPE_NORMAL SBCCButtonLikeSectionView* _LOGOS_SELF_CONST, SEL, BOOL); static void (*_logos_orig$SpringBoard$SBCCButtonLikeSectionView$buttonTapped$)(_LOGOS_SELF_TYPE_NORMAL SBCCButtonLikeSectionView* _LOGOS_SELF_CONST, SEL, id); static void _logos_method$SpringBoard$SBCCButtonLikeSectionView$buttonTapped$(_LOGOS_SELF_TYPE_NORMAL SBCCButtonLikeSectionView* _LOGOS_SELF_CONST, SEL, id); static BOOL (*_logos_orig$SpringBoard$SBCCButtonLikeSectionView$_shouldUseButtonAppearance)(_LOGOS_SELF_TYPE_NORMAL SBCCButtonLikeSectionView* _LOGOS_SELF_CONST, SEL); static BOOL _logos_method$SpringBoard$SBCCButtonLikeSectionView$_shouldUseButtonAppearance(_LOGOS_SELF_TYPE_NORMAL SBCCButtonLikeSectionView* _LOGOS_SELF_CONST, SEL); static BOOL (*_logos_orig$SpringBoard$SBCCBrightnessSectionController$_shouldDarkenBackground)(_LOGOS_SELF_TYPE_NORMAL SBCCBrightnessSectionController* _LOGOS_SELF_CONST, SEL); static BOOL _logos_method$SpringBoard$SBCCBrightnessSectionController$_shouldDarkenBackground(_LOGOS_SELF_TYPE_NORMAL SBCCBrightnessSectionController* _LOGOS_SELF_CONST, SEL); static SBUIControlCenterSlider* _logos_method$SpringBoard$SBCCBrightnessSectionController$xen_slider(_LOGOS_SELF_TYPE_NORMAL SBCCBrightnessSectionController* _LOGOS_SELF_CONST, SEL); static id (*_logos_orig$SpringBoard$SBUIControlCenterSlider$_valueImageForImage$state$)(_LOGOS_SELF_TYPE_NORMAL SBUIControlCenterSlider* _LOGOS_SELF_CONST, SEL, id, long long); static id _logos_method$SpringBoard$SBUIControlCenterSlider$_valueImageForImage$state$(_LOGOS_SELF_TYPE_NORMAL SBUIControlCenterSlider* _LOGOS_SELF_CONST, SEL, id, long long); static void (*_logos_orig$SpringBoard$SBUIControlCenterSlider$setAdjusting$)(_LOGOS_SELF_TYPE_NORMAL SBUIControlCenterSlider* _LOGOS_SELF_CONST, SEL, BOOL); static void _logos_method$SpringBoard$SBUIControlCenterSlider$setAdjusting$(_LOGOS_SELF_TYPE_NORMAL SBUIControlCenterSlider* _LOGOS_SELF_CONST, SEL, BOOL); static void (*_logos_orig$SpringBoard$SBUIControlCenterSlider$layoutSubviews)(_LOGOS_SELF_TYPE_NORMAL SBUIControlCenterSlider* _LOGOS_SELF_CONST, SEL); static void _logos_method$SpringBoard$SBUIControlCenterSlider$layoutSubviews(_LOGOS_SELF_TYPE_NORMAL SBUIControlCenterSlider* _LOGOS_SELF_CONST, SEL); static void (*_logos_orig$SpringBoard$SBUIControlCenterSlider$setMaximumTrackImage$forState$)(_LOGOS_SELF_TYPE_NORMAL SBUIControlCenterSlider* _LOGOS_SELF_CONST, SEL, UIImage*, int); static void _logos_method$SpringBoard$SBUIControlCenterSlider$setMaximumTrackImage$forState$(_LOGOS_SELF_TYPE_NORMAL SBUIControlCenterSlider* _LOGOS_SELF_CONST, SEL, UIImage*, int); static void (*_logos_orig$SpringBoard$SBUIControlCenterSlider$setMinimumTrackImage$forState$)(_LOGOS_SELF_TYPE_NORMAL SBUIControlCenterSlider* _LOGOS_SELF_CONST, SEL, UIImage*, int); static void _logos_method$SpringBoard$SBUIControlCenterSlider$setMinimumTrackImage$forState$(_LOGOS_SELF_TYPE_NORMAL SBUIControlCenterSlider* _LOGOS_SELF_CONST, SEL, UIImage*, int); static void (*_logos_orig$SpringBoard$SBUIControlCenterSlider$setThumbImage$forState$)(_LOGOS_SELF_TYPE_NORMAL SBUIControlCenterSlider* _LOGOS_SELF_CONST, SEL, UIImage*, int); static void _logos_method$SpringBoard$SBUIControlCenterSlider$setThumbImage$forState$(_LOGOS_SELF_TYPE_NORMAL SBUIControlCenterSlider* _LOGOS_SELF_CONST, SEL, UIImage*, int); static void _logos_method$SpringBoard$SBUIControlCenterSlider$_xen_setTrackImagesForCurrentTheme(_LOGOS_SELF_TYPE_NORMAL SBUIControlCenterSlider* _LOGOS_SELF_CONST, SEL); static XENControlCenterViewController* (*_logos_orig$SpringBoard$XENControlCenterViewController$init)(_LOGOS_SELF_TYPE_INIT XENControlCenterViewController*, SEL) _LOGOS_RETURN_RETAINED; static XENControlCenterViewController* _logos_method$SpringBoard$XENControlCenterViewController$init(_LOGOS_SELF_TYPE_INIT XENControlCenterViewController*, SEL) _LOGOS_RETURN_RETAINED; static void (*_logos_orig$SpringBoard$XENControlCenterViewController$_layoutScrollView)(_LOGOS_SELF_TYPE_NORMAL XENControlCenterViewController* _LOGOS_SELF_CONST, SEL); static void _logos_method$SpringBoard$XENControlCenterViewController$_layoutScrollView(_LOGOS_SELF_TYPE_NORMAL XENControlCenterViewController* _LOGOS_SELF_CONST, SEL); static void (*_logos_orig$SpringBoard$XENControlCenterViewController$_addContentViewController$)(_LOGOS_SELF_TYPE_NORMAL XENControlCenterViewController* _LOGOS_SELF_CONST, SEL, id); static void _logos_method$SpringBoard$XENControlCenterViewController$_addContentViewController$(_LOGOS_SELF_TYPE_NORMAL XENControlCenterViewController* _LOGOS_SELF_CONST, SEL, id); static id (*_logos_orig$SpringBoard$XENControlCenterViewController$controlCenterSystemAgent)(_LOGOS_SELF_TYPE_NORMAL XENControlCenterViewController* _LOGOS_SELF_CONST, SEL); static id _logos_method$SpringBoard$XENControlCenterViewController$controlCenterSystemAgent(_LOGOS_SELF_TYPE_NORMAL XENControlCenterViewController* _LOGOS_SELF_CONST, SEL); static AVFlashlight* (*_logos_orig$SpringBoard$AVFlashlight$init)(_LOGOS_SELF_TYPE_INIT AVFlashlight*, SEL) _LOGOS_RETURN_RETAINED; static AVFlashlight* _logos_method$SpringBoard$AVFlashlight$init(_LOGOS_SELF_TYPE_INIT AVFlashlight*, SEL) _LOGOS_RETURN_RETAINED; static void (*_logos_orig$SpringBoard$MPUMediaControlsVolumeView$layoutSubviews)(_LOGOS_SELF_TYPE_NORMAL MPUMediaControlsVolumeView* _LOGOS_SELF_CONST, SEL); static void _logos_method$SpringBoard$MPUMediaControlsVolumeView$layoutSubviews(_LOGOS_SELF_TYPE_NORMAL MPUMediaControlsVolumeView* _LOGOS_SELF_CONST, SEL); static void (*_logos_orig$SpringBoard$MPUMediaControlsVolumeView$updateSystemVolumeLevel)(_LOGOS_SELF_TYPE_NORMAL MPUMediaControlsVolumeView* _LOGOS_SELF_CONST, SEL); static void _logos_method$SpringBoard$MPUMediaControlsVolumeView$updateSystemVolumeLevel(_LOGOS_SELF_TYPE_NORMAL MPUMediaControlsVolumeView* _LOGOS_SELF_CONST, SEL); static void (*_logos_orig$SpringBoard$MPUMediaControlsVolumeView$volumeController$volumeValueDidChange$)(_LOGOS_SELF_TYPE_NORMAL MPUMediaControlsVolumeView* _LOGOS_SELF_CONST, SEL, id, float); static void _logos_method$SpringBoard$MPUMediaControlsVolumeView$volumeController$volumeValueDidChange$(_LOGOS_SELF_TYPE_NORMAL MPUMediaControlsVolumeView* _LOGOS_SELF_CONST, SEL, id, float); static void _logos_method$SpringBoard$MPUMediaControlsVolumeView$_xen_volumeChangeStarted$(_LOGOS_SELF_TYPE_NORMAL MPUMediaControlsVolumeView* _LOGOS_SELF_CONST, SEL, id); static void _logos_method$SpringBoard$MPUMediaControlsVolumeView$_xen_volumeValueChanged$(_LOGOS_SELF_TYPE_NORMAL MPUMediaControlsVolumeView* _LOGOS_SELF_CONST, SEL, id); static void _logos_method$SpringBoard$MPUMediaControlsVolumeView$_xen_volumeStoppedChange$(_LOGOS_SELF_TYPE_NORMAL MPUMediaControlsVolumeView* _LOGOS_SELF_CONST, SEL, id); static void (*_logos_orig$SpringBoard$SBDashBoardView$_layoutPageControl)(_LOGOS_SELF_TYPE_NORMAL SBDashBoardView* _LOGOS_SELF_CONST, SEL); static void _logos_method$SpringBoard$SBDashBoardView$_layoutPageControl(_LOGOS_SELF_TYPE_NORMAL SBDashBoardView* _LOGOS_SELF_CONST, SEL); static int (*_logos_orig$SpringBoard$UIDevice$userInterfaceIdiom)(_LOGOS_SELF_TYPE_NORMAL UIDevice* _LOGOS_SELF_CONST, SEL); static int _logos_method$SpringBoard$UIDevice$userInterfaceIdiom(_LOGOS_SELF_TYPE_NORMAL UIDevice* _LOGOS_SELF_CONST, SEL); static void (*_logos_orig$SpringBoard$SBCCButtonLayoutView$layoutSubviews)(_LOGOS_SELF_TYPE_NORMAL SBCCButtonLayoutView* _LOGOS_SELF_CONST, SEL); static void _logos_method$SpringBoard$SBCCButtonLayoutView$layoutSubviews(_LOGOS_SELF_TYPE_NORMAL SBCCButtonLayoutView* _LOGOS_SELF_CONST, SEL); static CGFloat (*_logos_orig$SpringBoard$SBCCButtonLayoutView$interButtonPadding)(_LOGOS_SELF_TYPE_NORMAL SBCCButtonLayoutView* _LOGOS_SELF_CONST, SEL); static CGFloat _logos_method$SpringBoard$SBCCButtonLayoutView$interButtonPadding(_LOGOS_SELF_TYPE_NORMAL SBCCButtonLayoutView* _LOGOS_SELF_CONST, SEL); static UIEdgeInsets (*_logos_orig$SpringBoard$SBCCButtonLikeSectionSplitView$_landscapeInsetsForSection)(_LOGOS_SELF_TYPE_NORMAL SBCCButtonLikeSectionSplitView* _LOGOS_SELF_CONST, SEL); static UIEdgeInsets _logos_method$SpringBoard$SBCCButtonLikeSectionSplitView$_landscapeInsetsForSection(_LOGOS_SELF_TYPE_NORMAL SBCCButtonLikeSectionSplitView* _LOGOS_SELF_CONST, SEL); static BOOL (*_logos_orig$SpringBoard$SBCCButtonLikeSectionSplitView$_useLandscapeBehavior)(_LOGOS_SELF_TYPE_NORMAL SBCCButtonLikeSectionSplitView* _LOGOS_SELF_CONST, SEL); static BOOL _logos_method$SpringBoard$SBCCButtonLikeSectionSplitView$_useLandscapeBehavior(_LOGOS_SELF_TYPE_NORMAL SBCCButtonLikeSectionSplitView* _LOGOS_SELF_CONST, SEL); static void (*_logos_orig$SpringBoard$EKBBTodayProvider$_refreshUpcomingEventBulletin)(_LOGOS_SELF_TYPE_NORMAL EKBBTodayProvider* _LOGOS_SELF_CONST, SEL); static void _logos_method$SpringBoard$EKBBTodayProvider$_refreshUpcomingEventBulletin(_LOGOS_SELF_TYPE_NORMAL EKBBTodayProvider* _LOGOS_SELF_CONST, SEL); static void (*_logos_orig$SpringBoard$EKBBTodayProvider$_refreshBirthdayBulletin)(_LOGOS_SELF_TYPE_NORMAL EKBBTodayProvider* _LOGOS_SELF_CONST, SEL); static void _logos_method$SpringBoard$EKBBTodayProvider$_refreshBirthdayBulletin(_LOGOS_SELF_TYPE_NORMAL EKBBTodayProvider* _LOGOS_SELF_CONST, SEL); static UIView* (*_logos_orig$SpringBoard$UIVisualEffectView$hitTest$withEvent$)(_LOGOS_SELF_TYPE_NORMAL UIVisualEffectView* _LOGOS_SELF_CONST, SEL, CGPoint, UIEvent *); static UIView* _logos_method$SpringBoard$UIVisualEffectView$hitTest$withEvent$(_LOGOS_SELF_TYPE_NORMAL UIVisualEffectView* _LOGOS_SELF_CONST, SEL, CGPoint, UIEvent *); static int (*_logos_orig$SpringBoard$LPPageController$calculateStartIndex$)(_LOGOS_SELF_TYPE_NORMAL LPPageController* _LOGOS_SELF_CONST, SEL, id); static int _logos_method$SpringBoard$LPPageController$calculateStartIndex$(_LOGOS_SELF_TYPE_NORMAL LPPageController* _LOGOS_SELF_CONST, SEL, id); static long long (*_logos_orig$SpringBoard$LPPageController$realPageCount)(_LOGOS_SELF_TYPE_NORMAL LPPageController* _LOGOS_SELF_CONST, SEL); static long long _logos_method$SpringBoard$LPPageController$realPageCount(_LOGOS_SELF_TYPE_NORMAL LPPageController* _LOGOS_SELF_CONST, SEL); static id (*_logos_orig$SpringBoard$LPPageController$pageAtOffset$)(_LOGOS_SELF_TYPE_NORMAL LPPageController* _LOGOS_SELF_CONST, SEL, double); static id _logos_method$SpringBoard$LPPageController$pageAtOffset$(_LOGOS_SELF_TYPE_NORMAL LPPageController* _LOGOS_SELF_CONST, SEL, double); static id (*_logos_orig$SpringBoard$LPPageController$pageAtAbsoluteIndex$)(_LOGOS_SELF_TYPE_NORMAL LPPageController* _LOGOS_SELF_CONST, SEL, unsigned long long); static id _logos_method$SpringBoard$LPPageController$pageAtAbsoluteIndex$(_LOGOS_SELF_TYPE_NORMAL LPPageController* _LOGOS_SELF_CONST, SEL, unsigned long long); static void (*_logos_orig$SpringBoard$LPPageController$layoutLockScreenView$)(_LOGOS_SELF_TYPE_NORMAL LPPageController* _LOGOS_SELF_CONST, SEL, id); static void _logos_method$SpringBoard$LPPageController$layoutLockScreenView$(_LOGOS_SELF_TYPE_NORMAL LPPageController* _LOGOS_SELF_CONST, SEL, id); static void (*_logos_orig$SpringBoard$LPPageController$layoutPages)(_LOGOS_SELF_TYPE_NORMAL LPPageController* _LOGOS_SELF_CONST, SEL); static void _logos_method$SpringBoard$LPPageController$layoutPages(_LOGOS_SELF_TYPE_NORMAL LPPageController* _LOGOS_SELF_CONST, SEL); static void (*_logos_orig$SpringBoard$LPPageController$addPage$)(_LOGOS_SELF_TYPE_NORMAL LPPageController* _LOGOS_SELF_CONST, SEL, id); static void _logos_method$SpringBoard$LPPageController$addPage$(_LOGOS_SELF_TYPE_NORMAL LPPageController* _LOGOS_SELF_CONST, SEL, id); static id _logos_method$SpringBoard$LPPageController$_xen_sortedPages(_LOGOS_SELF_TYPE_NORMAL LPPageController* _LOGOS_SELF_CONST, SEL); static _Bool (*_logos_orig$SpringBoard$LPPage$supportsBackgroundAlpha)(_LOGOS_SELF_TYPE_NORMAL LPPage* _LOGOS_SELF_CONST, SEL); static _Bool _logos_method$SpringBoard$LPPage$supportsBackgroundAlpha(_LOGOS_SELF_TYPE_NORMAL LPPage* _LOGOS_SELF_CONST, SEL); static void (*_logos_orig$SpringBoard$SBUIPasscodeLockViewBase$_noteDeviceHasBeenUnlockedOnceSinceBoot$)(_LOGOS_SELF_TYPE_NORMAL SBUIPasscodeLockViewBase* _LOGOS_SELF_CONST, SEL, BOOL); static void _logos_method$SpringBoard$SBUIPasscodeLockViewBase$_noteDeviceHasBeenUnlockedOnceSinceBoot$(_LOGOS_SELF_TYPE_NORMAL SBUIPasscodeLockViewBase* _LOGOS_SELF_CONST, SEL, BOOL); static void (*_logos_orig$SpringBoard$SBUIPasscodeLockViewBase$_setLuminosityBoost$)(_LOGOS_SELF_TYPE_NORMAL SBUIPasscodeLockViewBase* _LOGOS_SELF_CONST, SEL, double); static void _logos_method$SpringBoard$SBUIPasscodeLockViewBase$_setLuminosityBoost$(_LOGOS_SELF_TYPE_NORMAL SBUIPasscodeLockViewBase* _LOGOS_SELF_CONST, SEL, double); static void _logos_method$SpringBoard$SBUIPasscodeLockViewBase$_xen_layoutForHidingViews(_LOGOS_SELF_TYPE_NORMAL SBUIPasscodeLockViewBase* _LOGOS_SELF_CONST, SEL); static BOOL (*_logos_orig$SpringBoard$SBNotificationCenterController$isVisible)(_LOGOS_SELF_TYPE_NORMAL SBNotificationCenterController* _LOGOS_SELF_CONST, SEL); static BOOL _logos_method$SpringBoard$SBNotificationCenterController$isVisible(_LOGOS_SELF_TYPE_NORMAL SBNotificationCenterController* _LOGOS_SELF_CONST, SEL); static BOOL (*_logos_orig$SpringBoard$SBNotificationCenterController$shouldRequestWidgetRemoteViewControllers)(_LOGOS_SELF_TYPE_NORMAL SBNotificationCenterController* _LOGOS_SELF_CONST, SEL); static BOOL _logos_method$SpringBoard$SBNotificationCenterController$shouldRequestWidgetRemoteViewControllers(_LOGOS_SELF_TYPE_NORMAL SBNotificationCenterController* _LOGOS_SELF_CONST, SEL); static void _logos_meta_method$SpringBoard$SBNotificationCenterController$_xen_setRequestVisible$(_LOGOS_SELF_TYPE_NORMAL Class _LOGOS_SELF_CONST, SEL, BOOL); static NSSet* _logos_method$SpringBoard$SBNotificationCenterLayoutViewController$xen_defaultEnabledIDs(_LOGOS_SELF_TYPE_NORMAL SBNotificationCenterLayoutViewController* _LOGOS_SELF_CONST, SEL); static NSMutableDictionary * _logos_method$SpringBoard$SBNotificationCenterLayoutViewController$xen_identifiersToDatums(_LOGOS_SELF_TYPE_NORMAL SBNotificationCenterLayoutViewController* _LOGOS_SELF_CONST, SEL); static NSMutableDictionary * _logos_method$SpringBoard$SBNotificationCenterLayoutViewController$xen_dataSourceIdentifiersToDatumIdentifiers(_LOGOS_SELF_TYPE_NORMAL SBNotificationCenterLayoutViewController* _LOGOS_SELF_CONST, SEL); static void _logos_method$SpringBoard$SBUIPasscodeLockViewWithKeyboard$_xen_layoutForHidingViews(_LOGOS_SELF_TYPE_NORMAL SBUIPasscodeLockViewWithKeyboard* _LOGOS_SELF_CONST, SEL); static CGFloat (*_logos_orig$SpringBoard$SBUIPasscodeTextField$alpha)(_LOGOS_SELF_TYPE_NORMAL SBUIPasscodeTextField* _LOGOS_SELF_CONST, SEL); static CGFloat _logos_method$SpringBoard$SBUIPasscodeTextField$alpha(_LOGOS_SELF_TYPE_NORMAL SBUIPasscodeTextField* _LOGOS_SELF_CONST, SEL); static void (*_logos_orig$SpringBoard$SBUIPasscodeTextField$setAlpha$)(_LOGOS_SELF_TYPE_NORMAL SBUIPasscodeTextField* _LOGOS_SELF_CONST, SEL, CGFloat); static void _logos_method$SpringBoard$SBUIPasscodeTextField$setAlpha$(_LOGOS_SELF_TYPE_NORMAL SBUIPasscodeTextField* _LOGOS_SELF_CONST, SEL, CGFloat); static UIColor* (*_logos_orig$SpringBoard$SBUIPasscodeTextField$backgroundColor)(_LOGOS_SELF_TYPE_NORMAL SBUIPasscodeTextField* _LOGOS_SELF_CONST, SEL); static UIColor* _logos_method$SpringBoard$SBUIPasscodeTextField$backgroundColor(_LOGOS_SELF_TYPE_NORMAL SBUIPasscodeTextField* _LOGOS_SELF_CONST, SEL); static void (*_logos_orig$SpringBoard$SBUIPasscodeTextField$setBackgroundColor$)(_LOGOS_SELF_TYPE_NORMAL SBUIPasscodeTextField* _LOGOS_SELF_CONST, SEL, UIColor*); static void _logos_method$SpringBoard$SBUIPasscodeTextField$setBackgroundColor$(_LOGOS_SELF_TYPE_NORMAL SBUIPasscodeTextField* _LOGOS_SELF_CONST, SEL, UIColor*); static void (*_logos_orig$SpringBoard$CBRGradientView$setFrame$)(_LOGOS_SELF_TYPE_NORMAL CBRGradientView* _LOGOS_SELF_CONST, SEL, CGRect); static void _logos_method$SpringBoard$CBRGradientView$setFrame$(_LOGOS_SELF_TYPE_NORMAL CBRGradientView* _LOGOS_SELF_CONST, SEL, CGRect); 



static SBLockScreenScrollView* _logos_method$SpringBoard$SBLockScreenScrollView$initWithFrame$(_LOGOS_SELF_TYPE_INIT SBLockScreenScrollView* __unused self, SEL __unused _cmd, CGRect frame) _LOGOS_RETURN_RETAINED {
    id original = _logos_orig$SpringBoard$SBLockScreenScrollView$initWithFrame$(self, _cmd, frame);
    
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





static void _logos_method$SpringBoard$XENScrollView$setDelegate$(_LOGOS_SELF_TYPE_NORMAL XENScrollView* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, id delegate) {
    
    if ([delegate isKindOfClass:[XENScrollViewController class]] && [XENResources enabled]) {
        _logos_orig$SpringBoard$XENScrollView$setDelegate$(self, _cmd, delegate);
    } else if (![XENResources enabled]) {
        _logos_orig$SpringBoard$XENScrollView$setDelegate$(self, _cmd, delegate);
    }
}

static void _logos_method$SpringBoard$XENScrollView$addSubview$(_LOGOS_SELF_TYPE_NORMAL XENScrollView* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, UIView* subview) {
    if ([XENResources enabled] && subview.tag != 12345) {
        [baseXenController addViewFromOriginalLockscreen:subview];
    } else {
        _logos_orig$SpringBoard$XENScrollView$addSubview$(self, _cmd, subview);
    }
}


static BOOL _logos_method$SpringBoard$XENScrollView$touchesShouldCancelInContentView$(_LOGOS_SELF_TYPE_NORMAL XENScrollView* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, UIView * view) {
    BOOL orig = _logos_orig$SpringBoard$XENScrollView$touchesShouldCancelInContentView$(self, _cmd, view);
    
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

static void _logos_method$SpringBoard$XENScrollView$setContentOffset$(_LOGOS_SELF_TYPE_NORMAL XENScrollView* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, CGFloat offset) {
    
    if (!dontAllowScrollViewOffsetChange && !dontScrollForLockPages)
        _logos_orig$SpringBoard$XENScrollView$setContentOffset$(self, _cmd, offset);
    
    dontScrollForLockPages = NO;
}





static void _logos_method$SpringBoard$SBLockScreenViewController$addChildViewController$(_LOGOS_SELF_TYPE_NORMAL SBLockScreenViewController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, UIViewController * childController) {
    if ([XENResources enabled]) {
        [(UIViewController*)[baseXenController homeViewController] addChildViewController:childController];
    } else {
        _logos_orig$SpringBoard$SBLockScreenViewController$addChildViewController$(self, _cmd, childController);
    }
}



#pragma mark Inject (iOS 10+)








static SBDashBoardViewController* _logos_method$SpringBoard$SBDashBoardViewController$initWithPageViewControllers$mainPageViewController$legibilityProvider$(_LOGOS_SELF_TYPE_INIT SBDashBoardViewController* __unused self, SEL __unused _cmd, NSArray* arg1, SBDashBoardPageViewController* arg2, id arg3) _LOGOS_RETURN_RETAINED {
    NSMutableArray *newArray = [NSMutableArray array];
    [newArray addObjectsFromArray:arg1];
    
    for (XENBaseViewController *contr in [XENResources availableViewControllers]) {
        XENDashBoardPageViewController *pageCont = [[objc_getClass("XENDashBoardPageViewController") alloc] init];
        pageCont.xenController = contr;
        
        [newArray addObject:pageCont];
    }
    
    id original = _logos_orig$SpringBoard$SBDashBoardViewController$initWithPageViewControllers$mainPageViewController$legibilityProvider$(self, _cmd, newArray, arg2, arg3);
    
    if (original) {
        [XENResources setLsViewController:original];
    
        
        [[NSNotificationCenter defaultCenter] addObserver:original
                                             selector:@selector(_updateLegibilitySettings)
                                                 name:@"XENWallpaperChanged"
                                               object:nil];
    }
    
    return original;
}

static void _logos_method$SpringBoard$SBDashBoardViewController$_setAllowedPageViewControllers$(_LOGOS_SELF_TYPE_NORMAL SBDashBoardViewController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, NSArray* controllers) {
    
    
    if ([XENResources enabled]) {
        XENlog(@"Arranging pages...");
        
        NSArray *originalOrder = controllers;
        NSMutableArray *newOrder = [NSMutableArray array];
        NSArray *enabled = [XENResources enabledControllerIdentifiers];
    
        for (NSString *identifier in enabled) {
            SBDashBoardPageViewController *controller = [self _xen_fetchWithIdentifier:identifier andArray:originalOrder];
            if (controller)
                [newOrder addObject:controller];
        
            
            if ([controller respondsToSelector:@selector(_xen_addViewIfNeeded)]) {
                [(XENDashBoardPageViewController*)controller _xen_addViewIfNeeded];
            }
        }
        
        
        
        _logos_orig$SpringBoard$SBDashBoardViewController$_setAllowedPageViewControllers$(self, _cmd, newOrder);
    } else {
        










        
        NSMutableArray *newOrder = [NSMutableArray array];
        for (id object in controllers) {
            if (![object isKindOfClass:objc_getClass("XENDashBoardPageViewController")]) {
                [newOrder addObject:object];
            }
        }
        
        
        
        
        
        
        NSMutableArray *finalOrder = [NSMutableArray array];
        NSArray *enabled = @[@"com.apple.today", @"com.apple.main", @"com.apple.camera"];
        
        for (NSString *identifier in enabled) {
            SBDashBoardPageViewController *controller = [self _xen_fetchWithIdentifier:identifier andArray:newOrder];
            if (controller)
                [finalOrder addObject:controller];
        }
        
        _logos_orig$SpringBoard$SBDashBoardViewController$_setAllowedPageViewControllers$(self, _cmd, finalOrder);
    }
}

static void _logos_method$SpringBoard$SBDashBoardViewController$loadView(_LOGOS_SELF_TYPE_NORMAL SBDashBoardViewController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    [XENResources reloadSettings];
    
    
    if ([XENResources enabled]) {
        XENlog(@"Injecting Xen UI");
        baseXenController = [[XENDashBoardViewController alloc] init];
        [baseXenController configureWithScrollView:nil];
        [baseXenController configureControllersForLock];
    }
    
    _logos_orig$SpringBoard$SBDashBoardViewController$loadView(self, _cmd);
}

static void _logos_method$SpringBoard$SBDashBoardViewController$viewWillAppear$(_LOGOS_SELF_TYPE_NORMAL SBDashBoardViewController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, _Bool arg1) {
    [XENResources reloadSettings];
    
    
    if (!baseXenController && [XENResources enabled]) {
        XENlog(@"Injecting Xen UI");
        baseXenController = [[XENDashBoardViewController alloc] init];
        [baseXenController configureWithScrollView:nil];
        [baseXenController configureControllersForLock];
    }
    
    _logos_orig$SpringBoard$SBDashBoardViewController$viewWillAppear$(self, _cmd, arg1);
}


static id _logos_method$SpringBoard$SBDashBoardViewController$_xen_fetchWithIdentifier$andArray$(_LOGOS_SELF_TYPE_NORMAL SBDashBoardViewController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, NSString* identifier, NSArray* array) {
    for (SBDashBoardPageViewController *controller in array) {
        if ([[controller _xen_identifier] isEqualToString:identifier])
            return controller;
    }
    
    return nil;
}






static void _logos_method$SpringBoard$SBLockScreenToAppsWorkspaceTransaction$_didComplete(_LOGOS_SELF_TYPE_NORMAL SBLockScreenToAppsWorkspaceTransaction* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    _logos_orig$SpringBoard$SBLockScreenToAppsWorkspaceTransaction$_didComplete(self, _cmd);
    
    if ([UIDevice currentDevice].systemVersion.floatValue >= 10) {
        XENlog(@"Unloading Xen UI");
        baseXenController = nil;
    
        [XENResources readyResourcesForNewLock];
    }
}



#pragma mark Give the Apple controllers an identifier. (iOS 10+)




static NSString* _logos_method$SpringBoard$SBDashBoardPageViewController$_xen_identifier(_LOGOS_SELF_TYPE_NORMAL SBDashBoardPageViewController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    return @"com.apple.BASE";
}


static NSString* _logos_method$SpringBoard$SBDashBoardPageViewController$_xen_name(_LOGOS_SELF_TYPE_NORMAL SBDashBoardPageViewController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    return @"BASE_VIEW";
}






static NSString* _logos_method$SpringBoard$SBDashBoardTodayPageViewController$_xen_identifier(_LOGOS_SELF_TYPE_NORMAL SBDashBoardTodayPageViewController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    return @"com.apple.today";
}


static NSString* _logos_method$SpringBoard$SBDashBoardTodayPageViewController$_xen_name(_LOGOS_SELF_TYPE_NORMAL SBDashBoardTodayPageViewController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    return [XENResources localisedStringForKey:@"NC Widgets" value:@"NC Widgets"];
}

static void _logos_method$SpringBoard$SBDashBoardTodayPageViewController$viewDidLayoutSubviews(_LOGOS_SELF_TYPE_NORMAL SBDashBoardTodayPageViewController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    _logos_orig$SpringBoard$SBDashBoardTodayPageViewController$viewDidLayoutSubviews(self, _cmd);
    
    BOOL enabled = [[XENResources enabledControllerIdentifiers] containsObject:[self _xen_identifier]];
    self.view.hidden = !enabled;
    self.view.userInteractionEnabled = enabled;
}






static NSString* _logos_method$SpringBoard$SBDashBoardCameraPageViewController$_xen_identifier(_LOGOS_SELF_TYPE_NORMAL SBDashBoardCameraPageViewController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    return @"com.apple.camera";
}


static NSString* _logos_method$SpringBoard$SBDashBoardCameraPageViewController$_xen_name(_LOGOS_SELF_TYPE_NORMAL SBDashBoardCameraPageViewController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    return [XENResources localisedStringForKey:@"Camera" value:@"Camera"];
}

static void _logos_method$SpringBoard$SBDashBoardCameraPageViewController$viewDidLayoutSubviews(_LOGOS_SELF_TYPE_NORMAL SBDashBoardCameraPageViewController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    _logos_orig$SpringBoard$SBDashBoardCameraPageViewController$viewDidLayoutSubviews(self, _cmd);
    
    BOOL enabled = [[XENResources enabledControllerIdentifiers] containsObject:[self _xen_identifier]];
    self.view.hidden = !enabled;
    self.view.userInteractionEnabled = enabled;
}


static void _logos_method$SpringBoard$SBDashBoardCameraPageViewController$aggregateAppearance$(_LOGOS_SELF_TYPE_NORMAL SBDashBoardCameraPageViewController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, SBDashBoardAppearance* arg1) {
    _logos_orig$SpringBoard$SBDashBoardCameraPageViewController$aggregateAppearance$(self, _cmd, arg1);
    
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







static NSString* _logos_method$SpringBoard$SBDashBoardMainPageViewController$_xen_identifier(_LOGOS_SELF_TYPE_NORMAL SBDashBoardMainPageViewController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    return @"com.apple.main";
}


static NSString* _logos_method$SpringBoard$SBDashBoardMainPageViewController$_xen_name(_LOGOS_SELF_TYPE_NORMAL SBDashBoardMainPageViewController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    return [XENResources localisedStringForKey:@"Unlock" value:@"Unlock"];
}

static void _logos_method$SpringBoard$SBDashBoardMainPageViewController$viewDidLayoutSubviews(_LOGOS_SELF_TYPE_NORMAL SBDashBoardMainPageViewController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    _logos_orig$SpringBoard$SBDashBoardMainPageViewController$viewDidLayoutSubviews(self, _cmd);
    
    baseXenController.homeViewController.view.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
    
    
    if (![[self.view.subviews lastObject] isEqual:baseXenController.homeViewController.view]) {
        XENlog(@"Placing Xen's Home controller to the top of Apple's Main controller.");
        [self.view addSubview:baseXenController.homeViewController.view];
    }
}



#pragma mark Runtime subclass for Xen's Page Views. (iOS 10+)



static char _logos_property_key$SpringBoard$XENDashBoardPageViewController$xenController;__attribute__((used)) static XENBaseViewController * _logos_method$SpringBoard$XENDashBoardPageViewController$xenController$(XENDashBoardPageViewController* __unused self, SEL __unused _cmd){ return objc_getAssociatedObject(self, &_logos_property_key$SpringBoard$XENDashBoardPageViewController$xenController); }__attribute__((used)) static void _logos_method$SpringBoard$XENDashBoardPageViewController$setXenController$(XENDashBoardPageViewController* __unused self, SEL __unused _cmd, XENBaseViewController * arg){ objc_setAssociatedObject(self, &_logos_property_key$SpringBoard$XENDashBoardPageViewController$xenController, arg, OBJC_ASSOCIATION_RETAIN_NONATOMIC); }
static char _logos_property_key$SpringBoard$XENDashBoardPageViewController$xenVisible;__attribute__((used)) static BOOL _logos_method$SpringBoard$XENDashBoardPageViewController$xenVisible$(XENDashBoardPageViewController* __unused self, SEL __unused _cmd){ return [objc_getAssociatedObject(self, &_logos_property_key$SpringBoard$XENDashBoardPageViewController$xenVisible) boolValue]; }__attribute__((used)) static void _logos_method$SpringBoard$XENDashBoardPageViewController$setXenVisible$(XENDashBoardPageViewController* __unused self, SEL __unused _cmd, BOOL arg){ objc_setAssociatedObject(self, &_logos_property_key$SpringBoard$XENDashBoardPageViewController$xenVisible, [NSNumber numberWithBool:arg], OBJC_ASSOCIATION_ASSIGN); }

static unsigned long long _logos_meta_method$SpringBoard$XENDashBoardPageViewController$requiredCapabilities(_LOGOS_SELF_TYPE_NORMAL Class _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    return 0;
}

static _Bool _logos_meta_method$SpringBoard$XENDashBoardPageViewController$isAvailableForConfiguration(_LOGOS_SELF_TYPE_NORMAL Class _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    return YES;
}

static void _logos_method$SpringBoard$XENDashBoardPageViewController$didTransitionToVisible$(_LOGOS_SELF_TYPE_NORMAL XENDashBoardPageViewController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, _Bool arg1) {
    if (arg1)
        [self.xenController willMoveToControllerAfterScrollingEnds];
    else
        [self.xenController movingToControllerWithPercent:0.0];
    
    self.xenVisible = arg1;
}

static void _logos_method$SpringBoard$XENDashBoardPageViewController$updateTransitionToVisible$progress$mode$(_LOGOS_SELF_TYPE_NORMAL XENDashBoardPageViewController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, _Bool arg1, double arg2, long long arg3) {    
    if (!arg1 && arg2 != 1.0 && !self.xenVisible) {
        
        
        
        return;
    }
    
    if (!arg1) arg2 = 1.0 - arg2; 
    [self.xenController movingToControllerWithPercent:arg2];
    
    
    if (arg1 && !self.xenController.view.superview) {
        [self.view addSubview:self.xenController.view];
    }
}


static void _logos_method$SpringBoard$XENDashBoardPageViewController$aggregateAppearance$(_LOGOS_SELF_TYPE_NORMAL XENDashBoardPageViewController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, SBDashBoardAppearance* arg1) {
    _logos_orig$SpringBoard$XENDashBoardPageViewController$aggregateAppearance$(self, _cmd, arg1);
    
    SBDashBoardComponent *dateView = [[objc_getClass("SBDashBoardComponent") dateView] hidden:YES];
    [arg1 addComponent:dateView];
    
    SBDashBoardComponent *pageControl = [[objc_getClass("SBDashBoardComponent") pageControl] hidden:YES];
    [arg1 addComponent:pageControl];
}

static void _logos_method$SpringBoard$XENDashBoardPageViewController$aggregateBehavior$(_LOGOS_SELF_TYPE_NORMAL XENDashBoardPageViewController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, SBDashBoardBehavior* arg1) {
    _logos_orig$SpringBoard$XENDashBoardPageViewController$aggregateBehavior$(self, _cmd, arg1);
    
    if ([arg1 respondsToSelector:@selector(setScrollingStrategy:)])
        arg1.scrollingStrategy = 3;
    else if ([arg1 respondsToSelector:@selector(setScrollingMode:)])
        arg1.scrollingMode = 3;
}


static void _logos_method$SpringBoard$XENDashBoardPageViewController$_xen_addViewIfNeeded(_LOGOS_SELF_TYPE_NORMAL XENDashBoardPageViewController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    [self.view addSubview:self.xenController.view];
}

static void _logos_method$SpringBoard$XENDashBoardPageViewController$loadView(_LOGOS_SELF_TYPE_NORMAL XENDashBoardPageViewController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    _logos_orig$SpringBoard$XENDashBoardPageViewController$loadView(self, _cmd);
    
    [self.view addSubview:self.xenController.view];
}

static void _logos_method$SpringBoard$XENDashBoardPageViewController$viewDidAppear$(_LOGOS_SELF_TYPE_NORMAL XENDashBoardPageViewController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, BOOL animated) {
    _logos_orig$SpringBoard$XENDashBoardPageViewController$viewDidAppear$(self, _cmd, animated);
    
    [self.xenController viewDidAppear:animated];
}

static void _logos_method$SpringBoard$XENDashBoardPageViewController$viewDidLoad(_LOGOS_SELF_TYPE_NORMAL XENDashBoardPageViewController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    _logos_orig$SpringBoard$XENDashBoardPageViewController$viewDidLoad(self, _cmd);
    
    [self.xenController viewDidLoad];
}

static void _logos_method$SpringBoard$XENDashBoardPageViewController$viewWillAppear$(_LOGOS_SELF_TYPE_NORMAL XENDashBoardPageViewController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, BOOL animated) {
    _logos_orig$SpringBoard$XENDashBoardPageViewController$viewWillAppear$(self, _cmd, animated);
    
    [self.xenController viewWillAppear:animated];
}

static void _logos_method$SpringBoard$XENDashBoardPageViewController$viewDidDisappear$(_LOGOS_SELF_TYPE_NORMAL XENDashBoardPageViewController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, BOOL animated) {
    _logos_orig$SpringBoard$XENDashBoardPageViewController$viewDidDisappear$(self, _cmd, animated);
    
    [self.xenController viewDidDisappear:animated];
}

static void _logos_method$SpringBoard$XENDashBoardPageViewController$viewDidLayoutSubviews(_LOGOS_SELF_TYPE_NORMAL XENDashBoardPageViewController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    _logos_orig$SpringBoard$XENDashBoardPageViewController$viewDidLayoutSubviews(self, _cmd);
    
    self.xenController.view.transform = CGAffineTransformIdentity;
    self.xenController.view.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
    
    BOOL enabled = [[XENResources enabledControllerIdentifiers] containsObject:[self.xenController uniqueIdentifier]];
    self.view.hidden = !enabled;
    self.view.userInteractionEnabled = enabled;
    self.view.clipsToBounds = YES;
}

static long long _logos_method$SpringBoard$XENDashBoardPageViewController$backgroundStyle(_LOGOS_SELF_TYPE_NORMAL XENDashBoardPageViewController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    







    
    return [self.xenController wantsBlurredBackground] ? 6 : 1;
}


static NSString* _logos_method$SpringBoard$XENDashBoardPageViewController$_xen_identifier(_LOGOS_SELF_TYPE_NORMAL XENDashBoardPageViewController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    return [self.xenController uniqueIdentifier];
}


static NSString* _logos_method$SpringBoard$XENDashBoardPageViewController$_xen_name(_LOGOS_SELF_TYPE_NORMAL XENDashBoardPageViewController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    return [self.xenController name];
}



#pragma mark Allow touches in the lockscreen clock region (iOS 10+, Activator)




static UIView * _logos_method$SpringBoard$SBFLockScreenDateView$hitTest$withEvent$(_LOGOS_SELF_TYPE_NORMAL SBFLockScreenDateView* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, CGPoint point, UIEvent * event) {
    if ([UIDevice currentDevice].systemVersion.floatValue >= 10 && [XENResources enabled]) {
        
        
        
        SBDashBoardViewController *cont = [XENResources lsViewController];
        if (![cont isKindOfClass:objc_getClass("SBDashBoardViewController")]) {
            return _logos_orig$SpringBoard$SBFLockScreenDateView$hitTest$withEvent$(self, _cmd, point, event);
        }
        
        if (cont.lastSettledPageIndex != [cont _indexOfMainPage]) {
            return nil;
        }
    }
    
    return _logos_orig$SpringBoard$SBFLockScreenDateView$hitTest$withEvent$(self, _cmd, point, event);
}



#pragma mark Allow an unlock to occur without Home button being clicked. (iOS 10+)

static BOOL maybeClickingHomeToUnlock = NO;







static _Bool _logos_method$SpringBoard$SBDashBoardViewController$canUIUnlockFromSource$(_LOGOS_SELF_TYPE_NORMAL SBDashBoardViewController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, int arg1) {
    BOOL orig = _logos_orig$SpringBoard$SBDashBoardViewController$canUIUnlockFromSource$(self, _cmd, arg1);
    
    if ([XENResources enabled] && (arg1 == 1337 || isLaunchpadLaunching)) {
            return YES;
    } else if ([XENResources enabled] && [XENResources slideToUnlockModeDirection] != 3 && maybeClickingHomeToUnlock) {
        




        
        
        return NO;
    }
    
    return orig;
}



#pragma mark Disable Press Home to Unlock if needed (iOS 10+)








static void _logos_method$SpringBoard$SBHomeHardwareButtonActions$performSinglePressUpActions(_LOGOS_SELF_TYPE_NORMAL SBHomeHardwareButtonActions* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    maybeClickingHomeToUnlock = YES;
    _logos_orig$SpringBoard$SBHomeHardwareButtonActions$performSinglePressUpActions(self, _cmd);
    maybeClickingHomeToUnlock = NO;
}










static unsigned long long _logos_method$SpringBoard$SBDashBoardHomeButtonShowPasscodeRecognizer$_state(_LOGOS_SELF_TYPE_NORMAL SBDashBoardHomeButtonShowPasscodeRecognizer* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    
    
    
    
    
    
    
    return _logos_orig$SpringBoard$SBDashBoardHomeButtonShowPasscodeRecognizer$_state(self, _cmd);
}



#pragma mark Prevent touches cancelling for things like the up arrow (iOS 10+)



static _Bool _logos_method$SpringBoard$SBHorizontalScrollFailureRecognizer$_isOutOfBounds$forAngle$(_LOGOS_SELF_TYPE_NORMAL SBHorizontalScrollFailureRecognizer* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, struct CGPoint arg1, double arg2) {
    return [XENResources enabled] ? NO : _logos_orig$SpringBoard$SBHorizontalScrollFailureRecognizer$_isOutOfBounds$forAngle$(self, _cmd, arg1, arg2);
}





static BOOL _logos_method$SpringBoard$SBPagedScrollView$touchesShouldCancelInContentView$(_LOGOS_SELF_TYPE_NORMAL SBPagedScrollView* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, UIView * view) {
    BOOL orig = _logos_orig$SpringBoard$SBPagedScrollView$touchesShouldCancelInContentView$(self, _cmd, view);
    
    if ([XENResources enabled] && [baseXenController isDraggingSlideUpArrow] && [XENResources slideToUnlockModeDirection] == 1) {
        return NO;
    }
    
    return orig;
}



#pragma mark Notify that locking has finished

@interface SpringBoard (Testing)
- (void)_publishFakeLockScreenNotificationsWithCount:(unsigned long long)arg1 completion:(id)arg2;
@end



static void _logos_method$SpringBoard$SBLockScreenManager$lockUIFromSource$withOptions$(_LOGOS_SELF_TYPE_NORMAL SBLockScreenManager* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, int source, id options) {
    isLaunchpadLaunching = NO;
    [XENResources hideContentEditWindow];
    
    _logos_orig$SpringBoard$SBLockScreenManager$lockUIFromSource$withOptions$(self, _cmd, source, options);
    
    XENlog(@"locking UI from source.");
    if ([XENResources enabled]) {
        [baseXenController postLockScreenInit];
        [baseXenController prepareForScreenUndim];
    }
}





static void _logos_method$SpringBoard$SBLockScreenView$layoutSubviews(_LOGOS_SELF_TYPE_NORMAL SBLockScreenView* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    dontAllowScrollViewOffsetChange = YES;
    _logos_orig$SpringBoard$SBLockScreenView$layoutSubviews(self, _cmd);
    dontAllowScrollViewOffsetChange = NO;

    if ([XENResources enabled]) {
        [baseXenController postLockScreenInit];
        [XENResources setLockscreenView:self];
        
        [self _xen_relayoutDateView];
    }
}

#pragma mark Relayout notifications UI (<= iOS 9)

static void _logos_method$SpringBoard$SBLockScreenView$_layoutNotificationView(_LOGOS_SELF_TYPE_NORMAL SBLockScreenView* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    _logos_orig$SpringBoard$SBLockScreenView$_layoutNotificationView(self, _cmd);
    
    if ([XENResources enabled])
        [baseXenController invalidateNotificationFrame];
}



#pragma mark Handle rotation! (<= iOS 9)



static void _logos_method$SpringBoard$SBLockScreenViewController$willRotateToInterfaceOrientation$duration$(_LOGOS_SELF_TYPE_NORMAL SBLockScreenViewController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, long long interfaceOrientation, double duration) {
    _logos_orig$SpringBoard$SBLockScreenViewController$willRotateToInterfaceOrientation$duration$(self, _cmd, interfaceOrientation, duration);
    
    if ([XENResources enabled]) {
        
        [baseXenController setUIMaskedForRotation:YES];
        
        [UIView animateWithDuration:duration animations:^{
            [baseXenController rotateToOrientation:(int)interfaceOrientation];
        }];
    }
}

static void _logos_method$SpringBoard$SBLockScreenViewController$didRotateFromInterfaceOrientation$(_LOGOS_SELF_TYPE_NORMAL SBLockScreenViewController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, long long arg1) {
    _logos_orig$SpringBoard$SBLockScreenViewController$didRotateFromInterfaceOrientation$(self, _cmd, arg1);
    
    if ([XENResources enabled]) {
        
        [baseXenController setUIMaskedForRotation:NO];
    }
}





static void _logos_method$SpringBoard$SBLockScreenView$resetContentOffsetToCurrentPage(_LOGOS_SELF_TYPE_NORMAL SBLockScreenView* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    if ([XENResources enabled]) {
        XENlog(@"resetContentOffsetToCurrentPage");
    } else {
        _logos_orig$SpringBoard$SBLockScreenView$resetContentOffsetToCurrentPage(self, _cmd);
    }
}



#pragma mark Handle rotation! (iOS 10+)



static void _logos_method$SpringBoard$SBDashBoardViewController$viewWillTransitionToSize$withTransitionCoordinator$(_LOGOS_SELF_TYPE_NORMAL SBDashBoardViewController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, CGSize size, id<UIViewControllerTransitionCoordinator> coordinator) {
    if ([XENResources enabled]) {
        [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
            
            
            
            int orientation = 1; 
            if (size.width == SCREEN_MAX_LENGTH) {
                orientation = 3;
            }
        
            [baseXenController rotateToOrientation:(int)orientation];
        } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        }];
    }
    
    _logos_orig$SpringBoard$SBDashBoardViewController$viewWillTransitionToSize$withTransitionCoordinator$(self, _cmd, size, coordinator);
}



#pragma mark Adjust notification view position on iPad when grouped. (<= iOS 9)



static UIEdgeInsets _logos_meta_method$SpringBoard$SBFLockScreenMetrics$notificationListInsets(_LOGOS_SELF_TYPE_NORMAL Class _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    UIEdgeInsets orig = _logos_meta_orig$SpringBoard$SBFLockScreenMetrics$notificationListInsets(self, _cmd);
    
    if ([XENResources enabled] && [XENResources useGroupedNotifications] && IS_IPAD && (orient3 > 2)) {
        orig.top += 20; 
    } else if ([XENResources enabled] && [XENResources useGroupedNotifications] && SCREEN_MAX_LENGTH <= 568) {
        orig.top += 20; 
    }
    
    return orig;
}



#pragma mark Adjust notification view position on iPad when grouped. (iOS 10+)







#pragma mark Adjust page control image for slide to unlock. (iOS 10+)



static void _logos_method$SpringBoard$SBDashBoardPageControl$_setIndicatorImage$toEnabled$index$(_LOGOS_SELF_TYPE_NORMAL SBDashBoardPageControl* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, _UILegibilityView* arg1, _Bool arg2, long long arg3) {
    if ([XENResources enabled]) {
        BOOL stul = [XENResources slideToUnlockModeDirection] == 0 && arg3 == 0;
        BOOL stur = [XENResources slideToUnlockModeDirection] == 2 && arg3 == self.numberOfPages-1;
        
        if (stul || stur) {
            UIImage *img = [self _xen_unlockIndicatorImage:arg2];
            [arg1 setImage:img shadowImage:nil];
            [arg1 sizeToFit];
            
            return;
        }
        
        
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
    
    _logos_orig$SpringBoard$SBDashBoardPageControl$_setIndicatorImage$toEnabled$index$(self, _cmd, arg1, arg2, arg3);
}


static id _logos_method$SpringBoard$SBDashBoardPageControl$_xen_unlockIndicatorImage$(_LOGOS_SELF_TYPE_NORMAL SBDashBoardPageControl* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, BOOL arg1) {
    
    
    
    UIImage *image = [XENResources themedImageWithName:@"PageControlUnlock"];
    UIColor *imageColor = nil;
    if (arg1) {
        imageColor = [self _currentPageIndicatorColor];
    } else {
        imageColor = [self _pageIndicatorColor];
    }
    
    return [image _flatImageWithColor:imageColor];
}



#pragma mark Fix issues with our scroll view caused by Apple (iOS 9.0 - 9.3)




static void _logos_method$SpringBoard$SBLockScreenView$_adjustTopAndBottomGrabbersForPercentScrolled$(_LOGOS_SELF_TYPE_NORMAL SBLockScreenView* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, CGFloat percentScrolled) {
    if (![XENResources enabled]) {
        _logos_orig$SpringBoard$SBLockScreenView$_adjustTopAndBottomGrabbersForPercentScrolled$(self, _cmd, percentScrolled);
    }
}

static void _logos_method$SpringBoard$SBLockScreenView$scrollViewDidEndDecelerating$(_LOGOS_SELF_TYPE_NORMAL SBLockScreenView* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, id scrollView) {
    if (![XENResources enabled]) _logos_orig$SpringBoard$SBLockScreenView$scrollViewDidEndDecelerating$(self, _cmd, scrollView);
}
static void _logos_method$SpringBoard$SBLockScreenView$scrollViewDidEndDragging$willDecelerate$(_LOGOS_SELF_TYPE_NORMAL SBLockScreenView* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, id scrollView, BOOL decelerate) {
    if (![XENResources enabled]) _logos_orig$SpringBoard$SBLockScreenView$scrollViewDidEndDragging$willDecelerate$(self, _cmd, scrollView, decelerate);
}
static void _logos_method$SpringBoard$SBLockScreenView$scrollViewDidEndScrollingAnimation$(_LOGOS_SELF_TYPE_NORMAL SBLockScreenView* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, id scrollView) {
    if (![XENResources enabled]) _logos_orig$SpringBoard$SBLockScreenView$scrollViewDidEndScrollingAnimation$(self, _cmd, scrollView);
}
static void _logos_method$SpringBoard$SBLockScreenView$scrollViewDidScroll$(_LOGOS_SELF_TYPE_NORMAL SBLockScreenView* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, id scrollView) {
    if (![XENResources enabled]) _logos_orig$SpringBoard$SBLockScreenView$scrollViewDidScroll$(self, _cmd, scrollView);
}
static void _logos_method$SpringBoard$SBLockScreenView$scrollViewWillBeginDragging$(_LOGOS_SELF_TYPE_NORMAL SBLockScreenView* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, id scrollView) {
    if (![XENResources enabled]) _logos_orig$SpringBoard$SBLockScreenView$scrollViewWillBeginDragging$(self, _cmd, scrollView);
}
static void _logos_method$SpringBoard$SBLockScreenView$scrollViewWillEndDragging$withVelocity$targetContentOffset$(_LOGOS_SELF_TYPE_NORMAL SBLockScreenView* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, id scrollView, CGPoint velocity, CGPoint * offset) {
    if (![XENResources enabled]) _logos_orig$SpringBoard$SBLockScreenView$scrollViewWillEndDragging$withVelocity$targetContentOffset$(self, _cmd, scrollView, velocity, offset);
}

static void _logos_method$SpringBoard$SBLockScreenView$_slideToUnlockFailureGestureRecognizerChanged(_LOGOS_SELF_TYPE_NORMAL SBLockScreenView* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    if (![XENResources enabled]) _logos_orig$SpringBoard$SBLockScreenView$_slideToUnlockFailureGestureRecognizerChanged(self, _cmd);
}





static BOOL _logos_method$SpringBoard$SBSlideToUnlockFailureRecognizer$_isOutOfBoundsVertically$(_LOGOS_SELF_TYPE_NORMAL SBSlideToUnlockFailureRecognizer* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, CGPoint boundsVertically) {
    BOOL orig = _logos_orig$SpringBoard$SBSlideToUnlockFailureRecognizer$_isOutOfBoundsVertically$(self, _cmd, boundsVertically);
    
    if ([XENResources enabled] && [baseXenController onHomePage]) {
        return NO;
    }
    
    return orig;
}






static BOOL _logos_method$SpringBoard$SBLockScreenViewController$isBounceEnabledForPresentingController$locationInWindow$(_LOGOS_SELF_TYPE_NORMAL SBLockScreenViewController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, id fp8, CGPoint fp12) {
    return ([XENResources enabled] ? NO : _logos_orig$SpringBoard$SBLockScreenViewController$isBounceEnabledForPresentingController$locationInWindow$(self, _cmd, fp8, fp12));
}






static void _logos_method$SpringBoard$SBLockScreenBounceAnimator$_handleTapGesture$(_LOGOS_SELF_TYPE_NORMAL SBLockScreenBounceAnimator* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, id arg1) {
    
    if (![XENResources enabled]) {
        _logos_orig$SpringBoard$SBLockScreenBounceAnimator$_handleTapGesture$(self, _cmd, arg1);
    }
}



#pragma mark Destroy UI on unlock (iOS 9.0 - 9.3)



static void _logos_method$SpringBoard$SBLockScreenViewController$_releaseLockScreenView(_LOGOS_SELF_TYPE_NORMAL SBLockScreenViewController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    _logos_orig$SpringBoard$SBLockScreenViewController$_releaseLockScreenView(self, _cmd);
    
    baseXenController = nil;
    
    [XENResources readyResourcesForNewLock];
    
    
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





static void _logos_method$SpringBoard$SBLockScreenManager$_finishUIUnlockFromSource$withOptions$(_LOGOS_SELF_TYPE_NORMAL SBLockScreenManager* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, int source, id options) {
    _logos_orig$SpringBoard$SBLockScreenManager$_finishUIUnlockFromSource$withOptions$(self, _cmd, source, options);
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:@"/tmp/com.matchstic.xen.reboot_flag"])
        [[NSFileManager defaultManager] createFileAtPath:@"/tmp/com.matchstic.xen.reboot_flag" contents:[NSData data] attributes:nil];
    
    if ([XENResources enabled]) {
        [baseXenController notifyUnlockWillBegin];
    }
}



#pragma mark Notify ourselves that the passcode cancel button was tapped (<= iOS 9)



static void _logos_method$SpringBoard$SBLockScreenViewController$passcodeLockViewCancelButtonPressed$(_LOGOS_SELF_TYPE_NORMAL SBLockScreenViewController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, id arg1) {
    _logos_orig$SpringBoard$SBLockScreenViewController$passcodeLockViewCancelButtonPressed$(self, _cmd, arg1);
    [baseXenController passcodeCancelButtonWasTapped];
}



#pragma mark Notify ourselves that the passcode cancel button was tapped (iOS 10+)



static void _logos_method$SpringBoard$SBDashBoardPasscodeViewController$passcodeLockViewCancelButtonPressed$(_LOGOS_SELF_TYPE_NORMAL SBDashBoardPasscodeViewController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, id arg1) {
    _logos_orig$SpringBoard$SBDashBoardPasscodeViewController$passcodeLockViewCancelButtonPressed$(self, _cmd, arg1);
    
    [baseXenController passcodeCancelButtonWasTapped];
}



#pragma mark Notify controllers that screen is now off, and begin proximity monitoring for Peek (<= iOS 9)



static void _logos_method$SpringBoard$SBLockScreenViewController$_handleDisplayTurnedOff(_LOGOS_SELF_TYPE_NORMAL SBLockScreenViewController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    _logos_orig$SpringBoard$SBLockScreenViewController$_handleDisplayTurnedOff(self, _cmd);
    
    XENlog(@"Handling display turned off.");
    [XENResources setScreenOnState:NO];
    
    if ([XENResources enabled])
        [baseXenController screenDidTurnOff];
    
#if USE_PEEK==1
    if ([XENResources peekEnabled] && [XENResources enabled]) {
        if ([XENResources peekMode] == 1) { 
            
            peekTimer = [NSTimer scheduledTimerWithTimeInterval:60.0 * [XENResources peekIntervalDuration] target:self selector:@selector(_xen_peekTimerDidFire:) userInfo:nil repeats:NO];
        }
        
        beginMonitoringProximity();
    }
#endif
}


static void _logos_method$SpringBoard$SBLockScreenViewController$_xen_peekTimerDidFire$(_LOGOS_SELF_TYPE_NORMAL SBLockScreenViewController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, id sender) {
    #if USE_PEEK==1
    
    shouldBeInPeekMode = NO;
    pauseMonitoring = YES;
    
    
    restoreLLSleep();
    
    if (accelHandler.isUpdating)
        [accelHandler pauseMonitoring];
    
    [peekTimer invalidate];
    peekTimer = nil;
    
    XENlog(@"We should have now finished that interval for Peek.");
    #endif
}



#pragma mark Notify controllers that screen is now off, and begin proximity monitoring for Peek (iOS 10+)























static void _logos_method$SpringBoard$SBDashBoardViewController$setInScreenOffMode$forAutoUnlock$(_LOGOS_SELF_TYPE_NORMAL SBDashBoardViewController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, _Bool arg1, _Bool arg2) {
    _logos_orig$SpringBoard$SBDashBoardViewController$setInScreenOffMode$forAutoUnlock$(self, _cmd, arg1, arg2);
    
    if (arg1) {
        
        [baseXenController screenDidTurnOff];
    } else {
        
    }
}



#pragma mark Remove camera from lockscreen (<= iOS 9)



static void _logos_method$SpringBoard$SBLockScreenViewController$_addCameraGrabberIfNecessary(_LOGOS_SELF_TYPE_NORMAL SBLockScreenViewController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    if (![XENResources enabled] || ![XENResources hideCameraGrabber]) {
        _logos_orig$SpringBoard$SBLockScreenViewController$_addCameraGrabberIfNecessary(self, _cmd);
    }
}



#pragma mark Remove STU view if necessary (<= iOS 9)



static void _logos_method$SpringBoard$SBLockScreenView$_layoutSlideToUnlockView(_LOGOS_SELF_TYPE_NORMAL SBLockScreenView* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    if (![XENResources enabled] || [XENResources useSlideToUnlockMode]) {
        _logos_orig$SpringBoard$SBLockScreenView$_layoutSlideToUnlockView(self, _cmd);
    } else if ([XENResources enabled] && ![XENResources useSlideToUnlockMode]) {
#if TARGET_IPHONE_SIMULATOR==0
        UIView *_stuView = MSHookIvar<UIView*>(self, "_slideToUnlockView");
        _stuView.frame = CGRectZero;
#endif
    }
}



#pragma mark Remove PHTU view if necessary (iOS 10+)



static void _logos_method$SpringBoard$SBUICallToActionLabel$setText$forLanguage$animated$(_LOGOS_SELF_TYPE_NORMAL SBUICallToActionLabel* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, id arg1, id arg2, BOOL arg3) {
    
    if ([XENResources enabled] && [XENResources slideToUnlockModeDirection] != 3) {
        if ([XENResources useSlideToUnlockMode]) {
            _logos_orig$SpringBoard$SBUICallToActionLabel$setText$forLanguage$animated$(self, _cmd, [XENResources localisedStringForKey:@"Slide to unlock" value:@"Slide to unlock"], arg2, arg3);
        } else {
            _logos_orig$SpringBoard$SBUICallToActionLabel$setText$forLanguage$animated$(self, _cmd, @"", arg2, arg3);
        }
    } else {
        _logos_orig$SpringBoard$SBUICallToActionLabel$setText$forLanguage$animated$(self, _cmd, arg1, arg2, arg3);
    }
}



#pragma mark Hide STU chevron for left/right mode (<= iOS 9)



static double _logos_method$SpringBoard$_UIGlintyStringView$_chevronWidthWithPadding(_LOGOS_SELF_TYPE_NORMAL _UIGlintyStringView* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    if ([XENResources enabled]) {
        return 0.0;
    } else {
        return _logos_orig$SpringBoard$_UIGlintyStringView$_chevronWidthWithPadding(self, _cmd);
    }
}

static int _logos_method$SpringBoard$_UIGlintyStringView$chevronStyle(_LOGOS_SELF_TYPE_NORMAL _UIGlintyStringView* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    return ([XENResources enabled]) ? 0 : _logos_orig$SpringBoard$_UIGlintyStringView$chevronStyle(self, _cmd);
}

static void _logos_method$SpringBoard$_UIGlintyStringView$setChevronStyle$(_LOGOS_SELF_TYPE_NORMAL _UIGlintyStringView* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, int style) {
    if ([XENResources enabled])
        style = 0;
        
    _logos_orig$SpringBoard$_UIGlintyStringView$setChevronStyle$(self, _cmd, style);
}

static double _logos_method$SpringBoard$_UIGlintyStringView$_chevronPadding(_LOGOS_SELF_TYPE_NORMAL _UIGlintyStringView* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    return ([XENResources enabled]) ? 0 : _logos_orig$SpringBoard$_UIGlintyStringView$_chevronPadding(self, _cmd);
}

static id _logos_method$SpringBoard$_UIGlintyStringView$_chevronImageForStyle$(_LOGOS_SELF_TYPE_NORMAL _UIGlintyStringView* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, long long arg1) {
    return ([XENResources enabled]) ? nil : _logos_orig$SpringBoard$_UIGlintyStringView$_chevronImageForStyle$(self, _cmd, arg1);
}

static CGRect _logos_method$SpringBoard$_UIGlintyStringView$chevronFrame(_LOGOS_SELF_TYPE_NORMAL _UIGlintyStringView* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    return ([XENResources enabled]) ? CGRectZero : _logos_orig$SpringBoard$_UIGlintyStringView$chevronFrame(self, _cmd);
}



#pragma mark Adjust original lockscreen blur (iOS 9.0 - 9.3)



static void _logos_method$SpringBoard$SBLockScreenView$_setCurrentBlurRadius$(_LOGOS_SELF_TYPE_NORMAL SBLockScreenView* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, CGFloat radius) {
    _logos_orig$SpringBoard$SBLockScreenView$_setCurrentBlurRadius$(self, _cmd, [XENResources enabled] ? 0.0 : radius);
}





static CGFloat _logos_method$SpringBoard$SBLockOverlayStyleProperties$tintAlpha(_LOGOS_SELF_TYPE_NORMAL SBLockOverlayStyleProperties* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    return [XENResources enabled] ? 0.0 : _logos_orig$SpringBoard$SBLockOverlayStyleProperties$tintAlpha(self, _cmd);
}



#pragma mark Same sized status bar (<= iOS 9)



static int _logos_method$SpringBoard$SBLockScreenViewController$statusBarStyle(_LOGOS_SELF_TYPE_NORMAL SBLockScreenViewController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    return [XENResources enabled] ? 0 : _logos_orig$SpringBoard$SBLockScreenViewController$statusBarStyle(self, _cmd);
}



#pragma mark Same sized status bar (iOS 10+)



static long long _logos_method$SpringBoard$SBDashBoardViewController$statusBarStyle(_LOGOS_SELF_TYPE_NORMAL SBDashBoardViewController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    return [XENResources enabled] ? 0 : _logos_orig$SpringBoard$SBDashBoardViewController$statusBarStyle(self, _cmd);
}



#pragma mark Prevent colour changes of UI when light wallpaper selected (<= iOS 9)



static id _logos_method$SpringBoard$SBLockScreenViewController$_effectiveLegibilitySettings(_LOGOS_SELF_TYPE_NORMAL SBLockScreenViewController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    return [XENResources enabled] ? [self _wallpaperLegibilitySettings] : _logos_orig$SpringBoard$SBLockScreenViewController$_effectiveLegibilitySettings(self, _cmd);
}

static void _logos_method$SpringBoard$SBLockScreenViewController$_updateLegibility(_LOGOS_SELF_TYPE_NORMAL SBLockScreenViewController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    _logos_orig$SpringBoard$SBLockScreenViewController$_updateLegibility(self, _cmd);
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"XENLegibibilityDidChange" object:nil];
}

static void _logos_method$SpringBoard$SBLockScreenViewController$wallpaperLegibilitySettingsDidChange$forVariant$(_LOGOS_SELF_TYPE_NORMAL SBLockScreenViewController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, id wallpaperLegibilitySettings, int variant) {
    _logos_orig$SpringBoard$SBLockScreenViewController$wallpaperLegibilitySettingsDidChange$forVariant$(self, _cmd, wallpaperLegibilitySettings, variant);
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"XENLegibibilityDidChange" object:nil];
}



#pragma mark Prevent colour changes of UI when light wallpaper selected (iOS 10+)



static void _logos_method$SpringBoard$SBDashBoardLegibilityProvider$wallpaperLegibilitySettingsDidChange$forVariant$(_LOGOS_SELF_TYPE_NORMAL SBDashBoardLegibilityProvider* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, id arg1, long long arg2) {
    _logos_orig$SpringBoard$SBDashBoardLegibilityProvider$wallpaperLegibilitySettingsDidChange$forVariant$(self, _cmd, arg1, arg2);
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"XENLegibibilityDidChange" object:nil];
}

static id _logos_method$SpringBoard$SBDashBoardLegibilityProvider$currentLegibilitySettings(_LOGOS_SELF_TYPE_NORMAL SBDashBoardLegibilityProvider* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    return [XENResources enabled] ? [self _wallpaperLegibilitySettings] : _logos_orig$SpringBoard$SBDashBoardLegibilityProvider$currentLegibilitySettings(self, _cmd);
}





static void _logos_method$SpringBoard$SBDashBoardViewController$_updateLegibilitySettings(_LOGOS_SELF_TYPE_NORMAL SBDashBoardViewController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    _logos_orig$SpringBoard$SBDashBoardViewController$_updateLegibilitySettings(self, _cmd);
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"XENLegibibilityDidChange" object:nil];
}



#pragma mark Legibility settings for fullscreen/combined artwork mode (<= iOS 9)



static SBLockScreenViewController* _logos_method$SpringBoard$SBLockScreenViewController$initWithNibName$bundle$(_LOGOS_SELF_TYPE_INIT SBLockScreenViewController* __unused self, SEL __unused _cmd, id nibName, id bundle) _LOGOS_RETURN_RETAINED {
    id orig = _logos_orig$SpringBoard$SBLockScreenViewController$initWithNibName$bundle$(self, _cmd, nibName, bundle);
    
    if (orig && [XENResources enabled]) {
        [[NSNotificationCenter defaultCenter] addObserver:orig
                                                 selector:@selector(_updateLegibility)
                                                     name:@"XENWallpaperChanged"
                                                   object:nil];
        [XENResources setLsViewController:self];
    }
    
    return orig;
}

static _UILegibilitySettings* _logos_method$SpringBoard$SBLockScreenViewController$_wallpaperLegibilitySettings(_LOGOS_SELF_TYPE_NORMAL SBLockScreenViewController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    if ([XENResources enabled] && peekIsVisble) {
        _UILegibilitySettings *settings = [[objc_getClass("_UILegibilitySettings") alloc] initWithContentColor:[UIColor blackColor] contrast:0.5];
        return settings;
    }
    
    if ([XENResources enabled] && [baseXenController.musicFullscreenController hasArtwork]) {
        
        UIColor *colour = [baseXenController.musicFullscreenController averageArtworkColour];
        
        _UILegibilitySettings *settings = [[objc_getClass("_UILegibilitySettings") alloc] initWithContentColor:colour contrast:0.3];
        
        return settings;
    } else {
        return _logos_orig$SpringBoard$SBLockScreenViewController$_wallpaperLegibilitySettings(self, _cmd);
    }
}



#pragma mark Legibility settings for fullscreen/combined artwork mode (iOS 10+) (Needs verification)



static id _logos_method$SpringBoard$SBDashBoardLegibilityProvider$_wallpaperLegibilitySettings(_LOGOS_SELF_TYPE_NORMAL SBDashBoardLegibilityProvider* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    if ([XENResources enabled] && peekIsVisble) {
        _UILegibilitySettings *settings = [[objc_getClass("_UILegibilitySettings") alloc] initWithContentColor:[UIColor blackColor] contrast:0.5];
        return settings;
    }
    
    if ([XENResources enabled] && [baseXenController.musicFullscreenController hasArtwork]) {
        
        UIColor *colour = [baseXenController.musicFullscreenController averageArtworkColour];
        
        _UILegibilitySettings *settings = [[objc_getClass("_UILegibilitySettings") alloc] initWithContentColor:colour contrast:0.3];
        
        return settings;
    } else {
        return _logos_orig$SpringBoard$SBDashBoardLegibilityProvider$_wallpaperLegibilitySettings(self, _cmd);
    }
}



#pragma mark Notification cell styling (<= iOS 9)

@interface SBLockScreenNotificationCell (EH)
-(void)_xen_addBlurIfNecessary;
@end



static SBLockScreenNotificationCell* _logos_method$SpringBoard$SBLockScreenNotificationCell$initWithStyle$reuseIdentifier$(_LOGOS_SELF_TYPE_INIT SBLockScreenNotificationCell* __unused self, SEL __unused _cmd, int style, id identifier) _LOGOS_RETURN_RETAINED {
    SBLockScreenNotificationCell *orig = _logos_orig$SpringBoard$SBLockScreenNotificationCell$initWithStyle$reuseIdentifier$(self, _cmd, style, identifier);
    
    [orig _xen_addBlurIfNecessary];
    
    if ([XENResources enabled]) {
        
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


static void _logos_method$SpringBoard$SBLockScreenNotificationCell$_xen_addBlurIfNecessary(_LOGOS_SELF_TYPE_NORMAL SBLockScreenNotificationCell* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
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

static void _logos_method$SpringBoard$SBLockScreenNotificationCell$setContentAlpha$(_LOGOS_SELF_TYPE_NORMAL SBLockScreenNotificationCell* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, CGFloat alpha) {
    if ([XENResources enabled] && [XENResources useGroupedNotifications]) {
        
        _logos_orig$SpringBoard$SBLockScreenNotificationCell$setContentAlpha$(self, _cmd, 1.0);
    } else {
        _logos_orig$SpringBoard$SBLockScreenNotificationCell$setContentAlpha$(self, _cmd, alpha);
    }
}

static void _logos_method$SpringBoard$SBLockScreenNotificationCell$setAlpha$(_LOGOS_SELF_TYPE_NORMAL SBLockScreenNotificationCell* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, CGFloat alpha) {
    if ([XENResources enabled] && [XENResources useGroupedNotifications]) {
        
        BOOL prev = self.layer.allowsGroupOpacity;
        self.layer.allowsGroupOpacity = NO;
        _logos_orig$SpringBoard$SBLockScreenNotificationCell$setAlpha$(self, _cmd, 1.0);
        self.layer.allowsGroupOpacity = prev;
    } else {
        _logos_orig$SpringBoard$SBLockScreenNotificationCell$setAlpha$(self, _cmd, alpha);
    }
}

static void _logos_method$SpringBoard$SBLockScreenNotificationCell$layoutSubviews(_LOGOS_SELF_TYPE_NORMAL SBLockScreenNotificationCell* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    _logos_orig$SpringBoard$SBLockScreenNotificationCell$layoutSubviews(self, _cmd);
    
    if ([XENResources enabled]) {
        
        self.iconView.hidden = [XENResources useGroupedNotifications] && ![XENResources usingWatchNotificationsCompatibilityMode] ? YES : NO;
        
        
        self.contentScrollView.scrollEnabled = NO;
        
        
    
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
                
                
                [backdrop.contentView insertSubview:colorBanner atIndex:0];
            } else {
                
                
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
        
        
        if (![XENResources useGroupedNotifications] && [XENResources useXENNotificationUI]) {
            self.iconView.center = CGPointMake((self.realContentView.frame.size.width * 0.05) + 20, (backdrop.frame.size.height / 2) + 5);
        }
    }
}

static id _logos_method$SpringBoard$SBLockScreenNotificationCell$_vibrantTextColor(_LOGOS_SELF_TYPE_NORMAL SBLockScreenNotificationCell* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    return ([XENResources enabled] && [XENResources useXENNotificationUI]) ? [UIColor whiteColor] : _logos_orig$SpringBoard$SBLockScreenNotificationCell$_vibrantTextColor(self, _cmd);
}


static UILabel* _logos_method$SpringBoard$SBLockScreenNotificationCell$XENUnlockTextLabel(_LOGOS_SELF_TYPE_NORMAL SBLockScreenNotificationCell* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
#if TARGET_IPHONE_SIMULATOR==1
    return nil;
#else
    return MSHookIvar<UILabel*>(self, "_unlockTextLabel");
#endif
}


static void _logos_method$SpringBoard$SBLockScreenNotificationCell$fireOffTappedEventToDelegate$(_LOGOS_SELF_TYPE_NORMAL SBLockScreenNotificationCell* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, UITapGestureRecognizer* sender) {
    [self.delegate handleActionFromTappedCellWithContext:self.lockScreenActionContext];
}


static void _logos_method$SpringBoard$SBLockScreenNotificationCell$handleLongPressGesture$(_LOGOS_SELF_TYPE_NORMAL SBLockScreenNotificationCell* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, UIGestureRecognizer* gesture) {
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


static BOOL _logos_method$SpringBoard$SBLockScreenNotificationCell$gestureRecognizer$shouldRecognizeSimultaneouslyWithGestureRecognizer$(_LOGOS_SELF_TYPE_NORMAL SBLockScreenNotificationCell* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, UIGestureRecognizer * gestureRecognizer, UIGestureRecognizer * otherGestureRecognizer) {
    if ([[otherGestureRecognizer class] isKindOfClass:[UITapGestureRecognizer class]]) {
        return YES;
    }
    
    return YES;
}


static BOOL _logos_method$SpringBoard$SBLockScreenNotificationCell$gestureRecognizerShouldBegin$(_LOGOS_SELF_TYPE_NORMAL SBLockScreenNotificationCell* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, UIGestureRecognizer * gestureRecognizer) {
    return YES;
}


static BOOL _logos_method$SpringBoard$SBLockScreenNotificationCell$gestureRecognizer$shouldReceiveTouch$(_LOGOS_SELF_TYPE_NORMAL SBLockScreenNotificationCell* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, UIGestureRecognizer * gestureRecognizer, UITouch * touch) {
    return YES;
}





static SBLockScreenNotificationListView* _logos_method$SpringBoard$SBLockScreenNotificationListView$initWithFrame$(_LOGOS_SELF_TYPE_INIT SBLockScreenNotificationListView* __unused self, SEL __unused _cmd, struct CGRect frame) _LOGOS_RETURN_RETAINED {
    self = _logos_orig$SpringBoard$SBLockScreenNotificationListView$initWithFrame$(self, _cmd, frame);

    if ([XENResources enabled] && [XENResources useXENNotificationUI]) {
#if TARGET_IPHONE_SIMULATOR==0
        UITableView *notificationsTableView = MSHookIvar<UITableView*>(self, "_tableView");
        notificationsTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
#endif
    }
    
    return self;
}

static SBLockScreenNotificationCell* _logos_method$SpringBoard$SBLockScreenNotificationListView$tableView$cellForRowAtIndexPath$(_LOGOS_SELF_TYPE_NORMAL SBLockScreenNotificationListView* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, UITableView* view, NSIndexPath* indexPath) {
    SBLockScreenNotificationCell *cell = _logos_orig$SpringBoard$SBLockScreenNotificationListView$tableView$cellForRowAtIndexPath$(self, _cmd, view, indexPath);
    
    if ([XENResources enabled]) {
        

        NSString *originalText = [cell XENUnlockTextLabel].text;
        
        if ((originalText && ![originalText isEqualToString:@""]) || [XENResources useXENNotificationUI])
            [cell _updateUnlockText:[XENResources tapToOpenTextForBundleIdentifier:[self XENBundleIdentifierForIndexPath:indexPath]]];
    }
    
    return cell;
}


static void _logos_method$SpringBoard$SBLockScreenNotificationListView$_xen_reloadSeparatorStyleForSetup(_LOGOS_SELF_TYPE_NORMAL SBLockScreenNotificationListView* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
#if TARGET_IPHONE_SIMULATOR==0
    UITableView *notificationsTableView = MSHookIvar<UITableView*>(self, "_tableView");
    if ([XENResources useXENNotificationUI])
        notificationsTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    else
        notificationsTableView.separatorStyle = 1;
#endif
}





static CGFloat _logos_meta_method$SpringBoard$SBLockScreenNotificationCell$rowHeightForTitle$subtitle$body$maxLines$attachmentSize$secondaryContentSize$datesVisible$rowWidth$includeUnlockActionText$(_LOGOS_SELF_TYPE_NORMAL Class _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, id title, id subtitle, id body, unsigned lines, CGSize size, CGSize size6, BOOL visible, CGFloat width, BOOL text) {
    if ([XENResources enabled] && [XENResources useXENNotificationUI]) {
        width *= 0.9;
        width -= 14; 
        
        return _logos_meta_orig$SpringBoard$SBLockScreenNotificationCell$rowHeightForTitle$subtitle$body$maxLines$attachmentSize$secondaryContentSize$datesVisible$rowWidth$includeUnlockActionText$(self, _cmd, title, subtitle, body, lines, size, size6, visible, width, YES);
    } else {
        return _logos_meta_orig$SpringBoard$SBLockScreenNotificationCell$rowHeightForTitle$subtitle$body$maxLines$attachmentSize$secondaryContentSize$datesVisible$rowWidth$includeUnlockActionText$(self, _cmd, title, subtitle, body, lines, size, size6, visible, width, text);
    }
}

static void _logos_method$SpringBoard$SBLockScreenNotificationCell$_updateUnlockText$(_LOGOS_SELF_TYPE_NORMAL SBLockScreenNotificationCell* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, NSString* text) {
    if ([XENResources enabled] && [XENResources useXENNotificationUI] && ([text isEqualToString:@""] || !text)) {
        
    } else {
        _logos_orig$SpringBoard$SBLockScreenNotificationCell$_updateUnlockText$(self, _cmd, text);
    }
}





static CGFloat _logos_meta_method$SpringBoard$SBLockScreenBulletinCell$rowHeightForTitle$subtitle$body$maxLines$attachmentSize$secondaryContentSize$datesVisible$rowWidth$includeUnlockActionText$(_LOGOS_SELF_TYPE_NORMAL Class _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, id title, id subtitle, id body, unsigned lines, CGSize size, CGSize size6, BOOL visible, CGFloat width, BOOL text) {
    if ([XENResources enabled] && [XENResources useXENNotificationUI]) {
        width *= 0.9;
        width -= 14; 
        
        return _logos_meta_orig$SpringBoard$SBLockScreenBulletinCell$rowHeightForTitle$subtitle$body$maxLines$attachmentSize$secondaryContentSize$datesVisible$rowWidth$includeUnlockActionText$(self, _cmd, title, subtitle, body, lines, size, size6, visible, width, YES);
    } else {
        return _logos_meta_orig$SpringBoard$SBLockScreenBulletinCell$rowHeightForTitle$subtitle$body$maxLines$attachmentSize$secondaryContentSize$datesVisible$rowWidth$includeUnlockActionText$(self, _cmd, title, subtitle, body, lines, size, size6, visible, width, text);
    }
}

static void _logos_method$SpringBoard$SBLockScreenBulletinCell$_updateUnlockText$(_LOGOS_SELF_TYPE_NORMAL SBLockScreenBulletinCell* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, NSString* text) {
    if ([XENResources enabled] && [XENResources useXENNotificationUI] && ([text isEqualToString:@""] || !text)) {
        
    } else {
        _logos_orig$SpringBoard$SBLockScreenBulletinCell$_updateUnlockText$(self, _cmd, text);
    }
}







static void _logos_method$SpringBoard$SBTableViewCellActionButton$setBackgroundColor$withBlendMode$(_LOGOS_SELF_TYPE_NORMAL SBTableViewCellActionButton* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, id color, int blendMode) {
    if (![XENResources enabled]) {
        _logos_orig$SpringBoard$SBTableViewCellActionButton$setBackgroundColor$withBlendMode$(self, _cmd, color, blendMode);
    } else {
        _logos_orig$SpringBoard$SBTableViewCellActionButton$setBackgroundColor$withBlendMode$(self, _cmd, color, ([XENResources blurBehindNotifications] ? blendMode : 0));
    }
    
}



#pragma mark Notification cell styling (iOS 10+) (TODO)













#pragma mark Sorting out shizzle for grouping of notifications (<= iOS 9)



static CGFloat _logos_method$SpringBoard$SBLockScreenNotificationListView$tableView$heightForRowAtIndexPath$(_LOGOS_SELF_TYPE_NORMAL SBLockScreenNotificationListView* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, UITableView* tableView, NSIndexPath* indexPath) {
    if ([XENResources enabled]) {
        
        if ([XENResources useGroupedNotifications]) {
            if ([XENResources usingPriorityHubCompatiblityMode]) {
                
                CGFloat original = _logos_orig$SpringBoard$SBLockScreenNotificationListView$tableView$heightForRowAtIndexPath$(self, _cmd, tableView, indexPath);
                return original == 0 ? 0 : _logos_orig$SpringBoard$SBLockScreenNotificationListView$tableView$heightForRowAtIndexPath$(self, _cmd, tableView, indexPath) + ([XENResources useXENNotificationUI] ? 10 : 0);
            } else {
                
                return [self XENShouldShowIndexPath:indexPath] ? _logos_orig$SpringBoard$SBLockScreenNotificationListView$tableView$heightForRowAtIndexPath$(self, _cmd, tableView, indexPath) + ([XENResources useXENNotificationUI] ? 10 : 0) : 0;
            }
        } else {
            
            return _logos_orig$SpringBoard$SBLockScreenNotificationListView$tableView$heightForRowAtIndexPath$(self, _cmd, tableView, indexPath) + ([XENResources useXENNotificationUI] ? 10 : 0);
        }
    } else {
        return _logos_orig$SpringBoard$SBLockScreenNotificationListView$tableView$heightForRowAtIndexPath$(self, _cmd, tableView, indexPath);
    }
}


static NSString* _logos_method$SpringBoard$SBLockScreenNotificationListView$XENBundleIdentifierForIndexPath$(_LOGOS_SELF_TYPE_NORMAL SBLockScreenNotificationListView* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, NSIndexPath* indexPath) {
#if TARGET_IPHONE_SIMULATOR==0
    SBAwayListItem *listItem = [MSHookIvar<id>(self, "_model") listItemAtIndexPath:indexPath];

    return [XENResources identifierForListItem:listItem];
#else
    return nil;
#endif
}


static BOOL _logos_method$SpringBoard$SBLockScreenNotificationListView$XENShouldShowIndexPath$(_LOGOS_SELF_TYPE_NORMAL SBLockScreenNotificationListView* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, NSIndexPath* indexPath) {
    NSString *bundleIdentifier = [self XENBundleIdentifierForIndexPath:indexPath];
    return [bundleIdentifier isEqualToString:[XENResources currentlyShownNotificationAppIdentifier]];
}



#pragma mark Sorting out grouping of notifications (iOS 10+) (TODO)












static CGSize _logos_method$SpringBoard$NCNotificationPriorityListViewController$collectionView$layout$sizeForItemAtIndexPath$(_LOGOS_SELF_TYPE_NORMAL NCNotificationPriorityListViewController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, UICollectionView * collectionView, UICollectionViewLayout * collectionViewLayout, NSIndexPath * indexPath) {
    
    CGSize size = _logos_orig$SpringBoard$NCNotificationPriorityListViewController$collectionView$layout$sizeForItemAtIndexPath$(self, _cmd, collectionView, collectionViewLayout, indexPath);
    
    if ([XENResources enabled]) {
        
        if ([XENResources useGroupedNotifications]) {
            if ([XENResources usingPriorityHubCompatiblityMode]) {
                
                size.height = size.height == 0 ? 0 : [self _xen_heightForCurrentCellStyling:size.height];
            } else {
                
                size.height = [self _xen_shouldShowIndexPath:indexPath] ? [self _xen_heightForCurrentCellStyling:size.height] : 0;
            }
        } else {
            
            size.height = [self _xen_heightForCurrentCellStyling:size.height];
        }
    }
    
    return size;
}


static CGFloat _logos_method$SpringBoard$NCNotificationPriorityListViewController$_xen_heightForCurrentCellStyling$(_LOGOS_SELF_TYPE_NORMAL NCNotificationPriorityListViewController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, CGFloat defaultHeight) {
    


    
    
    
    return defaultHeight;
}


static NSString* _logos_method$SpringBoard$NCNotificationPriorityListViewController$_xen_bundleIdentifierForIndexPath$(_LOGOS_SELF_TYPE_NORMAL NCNotificationPriorityListViewController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, NSIndexPath* indexPath) {
    NCNotificationRequest *listItem = [self.notificationRequestList requestAtIndex:indexPath.item];
    return [XENResources identifierForListItem:listItem];
}


static BOOL _logos_method$SpringBoard$NCNotificationPriorityListViewController$_xen_shouldShowIndexPath$(_LOGOS_SELF_TYPE_NORMAL NCNotificationPriorityListViewController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, NSIndexPath* indexPath) {
    NSString *bundleIdentifier = [self _xen_bundleIdentifierForIndexPath:indexPath];
    return [bundleIdentifier isEqualToString:[XENResources currentlyShownNotificationAppIdentifier]];
}



#pragma mark Notifications hooks for our collection view (<= iOS 9)




static void _logos_method$SpringBoard$SBLockScreenNotificationListController$_updateModelAndViewForAdditionOfItem$(_LOGOS_SELF_TYPE_NORMAL SBLockScreenNotificationListController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, SBAwayListItem* item) {
    _logos_orig$SpringBoard$SBLockScreenNotificationListController$_updateModelAndViewForAdditionOfItem$(self, _cmd, item);
    
    if ([XENResources enabled]) {
        NSString *appID = [XENResources identifierForListItem:item];
        
        [XENResources cacheNotificationForListItem:item];
            
        [baseXenController.homeViewController updateNotificationsViewWithBundleIdentifier:appID];
    }
}

static void _logos_method$SpringBoard$SBLockScreenNotificationListController$_updateModelForRemovalOfItem$updateView$(_LOGOS_SELF_TYPE_NORMAL SBLockScreenNotificationListController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, SBAwayListItem* item, BOOL update) {
    _logos_orig$SpringBoard$SBLockScreenNotificationListController$_updateModelForRemovalOfItem$updateView$(self, _cmd, item, update);

    if ([XENResources enabled]) {
        NSString *appID = [XENResources identifierForListItem:item];
                    
        [baseXenController.homeViewController removeBundleIdentfierFromNotificationsView:appID];
    }
}


static NSArray* _logos_method$SpringBoard$SBLockScreenNotificationListController$_xen_listItems(_LOGOS_SELF_TYPE_NORMAL SBLockScreenNotificationListController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
#if TARGET_IPHONE_SIMULATOR==0
    return MSHookIvar<NSMutableArray*>(self, "_listItems");
#else
    return [NSArray array];
#endif
}





static void _logos_method$SpringBoard$SBLockScreenNotificationListView$layoutSubviews(_LOGOS_SELF_TYPE_NORMAL SBLockScreenNotificationListView* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    _logos_orig$SpringBoard$SBLockScreenNotificationListView$layoutSubviews(self, _cmd);
    
    if ([XENResources enabled])
        [XENResources setNotificationListView:self];
}



#pragma mark Notifications hooks for our collection view (iOS 10+) (Needs verification)



static unsigned long long _logos_method$SpringBoard$NCNotificationPriorityList$insertNotificationRequest$(_LOGOS_SELF_TYPE_NORMAL NCNotificationPriorityList* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, NCNotificationRequest* request) {
    if ([XENResources enabled]) {
        XENlog(@"GOT REQUEST! %@", request);
        
        NSString *appID = [XENResources identifierForListItem:request];
        
        [XENResources cacheNotificationForListItem:request];
        
        [baseXenController.homeViewController updateNotificationsViewWithBundleIdentifier:appID];
    }
    
    return _logos_orig$SpringBoard$NCNotificationPriorityList$insertNotificationRequest$(self, _cmd, request);
}

static unsigned long long _logos_method$SpringBoard$NCNotificationPriorityList$removeNotificationRequest$(_LOGOS_SELF_TYPE_NORMAL NCNotificationPriorityList* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, NCNotificationRequest* request) {
    if ([XENResources enabled]) {
        NSString *appID = [XENResources identifierForListItem:request];
        
        [baseXenController.homeViewController removeBundleIdentfierFromNotificationsView:appID];
    }
    
    return _logos_orig$SpringBoard$NCNotificationPriorityList$removeNotificationRequest$(self, _cmd, request);
}



#pragma mark Prevent scaling bug on notification list view (<= iOS 9) (Needed on iOS 10?)




static void _logos_method$SpringBoard$SBLockScreenNotificationListView$setFrame$(_LOGOS_SELF_TYPE_NORMAL SBLockScreenNotificationListView* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, CGRect frame) {
    CGFloat transform = self.transform.a;
    
    if (transform != 1.0) {
        self.bounds = frame;
    } else {
        _logos_orig$SpringBoard$SBLockScreenNotificationListView$setFrame$(self, _cmd, frame);
    }
}

static BOOL _logos_method$SpringBoard$SBLockScreenNotificationListView$hidden(_LOGOS_SELF_TYPE_NORMAL SBLockScreenNotificationListView* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    if ([XENResources enabled] && [XENResources useGroupedNotifications] && ![XENResources usingPriorityHubCompatiblityMode]) {
        return ([XENResources currentlyShownNotificationAppIdentifier] == nil || [[XENResources currentlyShownNotificationAppIdentifier] isEqualToString:@""]);
    } else {
        return _logos_orig$SpringBoard$SBLockScreenNotificationListView$hidden(self, _cmd);
    }
}

static void _logos_method$SpringBoard$SBLockScreenNotificationListView$setHidden$(_LOGOS_SELF_TYPE_NORMAL SBLockScreenNotificationListView* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, BOOL hidden) {
    if ([XENResources enabled] && [XENResources useGroupedNotifications] && ![XENResources usingPriorityHubCompatiblityMode] && ([XENResources currentlyShownNotificationAppIdentifier] == nil || [[XENResources currentlyShownNotificationAppIdentifier] isEqualToString:@""])) {
        _logos_orig$SpringBoard$SBLockScreenNotificationListView$setHidden$(self, _cmd, YES);
    } else {
        _logos_orig$SpringBoard$SBLockScreenNotificationListView$setHidden$(self, _cmd, hidden);
    }
}



#pragma mark Fix being unable to tap things like notifications (iOS 9.2 - 9.3)







static void _logos_method$SpringBoard$SBLockScreenViewController$_addDeviceInformationTextView(_LOGOS_SELF_TYPE_NORMAL SBLockScreenViewController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    _logos_orig$SpringBoard$SBLockScreenViewController$_addDeviceInformationTextView(self, _cmd);
    
    
#if TARGET_IPHONE_SIMULATOR==0
    UIViewController *infoViewController = MSHookIvar<UIViewController*>(self, "_deviceInformationTextViewController");
    infoViewController.view.userInteractionEnabled = NO;
#endif
}



#pragma mark Clock postion when grouped notifications are enabled (<= iOS 9)



static void _logos_method$SpringBoard$SBFLockScreenDateView$setFrame$(_LOGOS_SELF_TYPE_NORMAL SBFLockScreenDateView* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, CGRect original) {
    if ([XENResources enabled] && [XENResources useGroupedNotifications] && ![XENResources usingPriorityHubCompatiblityMode]) {
        
        
        
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
            
            original.origin.y -= [XENResources calculateAdditionalOffsetForDateView:self withCurrentOffset:[self timeBaselineOffsetFromOrigin]];
        }
    }
    
    _logos_orig$SpringBoard$SBFLockScreenDateView$setFrame$(self, _cmd, original);
}





static void _logos_method$SpringBoard$SBLockScreenBatteryChargingView$setFrame$(_LOGOS_SELF_TYPE_NORMAL SBLockScreenBatteryChargingView* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, CGRect original) {
    if ([XENResources enabled] && [XENResources useGroupedNotifications] && ![XENResources usingPriorityHubCompatiblityMode]) {
        
        original.origin.y -= [XENResources calculateAdditionalOffsetForDateView:nil withCurrentOffset:0.0];
    }
    
    _logos_orig$SpringBoard$SBLockScreenBatteryChargingView$setFrame$(self, _cmd, original);
}



#pragma mark Clock postion when grouped notifications are enabled (iOS 10+) (TODO)








#pragma mark Allow tapping of cell (<= iOS 9)




static void _logos_method$SpringBoard$SBLockScreenNotificationListView$handleActionFromTappedCellWithContext$(_LOGOS_SELF_TYPE_NORMAL SBLockScreenNotificationListView* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, id context) {
    [self.delegate handleLockScreenActionWithContext:context];
}





static void _logos_method$SpringBoard$SBLockScreenNotificationTableView$setAllowsSelection$(_LOGOS_SELF_TYPE_NORMAL SBLockScreenNotificationTableView* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, BOOL orig) {
    _logos_orig$SpringBoard$SBLockScreenNotificationTableView$setAllowsSelection$(self, _cmd, [XENResources enabled] ? YES : orig);
}



#pragma mark Allow tapping of cell (iOS 10+) (TODO)






#pragma mark Plugin view handling (iOS 9.0 - 9.3)



static void _logos_method$SpringBoard$SBLockScreenView$setPluginView$presentationStyle$notificationBehavior$(_LOGOS_SELF_TYPE_NORMAL SBLockScreenView* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, UIView* arg1, unsigned int arg2, unsigned int arg3) {
    _logos_orig$SpringBoard$SBLockScreenView$setPluginView$presentationStyle$notificationBehavior$(self, _cmd, arg1, arg2, arg3);
    
    
    
    XENlog(@"Inserting plugin view %@", arg1);
    if ([XENResources enabled]) {
        
        
        
        
        if ([[arg1 class] isEqual:[objc_getClass("_NowPlayingArtView") class]]) {
            
        } else if ([[arg1 class] isEqual:[objc_getClass("WebCydgetLockScreenView") class]]) {
            
        } else {
            [baseXenController.homeViewController addPluginViewToView:arg1];
        }
    }
}



#pragma mark Fullscreen bulletin handling (<= iOS 9)



static void _logos_method$SpringBoard$SBSystemLocalNotificationAlert$willDeactivateForReason$(_LOGOS_SELF_TYPE_NORMAL SBSystemLocalNotificationAlert* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, int arg1) {
    _logos_orig$SpringBoard$SBSystemLocalNotificationAlert$willDeactivateForReason$(self, _cmd, arg1);
    
    if ([XENResources enabled]) {
        [baseXenController.homeViewController removeFullscreenBulletin];
    }
}





static void _logos_method$SpringBoard$SBLockScreenFullscreenBulletinViewController$setBulletinItem$(_LOGOS_SELF_TYPE_NORMAL SBLockScreenFullscreenBulletinViewController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, id item) {
    _logos_orig$SpringBoard$SBLockScreenFullscreenBulletinViewController$setBulletinItem$(self, _cmd, item);
    
    if ([XENResources enabled]) {
        [baseXenController.homeViewController addFullscreenBulletinWithNotification:self title:nil andSubtitle:nil];
    }
}

static void _logos_method$SpringBoard$SBLockScreenFullscreenBulletinViewController$performSnoozeAction(_LOGOS_SELF_TYPE_NORMAL SBLockScreenFullscreenBulletinViewController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    _logos_orig$SpringBoard$SBLockScreenFullscreenBulletinViewController$performSnoozeAction(self, _cmd);
    
    if ([XENResources enabled]) {
        [baseXenController.homeViewController removeFullscreenBulletin];
    }
}

static void _logos_method$SpringBoard$SBLockScreenFullscreenBulletinViewController$performDismissAction(_LOGOS_SELF_TYPE_NORMAL SBLockScreenFullscreenBulletinViewController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    _logos_orig$SpringBoard$SBLockScreenFullscreenBulletinViewController$performDismissAction(self, _cmd);
    
    if ([XENResources enabled]) {
        [baseXenController.homeViewController removeFullscreenBulletin];
    }
}

static void _logos_method$SpringBoard$SBLockScreenFullscreenBulletinViewController$lockButtonPressed$(_LOGOS_SELF_TYPE_NORMAL SBLockScreenFullscreenBulletinViewController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, id arg1) {
    _logos_orig$SpringBoard$SBLockScreenFullscreenBulletinViewController$lockButtonPressed$(self, _cmd, arg1);
    
    if ([XENResources enabled]) {
        [baseXenController.homeViewController removeFullscreenBulletin];
    }
}

static void _logos_method$SpringBoard$SBLockScreenFullscreenBulletinViewController$viewDidAppear$(_LOGOS_SELF_TYPE_NORMAL SBLockScreenFullscreenBulletinViewController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, BOOL view) {
    _logos_orig$SpringBoard$SBLockScreenFullscreenBulletinViewController$viewDidAppear$(self, _cmd, view);
    
    if ([XENResources enabled]) {
        self.view.hidden = YES;
    }
}



#pragma mark Fullscreen bulletin handling (iOS 10+) (TODO)

#pragma mark Move to passcode view when appropriate (<= iOS 9)



static void _logos_method$SpringBoard$SBLockScreenView$scrollToPage$animated$completion$(_LOGOS_SELF_TYPE_NORMAL SBLockScreenView* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, int page, BOOL animated, id completion) {
    XENlog(@"Trying to scroll to page %d, with completion", page);
    
    if (peekIsVisble && [XENResources peekEnabled] && [XENResources enabled]) {
        
        return;
    }
    
    int adjustedPage = page;
    if ([self respondsToSelector:@selector(lockScreenPageForPageNumber:)] && page == [self lockScreenPageForPageNumber:0])
        adjustedPage = 0;
    else if ([self respondsToSelector:@selector(lockScreenPageForPageNumber:)] && page == [self lockScreenPageForPageNumber:1])
        adjustedPage = 1;
    
    if ([XENResources enabled] && adjustedPage == 0) {
        [baseXenController.homeViewController scrollToPage:adjustedPage completion:nil];
        
        
        if (![XENResources useSlideToUnlockMode]) {
            [baseXenController moveToHomeController:YES];
        }
        
        [completion invoke];
    } else if ([XENResources enabled] && adjustedPage == 1) {
        
        _logos_orig$SpringBoard$SBLockScreenView$scrollToPage$animated$completion$(self, _cmd, page, animated, completion);
        
        [baseXenController moveToHomeController:NO];
    } else {
        _logos_orig$SpringBoard$SBLockScreenView$scrollToPage$animated$completion$(self, _cmd, page, animated, completion);
    }
}



#pragma mark Move to passcode view when appropriate (iOS 10+)



static void _logos_method$SpringBoard$SBDashBoardViewController$setPasscodeLockVisible$animated$completion$(_LOGOS_SELF_TYPE_NORMAL SBDashBoardViewController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, _Bool arg1, _Bool arg2, id arg3) {
    XENlog(@"Trying to set passcode visible: %d, with completion", arg1);
    
    if (peekIsVisble && [XENResources peekEnabled] && [XENResources enabled]) {
        
        return;
    }
    
    if ([XENResources enabled] && [XENResources useSlideToUnlockMode]) {
        






        
        if (arg1) {
            [baseXenController.homeViewController scrollToPage:0 completion:nil];
        
            
            if (![XENResources useSlideToUnlockMode]) {
                [baseXenController moveToHomeController:arg2];
            }
        }
        
        
        
        [arg3 invoke];
    } else if ([XENResources enabled] && ![XENResources useSlideToUnlockMode] && [XENResources slideToUnlockModeDirection] != 3) {
        




        
        if (![XENResources isSlideUpPasscodeVisible]) {
            _logos_orig$SpringBoard$SBDashBoardViewController$setPasscodeLockVisible$animated$completion$(self, _cmd, arg1, arg2, arg3);
        }
    } else {
        

















        _logos_orig$SpringBoard$SBDashBoardViewController$setPasscodeLockVisible$animated$completion$(self, _cmd, arg1, arg2, arg3);
    }
}





static void _logos_method$SpringBoard$SBFUserAuthenticationController$_setSecureMode$postNotification$(_LOGOS_SELF_TYPE_NORMAL SBFUserAuthenticationController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, bool arg1, bool arg2) {
    _logos_orig$SpringBoard$SBFUserAuthenticationController$_setSecureMode$postNotification$(self, _cmd, arg1, arg2);
    
    if ([UIDevice currentDevice].systemVersion.floatValue >= 10.0 && [XENResources enabled] && [XENResources slideToUnlockModeDirection] != 3) {
        
        if (arg1 && ![XENResources isPasscodeLocked]) {
            
            [baseXenController.homeViewController addPasscodeViewiOS10];
        }
    }
    
    [XENResources setIsPasscodeLocked:arg1];
}






static SBUIPasscodeLockViewBase* _logos_method$SpringBoard$SBDashBoardPasscodeViewController$_xen_passcodeLockView(_LOGOS_SELF_TYPE_NORMAL SBDashBoardPasscodeViewController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
#if TARGET_IPHONE_SIMULATOR==0
    return MSHookIvar<SBUIPasscodeLockViewBase*>(self, "_passcodeLockView");
#else
    return nil;
#endif
}


static UIView* _logos_method$SpringBoard$SBDashBoardPasscodeViewController$_xen_backgroundView(_LOGOS_SELF_TYPE_NORMAL SBDashBoardPasscodeViewController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
#if TARGET_IPHONE_SIMULATOR==0
    return MSHookIvar<SBUIPasscodeLockViewBase*>(self, "_backgroundView");
#else
    return nil;
#endif
}



#pragma mark Force resting authentication for Touch ID when needed (iOS 10+)



static BOOL _logos_method$SpringBoard$SBDashBoardMesaUnlockBehaviorConfiguration$_isAccessibilityRestingUnlockPreferenceEnabled(_LOGOS_SELF_TYPE_NORMAL SBDashBoardMesaUnlockBehaviorConfiguration* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    [XENResources reloadSettings];
    if ([XENResources enabled] && [XENResources slideToUnlockModeDirection] != 3) {
        return YES;
    }
    
    return _logos_orig$SpringBoard$SBDashBoardMesaUnlockBehaviorConfiguration$_isAccessibilityRestingUnlockPreferenceEnabled(self, _cmd);
}



#pragma mark Bounce up slider on failed Touch ID (<= iOS 9)



static void _logos_method$SpringBoard$SBLockScreenManager$biometricEventMonitor$handleBiometricEvent$(_LOGOS_SELF_TYPE_NORMAL SBLockScreenManager* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, id monitor, unsigned event) {
    if (event == 9 && [XENResources enabled]) {
        
        [baseXenController moveToHomeController:YES];
        [baseXenController.homeViewController bounce];
        
        if (peekIsVisble && [XENResources peekEnabled] && [XENResources enabled] && !lastProximityState) {
            [(SpringBoard*)[UIApplication sharedApplication] _xen_hidePeekUIWithEvent:kPeekEventOther];
        }
    } else if (event == 10 && [XENResources enabled]) {
        
        
        [baseXenController moveToHomeController:YES];
        [baseXenController.homeViewController bounce];
        
        if (peekIsVisble && [XENResources peekEnabled] && [XENResources enabled] && !lastProximityState) {
            [(SpringBoard*)[UIApplication sharedApplication] _xen_hidePeekUIWithEvent:kPeekEventOther];
        }
    }
    
    _logos_orig$SpringBoard$SBLockScreenManager$biometricEventMonitor$handleBiometricEvent$(self, _cmd, monitor, event);
}



#pragma mark Bounce up slider on failed Touch ID (iOS 10+)



static void _logos_method$SpringBoard$SBDashBoardViewController$handleBiometricEvent$(_LOGOS_SELF_TYPE_NORMAL SBDashBoardViewController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, unsigned long long event) {
    if (event == 9 && [XENResources enabled]) {
        XENlog(@"Failed to match finger (9)");
        [baseXenController moveToHomeController:YES];
        [baseXenController.homeViewController bounce];
        
        if (peekIsVisble && [XENResources peekEnabled] && [XENResources enabled] && !lastProximityState) {
            [(SpringBoard*)[UIApplication sharedApplication] _xen_hidePeekUIWithEvent:kPeekEventOther];
        }
    } else if (event == 10 && [XENResources enabled]) {
        
        XENlog(@"Failed to match finger (10)");
        [baseXenController moveToHomeController:YES];
        [baseXenController.homeViewController bounce];
        
        if (peekIsVisble && [XENResources peekEnabled] && [XENResources enabled] && !lastProximityState) {
            [(SpringBoard*)[UIApplication sharedApplication] _xen_hidePeekUIWithEvent:kPeekEventOther];
        }
    } else if ([XENResources enabled]) {
        XENlog(@"Recieved biometric event: %d", event);
    }
    
    _logos_orig$SpringBoard$SBDashBoardViewController$handleBiometricEvent$(self, _cmd, event);
}



#pragma mark Subclass for launching Launchpad apps (iOS 9+)



static BOOL _logos_method$SpringBoard$XENShortcutModule$isRestricted(_LOGOS_SELF_TYPE_NORMAL XENShortcutModule* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    return [XENResources requirePasscodeForLaunchpad];
}

static void _logos_method$SpringBoard$XENShortcutModule$activateAppWithDisplayID$url$(_LOGOS_SELF_TYPE_NORMAL XENShortcutModule* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, id displayID, id url) {
    isLaunchpadLaunching = YES;
    _logos_orig$SpringBoard$XENShortcutModule$activateAppWithDisplayID$url$(self, _cmd, displayID, url);
}


static void _logos_method$SpringBoard$XENShortcutModule$activateAppWithDisplayID$url$unlockIfNecessary$(_LOGOS_SELF_TYPE_NORMAL XENShortcutModule* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, id displayID, id url, bool arg3) {
    isLaunchpadLaunching = YES;
    
    SBControlCenterSystemAgent *agent = [[objc_getClass("SBControlCenterSystemAgent") alloc] init];
    [agent activateAppWithDisplayID:displayID url:url unlockIfNecessary:arg3];
}



#pragma mark Override activation settings for apps on Launchpad (iOS 9+)



static BOOL _logos_method$SpringBoard$SBApplication$boolForActivationSetting$(_LOGOS_SELF_TYPE_NORMAL SBApplication* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, unsigned activationSetting) {
    BOOL orig = _logos_orig$SpringBoard$SBApplication$boolForActivationSetting$(self, _cmd, activationSetting);
    
    if (isLaunchpadLaunching && [XENResources enabled] && [UIDevice currentDevice].systemVersion.floatValue < 10.0) {
        
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






static void _logos_method$SpringBoard$SBWorkspaceTransaction$_performDeviceCoherencyCheck(_LOGOS_SELF_TYPE_NORMAL SBWorkspaceTransaction* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    if (![XENResources enabled]) {
        _logos_orig$SpringBoard$SBWorkspaceTransaction$_performDeviceCoherencyCheck(self, _cmd);
        return;
    }
    
    if (!isLaunchpadLaunching && [XENResources enabled]) {
        _logos_orig$SpringBoard$SBWorkspaceTransaction$_performDeviceCoherencyCheck(self, _cmd);
    }
}





static void _logos_method$SpringBoard$SBAlertToAppsWorkspaceTransaction$_performDeviceCoherencyCheck(_LOGOS_SELF_TYPE_NORMAL SBAlertToAppsWorkspaceTransaction* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    if (![XENResources enabled]) {
        _logos_orig$SpringBoard$SBAlertToAppsWorkspaceTransaction$_performDeviceCoherencyCheck(self, _cmd);
        return;
    }
    
    if (!isLaunchpadLaunching && [XENResources enabled]) {
        _logos_orig$SpringBoard$SBAlertToAppsWorkspaceTransaction$_performDeviceCoherencyCheck(self, _cmd);
    }
}






static _Bool _logos_method$SpringBoard$SBMainWorkspace$_preflightTransitionRequest$(_LOGOS_SELF_TYPE_NORMAL SBMainWorkspace* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, id arg1) {
    if (isLaunchpadLaunching && [XENResources enabled] && [UIDevice currentDevice].systemVersion.floatValue >= 10.0) {
        
        return YES;
    }
    
    return _logos_orig$SpringBoard$SBMainWorkspace$_preflightTransitionRequest$(self, _cmd, arg1);
}



#pragma mark Correct view controller for UIAlertController in Launchpad Quick Dialer. (iOS 9+)



static id _logos_method$SpringBoard$CNContactGridViewController$viewControllerForActionsView$(_LOGOS_SELF_TYPE_NORMAL CNContactGridViewController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, id arg1) {
    
    if (self.view.superview.tag == 1337) {
        
        return [XENResources lsViewController];
    } else {
        return _logos_orig$SpringBoard$CNContactGridViewController$viewControllerForActionsView$(self, _cmd, arg1);
    }
}



#pragma mark Avoid assert() calls for Quick Dialer. (iOS 9+)







static void _logos_method$SpringBoard$CNContact$assertKeyIsAvailable$(_LOGOS_SELF_TYPE_NORMAL CNContact* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, id arg1) {
    if (!baseXenController && ![XENResources isLoadedInEditMode]) {
        _logos_orig$SpringBoard$CNContact$assertKeyIsAvailable$(self, _cmd, arg1);
    }
}

static void _logos_method$SpringBoard$CNContact$assertKeysAreAvailable$(_LOGOS_SELF_TYPE_NORMAL CNContact* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, id arg1) {
    if (!baseXenController && ![XENResources isLoadedInEditMode]) {
        _logos_orig$SpringBoard$CNContact$assertKeysAreAvailable$(self, _cmd, arg1);
    }
}



#pragma mark Handle passcode etc for Quick Dialer. (iOS 9+)









static void _logos_method$SpringBoard$CNPropertyAction$performActionForItem$sender$(_LOGOS_SELF_TYPE_NORMAL CNPropertyAction* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, id arg1, id arg2) {
    if (baseXenController) {
        [XENResources setShouldOverrideNextURLLaunch:YES];
    }
    
    _logos_orig$SpringBoard$CNPropertyAction$performActionForItem$sender$(self, _cmd, arg1, arg2);
}





static void _logos_method$SpringBoard$CNPropertySendMessageAction$performActionForItem$sender$(_LOGOS_SELF_TYPE_NORMAL CNPropertySendMessageAction* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, id arg1, id arg2) {
    if (baseXenController) {
        [XENResources setShouldOverrideNextURLLaunch:YES];
    }
    
    _logos_orig$SpringBoard$CNPropertySendMessageAction$performActionForItem$sender$(self, _cmd, arg1, arg2);
}





static void _logos_method$SpringBoard$CNPropertyFaceTimeAction$performActionForItem$sender$(_LOGOS_SELF_TYPE_NORMAL CNPropertyFaceTimeAction* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, id arg1, id arg2) {
    if (baseXenController) {
        [XENResources setShouldOverrideNextURLLaunch:YES];
    }
    
    _logos_orig$SpringBoard$CNPropertyFaceTimeAction$performActionForItem$sender$(self, _cmd, arg1, arg2);
}





static BOOL _logos_method$SpringBoard$SpringBoard$openURL$(_LOGOS_SELF_TYPE_NORMAL SpringBoard* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, id arg1) {
    if (baseXenController && [XENResources shouldOverrideNextURLLaunch]) {
        [XENResources setShouldOverrideNextURLLaunch:NO];
        
        [XENResources openURLWithPasscodeIfNeeded:arg1];
        return YES;
    } else {
        [XENResources setShouldOverrideNextURLLaunch:NO];
        return _logos_orig$SpringBoard$SpringBoard$openURL$(self, _cmd, arg1);
    }
}





static BOOL _logos_method$SpringBoard$LSApplicationWorkspace$openURL$withOptions$(_LOGOS_SELF_TYPE_NORMAL LSApplicationWorkspace* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, id arg1, id arg2) {
    if (baseXenController && [XENResources shouldOverrideNextURLLaunch]) {
        [XENResources setShouldOverrideNextURLLaunch:NO];
        
        [XENResources openURLWithPasscodeIfNeeded:arg1];
        return YES;
    } else {
        [XENResources setShouldOverrideNextURLLaunch:NO];
        return _logos_orig$SpringBoard$LSApplicationWorkspace$openURL$withOptions$(self, _cmd, arg1, arg2);
    }
}



#pragma mark "Peek" at current time, and notifications.





























































#include "IOHIDEventSystem.h"

typedef uint32_t IOPMAssertionID;
enum {
    kIOPMAssertionLevelOff = 0,
    kIOPMAssertionLevelOn = 255
};
typedef uint32_t IOPMAssertionLevel;
IOReturn (*IOPMAssertionCreateWithName)(CFStringRef, IOPMAssertionLevel, CFStringRef, IOPMAssertionID*);
IOReturn (*IOPMAssertionRelease)(IOPMAssertionID);



static Class _logos_method$SpringBoard$SBPluginManager$loadPluginBundle$(_LOGOS_SELF_TYPE_NORMAL SBPluginManager* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, NSBundle* bundle) {
#if USE_PEEK==1
    if ([[bundle bundleIdentifier] isEqualToString:@"com.apple.mobilephone.incomingcall"] && [bundle isLoaded] && peekIsVisble && [XENResources peekEnabled] && [XENResources enabled]) {
        XENlog(@"We should hide the UI for Peek this screen on event (incoming call).");
        [(SpringBoard*)[UIApplication sharedApplication] _xen_hidePeekUIWithEvent:kPeekEventOther];
    }
#endif
    
    return _logos_orig$SpringBoard$SBPluginManager$loadPluginBundle$(self, _cmd, bundle);
}
               




static void _logos_method$SpringBoard$SBLockScreenNotificationListController$turnOnScreenIfNecessaryForItem$withCompletion$(_LOGOS_SELF_TYPE_NORMAL SBLockScreenNotificationListController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, id arg1, void (^completion)(void)) {
#if USE_PEEK==1
    if (shouldBeInPeekMode && lastProximityState && [XENResources peekEnabled] && [XENResources enabled]) {
        completion();
        return;
    }
#endif
    
    _logos_orig$SpringBoard$SBLockScreenNotificationListController$turnOnScreenIfNecessaryForItem$withCompletion$(self, _cmd, arg1, completion);
}





static void _logos_method$SpringBoard$SBLockScreenViewController$_handleDisplayTurnedOnWhileUILocked$(_LOGOS_SELF_TYPE_NORMAL SBLockScreenViewController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, id locked) {
    XENlog(@"Handle display turned on: %@", locked);
    [XENResources setScreenOnState:YES];
    
    [baseXenController makeDamnSureThatHomeIsInMiddleBeforeScreenOn];
    
    _logos_orig$SpringBoard$SBLockScreenViewController$_handleDisplayTurnedOnWhileUILocked$(self, _cmd, locked);
    
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

static void _logos_method$SpringBoard$SBLockScreenViewController$_setMediaControlsVisible$(_LOGOS_SELF_TYPE_NORMAL SBLockScreenViewController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, BOOL visible) {
#if USE_PEEK==1
    if ([XENResources enabled]) {
        if ((peekIsVisble && visible && [XENResources peekEnabled]) || (!peekIsVisble || ![XENResources peekEnabled])) _logos_orig$SpringBoard$SBLockScreenViewController$_setMediaControlsVisible$(self, _cmd, visible);
    } else {
        _logos_orig$SpringBoard$SBLockScreenViewController$_setMediaControlsVisible$(self, _cmd, visible);
    }
#elif USE_PEEK==0
    _logos_orig$SpringBoard$SBLockScreenViewController$_setMediaControlsVisible$(self, _cmd, visible);
#endif
}

static void _logos_method$SpringBoard$SBLockScreenViewController$handleMenuButtonTap(_LOGOS_SELF_TYPE_NORMAL SBLockScreenViewController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
#if USE_PEEK==1
    if (peekIsVisble && [XENResources peekEnabled] && [XENResources enabled]) {
        XENlog(@"Menu button was pressed. If in Peek mode, we should hide it.");
        [(SpringBoard*)[UIApplication sharedApplication] _xen_hidePeekUIWithEvent:kPeekEventButtonPress];
    } else {
        _logos_orig$SpringBoard$SBLockScreenViewController$handleMenuButtonTap(self, _cmd);
    }
#elif USE_PEEK==0
    _logos_orig$SpringBoard$SBLockScreenViewController$handleMenuButtonTap(self, _cmd);
#endif
}





static BOOL _logos_method$SpringBoard$SpringBoard$_handlePhysicalButtonEvent$(_LOGOS_SELF_TYPE_NORMAL SpringBoard* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, UIPhysicalButtonsEvent* arg1) {
    if ([[NSFileManager defaultManager] fileExistsAtPath:@"/Library/MobileSubstrate/DynamicLibraries/LockPages.dylib"])
        dontScrollForLockPages = YES;
    
#if USE_PEEK==1
    if (peekIsVisble && [XENResources peekEnabled] && [XENResources enabled]) {
        





        
        XENlog(@"A physical button (%llu) was pressed. If in Peek mode, we should hide it.", arg1._triggeringPhysicalButton.type);
        
        if (arg1._triggeringPhysicalButton.type != 104) {
            [self _xen_hidePeekUIWithEvent:kPeekEventButtonPress];
            return (arg1._triggeringPhysicalButton.type == 101 ? YES : _logos_orig$SpringBoard$SpringBoard$_handlePhysicalButtonEvent$(self, _cmd, arg1)); 
        }
    }
#endif
    
    return _logos_orig$SpringBoard$SpringBoard$_handlePhysicalButtonEvent$(self, _cmd, arg1);
}

static void _logos_method$SpringBoard$SpringBoard$setStatusBarHidden$withAnimation$(_LOGOS_SELF_TYPE_NORMAL SpringBoard* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, BOOL arg1, long long arg2) {
#if USE_PEEK==1
    if (peekIsVisble && ![XENResources peekShowStatusBar] && [XENResources peekEnabled] && [XENResources enabled]) {
        _logos_orig$SpringBoard$SpringBoard$setStatusBarHidden$withAnimation$(self, _cmd, YES, arg2);
    } else {
        _logos_orig$SpringBoard$SpringBoard$setStatusBarHidden$withAnimation$(self, _cmd, arg1, arg2);
    }
#elif USE_PEEK==0
    _logos_orig$SpringBoard$SpringBoard$setStatusBarHidden$withAnimation$(self, _cmd, arg1, arg2);
#endif
}


static void _logos_method$SpringBoard$SpringBoard$_xen_showPeekUI(_LOGOS_SELF_TYPE_NORMAL SpringBoard* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
#if USE_PEEK==1
    
    if (lastProximityState) {
        
        return;
    } else if ((time(NULL) - lastProximityTimestamp) < 1.5) {
        
        return;
    }
    
    
    if ([XENResources peekShowDarkUI]) {
        XENlog(@"Showing peek UI");
        
        peekIsVisble = YES;
    
        if (shouldBeInPeekMode)
            [baseXenController.homeViewController initialisePeekInterfaceIfEnabled];
    } else {
        XENlog(@"Showing lockscreen directly.");
    }
    
    
    shouldBeInPeekMode = NO;
    restoreLLSleep();
    
    
    pauseMonitoring = YES;
    [accelHandler pauseMonitoring];
    
    
    [XENResources turnOnDisplay];
    [XENResources resetLockscreenDimTimer];
    
    [peekTimer invalidate];
    peekTimer = nil;
#endif
}


static void _logos_method$SpringBoard$SpringBoard$_xen_hidePeekUIWithEvent$(_LOGOS_SELF_TYPE_NORMAL SpringBoard* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, XENPeekEvent event) {
#if USE_PEEK==1
    XENlog(@"Hiding peek UI");
    
    
    pauseMonitoring = YES;
    if (accelHandler.isUpdating)
        [accelHandler pauseMonitoring];
    
    shouldBeInPeekMode = NO;
    peekIsVisble = NO;
    
    [baseXenController.homeViewController hidePeekInterfaceForEvent:event];
#endif
}





static void _logos_method$SpringBoard$SBAlertWindow$sendEvent$(_LOGOS_SELF_TYPE_NORMAL SBAlertWindow* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, UIEvent * event) {
    
    
    UITouch *touch = [event.allTouches anyObject];
    if (touch.phase == UITouchPhaseBegan) {
        [XENResources cancelLockscreenDimTimer];
    } else if (touch.phase == UITouchPhaseEnded || touch.phase == UITouchPhaseCancelled) {
        [XENResources resetLockscreenDimTimer];
        lastTouchTime = time(NULL);
    }
    
    _logos_orig$SpringBoard$SBAlertWindow$sendEvent$(self, _cmd, event);
}



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
    
    
    lastProximityState = NO;
    lastProximityTimestamp = time(NULL);
    
    shouldBeInPeekMode = YES;
    peekIsVisble = NO;
    
    
    pauseMonitoring = NO;
    [accelHandler pauseMonitoring];
    accelHandler = nil;
    accelHandler = [[XENAccelerometerHandler alloc] initWithThreshold:[XENResources peekSensitivity]];
    
    




    [accelHandler startMonitoringWithCallback:^{
        if (!pauseMonitoring) {
            [(SpringBoard*)[UIApplication sharedApplication] _xen_showPeekUI];
        } else if (!baseXenController) {
            [accelHandler pauseMonitoring];
        }
    }];
    
    
    [baseXenController.homeViewController hidePeekInterfaceForEvent:kPeekEventOther];
    
    
    
    notify_post("com.matchstic.xen/enableProx");
    
    disableLLSleep();
#endif
}

static void endMonitoringProximity() {
#if USE_PEEK==1
    
    
    notify_post("com.matchstic.xen/disableProx");
#endif
}





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
    
    [[_logos_static_class_lookup$BKProximitySensorInterface() sharedInstance] disableProximityDetection];
    [[_logos_static_class_lookup$BKProximitySensorInterface() sharedInstance] setPocketTouchesExpected:NO];
#endif
}

static void enableProximityMonitoring(CFNotificationCenterRef center, void *observer, CFStringRef name,
                                       const void *object,CFDictionaryRef userInfo) {
#if USE_PEEK==1
    XENlog(@"Enabling proximity monitoring...");
    
    






    
    if ([[_logos_static_class_lookup$BKProximitySensorInterface() sharedInstance] requestedMode] != 2) {
        [[_logos_static_class_lookup$BKProximitySensorInterface() sharedInstance] setPocketTouchesExpected:NO];
        [[_logos_static_class_lookup$BKProximitySensorInterface() sharedInstance] enableProximityDetectionWithMode:2];
    }
#endif
}

#if TARGET_IPHONE_SIMULATOR==0
typedef void(*IOHIDEventSystemCallback)(void* target, void* refcon, IOHIDServiceRef service, IOHIDEventRef event);

static Boolean (*ori_IOHIDEventSystemOpen)(IOHIDEventSystemRef, IOHIDEventSystemCallback,void *,void *,void *);
static void (*ori_IOHIDEventCallback)(void *a, void *b, __IOHIDService *c, __IOHIDEvent *e) = NULL;

static void __IOHIDEventCallback(void *a, void *b, __IOHIDService *c, __IOHIDEvent *e) {
    ori_IOHIDEventCallback(a, b, c, e);
    
    if (IOHIDEventGetType(e) == kIOHIDEventTypeProximity) { 
        int proximityValue = IOHIDEventGetIntegerValue(e, (IOHIDEventField)kIOHIDEventFieldProximityDetectionMask); 
        BOOL proximate = proximityValue == 0 ? NO : YES;
        
        
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



#pragma mark Ensure that grabbers don't move at all when scrolling (iOS 9.0 - 9.3)






static void _logos_method$SpringBoard$SBLockScreenView$_layoutGrabberView$atTop$percentScrolled$(_LOGOS_SELF_TYPE_NORMAL SBLockScreenView* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, id view, BOOL top, CGFloat scrolled) {
    _logos_orig$SpringBoard$SBLockScreenView$_layoutGrabberView$atTop$percentScrolled$(self, _cmd, view, top, [XENResources enabled] ? 0.0 : scrolled);
}



#pragma mark Lockscreen dim duration adjustments (iOS 9.0 - 9.3)



static double _logos_method$SpringBoard$SBBacklightController$defaultLockScreenDimInterval(_LOGOS_SELF_TYPE_NORMAL SBBacklightController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    return ([XENResources enabled] ? [XENResources lockScreenIdleTime] : _logos_orig$SpringBoard$SBBacklightController$defaultLockScreenDimInterval(self, _cmd));
}

static double _logos_method$SpringBoard$SBBacklightController$defaultLockScreenDimIntervalWhenNotificationsPresent(_LOGOS_SELF_TYPE_NORMAL SBBacklightController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    return ([XENResources enabled] ? [XENResources lockScreenIdleTime] : _logos_orig$SpringBoard$SBBacklightController$defaultLockScreenDimIntervalWhenNotificationsPresent(self, _cmd));
}



#pragma mark Lockscreen dim duration adjustments (iOS 10+)



static SBManualIdleTimer* _logos_method$SpringBoard$SBManualIdleTimer$initWithInterval$userEventInterface$(_LOGOS_SELF_TYPE_INIT SBManualIdleTimer* __unused self, SEL __unused _cmd, double arg1, id arg2) _LOGOS_RETURN_RETAINED {
    if (baseXenController && [XENResources enabled]) {
        arg1 = [XENResources lockScreenIdleTime];
    }
    
    if (setupWindow) {
        arg1 = 1000;
    }
    
    return _logos_orig$SpringBoard$SBManualIdleTimer$initWithInterval$userEventInterface$(self, _cmd, arg1, arg2);
}



#pragma mark Hide original artwork if necessary (<= iOS 9) (Needed on iOS 10?)








@interface _NowPlayingArtView : UIView
@end



static void _logos_method$SpringBoard$_NowPlayingArtView$layoutSubviews(_LOGOS_SELF_TYPE_NORMAL _NowPlayingArtView* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    _logos_orig$SpringBoard$_NowPlayingArtView$layoutSubviews(self, _cmd);
    
    BOOL shouldHide = [XENResources enabled] && ([XENResources mediaArtworkStyle] == 0 || [XENResources mediaArtworkStyle] == 2);
    
    if (shouldHide) {
        self.hidden = YES;
    }
}



#pragma mark Prevent blur from emergency dialer popping up (<= iOS 9) (Needed on iOS 10?)



static void _logos_method$SpringBoard$SBLockScreenView$_showFakeWallpaperBlurWithAlpha$withFactory$(_LOGOS_SELF_TYPE_NORMAL SBLockScreenView* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, CGFloat alpha, id factory) {
    _logos_orig$SpringBoard$SBLockScreenView$_showFakeWallpaperBlurWithAlpha$withFactory$(self, _cmd, [XENResources enabled] ? 0.0 : alpha, factory);
}



#pragma mark Ensure that touches are passed through the notifications collection view (iOS 9+)



static UIView * _logos_method$SpringBoard$UICollectionView$hitTest$withEvent$(_LOGOS_SELF_TYPE_NORMAL UICollectionView* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, CGPoint point, UIEvent * event) {
    UIView *orig = _logos_orig$SpringBoard$UICollectionView$hitTest$withEvent$(self, _cmd, point, event);
    
    if (self.tag != 1337123) {
        return orig;
    }
    
    return ([orig isEqual:self] ? nil : orig);
}



#pragma mark Toggles page, fix colourations. (<= iOS 9)




static MPUSystemMediaControlsView* _logos_method$SpringBoard$MPUSystemMediaControlsViewController$_xen_mediaView(_LOGOS_SELF_TYPE_NORMAL MPUSystemMediaControlsViewController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
#if TARGET_IPHONE_SIMULATOR==0
    return MSHookIvar<MPUSystemMediaControlsView*>(self, "_mediaControlsView");
#else
    return nil;
#endif
}



@interface SBUIControlCenterButton (Eh)
@property (nonatomic) id delegate;
@end



static SBUIControlCenterButton* _logos_method$SpringBoard$SBUIControlCenterButton$initWithFrame$(_LOGOS_SELF_TYPE_INIT SBUIControlCenterButton* __unused self, SEL __unused _cmd, CGRect arg1) _LOGOS_RETURN_RETAINED {
    
    SBUIControlCenterButton *orig = _logos_orig$SpringBoard$SBUIControlCenterButton$initWithFrame$(self, _cmd, arg1);
    
    
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

static id _logos_method$SpringBoard$SBUIControlCenterButton$_backgroundImage(_LOGOS_SELF_TYPE_NORMAL SBUIControlCenterButton* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    UIImage *orig = _logos_orig$SpringBoard$SBUIControlCenterButton$_backgroundImage(self, _cmd);
    if ([self viewWithTag:1337] != nil && ![object_getClass(self.delegate) isEqual:objc_getClass("SBCCButtonLikeSectionView")]) {
        
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

static id _logos_method$SpringBoard$SBUIControlCenterButton$_glyphImageForState$(_LOGOS_SELF_TYPE_NORMAL SBUIControlCenterButton* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, int arg1) {
    UIImage *glyph = _logos_orig$SpringBoard$SBUIControlCenterButton$_glyphImageForState$(self, _cmd, arg1);
    
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
        
        
        UIImage *img = [glyph imageWithRenderingMode:(fullColour ? UIImageRenderingModeAlwaysOriginal : UIImageRenderingModeAlwaysTemplate)];
        
        [(UIImageView*)[self viewWithTag:13379] setImage:img];
        
        return img;
    }
    
    return glyph;
}

static void _logos_method$SpringBoard$SBUIControlCenterButton$layoutSubviews(_LOGOS_SELF_TYPE_NORMAL SBUIControlCenterButton* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    _logos_orig$SpringBoard$SBUIControlCenterButton$layoutSubviews(self, _cmd);
    
    UIView *whitebg = [self viewWithTag:1337];
    whitebg.frame = self.bounds;
    
    
    
    
    if ([XENResources blurredBackground] || [object_getClass(self.delegate) isEqual:objc_getClass("SBCCButtonLikeSectionView")]) {
        whitebg.alpha = 0.0;
        whitebg.hidden = YES;
    } else {
        
        whitebg.layer.cornerRadius = [self isCircleButton] ? whitebg.frame.size.height/2 : 12.5;
    }
    
    if ([XENResources enabled] && [XENResources togglesGlyphTintForState:0 isCircle:[self isCircleButton]] && whitebg) {
        
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

static void _logos_method$SpringBoard$SBUIControlCenterButton$_updateEffects(_LOGOS_SELF_TYPE_NORMAL SBUIControlCenterButton* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    _logos_orig$SpringBoard$SBUIControlCenterButton$_updateEffects(self, _cmd);
    
    if ([self viewWithTag:1337] != nil) {
       
        
        
        if (![XENResources shouldUseDarkColouration]) {
            if (![XENResources blurredBackground]) {
                if (!UIAccessibilityIsReduceTransparencyEnabled()) {
                    
                    
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

static void _logos_method$SpringBoard$SBUIControlCenterButton$_updateForStateChange(_LOGOS_SELF_TYPE_NORMAL SBUIControlCenterButton* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    _logos_orig$SpringBoard$SBUIControlCenterButton$_updateForStateChange(self, _cmd);
    
    if ([self viewWithTag:1337] != nil) {
        UIView *whitebg = [self viewWithTag:1337];
        if ([[self superview].class isEqual:objc_getClass("SBCCButtonLikeSectionView")]) {
            whitebg.hidden = YES;
        } else {
            
            whitebg.hidden = YES;
        }
        
        
        
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
            
            effectView.alpha = [self _currentState] != 0 ? 0.75 : 1.0;
        }
#endif
    }
}





static SBCCButtonLikeSectionView* _logos_method$SpringBoard$SBCCButtonLikeSectionView$initWithFrame$(_LOGOS_SELF_TYPE_INIT SBCCButtonLikeSectionView* __unused self, SEL __unused _cmd, CGRect arg1) _LOGOS_RETURN_RETAINED {
    
    UIView *orig = _logos_orig$SpringBoard$SBCCButtonLikeSectionView$initWithFrame$(self, _cmd, arg1);
    
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

static void _logos_method$SpringBoard$SBCCButtonLikeSectionView$_updateEffects(_LOGOS_SELF_TYPE_NORMAL SBCCButtonLikeSectionView* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    _logos_orig$SpringBoard$SBCCButtonLikeSectionView$_updateEffects(self, _cmd);
    
    if ([self viewWithTag:1337] != nil) {
        if (![XENResources shouldUseDarkColouration]) {
            if (![XENResources blurredBackground] && !UIAccessibilityIsReduceTransparencyEnabled()) {
                
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

static void _logos_method$SpringBoard$SBCCButtonLikeSectionView$layoutSubviews(_LOGOS_SELF_TYPE_NORMAL SBCCButtonLikeSectionView* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    _logos_orig$SpringBoard$SBCCButtonLikeSectionView$layoutSubviews(self, _cmd);
    
    UIView *whitebg = [self viewWithTag:1337];
    if ([XENResources blurredBackground]) {
        whitebg.frame = CGRectZero;
    } else {
        whitebg.frame = self.bounds;
        
    }
    
    if ([XENResources enabled] && [XENResources togglesGlyphTintForState:0 isCircle:NO] && whitebg) {
            
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

static id _logos_method$SpringBoard$SBCCButtonLikeSectionView$_backgroundImageWithRoundCorners$(_LOGOS_SELF_TYPE_NORMAL SBCCButtonLikeSectionView* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, unsigned roundCorners) {
    UIImage *orig = _logos_orig$SpringBoard$SBCCButtonLikeSectionView$_backgroundImageWithRoundCorners$(self, _cmd, roundCorners);
    if ([self viewWithTag:1337] != nil) {
        
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

static void _logos_method$SpringBoard$SBCCButtonLikeSectionView$setSelected$(_LOGOS_SELF_TYPE_NORMAL SBCCButtonLikeSectionView* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, BOOL selected) {
    _logos_orig$SpringBoard$SBCCButtonLikeSectionView$setSelected$(self, _cmd, selected);
    
    if ([self viewWithTag:1337] != nil) {
        UIView *whitebg = [self viewWithTag:1337];
        if (![XENResources blurredBackground])
            whitebg.hidden = selected != 0;
        else
            whitebg.hidden = YES;
    }
}

static void _logos_method$SpringBoard$SBCCButtonLikeSectionView$buttonTapped$(_LOGOS_SELF_TYPE_NORMAL SBCCButtonLikeSectionView* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, id tapped) {
    _logos_orig$SpringBoard$SBCCButtonLikeSectionView$buttonTapped$(self, _cmd, tapped);
}





static BOOL _logos_method$SpringBoard$SBCCBrightnessSectionController$_shouldDarkenBackground(_LOGOS_SELF_TYPE_NORMAL SBCCBrightnessSectionController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    
    if ([self.view.superview.class isEqual:objc_getClass("_UIVisualEffectContentView")] || [self xen_slider].tag == 1337) {
        return NO;
    }
    
    return _logos_orig$SpringBoard$SBCCBrightnessSectionController$_shouldDarkenBackground(self, _cmd);
}


static SBUIControlCenterSlider* _logos_method$SpringBoard$SBCCBrightnessSectionController$xen_slider(_LOGOS_SELF_TYPE_NORMAL SBCCBrightnessSectionController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
#if TARGET_IPHONE_SIMULATOR==0
    return MSHookIvar<SBUIControlCenterSlider*>(self, "_slider");
#else
    return nil;
#endif
}





static id _logos_method$SpringBoard$SBUIControlCenterSlider$_valueImageForImage$state$(_LOGOS_SELF_TYPE_NORMAL SBUIControlCenterSlider* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, id arg1, long long arg2) {
    if (self.tag == 1337) {
        return _logos_orig$SpringBoard$SBUIControlCenterSlider$_valueImageForImage$state$(self, _cmd, arg1, 1);
    } else {
        return _logos_orig$SpringBoard$SBUIControlCenterSlider$_valueImageForImage$state$(self, _cmd, arg1, arg2);
    }
}

static void _logos_method$SpringBoard$SBUIControlCenterSlider$setAdjusting$(_LOGOS_SELF_TYPE_NORMAL SBUIControlCenterSlider* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, BOOL arg1) {
    _logos_orig$SpringBoard$SBUIControlCenterSlider$setAdjusting$(self, _cmd, self.tag == 1337 ? YES : arg1);
}



#pragma mark Toggles page subclass (iOS 10+)
















static XENControlCenterViewController* _logos_method$SpringBoard$XENControlCenterViewController$init(_LOGOS_SELF_TYPE_INIT XENControlCenterViewController* __unused self, SEL __unused _cmd) _LOGOS_RETURN_RETAINED {
    id orig = _logos_orig$SpringBoard$XENControlCenterViewController$init(self, _cmd);
    
    if (orig) {
        
        [[NSNotificationCenter defaultCenter] removeObserver:orig];
    }
    
    return orig;
}

static void _logos_method$SpringBoard$XENControlCenterViewController$_layoutScrollView(_LOGOS_SELF_TYPE_NORMAL XENControlCenterViewController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    
}

static void _logos_method$SpringBoard$XENControlCenterViewController$_addContentViewController$(_LOGOS_SELF_TYPE_NORMAL XENControlCenterViewController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, id arg1) {
    
    _logos_orig$SpringBoard$XENControlCenterViewController$_addContentViewController$(self, _cmd, arg1);    
}

static id _logos_method$SpringBoard$XENControlCenterViewController$controlCenterSystemAgent(_LOGOS_SELF_TYPE_NORMAL XENControlCenterViewController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    return [[objc_getClass("SBControlCenterController") sharedInstance] controlCenterSystemAgentForControlCenterViewController:self];
}



#pragma mark Dismiss Content page editor on physical button press (<= iOS 9)

@interface SpringBoard (ExtraEh)
-(void)xen_dismissContentEditor;
@end



static void _logos_method$SpringBoard$SpringBoard$_handleMenuButtonEvent(_LOGOS_SELF_TYPE_NORMAL SpringBoard* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    [self xen_dismissContentEditor];
    _logos_orig$SpringBoard$SpringBoard$_handleMenuButtonEvent(self, _cmd);
}

static void _logos_method$SpringBoard$SpringBoard$handleMenuDoubleTap(_LOGOS_SELF_TYPE_NORMAL SpringBoard* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    [self xen_dismissContentEditor];
    _logos_orig$SpringBoard$SpringBoard$handleMenuDoubleTap(self, _cmd);
}


static void _logos_method$SpringBoard$SpringBoard$xen_dismissContentEditor(_LOGOS_SELF_TYPE_NORMAL SpringBoard* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    [UIView animateWithDuration:0.0 animations:^{
        [XENResources contentEditWindow].alpha = 0.0;
    } completion:^(BOOL finished) {
        [XENResources hideContentEditWindow];
    }];
}



#pragma mark Dismiss Content page editor on physical button press (iOS 10+)

@interface SBDashBoardViewController (ExtraEh)
-(void)xen_dismissContentEditor;
@end



static _Bool _logos_method$SpringBoard$SBDashBoardViewController$handleMenuButtonTap(_LOGOS_SELF_TYPE_NORMAL SBDashBoardViewController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    [self xen_dismissContentEditor];
    return _logos_orig$SpringBoard$SBDashBoardViewController$handleMenuButtonTap(self, _cmd);
}

static _Bool _logos_method$SpringBoard$SBDashBoardViewController$handleMenuButtonHeld(_LOGOS_SELF_TYPE_NORMAL SBDashBoardViewController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    [self xen_dismissContentEditor];
    return _logos_orig$SpringBoard$SBDashBoardViewController$handleMenuButtonHeld(self, _cmd);
}


static void _logos_method$SpringBoard$SBDashBoardViewController$xen_dismissContentEditor(_LOGOS_SELF_TYPE_NORMAL SBDashBoardViewController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    [UIView animateWithDuration:0.0 animations:^{
        [XENResources contentEditWindow].alpha = 0.0;
    } completion:^(BOOL finished) {
        [XENResources hideContentEditWindow];
    }];
}




#pragma mark Suppress CC if appropriate (<= iOS 9)



static BOOL _logos_method$SpringBoard$SBLockScreenViewController$suppressesControlCenter(_LOGOS_SELF_TYPE_NORMAL SBLockScreenViewController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    if ([XENResources enabled] && ![XENResources shouldProvideCC])
        return YES;
    else
        return _logos_orig$SpringBoard$SBLockScreenViewController$suppressesControlCenter(self, _cmd);
}





static void _logos_method$SpringBoard$SBLockScreenView$_layoutGrabberView$atTop$(_LOGOS_SELF_TYPE_NORMAL SBLockScreenView* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, UIView* view, BOOL top) {
    if (!top && [XENResources enabled] && (![XENResources shouldProvideCC] || [XENResources hideCCGrabber])) {
        view.hidden = YES;
        view.alpha = 0.0;
    } else if (!top && [XENResources enabled] && [XENResources shouldProvideCC]) {
        view.hidden = NO;
        view.alpha = 1.0;
        _logos_orig$SpringBoard$SBLockScreenView$_layoutGrabberView$atTop$(self, _cmd, view, top);
    } else if (top && [XENResources enabled] && ([XENResources hideNCGrabber] || [XENResources isLoadedInEditMode])) {
        view.hidden = YES;
        view.alpha = 0.0;
    } else {
        _logos_orig$SpringBoard$SBLockScreenView$_layoutGrabberView$atTop$(self, _cmd, view, top);
    }
}



static void _logos_method$SpringBoard$SBLockScreenView$_xen_relayoutDateView(_LOGOS_SELF_TYPE_NORMAL SBLockScreenView* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    
#if TARGET_IPHONE_SIMULATOR==0
    SBFLockScreenDateView *_dateView = MSHookIvar<SBFLockScreenDateView*>(self, "_dateView");
    
    CGFloat baseY = [objc_getClass("SBFLockScreenMetrics") dateViewBaselineY];
    baseY -= [_dateView timeBaselineOffsetFromOrigin];
    
    [_dateView setFrame:CGRectMake(_dateView.frame.origin.x, baseY, _dateView.frame.size.width, _dateView.frame.size.height)];
#endif
}



#pragma mark Suppress CC if appropriate (iOS 10+) (TODO, should we even do this?)












#pragma mark Fix flashlight in CC and Xen. (iOS 9+)



static AVFlashlight* _logos_method$SpringBoard$AVFlashlight$init(_LOGOS_SELF_TYPE_INIT AVFlashlight* __unused self, SEL __unused _cmd) _LOGOS_RETURN_RETAINED {
    if (!_sharedFlashlight) {
        _sharedFlashlight = _logos_orig$SpringBoard$AVFlashlight$init(self, _cmd);
    }
    
    return _sharedFlashlight;
}



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

 

static void _logos_method$SpringBoard$SBUIControlCenterSlider$layoutSubviews(_LOGOS_SELF_TYPE_NORMAL SBUIControlCenterSlider* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    _logos_orig$SpringBoard$SBUIControlCenterSlider$layoutSubviews(self, _cmd);
    
    if ([XENResources isViewOnXen:self] && baseXenController) {
        for (UIView *view in self.subviews) {
            if ([[view class] isEqual:[UIVisualEffectView class]]) {
                [(UIVisualEffectView*)view setEffect:nil];
            }
        }
    
#if TARGET_IPHONE_SIMULATOR==0
        [self addSubview:MSHookIvar<UIView*>(self, "_thumbView")];
#endif
        
        
        
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


static void _logos_method$SpringBoard$SBUIControlCenterSlider$setMaximumTrackImage$forState$(_LOGOS_SELF_TYPE_NORMAL SBUIControlCenterSlider* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, UIImage* image, int state) {
    if (self.tag == 1337 && baseXenController) {
        UIImage *max = [[XENResources themedImageWithName:@"SliderMax"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 0, 5)];
        if (max)
            image = max;
    }
    
    _logos_orig$SpringBoard$SBUIControlCenterSlider$setMaximumTrackImage$forState$(self, _cmd, image, state);
}

static void _logos_method$SpringBoard$SBUIControlCenterSlider$setMinimumTrackImage$forState$(_LOGOS_SELF_TYPE_NORMAL SBUIControlCenterSlider* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, UIImage* image, int state) {
    if (self.tag == 1337 && baseXenController) {
        UIImage *max = [[XENResources themedImageWithName:@"SliderMin"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 5, 0, 0)];
        if (max)
            image = max;
    }
    
    _logos_orig$SpringBoard$SBUIControlCenterSlider$setMinimumTrackImage$forState$(self, _cmd, image, state);
}

static void _logos_method$SpringBoard$SBUIControlCenterSlider$setThumbImage$forState$(_LOGOS_SELF_TYPE_NORMAL SBUIControlCenterSlider* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, UIImage* image, int state) {
    if (self.tag == 1337 && baseXenController) {
        UIImage *thumb = [XENResources themedImageWithName:@"SliderThumb"];
        if (thumb)
            image = thumb;
    }
    
    _logos_orig$SpringBoard$SBUIControlCenterSlider$setThumbImage$forState$(self, _cmd, image, state);
}


static void _logos_method$SpringBoard$SBUIControlCenterSlider$_xen_setTrackImagesForCurrentTheme(_LOGOS_SELF_TYPE_NORMAL SBUIControlCenterSlider* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
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



@interface MPVolumeController : NSObject
- (float)setVolumeValue:(float)arg1;
- (float)volumeValue;
@end

@interface MPUMediaControlsVolumeView (Private)
- (id)_createVolumeSliderView;
- (void)_xen_postLayout;
@property (nonatomic, readonly) MPVolumeController *volumeController;
@end




static void _logos_method$SpringBoard$MPUMediaControlsVolumeView$layoutSubviews(_LOGOS_SELF_TYPE_NORMAL MPUMediaControlsVolumeView* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    _logos_orig$SpringBoard$MPUMediaControlsVolumeView$layoutSubviews(self, _cmd);
    
#if TARGET_IPHONE_SIMULATOR==0
    if ([XENResources enabled] && MSHookIvar<int>(self, "_style") != 1 && !self.slider.hidden && [XENResources themedImageWithName:@"SliderThumb"] && baseXenController) {
        
        self.slider.tag = 1;
        self.slider.hidden = YES;
        
        SBUIControlCenterSlider *slider = [[objc_getClass("SBUIControlCenterSlider") alloc] init];
        slider.tag = 1337;
        [slider setMinimumValueImage:self.slider.minimumValueImage];
        [slider setMaximumValueImage:self.slider.maximumValueImage];
        [slider setValue:self.slider.value];
        [slider setAdjusting:YES];
        [slider _xen_setTrackImagesForCurrentTheme];
        
        
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

static void _logos_method$SpringBoard$MPUMediaControlsVolumeView$updateSystemVolumeLevel(_LOGOS_SELF_TYPE_NORMAL MPUMediaControlsVolumeView* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    _logos_orig$SpringBoard$MPUMediaControlsVolumeView$updateSystemVolumeLevel(self, _cmd);
    
    SBUIControlCenterSlider *slider = (SBUIControlCenterSlider*)[self viewWithTag:1337];
    [slider setValue:[self.volumeController volumeValue]];
}

static void _logos_method$SpringBoard$MPUMediaControlsVolumeView$volumeController$volumeValueDidChange$(_LOGOS_SELF_TYPE_NORMAL MPUMediaControlsVolumeView* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, id arg1, float arg2) {
    _logos_orig$SpringBoard$MPUMediaControlsVolumeView$volumeController$volumeValueDidChange$(self, _cmd, arg1, arg2);
    
    SBUIControlCenterSlider *slider = (SBUIControlCenterSlider*)[self viewWithTag:1337];
    [slider setValue:[self.volumeController volumeValue]];
}


static void _logos_method$SpringBoard$MPUMediaControlsVolumeView$_xen_volumeChangeStarted$(_LOGOS_SELF_TYPE_NORMAL MPUMediaControlsVolumeView* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, id sender) {
    
}


static void _logos_method$SpringBoard$MPUMediaControlsVolumeView$_xen_volumeValueChanged$(_LOGOS_SELF_TYPE_NORMAL MPUMediaControlsVolumeView* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, id sender) {
    SBUIControlCenterSlider *slider = (SBUIControlCenterSlider*)[self viewWithTag:1337];
    
    [self.volumeController setVolumeValue:slider.value];
}


static void _logos_method$SpringBoard$MPUMediaControlsVolumeView$_xen_volumeStoppedChange$(_LOGOS_SELF_TYPE_NORMAL MPUMediaControlsVolumeView* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, id sender) {
}






static void _logos_method$SpringBoard$SBLockScreenViewController$_addMediaControls(_LOGOS_SELF_TYPE_NORMAL SBLockScreenViewController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
#if TARGET_IPHONE_SIMULATOR==0
    MSHookIvar<NSObject*>(self, "_mediaControlsViewController") = nil;
#endif
    _logos_orig$SpringBoard$SBLockScreenViewController$_addMediaControls(self, _cmd);
}





static id _logos_method$SpringBoard$MPUSystemMediaControlsViewController$_imageForTransportButtonWithControlType$(_LOGOS_SELF_TYPE_NORMAL MPUSystemMediaControlsViewController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, int arg1) {
    UIImage *orig = _logos_orig$SpringBoard$MPUSystemMediaControlsViewController$_imageForTransportButtonWithControlType$(self, _cmd, arg1);
    
#if TARGET_IPHONE_SIMULATOR==0
    if ([XENResources enabled] && MSHookIvar<int>(self, "_style") != 1 && baseXenController) {
        UIImage *maybeNewImage;
        
        
        
        
        
    
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





#pragma mark Hide Lockscreen Clock (iOS 9+)



static void _logos_method$SpringBoard$SBFLockScreenDateView$layoutSubviews(_LOGOS_SELF_TYPE_NORMAL SBFLockScreenDateView* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    _logos_orig$SpringBoard$SBFLockScreenDateView$layoutSubviews(self, _cmd);
    
    if ([XENResources enabled] && [XENResources hideClock]) {
        self.hidden = YES;
    }
}

static void _logos_method$SpringBoard$SBFLockScreenDateView$setHidden$(_LOGOS_SELF_TYPE_NORMAL SBFLockScreenDateView* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, BOOL hidden) {
    ([XENResources enabled] && [XENResources hideClock] ? _logos_orig$SpringBoard$SBFLockScreenDateView$setHidden$(self, _cmd, YES) : _logos_orig$SpringBoard$SBFLockScreenDateView$setHidden$(self, _cmd, hidden));
}








static BOOL _logos_method$SpringBoard$SBLockScreenViewController$_shouldShowChargingText(_LOGOS_SELF_TYPE_NORMAL SBLockScreenViewController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    return ([XENResources enabled] && [XENResources hideClock] ? NO : _logos_orig$SpringBoard$SBLockScreenViewController$_shouldShowChargingText(self, _cmd));
}



#pragma mark Hide page control dots (iOS 10+)



static void _logos_method$SpringBoard$SBDashBoardView$_layoutPageControl(_LOGOS_SELF_TYPE_NORMAL SBDashBoardView* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    _logos_orig$SpringBoard$SBDashBoardView$_layoutPageControl(self, _cmd);
    
    if ([XENResources enabled] && [XENResources hidePageControlDots]) {
#if TARGET_IPHONE_SIMULATOR==0
        UIView *control = MSHookIvar<UIView*>(self, "_pageControl");
        control.hidden = YES;
        control.userInteractionEnabled = NO;
#endif
    }
}



#pragma mark Fix views for toggles when using iPad (<= iOS 9)

BOOL iPadOverruleIdiom = NO;



static int _logos_method$SpringBoard$UIDevice$userInterfaceIdiom(_LOGOS_SELF_TYPE_NORMAL UIDevice* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    if (iPadOverruleIdiom) {
        return UIUserInterfaceIdiomPhone;
    } else {
        return _logos_orig$SpringBoard$UIDevice$userInterfaceIdiom(self, _cmd);
    }
}



@interface SBCCButtonLayoutView : UIView @end



static void _logos_method$SpringBoard$SBCCButtonLayoutView$layoutSubviews(_LOGOS_SELF_TYPE_NORMAL SBCCButtonLayoutView* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    if ([XENResources isViewOnXen:self]) {
        iPadOverruleIdiom = YES;
    }
    
    _logos_orig$SpringBoard$SBCCButtonLayoutView$layoutSubviews(self, _cmd);
    
    iPadOverruleIdiom = NO;
}

static CGFloat _logos_method$SpringBoard$SBCCButtonLayoutView$interButtonPadding(_LOGOS_SELF_TYPE_NORMAL SBCCButtonLayoutView* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    return ([XENResources isViewOnXen:self] ? 20 : _logos_orig$SpringBoard$SBCCButtonLayoutView$interButtonPadding(self, _cmd));
}





static UIEdgeInsets _logos_method$SpringBoard$SBCCButtonLikeSectionSplitView$_landscapeInsetsForSection(_LOGOS_SELF_TYPE_NORMAL SBCCButtonLikeSectionSplitView* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    if ([XENResources isViewOnXen:self]) {
        iPadOverruleIdiom = YES;
    }
    
    UIEdgeInsets orig = _logos_orig$SpringBoard$SBCCButtonLikeSectionSplitView$_landscapeInsetsForSection(self, _cmd);
    
    iPadOverruleIdiom = NO;
    
    return orig;
}

static BOOL _logos_method$SpringBoard$SBCCButtonLikeSectionSplitView$_useLandscapeBehavior(_LOGOS_SELF_TYPE_NORMAL SBCCButtonLikeSectionSplitView* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    if ([XENResources isViewOnXen:self]) {
        return NO;
    }
    
    return _logos_orig$SpringBoard$SBCCButtonLikeSectionSplitView$_useLandscapeBehavior(self, _cmd);
}





static BOOL _logos_method$SpringBoard$SBCCButtonLikeSectionView$_shouldUseButtonAppearance(_LOGOS_SELF_TYPE_NORMAL SBCCButtonLikeSectionView* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    if ([self viewWithTag:1337]) {
        return YES;
    }
    return _logos_orig$SpringBoard$SBCCButtonLikeSectionView$_shouldUseButtonAppearance(self, _cmd);
}



#pragma mark Welcome View Shizzle (iOS 9+) (Needs verification)



static void _logos_method$SpringBoard$EKBBTodayProvider$_refreshUpcomingEventBulletin(_LOGOS_SELF_TYPE_NORMAL EKBBTodayProvider* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    _logos_orig$SpringBoard$EKBBTodayProvider$_refreshUpcomingEventBulletin(self, _cmd);
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"com.matchstic.xen/refreshWelcomeView" object:nil];
}

static void _logos_method$SpringBoard$EKBBTodayProvider$_refreshBirthdayBulletin(_LOGOS_SELF_TYPE_NORMAL EKBBTodayProvider* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    _logos_orig$SpringBoard$EKBBTodayProvider$_refreshBirthdayBulletin(self, _cmd);
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"com.matchstic.xen/refreshWelcomeView" object:nil];
}





static UIView* _logos_method$SpringBoard$UIVisualEffectView$hitTest$withEvent$(_LOGOS_SELF_TYPE_NORMAL UIVisualEffectView* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, CGPoint point, UIEvent * event) {
    UIView *view = _logos_orig$SpringBoard$UIVisualEffectView$hitTest$withEvent$(self, _cmd, point, event);
    if ([view isEqual:self] && self.tag == 1337) {
        view = nil;
    }
    
    return view;
}



#pragma mark LockPages hooks (iOS 9.0 - 9.3) (Is this required on iOS 10?)
#import "XENLockPagesController.h"



static int _logos_method$SpringBoard$LPPageController$calculateStartIndex$(_LOGOS_SELF_TYPE_NORMAL LPPageController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, id arg1) {
    if ([XENResources enabled]) {
        int i = (int)[[XENResources enabledControllerIdentifiers] indexOfObject:@"com.matchstic.home"];
        
        return i;
    } else {
        return _logos_orig$SpringBoard$LPPageController$calculateStartIndex$(self, _cmd, arg1);
    }
}

static long long _logos_method$SpringBoard$LPPageController$realPageCount(_LOGOS_SELF_TYPE_NORMAL LPPageController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    if ([XENResources enabled]) {
        return (long long)[XENResources enabledControllerIdentifiers].count;
    } else {
        return _logos_orig$SpringBoard$LPPageController$realPageCount(self, _cmd);
    }
}

static id _logos_method$SpringBoard$LPPageController$pageAtOffset$(_LOGOS_SELF_TYPE_NORMAL LPPageController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, double arg1) {
    if ([XENResources enabled]) {
        XENBaseViewController *controller = [baseXenController controllerAtOffset:arg1];
        
        if ([[controller class] isEqual:[XENLockPagesController class]]) {
            return [(XENLockPagesController*)controller LPPage];
        } else {
            return nil;
        }
    } else {
        return _logos_orig$SpringBoard$LPPageController$pageAtOffset$(self, _cmd, arg1);
    }
}

static id _logos_method$SpringBoard$LPPageController$pageAtAbsoluteIndex$(_LOGOS_SELF_TYPE_NORMAL LPPageController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, unsigned long long arg1) {
    if ([XENResources enabled]) {
        if (arg1 >= [XENResources enabledControllerIdentifiers].count) {
            
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
        return _logos_orig$SpringBoard$LPPageController$pageAtAbsoluteIndex$(self, _cmd, arg1);
    }
}

static void _logos_method$SpringBoard$LPPageController$layoutLockScreenView$(_LOGOS_SELF_TYPE_NORMAL LPPageController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, id arg1) {
    dontAllowScrollViewOffsetChange = YES;
    dontScrollForLockPages = YES;
    _logos_orig$SpringBoard$LPPageController$layoutLockScreenView$(self, _cmd, arg1);
    dontAllowScrollViewOffsetChange = NO;
    
    [XENResources relayourLockPagesControllers];
}

static void _logos_method$SpringBoard$LPPageController$layoutPages(_LOGOS_SELF_TYPE_NORMAL LPPageController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    dontAllowScrollViewOffsetChange = YES;
    _logos_orig$SpringBoard$LPPageController$layoutPages(self, _cmd);
    dontAllowScrollViewOffsetChange = NO;
}

static void _logos_method$SpringBoard$LPPageController$addPage$(_LOGOS_SELF_TYPE_NORMAL LPPageController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, id arg1) {
    _logos_orig$SpringBoard$LPPageController$addPage$(self, _cmd, arg1);
    
    [XENResources didSortLockPages];
    [baseXenController invalidateControllersForLockPages];
}


static id _logos_method$SpringBoard$LPPageController$_xen_sortedPages(_LOGOS_SELF_TYPE_NORMAL LPPageController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
#if TARGET_IPHONE_SIMULATOR==0
    return MSHookIvar<NSMutableArray*>(self, "_sortedPages");
#else
    return [NSArray array];
#endif
}





static _Bool _logos_method$SpringBoard$LPPage$supportsBackgroundAlpha(_LOGOS_SELF_TYPE_NORMAL LPPage* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    return [XENResources enabled] ? NO : _logos_orig$SpringBoard$LPPage$supportsBackgroundAlpha(self, _cmd);
}





static void _logos_method$SpringBoard$SBLockScreenView$lp_updateUnderlayAlpha$(_LOGOS_SELF_TYPE_NORMAL SBLockScreenView* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, CGFloat arg1) {
    _logos_orig$SpringBoard$SBLockScreenView$lp_updateUnderlayAlpha$(self, _cmd, [XENResources enabled] ? 0.0 : arg1);
}

static void _logos_method$SpringBoard$SBLockScreenView$lp_updateUnderlayForCurrentScroll(_LOGOS_SELF_TYPE_NORMAL SBLockScreenView* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    if (![XENResources enabled])
        _logos_orig$SpringBoard$SBLockScreenView$lp_updateUnderlayForCurrentScroll(self, _cmd);
}



#pragma mark Check that device has been unlocked since boot



static void _logos_method$SpringBoard$SBUIPasscodeLockViewBase$_noteDeviceHasBeenUnlockedOnceSinceBoot$(_LOGOS_SELF_TYPE_NORMAL SBUIPasscodeLockViewBase* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, BOOL arg1) {
    _logos_orig$SpringBoard$SBUIPasscodeLockViewBase$_noteDeviceHasBeenUnlockedOnceSinceBoot$(self, _cmd, arg1);
    
    [XENResources setUnlockedSinceBoot:arg1];
}






static BOOL xenRequestVisible = NO;



static BOOL _logos_method$SpringBoard$SBNotificationCenterController$isVisible(_LOGOS_SELF_TYPE_NORMAL SBNotificationCenterController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    return (xenRequestVisible ? YES : _logos_orig$SpringBoard$SBNotificationCenterController$isVisible(self, _cmd));
}

static BOOL _logos_method$SpringBoard$SBNotificationCenterController$shouldRequestWidgetRemoteViewControllers(_LOGOS_SELF_TYPE_NORMAL SBNotificationCenterController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    return (xenRequestVisible ? YES : _logos_orig$SpringBoard$SBNotificationCenterController$shouldRequestWidgetRemoteViewControllers(self, _cmd));
}


static void _logos_meta_method$SpringBoard$SBNotificationCenterController$_xen_setRequestVisible$(_LOGOS_SELF_TYPE_NORMAL Class _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, BOOL visible) {
    xenRequestVisible = visible;
}



#pragma mark Hooks needed to get the NC widgets page working. (iOS 9.0 - 9.3) (Necessary?)




static NSSet* _logos_method$SpringBoard$SBNotificationCenterLayoutViewController$xen_defaultEnabledIDs(_LOGOS_SELF_TYPE_NORMAL SBNotificationCenterLayoutViewController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
#if TARGET_IPHONE_SIMULATOR==0
    return MSHookIvar<NSSet*>(self, "_defaultEnabledIDs");
#else
    return [NSSet set];
#endif
}


static NSMutableDictionary * _logos_method$SpringBoard$SBNotificationCenterLayoutViewController$xen_identifiersToDatums(_LOGOS_SELF_TYPE_NORMAL SBNotificationCenterLayoutViewController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
#if TARGET_IPHONE_SIMULATOR==0
    return MSHookIvar<NSMutableDictionary*>(self, "_identifiersToDatums");
#else
    return [NSMutableDictionary dictionary];
#endif
}


static NSMutableDictionary * _logos_method$SpringBoard$SBNotificationCenterLayoutViewController$xen_dataSourceIdentifiersToDatumIdentifiers(_LOGOS_SELF_TYPE_NORMAL SBNotificationCenterLayoutViewController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
#if TARGET_IPHONE_SIMULATOR==0
    return MSHookIvar<NSMutableDictionary*>(self, "_dataSourceIdentifiersToDatumIdentifiers");
#else
    return [NSMutableDictionary dictionary];
#endif
}



#pragma mark Fix awful backgrounds on passcode (iOS 9.0 - 9.3)



static void _logos_method$SpringBoard$SBUIPasscodeLockViewBase$_setLuminosityBoost$(_LOGOS_SELF_TYPE_NORMAL SBUIPasscodeLockViewBase* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, double arg1) {
    _logos_orig$SpringBoard$SBUIPasscodeLockViewBase$_setLuminosityBoost$(self, _cmd, [XENResources enabled] ? 0.5 : arg1);
}


static void _logos_method$SpringBoard$SBUIPasscodeLockViewBase$_xen_layoutForHidingViews(_LOGOS_SELF_TYPE_NORMAL SBUIPasscodeLockViewBase* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
}






static void _logos_method$SpringBoard$SBUIPasscodeLockViewWithKeyboard$_xen_layoutForHidingViews(_LOGOS_SELF_TYPE_NORMAL SBUIPasscodeLockViewWithKeyboard* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
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





static CGFloat _logos_method$SpringBoard$SBUIPasscodeTextField$alpha(_LOGOS_SELF_TYPE_NORMAL SBUIPasscodeTextField* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    return [XENResources enabled] && [UIDevice currentDevice].systemVersion.floatValue < 10 ? 1.0 : _logos_orig$SpringBoard$SBUIPasscodeTextField$alpha(self, _cmd);
}

static void _logos_method$SpringBoard$SBUIPasscodeTextField$setAlpha$(_LOGOS_SELF_TYPE_NORMAL SBUIPasscodeTextField* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, CGFloat alpha) {
    _logos_orig$SpringBoard$SBUIPasscodeTextField$setAlpha$(self, _cmd, [XENResources enabled] && [UIDevice currentDevice].systemVersion.floatValue < 10 ? 1.0 : alpha);
}

static UIColor* _logos_method$SpringBoard$SBUIPasscodeTextField$backgroundColor(_LOGOS_SELF_TYPE_NORMAL SBUIPasscodeTextField* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    return [XENResources enabled] && [UIDevice currentDevice].systemVersion.floatValue < 10 ? [UIColor clearColor] : _logos_orig$SpringBoard$SBUIPasscodeTextField$backgroundColor(self, _cmd);
}

static void _logos_method$SpringBoard$SBUIPasscodeTextField$setBackgroundColor$(_LOGOS_SELF_TYPE_NORMAL SBUIPasscodeTextField* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, UIColor* color) {
    _logos_orig$SpringBoard$SBUIPasscodeTextField$setBackgroundColor$(self, _cmd, [XENResources enabled] && [UIDevice currentDevice].systemVersion.floatValue < 10 ? [UIColor clearColor] : color);
}



#pragma mark Fix ColorBanners

@interface CBRGradientView : UIView
@end



static void _logos_method$SpringBoard$CBRGradientView$setFrame$(_LOGOS_SELF_TYPE_NORMAL CBRGradientView* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, CGRect frame) {
    
    if (baseXenController && [XENResources enabled] && [XENResources useXENNotificationUI] && self.tag != 1337) {
        return;
    }
    
    _logos_orig$SpringBoard$CBRGradientView$setFrame$(self, _cmd, frame);
}



#pragma mark Settings handling

static void handlePeekSettingsChanged() {
    #if USE_PEEK==1
    if (![XENResources peekEnabled]) {
        
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

 

#pragma mark Setup UI stuff





static void _logos_method$_ungrouped$SpringBoard$_xen_relayoutAfterSetupContentEditorDisplayed(_LOGOS_SELF_TYPE_NORMAL SpringBoard* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    
    [baseXenController handleReconfigureFromSetup];
}


static void _logos_method$_ungrouped$SpringBoard$_xen_releaseSetupUI(_LOGOS_SELF_TYPE_NORMAL SpringBoard* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
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


static void _logos_method$_ungrouped$SpringBoard$_xen_finaliseAfterSetup(_LOGOS_SELF_TYPE_NORMAL SpringBoard* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    [baseXenController finaliseEverythingForPostSetup];
}





static BOOL _logos_method$_ungrouped$SBLockScreenViewController$suppressesSiri(_LOGOS_SELF_TYPE_NORMAL SBLockScreenViewController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    return ([XENResources enabled] && setupWindow) ? YES : _logos_orig$_ungrouped$SBLockScreenViewController$suppressesSiri(self, _cmd);
}





static void _logos_method$_ungrouped$SBBacklightController$_lockScreenDimTimerFired(_LOGOS_SELF_TYPE_NORMAL SBBacklightController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    if ([XENResources enabled] && setupWindow) {
        return;
    }
    
    _logos_orig$_ungrouped$SBBacklightController$_lockScreenDimTimerFired(self, _cmd);
}



#pragma mark Constructor

static __attribute__((constructor)) void _logosLocalCtor_cd9758df(int __unused argc, char __unused **argv, char __unused **envp) {
    BOOL sb = [[[NSBundle mainBundle] bundleIdentifier] isEqualToString:@"com.apple.springboard"];
    BOOL prefs = [[[NSBundle mainBundle] bundleIdentifier] isEqualToString:@"com.apple.Preferences"];
    
    if (sb) {
        
        Class $XENScrollView = objc_allocateClassPair(objc_getClass("SBLockScreenScrollView"), "XENScrollView", 0);
        objc_registerClassPair($XENScrollView);
    
        if ([[UIDevice currentDevice].systemVersion floatValue] < 10.0) {
            Class $XENShortcutModule = objc_allocateClassPair(objc_getClass("SBCCShortcutModule"), "XENShortcutModule", 0);
            objc_registerClassPair($XENShortcutModule);
        } else {
            
            Class $XENShortcutModule = objc_allocateClassPair(objc_getClass("CCUIShortcutModule"), "XENShortcutModule", 0);
            objc_registerClassPair($XENShortcutModule);
            
            
            Class $XENDashBoardPageViewController = objc_allocateClassPair(objc_getClass("SBDashBoardPageViewController"), "XENDashBoardPageViewController", 0);
            objc_registerClassPair($XENDashBoardPageViewController);
            
            
            Class $XENControlCenterViewController = objc_allocateClassPair(objc_getClass("CCUIControlCenterViewController"), "XENControlCenterViewController", 0);
            objc_registerClassPair($XENControlCenterViewController);
        }
    }

    {Class _logos_class$_ungrouped$SpringBoard = objc_getClass("SpringBoard"); Class _logos_metaclass$_ungrouped$SpringBoard = object_getClass(_logos_class$_ungrouped$SpringBoard); MSHookMessageEx(_logos_class$_ungrouped$SpringBoard, @selector(applicationDidFinishLaunching:), (IMP)&_logos_method$_ungrouped$SpringBoard$applicationDidFinishLaunching$, (IMP*)&_logos_orig$_ungrouped$SpringBoard$applicationDidFinishLaunching$);{ char _typeEncoding[1024]; unsigned int i = 0; _typeEncoding[i] = '@'; i += 1; _typeEncoding[i] = '@'; i += 1; _typeEncoding[i] = ':'; i += 1; memcpy(_typeEncoding + i, @encode(NSString*), strlen(@encode(NSString*))); i += strlen(@encode(NSString*)); _typeEncoding[i] = '@'; i += 1; _typeEncoding[i] = '\0'; class_addMethod(_logos_metaclass$_ungrouped$SpringBoard, @selector(XEN_ivarNamed:withinObject:), (IMP)&_logos_meta_method$_ungrouped$SpringBoard$XEN_ivarNamed$withinObject$, _typeEncoding); }{ char _typeEncoding[1024]; unsigned int i = 0; _typeEncoding[i] = 'v'; i += 1; _typeEncoding[i] = '@'; i += 1; _typeEncoding[i] = ':'; i += 1; _typeEncoding[i] = '\0'; class_addMethod(_logos_class$_ungrouped$SpringBoard, @selector(_xen_setupMidnightTimer), (IMP)&_logos_method$_ungrouped$SpringBoard$_xen_setupMidnightTimer, _typeEncoding); }{ char _typeEncoding[1024]; unsigned int i = 0; _typeEncoding[i] = 'v'; i += 1; _typeEncoding[i] = '@'; i += 1; _typeEncoding[i] = ':'; i += 1; _typeEncoding[i] = '@'; i += 1; _typeEncoding[i] = '\0'; class_addMethod(_logos_class$_ungrouped$SpringBoard, @selector(_xen_midnightTimerFired:), (IMP)&_logos_method$_ungrouped$SpringBoard$_xen_midnightTimerFired$, _typeEncoding); }{ char _typeEncoding[1024]; unsigned int i = 0; _typeEncoding[i] = 'v'; i += 1; _typeEncoding[i] = '@'; i += 1; _typeEncoding[i] = ':'; i += 1; _typeEncoding[i] = '@'; i += 1; _typeEncoding[i] = '\0'; class_addMethod(_logos_class$_ungrouped$SpringBoard, @selector(checkIfShouldShowWelcome:), (IMP)&_logos_method$_ungrouped$SpringBoard$checkIfShouldShowWelcome$, _typeEncoding); }{ char _typeEncoding[1024]; unsigned int i = 0; _typeEncoding[i] = 'v'; i += 1; _typeEncoding[i] = '@'; i += 1; _typeEncoding[i] = ':'; i += 1; _typeEncoding[i] = '\0'; class_addMethod(_logos_class$_ungrouped$SpringBoard, @selector(_xen_relayoutAfterSetupContentEditorDisplayed), (IMP)&_logos_method$_ungrouped$SpringBoard$_xen_relayoutAfterSetupContentEditorDisplayed, _typeEncoding); }{ char _typeEncoding[1024]; unsigned int i = 0; _typeEncoding[i] = 'v'; i += 1; _typeEncoding[i] = '@'; i += 1; _typeEncoding[i] = ':'; i += 1; _typeEncoding[i] = '\0'; class_addMethod(_logos_class$_ungrouped$SpringBoard, @selector(_xen_releaseSetupUI), (IMP)&_logos_method$_ungrouped$SpringBoard$_xen_releaseSetupUI, _typeEncoding); }{ char _typeEncoding[1024]; unsigned int i = 0; _typeEncoding[i] = 'v'; i += 1; _typeEncoding[i] = '@'; i += 1; _typeEncoding[i] = ':'; i += 1; _typeEncoding[i] = '\0'; class_addMethod(_logos_class$_ungrouped$SpringBoard, @selector(_xen_finaliseAfterSetup), (IMP)&_logos_method$_ungrouped$SpringBoard$_xen_finaliseAfterSetup, _typeEncoding); }Class _logos_class$_ungrouped$SBLockScreenViewController = objc_getClass("SBLockScreenViewController"); MSHookMessageEx(_logos_class$_ungrouped$SBLockScreenViewController, @selector(suppressesSiri), (IMP)&_logos_method$_ungrouped$SBLockScreenViewController$suppressesSiri, (IMP*)&_logos_orig$_ungrouped$SBLockScreenViewController$suppressesSiri);Class _logos_class$_ungrouped$SBBacklightController = objc_getClass("SBBacklightController"); MSHookMessageEx(_logos_class$_ungrouped$SBBacklightController, @selector(_lockScreenDimTimerFired), (IMP)&_logos_method$_ungrouped$SBBacklightController$_lockScreenDimTimerFired, (IMP*)&_logos_orig$_ungrouped$SBBacklightController$_lockScreenDimTimerFired);}
    
    if (sb) {
        if ([[UIDevice currentDevice].systemVersion floatValue] >= 11.0 || [[UIDevice currentDevice].systemVersion floatValue] < 9.0) {
            
            return;
        }
        
        dlopen("/System/Library/SpringBoardPlugins/NowPlayingArtLockScreen.lockbundle/NowPlayingArtLockScreen", 2);
        
        {Class _logos_class$SpringBoard$SBLockScreenScrollView = objc_getClass("SBLockScreenScrollView"); MSHookMessageEx(_logos_class$SpringBoard$SBLockScreenScrollView, @selector(initWithFrame:), (IMP)&_logos_method$SpringBoard$SBLockScreenScrollView$initWithFrame$, (IMP*)&_logos_orig$SpringBoard$SBLockScreenScrollView$initWithFrame$);Class _logos_class$SpringBoard$XENScrollView = objc_getClass("XENScrollView"); MSHookMessageEx(_logos_class$SpringBoard$XENScrollView, @selector(setDelegate:), (IMP)&_logos_method$SpringBoard$XENScrollView$setDelegate$, (IMP*)&_logos_orig$SpringBoard$XENScrollView$setDelegate$);MSHookMessageEx(_logos_class$SpringBoard$XENScrollView, @selector(addSubview:), (IMP)&_logos_method$SpringBoard$XENScrollView$addSubview$, (IMP*)&_logos_orig$SpringBoard$XENScrollView$addSubview$);MSHookMessageEx(_logos_class$SpringBoard$XENScrollView, @selector(touchesShouldCancelInContentView:), (IMP)&_logos_method$SpringBoard$XENScrollView$touchesShouldCancelInContentView$, (IMP*)&_logos_orig$SpringBoard$XENScrollView$touchesShouldCancelInContentView$);MSHookMessageEx(_logos_class$SpringBoard$XENScrollView, @selector(setContentOffset:), (IMP)&_logos_method$SpringBoard$XENScrollView$setContentOffset$, (IMP*)&_logos_orig$SpringBoard$XENScrollView$setContentOffset$);Class _logos_class$SpringBoard$SBLockScreenViewController = objc_getClass("SBLockScreenViewController"); MSHookMessageEx(_logos_class$SpringBoard$SBLockScreenViewController, @selector(addChildViewController:), (IMP)&_logos_method$SpringBoard$SBLockScreenViewController$addChildViewController$, (IMP*)&_logos_orig$SpringBoard$SBLockScreenViewController$addChildViewController$);MSHookMessageEx(_logos_class$SpringBoard$SBLockScreenViewController, @selector(willRotateToInterfaceOrientation:duration:), (IMP)&_logos_method$SpringBoard$SBLockScreenViewController$willRotateToInterfaceOrientation$duration$, (IMP*)&_logos_orig$SpringBoard$SBLockScreenViewController$willRotateToInterfaceOrientation$duration$);MSHookMessageEx(_logos_class$SpringBoard$SBLockScreenViewController, @selector(didRotateFromInterfaceOrientation:), (IMP)&_logos_method$SpringBoard$SBLockScreenViewController$didRotateFromInterfaceOrientation$, (IMP*)&_logos_orig$SpringBoard$SBLockScreenViewController$didRotateFromInterfaceOrientation$);MSHookMessageEx(_logos_class$SpringBoard$SBLockScreenViewController, @selector(isBounceEnabledForPresentingController:locationInWindow:), (IMP)&_logos_method$SpringBoard$SBLockScreenViewController$isBounceEnabledForPresentingController$locationInWindow$, (IMP*)&_logos_orig$SpringBoard$SBLockScreenViewController$isBounceEnabledForPresentingController$locationInWindow$);MSHookMessageEx(_logos_class$SpringBoard$SBLockScreenViewController, @selector(_releaseLockScreenView), (IMP)&_logos_method$SpringBoard$SBLockScreenViewController$_releaseLockScreenView, (IMP*)&_logos_orig$SpringBoard$SBLockScreenViewController$_releaseLockScreenView);MSHookMessageEx(_logos_class$SpringBoard$SBLockScreenViewController, @selector(passcodeLockViewCancelButtonPressed:), (IMP)&_logos_method$SpringBoard$SBLockScreenViewController$passcodeLockViewCancelButtonPressed$, (IMP*)&_logos_orig$SpringBoard$SBLockScreenViewController$passcodeLockViewCancelButtonPressed$);MSHookMessageEx(_logos_class$SpringBoard$SBLockScreenViewController, @selector(_handleDisplayTurnedOff), (IMP)&_logos_method$SpringBoard$SBLockScreenViewController$_handleDisplayTurnedOff, (IMP*)&_logos_orig$SpringBoard$SBLockScreenViewController$_handleDisplayTurnedOff);{ char _typeEncoding[1024]; unsigned int i = 0; _typeEncoding[i] = 'v'; i += 1; _typeEncoding[i] = '@'; i += 1; _typeEncoding[i] = ':'; i += 1; _typeEncoding[i] = '@'; i += 1; _typeEncoding[i] = '\0'; class_addMethod(_logos_class$SpringBoard$SBLockScreenViewController, @selector(_xen_peekTimerDidFire:), (IMP)&_logos_method$SpringBoard$SBLockScreenViewController$_xen_peekTimerDidFire$, _typeEncoding); }MSHookMessageEx(_logos_class$SpringBoard$SBLockScreenViewController, @selector(_addCameraGrabberIfNecessary), (IMP)&_logos_method$SpringBoard$SBLockScreenViewController$_addCameraGrabberIfNecessary, (IMP*)&_logos_orig$SpringBoard$SBLockScreenViewController$_addCameraGrabberIfNecessary);MSHookMessageEx(_logos_class$SpringBoard$SBLockScreenViewController, @selector(statusBarStyle), (IMP)&_logos_method$SpringBoard$SBLockScreenViewController$statusBarStyle, (IMP*)&_logos_orig$SpringBoard$SBLockScreenViewController$statusBarStyle);MSHookMessageEx(_logos_class$SpringBoard$SBLockScreenViewController, @selector(_effectiveLegibilitySettings), (IMP)&_logos_method$SpringBoard$SBLockScreenViewController$_effectiveLegibilitySettings, (IMP*)&_logos_orig$SpringBoard$SBLockScreenViewController$_effectiveLegibilitySettings);MSHookMessageEx(_logos_class$SpringBoard$SBLockScreenViewController, @selector(_updateLegibility), (IMP)&_logos_method$SpringBoard$SBLockScreenViewController$_updateLegibility, (IMP*)&_logos_orig$SpringBoard$SBLockScreenViewController$_updateLegibility);MSHookMessageEx(_logos_class$SpringBoard$SBLockScreenViewController, @selector(wallpaperLegibilitySettingsDidChange:forVariant:), (IMP)&_logos_method$SpringBoard$SBLockScreenViewController$wallpaperLegibilitySettingsDidChange$forVariant$, (IMP*)&_logos_orig$SpringBoard$SBLockScreenViewController$wallpaperLegibilitySettingsDidChange$forVariant$);MSHookMessageEx(_logos_class$SpringBoard$SBLockScreenViewController, @selector(initWithNibName:bundle:), (IMP)&_logos_method$SpringBoard$SBLockScreenViewController$initWithNibName$bundle$, (IMP*)&_logos_orig$SpringBoard$SBLockScreenViewController$initWithNibName$bundle$);MSHookMessageEx(_logos_class$SpringBoard$SBLockScreenViewController, @selector(_wallpaperLegibilitySettings), (IMP)&_logos_method$SpringBoard$SBLockScreenViewController$_wallpaperLegibilitySettings, (IMP*)&_logos_orig$SpringBoard$SBLockScreenViewController$_wallpaperLegibilitySettings);MSHookMessageEx(_logos_class$SpringBoard$SBLockScreenViewController, @selector(_addDeviceInformationTextView), (IMP)&_logos_method$SpringBoard$SBLockScreenViewController$_addDeviceInformationTextView, (IMP*)&_logos_orig$SpringBoard$SBLockScreenViewController$_addDeviceInformationTextView);MSHookMessageEx(_logos_class$SpringBoard$SBLockScreenViewController, @selector(_handleDisplayTurnedOnWhileUILocked:), (IMP)&_logos_method$SpringBoard$SBLockScreenViewController$_handleDisplayTurnedOnWhileUILocked$, (IMP*)&_logos_orig$SpringBoard$SBLockScreenViewController$_handleDisplayTurnedOnWhileUILocked$);MSHookMessageEx(_logos_class$SpringBoard$SBLockScreenViewController, @selector(_setMediaControlsVisible:), (IMP)&_logos_method$SpringBoard$SBLockScreenViewController$_setMediaControlsVisible$, (IMP*)&_logos_orig$SpringBoard$SBLockScreenViewController$_setMediaControlsVisible$);MSHookMessageEx(_logos_class$SpringBoard$SBLockScreenViewController, @selector(handleMenuButtonTap), (IMP)&_logos_method$SpringBoard$SBLockScreenViewController$handleMenuButtonTap, (IMP*)&_logos_orig$SpringBoard$SBLockScreenViewController$handleMenuButtonTap);MSHookMessageEx(_logos_class$SpringBoard$SBLockScreenViewController, @selector(suppressesControlCenter), (IMP)&_logos_method$SpringBoard$SBLockScreenViewController$suppressesControlCenter, (IMP*)&_logos_orig$SpringBoard$SBLockScreenViewController$suppressesControlCenter);MSHookMessageEx(_logos_class$SpringBoard$SBLockScreenViewController, @selector(_addMediaControls), (IMP)&_logos_method$SpringBoard$SBLockScreenViewController$_addMediaControls, (IMP*)&_logos_orig$SpringBoard$SBLockScreenViewController$_addMediaControls);MSHookMessageEx(_logos_class$SpringBoard$SBLockScreenViewController, @selector(_shouldShowChargingText), (IMP)&_logos_method$SpringBoard$SBLockScreenViewController$_shouldShowChargingText, (IMP*)&_logos_orig$SpringBoard$SBLockScreenViewController$_shouldShowChargingText);Class _logos_class$SpringBoard$SBDashBoardViewController = objc_getClass("SBDashBoardViewController"); MSHookMessageEx(_logos_class$SpringBoard$SBDashBoardViewController, @selector(initWithPageViewControllers:mainPageViewController:legibilityProvider:), (IMP)&_logos_method$SpringBoard$SBDashBoardViewController$initWithPageViewControllers$mainPageViewController$legibilityProvider$, (IMP*)&_logos_orig$SpringBoard$SBDashBoardViewController$initWithPageViewControllers$mainPageViewController$legibilityProvider$);MSHookMessageEx(_logos_class$SpringBoard$SBDashBoardViewController, @selector(_setAllowedPageViewControllers:), (IMP)&_logos_method$SpringBoard$SBDashBoardViewController$_setAllowedPageViewControllers$, (IMP*)&_logos_orig$SpringBoard$SBDashBoardViewController$_setAllowedPageViewControllers$);MSHookMessageEx(_logos_class$SpringBoard$SBDashBoardViewController, @selector(loadView), (IMP)&_logos_method$SpringBoard$SBDashBoardViewController$loadView, (IMP*)&_logos_orig$SpringBoard$SBDashBoardViewController$loadView);MSHookMessageEx(_logos_class$SpringBoard$SBDashBoardViewController, @selector(viewWillAppear:), (IMP)&_logos_method$SpringBoard$SBDashBoardViewController$viewWillAppear$, (IMP*)&_logos_orig$SpringBoard$SBDashBoardViewController$viewWillAppear$);{ char _typeEncoding[1024]; unsigned int i = 0; _typeEncoding[i] = '@'; i += 1; _typeEncoding[i] = '@'; i += 1; _typeEncoding[i] = ':'; i += 1; memcpy(_typeEncoding + i, @encode(NSString*), strlen(@encode(NSString*))); i += strlen(@encode(NSString*)); memcpy(_typeEncoding + i, @encode(NSArray*), strlen(@encode(NSArray*))); i += strlen(@encode(NSArray*)); _typeEncoding[i] = '\0'; class_addMethod(_logos_class$SpringBoard$SBDashBoardViewController, @selector(_xen_fetchWithIdentifier:andArray:), (IMP)&_logos_method$SpringBoard$SBDashBoardViewController$_xen_fetchWithIdentifier$andArray$, _typeEncoding); }MSHookMessageEx(_logos_class$SpringBoard$SBDashBoardViewController, @selector(canUIUnlockFromSource:), (IMP)&_logos_method$SpringBoard$SBDashBoardViewController$canUIUnlockFromSource$, (IMP*)&_logos_orig$SpringBoard$SBDashBoardViewController$canUIUnlockFromSource$);MSHookMessageEx(_logos_class$SpringBoard$SBDashBoardViewController, @selector(viewWillTransitionToSize:withTransitionCoordinator:), (IMP)&_logos_method$SpringBoard$SBDashBoardViewController$viewWillTransitionToSize$withTransitionCoordinator$, (IMP*)&_logos_orig$SpringBoard$SBDashBoardViewController$viewWillTransitionToSize$withTransitionCoordinator$);MSHookMessageEx(_logos_class$SpringBoard$SBDashBoardViewController, @selector(setInScreenOffMode:forAutoUnlock:), (IMP)&_logos_method$SpringBoard$SBDashBoardViewController$setInScreenOffMode$forAutoUnlock$, (IMP*)&_logos_orig$SpringBoard$SBDashBoardViewController$setInScreenOffMode$forAutoUnlock$);MSHookMessageEx(_logos_class$SpringBoard$SBDashBoardViewController, @selector(statusBarStyle), (IMP)&_logos_method$SpringBoard$SBDashBoardViewController$statusBarStyle, (IMP*)&_logos_orig$SpringBoard$SBDashBoardViewController$statusBarStyle);MSHookMessageEx(_logos_class$SpringBoard$SBDashBoardViewController, @selector(_updateLegibilitySettings), (IMP)&_logos_method$SpringBoard$SBDashBoardViewController$_updateLegibilitySettings, (IMP*)&_logos_orig$SpringBoard$SBDashBoardViewController$_updateLegibilitySettings);MSHookMessageEx(_logos_class$SpringBoard$SBDashBoardViewController, @selector(setPasscodeLockVisible:animated:completion:), (IMP)&_logos_method$SpringBoard$SBDashBoardViewController$setPasscodeLockVisible$animated$completion$, (IMP*)&_logos_orig$SpringBoard$SBDashBoardViewController$setPasscodeLockVisible$animated$completion$);MSHookMessageEx(_logos_class$SpringBoard$SBDashBoardViewController, @selector(handleBiometricEvent:), (IMP)&_logos_method$SpringBoard$SBDashBoardViewController$handleBiometricEvent$, (IMP*)&_logos_orig$SpringBoard$SBDashBoardViewController$handleBiometricEvent$);MSHookMessageEx(_logos_class$SpringBoard$SBDashBoardViewController, @selector(handleMenuButtonTap), (IMP)&_logos_method$SpringBoard$SBDashBoardViewController$handleMenuButtonTap, (IMP*)&_logos_orig$SpringBoard$SBDashBoardViewController$handleMenuButtonTap);MSHookMessageEx(_logos_class$SpringBoard$SBDashBoardViewController, @selector(handleMenuButtonHeld), (IMP)&_logos_method$SpringBoard$SBDashBoardViewController$handleMenuButtonHeld, (IMP*)&_logos_orig$SpringBoard$SBDashBoardViewController$handleMenuButtonHeld);{ char _typeEncoding[1024]; unsigned int i = 0; _typeEncoding[i] = 'v'; i += 1; _typeEncoding[i] = '@'; i += 1; _typeEncoding[i] = ':'; i += 1; _typeEncoding[i] = '\0'; class_addMethod(_logos_class$SpringBoard$SBDashBoardViewController, @selector(xen_dismissContentEditor), (IMP)&_logos_method$SpringBoard$SBDashBoardViewController$xen_dismissContentEditor, _typeEncoding); }Class _logos_class$SpringBoard$SBLockScreenToAppsWorkspaceTransaction = objc_getClass("SBLockScreenToAppsWorkspaceTransaction"); MSHookMessageEx(_logos_class$SpringBoard$SBLockScreenToAppsWorkspaceTransaction, @selector(_didComplete), (IMP)&_logos_method$SpringBoard$SBLockScreenToAppsWorkspaceTransaction$_didComplete, (IMP*)&_logos_orig$SpringBoard$SBLockScreenToAppsWorkspaceTransaction$_didComplete);Class _logos_class$SpringBoard$SBDashBoardPageViewController = objc_getClass("SBDashBoardPageViewController"); { char _typeEncoding[1024]; unsigned int i = 0; memcpy(_typeEncoding + i, @encode(NSString*), strlen(@encode(NSString*))); i += strlen(@encode(NSString*)); _typeEncoding[i] = '@'; i += 1; _typeEncoding[i] = ':'; i += 1; _typeEncoding[i] = '\0'; class_addMethod(_logos_class$SpringBoard$SBDashBoardPageViewController, @selector(_xen_identifier), (IMP)&_logos_method$SpringBoard$SBDashBoardPageViewController$_xen_identifier, _typeEncoding); }{ char _typeEncoding[1024]; unsigned int i = 0; memcpy(_typeEncoding + i, @encode(NSString*), strlen(@encode(NSString*))); i += strlen(@encode(NSString*)); _typeEncoding[i] = '@'; i += 1; _typeEncoding[i] = ':'; i += 1; _typeEncoding[i] = '\0'; class_addMethod(_logos_class$SpringBoard$SBDashBoardPageViewController, @selector(_xen_name), (IMP)&_logos_method$SpringBoard$SBDashBoardPageViewController$_xen_name, _typeEncoding); }Class _logos_class$SpringBoard$SBDashBoardTodayPageViewController = objc_getClass("SBDashBoardTodayPageViewController"); { char _typeEncoding[1024]; unsigned int i = 0; memcpy(_typeEncoding + i, @encode(NSString*), strlen(@encode(NSString*))); i += strlen(@encode(NSString*)); _typeEncoding[i] = '@'; i += 1; _typeEncoding[i] = ':'; i += 1; _typeEncoding[i] = '\0'; class_addMethod(_logos_class$SpringBoard$SBDashBoardTodayPageViewController, @selector(_xen_identifier), (IMP)&_logos_method$SpringBoard$SBDashBoardTodayPageViewController$_xen_identifier, _typeEncoding); }{ char _typeEncoding[1024]; unsigned int i = 0; memcpy(_typeEncoding + i, @encode(NSString*), strlen(@encode(NSString*))); i += strlen(@encode(NSString*)); _typeEncoding[i] = '@'; i += 1; _typeEncoding[i] = ':'; i += 1; _typeEncoding[i] = '\0'; class_addMethod(_logos_class$SpringBoard$SBDashBoardTodayPageViewController, @selector(_xen_name), (IMP)&_logos_method$SpringBoard$SBDashBoardTodayPageViewController$_xen_name, _typeEncoding); }MSHookMessageEx(_logos_class$SpringBoard$SBDashBoardTodayPageViewController, @selector(viewDidLayoutSubviews), (IMP)&_logos_method$SpringBoard$SBDashBoardTodayPageViewController$viewDidLayoutSubviews, (IMP*)&_logos_orig$SpringBoard$SBDashBoardTodayPageViewController$viewDidLayoutSubviews);Class _logos_class$SpringBoard$SBDashBoardCameraPageViewController = objc_getClass("SBDashBoardCameraPageViewController"); { char _typeEncoding[1024]; unsigned int i = 0; memcpy(_typeEncoding + i, @encode(NSString*), strlen(@encode(NSString*))); i += strlen(@encode(NSString*)); _typeEncoding[i] = '@'; i += 1; _typeEncoding[i] = ':'; i += 1; _typeEncoding[i] = '\0'; class_addMethod(_logos_class$SpringBoard$SBDashBoardCameraPageViewController, @selector(_xen_identifier), (IMP)&_logos_method$SpringBoard$SBDashBoardCameraPageViewController$_xen_identifier, _typeEncoding); }{ char _typeEncoding[1024]; unsigned int i = 0; memcpy(_typeEncoding + i, @encode(NSString*), strlen(@encode(NSString*))); i += strlen(@encode(NSString*)); _typeEncoding[i] = '@'; i += 1; _typeEncoding[i] = ':'; i += 1; _typeEncoding[i] = '\0'; class_addMethod(_logos_class$SpringBoard$SBDashBoardCameraPageViewController, @selector(_xen_name), (IMP)&_logos_method$SpringBoard$SBDashBoardCameraPageViewController$_xen_name, _typeEncoding); }MSHookMessageEx(_logos_class$SpringBoard$SBDashBoardCameraPageViewController, @selector(viewDidLayoutSubviews), (IMP)&_logos_method$SpringBoard$SBDashBoardCameraPageViewController$viewDidLayoutSubviews, (IMP*)&_logos_orig$SpringBoard$SBDashBoardCameraPageViewController$viewDidLayoutSubviews);MSHookMessageEx(_logos_class$SpringBoard$SBDashBoardCameraPageViewController, @selector(aggregateAppearance:), (IMP)&_logos_method$SpringBoard$SBDashBoardCameraPageViewController$aggregateAppearance$, (IMP*)&_logos_orig$SpringBoard$SBDashBoardCameraPageViewController$aggregateAppearance$);Class _logos_class$SpringBoard$SBDashBoardMainPageViewController = objc_getClass("SBDashBoardMainPageViewController"); { char _typeEncoding[1024]; unsigned int i = 0; memcpy(_typeEncoding + i, @encode(NSString*), strlen(@encode(NSString*))); i += strlen(@encode(NSString*)); _typeEncoding[i] = '@'; i += 1; _typeEncoding[i] = ':'; i += 1; _typeEncoding[i] = '\0'; class_addMethod(_logos_class$SpringBoard$SBDashBoardMainPageViewController, @selector(_xen_identifier), (IMP)&_logos_method$SpringBoard$SBDashBoardMainPageViewController$_xen_identifier, _typeEncoding); }{ char _typeEncoding[1024]; unsigned int i = 0; memcpy(_typeEncoding + i, @encode(NSString*), strlen(@encode(NSString*))); i += strlen(@encode(NSString*)); _typeEncoding[i] = '@'; i += 1; _typeEncoding[i] = ':'; i += 1; _typeEncoding[i] = '\0'; class_addMethod(_logos_class$SpringBoard$SBDashBoardMainPageViewController, @selector(_xen_name), (IMP)&_logos_method$SpringBoard$SBDashBoardMainPageViewController$_xen_name, _typeEncoding); }MSHookMessageEx(_logos_class$SpringBoard$SBDashBoardMainPageViewController, @selector(viewDidLayoutSubviews), (IMP)&_logos_method$SpringBoard$SBDashBoardMainPageViewController$viewDidLayoutSubviews, (IMP*)&_logos_orig$SpringBoard$SBDashBoardMainPageViewController$viewDidLayoutSubviews);Class _logos_class$SpringBoard$XENDashBoardPageViewController = objc_getClass("XENDashBoardPageViewController"); Class _logos_metaclass$SpringBoard$XENDashBoardPageViewController = object_getClass(_logos_class$SpringBoard$XENDashBoardPageViewController); MSHookMessageEx(_logos_metaclass$SpringBoard$XENDashBoardPageViewController, @selector(requiredCapabilities), (IMP)&_logos_meta_method$SpringBoard$XENDashBoardPageViewController$requiredCapabilities, (IMP*)&_logos_meta_orig$SpringBoard$XENDashBoardPageViewController$requiredCapabilities);MSHookMessageEx(_logos_metaclass$SpringBoard$XENDashBoardPageViewController, @selector(isAvailableForConfiguration), (IMP)&_logos_meta_method$SpringBoard$XENDashBoardPageViewController$isAvailableForConfiguration, (IMP*)&_logos_meta_orig$SpringBoard$XENDashBoardPageViewController$isAvailableForConfiguration);MSHookMessageEx(_logos_class$SpringBoard$XENDashBoardPageViewController, @selector(didTransitionToVisible:), (IMP)&_logos_method$SpringBoard$XENDashBoardPageViewController$didTransitionToVisible$, (IMP*)&_logos_orig$SpringBoard$XENDashBoardPageViewController$didTransitionToVisible$);MSHookMessageEx(_logos_class$SpringBoard$XENDashBoardPageViewController, @selector(updateTransitionToVisible:progress:mode:), (IMP)&_logos_method$SpringBoard$XENDashBoardPageViewController$updateTransitionToVisible$progress$mode$, (IMP*)&_logos_orig$SpringBoard$XENDashBoardPageViewController$updateTransitionToVisible$progress$mode$);MSHookMessageEx(_logos_class$SpringBoard$XENDashBoardPageViewController, @selector(aggregateAppearance:), (IMP)&_logos_method$SpringBoard$XENDashBoardPageViewController$aggregateAppearance$, (IMP*)&_logos_orig$SpringBoard$XENDashBoardPageViewController$aggregateAppearance$);MSHookMessageEx(_logos_class$SpringBoard$XENDashBoardPageViewController, @selector(aggregateBehavior:), (IMP)&_logos_method$SpringBoard$XENDashBoardPageViewController$aggregateBehavior$, (IMP*)&_logos_orig$SpringBoard$XENDashBoardPageViewController$aggregateBehavior$);{ char _typeEncoding[1024]; unsigned int i = 0; _typeEncoding[i] = 'v'; i += 1; _typeEncoding[i] = '@'; i += 1; _typeEncoding[i] = ':'; i += 1; _typeEncoding[i] = '\0'; class_addMethod(_logos_class$SpringBoard$XENDashBoardPageViewController, @selector(_xen_addViewIfNeeded), (IMP)&_logos_method$SpringBoard$XENDashBoardPageViewController$_xen_addViewIfNeeded, _typeEncoding); }MSHookMessageEx(_logos_class$SpringBoard$XENDashBoardPageViewController, @selector(loadView), (IMP)&_logos_method$SpringBoard$XENDashBoardPageViewController$loadView, (IMP*)&_logos_orig$SpringBoard$XENDashBoardPageViewController$loadView);MSHookMessageEx(_logos_class$SpringBoard$XENDashBoardPageViewController, @selector(viewDidAppear:), (IMP)&_logos_method$SpringBoard$XENDashBoardPageViewController$viewDidAppear$, (IMP*)&_logos_orig$SpringBoard$XENDashBoardPageViewController$viewDidAppear$);MSHookMessageEx(_logos_class$SpringBoard$XENDashBoardPageViewController, @selector(viewDidLoad), (IMP)&_logos_method$SpringBoard$XENDashBoardPageViewController$viewDidLoad, (IMP*)&_logos_orig$SpringBoard$XENDashBoardPageViewController$viewDidLoad);MSHookMessageEx(_logos_class$SpringBoard$XENDashBoardPageViewController, @selector(viewWillAppear:), (IMP)&_logos_method$SpringBoard$XENDashBoardPageViewController$viewWillAppear$, (IMP*)&_logos_orig$SpringBoard$XENDashBoardPageViewController$viewWillAppear$);MSHookMessageEx(_logos_class$SpringBoard$XENDashBoardPageViewController, @selector(viewDidDisappear:), (IMP)&_logos_method$SpringBoard$XENDashBoardPageViewController$viewDidDisappear$, (IMP*)&_logos_orig$SpringBoard$XENDashBoardPageViewController$viewDidDisappear$);MSHookMessageEx(_logos_class$SpringBoard$XENDashBoardPageViewController, @selector(viewDidLayoutSubviews), (IMP)&_logos_method$SpringBoard$XENDashBoardPageViewController$viewDidLayoutSubviews, (IMP*)&_logos_orig$SpringBoard$XENDashBoardPageViewController$viewDidLayoutSubviews);MSHookMessageEx(_logos_class$SpringBoard$XENDashBoardPageViewController, @selector(backgroundStyle), (IMP)&_logos_method$SpringBoard$XENDashBoardPageViewController$backgroundStyle, (IMP*)&_logos_orig$SpringBoard$XENDashBoardPageViewController$backgroundStyle);{ char _typeEncoding[1024]; unsigned int i = 0; memcpy(_typeEncoding + i, @encode(NSString*), strlen(@encode(NSString*))); i += strlen(@encode(NSString*)); _typeEncoding[i] = '@'; i += 1; _typeEncoding[i] = ':'; i += 1; _typeEncoding[i] = '\0'; class_addMethod(_logos_class$SpringBoard$XENDashBoardPageViewController, @selector(_xen_identifier), (IMP)&_logos_method$SpringBoard$XENDashBoardPageViewController$_xen_identifier, _typeEncoding); }{ char _typeEncoding[1024]; unsigned int i = 0; memcpy(_typeEncoding + i, @encode(NSString*), strlen(@encode(NSString*))); i += strlen(@encode(NSString*)); _typeEncoding[i] = '@'; i += 1; _typeEncoding[i] = ':'; i += 1; _typeEncoding[i] = '\0'; class_addMethod(_logos_class$SpringBoard$XENDashBoardPageViewController, @selector(_xen_name), (IMP)&_logos_method$SpringBoard$XENDashBoardPageViewController$_xen_name, _typeEncoding); }{ class_addMethod(_logos_class$SpringBoard$XENDashBoardPageViewController, @selector(xenController), (IMP)&_logos_method$SpringBoard$XENDashBoardPageViewController$xenController$, [[NSString stringWithFormat:@"%s@:", @encode(XENBaseViewController *)] UTF8String]);class_addMethod(_logos_class$SpringBoard$XENDashBoardPageViewController, @selector(setXenController:), (IMP)&_logos_method$SpringBoard$XENDashBoardPageViewController$setXenController$, [[NSString stringWithFormat:@"v@:%s", @encode(XENBaseViewController *)] UTF8String]);} { class_addMethod(_logos_class$SpringBoard$XENDashBoardPageViewController, @selector(xenVisible), (IMP)&_logos_method$SpringBoard$XENDashBoardPageViewController$xenVisible$, [[NSString stringWithFormat:@"%s@:", @encode(BOOL)] UTF8String]);class_addMethod(_logos_class$SpringBoard$XENDashBoardPageViewController, @selector(setXenVisible:), (IMP)&_logos_method$SpringBoard$XENDashBoardPageViewController$setXenVisible$, [[NSString stringWithFormat:@"v@:%s", @encode(BOOL)] UTF8String]);} Class _logos_class$SpringBoard$SBFLockScreenDateView = objc_getClass("SBFLockScreenDateView"); MSHookMessageEx(_logos_class$SpringBoard$SBFLockScreenDateView, @selector(hitTest:withEvent:), (IMP)&_logos_method$SpringBoard$SBFLockScreenDateView$hitTest$withEvent$, (IMP*)&_logos_orig$SpringBoard$SBFLockScreenDateView$hitTest$withEvent$);MSHookMessageEx(_logos_class$SpringBoard$SBFLockScreenDateView, @selector(setFrame:), (IMP)&_logos_method$SpringBoard$SBFLockScreenDateView$setFrame$, (IMP*)&_logos_orig$SpringBoard$SBFLockScreenDateView$setFrame$);MSHookMessageEx(_logos_class$SpringBoard$SBFLockScreenDateView, @selector(layoutSubviews), (IMP)&_logos_method$SpringBoard$SBFLockScreenDateView$layoutSubviews, (IMP*)&_logos_orig$SpringBoard$SBFLockScreenDateView$layoutSubviews);MSHookMessageEx(_logos_class$SpringBoard$SBFLockScreenDateView, @selector(setHidden:), (IMP)&_logos_method$SpringBoard$SBFLockScreenDateView$setHidden$, (IMP*)&_logos_orig$SpringBoard$SBFLockScreenDateView$setHidden$);Class _logos_class$SpringBoard$SBHomeHardwareButtonActions = objc_getClass("SBHomeHardwareButtonActions"); MSHookMessageEx(_logos_class$SpringBoard$SBHomeHardwareButtonActions, @selector(performSinglePressUpActions), (IMP)&_logos_method$SpringBoard$SBHomeHardwareButtonActions$performSinglePressUpActions, (IMP*)&_logos_orig$SpringBoard$SBHomeHardwareButtonActions$performSinglePressUpActions);Class _logos_class$SpringBoard$SBDashBoardHomeButtonShowPasscodeRecognizer = objc_getClass("SBDashBoardHomeButtonShowPasscodeRecognizer"); MSHookMessageEx(_logos_class$SpringBoard$SBDashBoardHomeButtonShowPasscodeRecognizer, @selector(_state), (IMP)&_logos_method$SpringBoard$SBDashBoardHomeButtonShowPasscodeRecognizer$_state, (IMP*)&_logos_orig$SpringBoard$SBDashBoardHomeButtonShowPasscodeRecognizer$_state);Class _logos_class$SpringBoard$SBHorizontalScrollFailureRecognizer = objc_getClass("SBHorizontalScrollFailureRecognizer"); MSHookMessageEx(_logos_class$SpringBoard$SBHorizontalScrollFailureRecognizer, @selector(_isOutOfBounds:forAngle:), (IMP)&_logos_method$SpringBoard$SBHorizontalScrollFailureRecognizer$_isOutOfBounds$forAngle$, (IMP*)&_logos_orig$SpringBoard$SBHorizontalScrollFailureRecognizer$_isOutOfBounds$forAngle$);Class _logos_class$SpringBoard$SBPagedScrollView = objc_getClass("SBPagedScrollView"); MSHookMessageEx(_logos_class$SpringBoard$SBPagedScrollView, @selector(touchesShouldCancelInContentView:), (IMP)&_logos_method$SpringBoard$SBPagedScrollView$touchesShouldCancelInContentView$, (IMP*)&_logos_orig$SpringBoard$SBPagedScrollView$touchesShouldCancelInContentView$);Class _logos_class$SpringBoard$SBLockScreenManager = objc_getClass("SBLockScreenManager"); MSHookMessageEx(_logos_class$SpringBoard$SBLockScreenManager, @selector(lockUIFromSource:withOptions:), (IMP)&_logos_method$SpringBoard$SBLockScreenManager$lockUIFromSource$withOptions$, (IMP*)&_logos_orig$SpringBoard$SBLockScreenManager$lockUIFromSource$withOptions$);MSHookMessageEx(_logos_class$SpringBoard$SBLockScreenManager, @selector(_finishUIUnlockFromSource:withOptions:), (IMP)&_logos_method$SpringBoard$SBLockScreenManager$_finishUIUnlockFromSource$withOptions$, (IMP*)&_logos_orig$SpringBoard$SBLockScreenManager$_finishUIUnlockFromSource$withOptions$);MSHookMessageEx(_logos_class$SpringBoard$SBLockScreenManager, @selector(biometricEventMonitor:handleBiometricEvent:), (IMP)&_logos_method$SpringBoard$SBLockScreenManager$biometricEventMonitor$handleBiometricEvent$, (IMP*)&_logos_orig$SpringBoard$SBLockScreenManager$biometricEventMonitor$handleBiometricEvent$);Class _logos_class$SpringBoard$SBLockScreenView = objc_getClass("SBLockScreenView"); MSHookMessageEx(_logos_class$SpringBoard$SBLockScreenView, @selector(layoutSubviews), (IMP)&_logos_method$SpringBoard$SBLockScreenView$layoutSubviews, (IMP*)&_logos_orig$SpringBoard$SBLockScreenView$layoutSubviews);MSHookMessageEx(_logos_class$SpringBoard$SBLockScreenView, @selector(_layoutNotificationView), (IMP)&_logos_method$SpringBoard$SBLockScreenView$_layoutNotificationView, (IMP*)&_logos_orig$SpringBoard$SBLockScreenView$_layoutNotificationView);MSHookMessageEx(_logos_class$SpringBoard$SBLockScreenView, @selector(resetContentOffsetToCurrentPage), (IMP)&_logos_method$SpringBoard$SBLockScreenView$resetContentOffsetToCurrentPage, (IMP*)&_logos_orig$SpringBoard$SBLockScreenView$resetContentOffsetToCurrentPage);MSHookMessageEx(_logos_class$SpringBoard$SBLockScreenView, @selector(_adjustTopAndBottomGrabbersForPercentScrolled:), (IMP)&_logos_method$SpringBoard$SBLockScreenView$_adjustTopAndBottomGrabbersForPercentScrolled$, (IMP*)&_logos_orig$SpringBoard$SBLockScreenView$_adjustTopAndBottomGrabbersForPercentScrolled$);MSHookMessageEx(_logos_class$SpringBoard$SBLockScreenView, @selector(scrollViewDidEndDecelerating:), (IMP)&_logos_method$SpringBoard$SBLockScreenView$scrollViewDidEndDecelerating$, (IMP*)&_logos_orig$SpringBoard$SBLockScreenView$scrollViewDidEndDecelerating$);MSHookMessageEx(_logos_class$SpringBoard$SBLockScreenView, @selector(scrollViewDidEndDragging:willDecelerate:), (IMP)&_logos_method$SpringBoard$SBLockScreenView$scrollViewDidEndDragging$willDecelerate$, (IMP*)&_logos_orig$SpringBoard$SBLockScreenView$scrollViewDidEndDragging$willDecelerate$);MSHookMessageEx(_logos_class$SpringBoard$SBLockScreenView, @selector(scrollViewDidEndScrollingAnimation:), (IMP)&_logos_method$SpringBoard$SBLockScreenView$scrollViewDidEndScrollingAnimation$, (IMP*)&_logos_orig$SpringBoard$SBLockScreenView$scrollViewDidEndScrollingAnimation$);MSHookMessageEx(_logos_class$SpringBoard$SBLockScreenView, @selector(scrollViewDidScroll:), (IMP)&_logos_method$SpringBoard$SBLockScreenView$scrollViewDidScroll$, (IMP*)&_logos_orig$SpringBoard$SBLockScreenView$scrollViewDidScroll$);MSHookMessageEx(_logos_class$SpringBoard$SBLockScreenView, @selector(scrollViewWillBeginDragging:), (IMP)&_logos_method$SpringBoard$SBLockScreenView$scrollViewWillBeginDragging$, (IMP*)&_logos_orig$SpringBoard$SBLockScreenView$scrollViewWillBeginDragging$);MSHookMessageEx(_logos_class$SpringBoard$SBLockScreenView, @selector(scrollViewWillEndDragging:withVelocity:targetContentOffset:), (IMP)&_logos_method$SpringBoard$SBLockScreenView$scrollViewWillEndDragging$withVelocity$targetContentOffset$, (IMP*)&_logos_orig$SpringBoard$SBLockScreenView$scrollViewWillEndDragging$withVelocity$targetContentOffset$);MSHookMessageEx(_logos_class$SpringBoard$SBLockScreenView, @selector(_slideToUnlockFailureGestureRecognizerChanged), (IMP)&_logos_method$SpringBoard$SBLockScreenView$_slideToUnlockFailureGestureRecognizerChanged, (IMP*)&_logos_orig$SpringBoard$SBLockScreenView$_slideToUnlockFailureGestureRecognizerChanged);MSHookMessageEx(_logos_class$SpringBoard$SBLockScreenView, @selector(_layoutSlideToUnlockView), (IMP)&_logos_method$SpringBoard$SBLockScreenView$_layoutSlideToUnlockView, (IMP*)&_logos_orig$SpringBoard$SBLockScreenView$_layoutSlideToUnlockView);MSHookMessageEx(_logos_class$SpringBoard$SBLockScreenView, @selector(_setCurrentBlurRadius:), (IMP)&_logos_method$SpringBoard$SBLockScreenView$_setCurrentBlurRadius$, (IMP*)&_logos_orig$SpringBoard$SBLockScreenView$_setCurrentBlurRadius$);MSHookMessageEx(_logos_class$SpringBoard$SBLockScreenView, @selector(setPluginView:presentationStyle:notificationBehavior:), (IMP)&_logos_method$SpringBoard$SBLockScreenView$setPluginView$presentationStyle$notificationBehavior$, (IMP*)&_logos_orig$SpringBoard$SBLockScreenView$setPluginView$presentationStyle$notificationBehavior$);MSHookMessageEx(_logos_class$SpringBoard$SBLockScreenView, @selector(scrollToPage:animated:completion:), (IMP)&_logos_method$SpringBoard$SBLockScreenView$scrollToPage$animated$completion$, (IMP*)&_logos_orig$SpringBoard$SBLockScreenView$scrollToPage$animated$completion$);MSHookMessageEx(_logos_class$SpringBoard$SBLockScreenView, @selector(_layoutGrabberView:atTop:percentScrolled:), (IMP)&_logos_method$SpringBoard$SBLockScreenView$_layoutGrabberView$atTop$percentScrolled$, (IMP*)&_logos_orig$SpringBoard$SBLockScreenView$_layoutGrabberView$atTop$percentScrolled$);MSHookMessageEx(_logos_class$SpringBoard$SBLockScreenView, @selector(_showFakeWallpaperBlurWithAlpha:withFactory:), (IMP)&_logos_method$SpringBoard$SBLockScreenView$_showFakeWallpaperBlurWithAlpha$withFactory$, (IMP*)&_logos_orig$SpringBoard$SBLockScreenView$_showFakeWallpaperBlurWithAlpha$withFactory$);MSHookMessageEx(_logos_class$SpringBoard$SBLockScreenView, @selector(_layoutGrabberView:atTop:), (IMP)&_logos_method$SpringBoard$SBLockScreenView$_layoutGrabberView$atTop$, (IMP*)&_logos_orig$SpringBoard$SBLockScreenView$_layoutGrabberView$atTop$);{ char _typeEncoding[1024]; unsigned int i = 0; _typeEncoding[i] = 'v'; i += 1; _typeEncoding[i] = '@'; i += 1; _typeEncoding[i] = ':'; i += 1; _typeEncoding[i] = '\0'; class_addMethod(_logos_class$SpringBoard$SBLockScreenView, @selector(_xen_relayoutDateView), (IMP)&_logos_method$SpringBoard$SBLockScreenView$_xen_relayoutDateView, _typeEncoding); }MSHookMessageEx(_logos_class$SpringBoard$SBLockScreenView, @selector(lp_updateUnderlayAlpha:), (IMP)&_logos_method$SpringBoard$SBLockScreenView$lp_updateUnderlayAlpha$, (IMP*)&_logos_orig$SpringBoard$SBLockScreenView$lp_updateUnderlayAlpha$);MSHookMessageEx(_logos_class$SpringBoard$SBLockScreenView, @selector(lp_updateUnderlayForCurrentScroll), (IMP)&_logos_method$SpringBoard$SBLockScreenView$lp_updateUnderlayForCurrentScroll, (IMP*)&_logos_orig$SpringBoard$SBLockScreenView$lp_updateUnderlayForCurrentScroll);Class _logos_class$SpringBoard$SBFLockScreenMetrics = objc_getClass("SBFLockScreenMetrics"); Class _logos_metaclass$SpringBoard$SBFLockScreenMetrics = object_getClass(_logos_class$SpringBoard$SBFLockScreenMetrics); MSHookMessageEx(_logos_metaclass$SpringBoard$SBFLockScreenMetrics, @selector(notificationListInsets), (IMP)&_logos_meta_method$SpringBoard$SBFLockScreenMetrics$notificationListInsets, (IMP*)&_logos_meta_orig$SpringBoard$SBFLockScreenMetrics$notificationListInsets);Class _logos_class$SpringBoard$SBDashBoardPageControl = objc_getClass("SBDashBoardPageControl"); MSHookMessageEx(_logos_class$SpringBoard$SBDashBoardPageControl, @selector(_setIndicatorImage:toEnabled:index:), (IMP)&_logos_method$SpringBoard$SBDashBoardPageControl$_setIndicatorImage$toEnabled$index$, (IMP*)&_logos_orig$SpringBoard$SBDashBoardPageControl$_setIndicatorImage$toEnabled$index$);{ char _typeEncoding[1024]; unsigned int i = 0; _typeEncoding[i] = '@'; i += 1; _typeEncoding[i] = '@'; i += 1; _typeEncoding[i] = ':'; i += 1; memcpy(_typeEncoding + i, @encode(BOOL), strlen(@encode(BOOL))); i += strlen(@encode(BOOL)); _typeEncoding[i] = '\0'; class_addMethod(_logos_class$SpringBoard$SBDashBoardPageControl, @selector(_xen_unlockIndicatorImage:), (IMP)&_logos_method$SpringBoard$SBDashBoardPageControl$_xen_unlockIndicatorImage$, _typeEncoding); }Class _logos_class$SpringBoard$SBSlideToUnlockFailureRecognizer = objc_getClass("SBSlideToUnlockFailureRecognizer"); MSHookMessageEx(_logos_class$SpringBoard$SBSlideToUnlockFailureRecognizer, @selector(_isOutOfBoundsVertically:), (IMP)&_logos_method$SpringBoard$SBSlideToUnlockFailureRecognizer$_isOutOfBoundsVertically$, (IMP*)&_logos_orig$SpringBoard$SBSlideToUnlockFailureRecognizer$_isOutOfBoundsVertically$);Class _logos_class$SpringBoard$SBLockScreenBounceAnimator = objc_getClass("SBLockScreenBounceAnimator"); MSHookMessageEx(_logos_class$SpringBoard$SBLockScreenBounceAnimator, @selector(_handleTapGesture:), (IMP)&_logos_method$SpringBoard$SBLockScreenBounceAnimator$_handleTapGesture$, (IMP*)&_logos_orig$SpringBoard$SBLockScreenBounceAnimator$_handleTapGesture$);Class _logos_class$SpringBoard$SBDashBoardPasscodeViewController = objc_getClass("SBDashBoardPasscodeViewController"); MSHookMessageEx(_logos_class$SpringBoard$SBDashBoardPasscodeViewController, @selector(passcodeLockViewCancelButtonPressed:), (IMP)&_logos_method$SpringBoard$SBDashBoardPasscodeViewController$passcodeLockViewCancelButtonPressed$, (IMP*)&_logos_orig$SpringBoard$SBDashBoardPasscodeViewController$passcodeLockViewCancelButtonPressed$);{ char _typeEncoding[1024]; unsigned int i = 0; memcpy(_typeEncoding + i, @encode(SBUIPasscodeLockViewBase*), strlen(@encode(SBUIPasscodeLockViewBase*))); i += strlen(@encode(SBUIPasscodeLockViewBase*)); _typeEncoding[i] = '@'; i += 1; _typeEncoding[i] = ':'; i += 1; _typeEncoding[i] = '\0'; class_addMethod(_logos_class$SpringBoard$SBDashBoardPasscodeViewController, @selector(_xen_passcodeLockView), (IMP)&_logos_method$SpringBoard$SBDashBoardPasscodeViewController$_xen_passcodeLockView, _typeEncoding); }{ char _typeEncoding[1024]; unsigned int i = 0; memcpy(_typeEncoding + i, @encode(UIView*), strlen(@encode(UIView*))); i += strlen(@encode(UIView*)); _typeEncoding[i] = '@'; i += 1; _typeEncoding[i] = ':'; i += 1; _typeEncoding[i] = '\0'; class_addMethod(_logos_class$SpringBoard$SBDashBoardPasscodeViewController, @selector(_xen_backgroundView), (IMP)&_logos_method$SpringBoard$SBDashBoardPasscodeViewController$_xen_backgroundView, _typeEncoding); }Class _logos_class$SpringBoard$SBUICallToActionLabel = objc_getClass("SBUICallToActionLabel"); MSHookMessageEx(_logos_class$SpringBoard$SBUICallToActionLabel, @selector(setText:forLanguage:animated:), (IMP)&_logos_method$SpringBoard$SBUICallToActionLabel$setText$forLanguage$animated$, (IMP*)&_logos_orig$SpringBoard$SBUICallToActionLabel$setText$forLanguage$animated$);Class _logos_class$SpringBoard$_UIGlintyStringView = objc_getClass("_UIGlintyStringView"); MSHookMessageEx(_logos_class$SpringBoard$_UIGlintyStringView, @selector(_chevronWidthWithPadding), (IMP)&_logos_method$SpringBoard$_UIGlintyStringView$_chevronWidthWithPadding, (IMP*)&_logos_orig$SpringBoard$_UIGlintyStringView$_chevronWidthWithPadding);MSHookMessageEx(_logos_class$SpringBoard$_UIGlintyStringView, @selector(chevronStyle), (IMP)&_logos_method$SpringBoard$_UIGlintyStringView$chevronStyle, (IMP*)&_logos_orig$SpringBoard$_UIGlintyStringView$chevronStyle);MSHookMessageEx(_logos_class$SpringBoard$_UIGlintyStringView, @selector(setChevronStyle:), (IMP)&_logos_method$SpringBoard$_UIGlintyStringView$setChevronStyle$, (IMP*)&_logos_orig$SpringBoard$_UIGlintyStringView$setChevronStyle$);MSHookMessageEx(_logos_class$SpringBoard$_UIGlintyStringView, @selector(_chevronPadding), (IMP)&_logos_method$SpringBoard$_UIGlintyStringView$_chevronPadding, (IMP*)&_logos_orig$SpringBoard$_UIGlintyStringView$_chevronPadding);MSHookMessageEx(_logos_class$SpringBoard$_UIGlintyStringView, @selector(_chevronImageForStyle:), (IMP)&_logos_method$SpringBoard$_UIGlintyStringView$_chevronImageForStyle$, (IMP*)&_logos_orig$SpringBoard$_UIGlintyStringView$_chevronImageForStyle$);MSHookMessageEx(_logos_class$SpringBoard$_UIGlintyStringView, @selector(chevronFrame), (IMP)&_logos_method$SpringBoard$_UIGlintyStringView$chevronFrame, (IMP*)&_logos_orig$SpringBoard$_UIGlintyStringView$chevronFrame);Class _logos_class$SpringBoard$SBLockOverlayStyleProperties = objc_getClass("SBLockOverlayStyleProperties"); MSHookMessageEx(_logos_class$SpringBoard$SBLockOverlayStyleProperties, @selector(tintAlpha), (IMP)&_logos_method$SpringBoard$SBLockOverlayStyleProperties$tintAlpha, (IMP*)&_logos_orig$SpringBoard$SBLockOverlayStyleProperties$tintAlpha);Class _logos_class$SpringBoard$SBDashBoardLegibilityProvider = objc_getClass("SBDashBoardLegibilityProvider"); MSHookMessageEx(_logos_class$SpringBoard$SBDashBoardLegibilityProvider, @selector(wallpaperLegibilitySettingsDidChange:forVariant:), (IMP)&_logos_method$SpringBoard$SBDashBoardLegibilityProvider$wallpaperLegibilitySettingsDidChange$forVariant$, (IMP*)&_logos_orig$SpringBoard$SBDashBoardLegibilityProvider$wallpaperLegibilitySettingsDidChange$forVariant$);MSHookMessageEx(_logos_class$SpringBoard$SBDashBoardLegibilityProvider, @selector(currentLegibilitySettings), (IMP)&_logos_method$SpringBoard$SBDashBoardLegibilityProvider$currentLegibilitySettings, (IMP*)&_logos_orig$SpringBoard$SBDashBoardLegibilityProvider$currentLegibilitySettings);MSHookMessageEx(_logos_class$SpringBoard$SBDashBoardLegibilityProvider, @selector(_wallpaperLegibilitySettings), (IMP)&_logos_method$SpringBoard$SBDashBoardLegibilityProvider$_wallpaperLegibilitySettings, (IMP*)&_logos_orig$SpringBoard$SBDashBoardLegibilityProvider$_wallpaperLegibilitySettings);Class _logos_class$SpringBoard$SBLockScreenNotificationCell = objc_getClass("SBLockScreenNotificationCell"); Class _logos_metaclass$SpringBoard$SBLockScreenNotificationCell = object_getClass(_logos_class$SpringBoard$SBLockScreenNotificationCell); MSHookMessageEx(_logos_class$SpringBoard$SBLockScreenNotificationCell, @selector(initWithStyle:reuseIdentifier:), (IMP)&_logos_method$SpringBoard$SBLockScreenNotificationCell$initWithStyle$reuseIdentifier$, (IMP*)&_logos_orig$SpringBoard$SBLockScreenNotificationCell$initWithStyle$reuseIdentifier$);{ char _typeEncoding[1024]; unsigned int i = 0; _typeEncoding[i] = 'v'; i += 1; _typeEncoding[i] = '@'; i += 1; _typeEncoding[i] = ':'; i += 1; _typeEncoding[i] = '\0'; class_addMethod(_logos_class$SpringBoard$SBLockScreenNotificationCell, @selector(_xen_addBlurIfNecessary), (IMP)&_logos_method$SpringBoard$SBLockScreenNotificationCell$_xen_addBlurIfNecessary, _typeEncoding); }MSHookMessageEx(_logos_class$SpringBoard$SBLockScreenNotificationCell, @selector(setContentAlpha:), (IMP)&_logos_method$SpringBoard$SBLockScreenNotificationCell$setContentAlpha$, (IMP*)&_logos_orig$SpringBoard$SBLockScreenNotificationCell$setContentAlpha$);MSHookMessageEx(_logos_class$SpringBoard$SBLockScreenNotificationCell, @selector(setAlpha:), (IMP)&_logos_method$SpringBoard$SBLockScreenNotificationCell$setAlpha$, (IMP*)&_logos_orig$SpringBoard$SBLockScreenNotificationCell$setAlpha$);MSHookMessageEx(_logos_class$SpringBoard$SBLockScreenNotificationCell, @selector(layoutSubviews), (IMP)&_logos_method$SpringBoard$SBLockScreenNotificationCell$layoutSubviews, (IMP*)&_logos_orig$SpringBoard$SBLockScreenNotificationCell$layoutSubviews);MSHookMessageEx(_logos_class$SpringBoard$SBLockScreenNotificationCell, @selector(_vibrantTextColor), (IMP)&_logos_method$SpringBoard$SBLockScreenNotificationCell$_vibrantTextColor, (IMP*)&_logos_orig$SpringBoard$SBLockScreenNotificationCell$_vibrantTextColor);{ char _typeEncoding[1024]; unsigned int i = 0; memcpy(_typeEncoding + i, @encode(UILabel*), strlen(@encode(UILabel*))); i += strlen(@encode(UILabel*)); _typeEncoding[i] = '@'; i += 1; _typeEncoding[i] = ':'; i += 1; _typeEncoding[i] = '\0'; class_addMethod(_logos_class$SpringBoard$SBLockScreenNotificationCell, @selector(XENUnlockTextLabel), (IMP)&_logos_method$SpringBoard$SBLockScreenNotificationCell$XENUnlockTextLabel, _typeEncoding); }{ char _typeEncoding[1024]; unsigned int i = 0; _typeEncoding[i] = 'v'; i += 1; _typeEncoding[i] = '@'; i += 1; _typeEncoding[i] = ':'; i += 1; memcpy(_typeEncoding + i, @encode(UITapGestureRecognizer*), strlen(@encode(UITapGestureRecognizer*))); i += strlen(@encode(UITapGestureRecognizer*)); _typeEncoding[i] = '\0'; class_addMethod(_logos_class$SpringBoard$SBLockScreenNotificationCell, @selector(fireOffTappedEventToDelegate:), (IMP)&_logos_method$SpringBoard$SBLockScreenNotificationCell$fireOffTappedEventToDelegate$, _typeEncoding); }{ char _typeEncoding[1024]; unsigned int i = 0; _typeEncoding[i] = 'v'; i += 1; _typeEncoding[i] = '@'; i += 1; _typeEncoding[i] = ':'; i += 1; memcpy(_typeEncoding + i, @encode(UIGestureRecognizer*), strlen(@encode(UIGestureRecognizer*))); i += strlen(@encode(UIGestureRecognizer*)); _typeEncoding[i] = '\0'; class_addMethod(_logos_class$SpringBoard$SBLockScreenNotificationCell, @selector(handleLongPressGesture:), (IMP)&_logos_method$SpringBoard$SBLockScreenNotificationCell$handleLongPressGesture$, _typeEncoding); }{ char _typeEncoding[1024]; unsigned int i = 0; memcpy(_typeEncoding + i, @encode(BOOL), strlen(@encode(BOOL))); i += strlen(@encode(BOOL)); _typeEncoding[i] = '@'; i += 1; _typeEncoding[i] = ':'; i += 1; memcpy(_typeEncoding + i, @encode(UIGestureRecognizer *), strlen(@encode(UIGestureRecognizer *))); i += strlen(@encode(UIGestureRecognizer *)); memcpy(_typeEncoding + i, @encode(UIGestureRecognizer *), strlen(@encode(UIGestureRecognizer *))); i += strlen(@encode(UIGestureRecognizer *)); _typeEncoding[i] = '\0'; class_addMethod(_logos_class$SpringBoard$SBLockScreenNotificationCell, @selector(gestureRecognizer:shouldRecognizeSimultaneouslyWithGestureRecognizer:), (IMP)&_logos_method$SpringBoard$SBLockScreenNotificationCell$gestureRecognizer$shouldRecognizeSimultaneouslyWithGestureRecognizer$, _typeEncoding); }{ char _typeEncoding[1024]; unsigned int i = 0; memcpy(_typeEncoding + i, @encode(BOOL), strlen(@encode(BOOL))); i += strlen(@encode(BOOL)); _typeEncoding[i] = '@'; i += 1; _typeEncoding[i] = ':'; i += 1; memcpy(_typeEncoding + i, @encode(UIGestureRecognizer *), strlen(@encode(UIGestureRecognizer *))); i += strlen(@encode(UIGestureRecognizer *)); _typeEncoding[i] = '\0'; class_addMethod(_logos_class$SpringBoard$SBLockScreenNotificationCell, @selector(gestureRecognizerShouldBegin:), (IMP)&_logos_method$SpringBoard$SBLockScreenNotificationCell$gestureRecognizerShouldBegin$, _typeEncoding); }{ char _typeEncoding[1024]; unsigned int i = 0; memcpy(_typeEncoding + i, @encode(BOOL), strlen(@encode(BOOL))); i += strlen(@encode(BOOL)); _typeEncoding[i] = '@'; i += 1; _typeEncoding[i] = ':'; i += 1; memcpy(_typeEncoding + i, @encode(UIGestureRecognizer *), strlen(@encode(UIGestureRecognizer *))); i += strlen(@encode(UIGestureRecognizer *)); memcpy(_typeEncoding + i, @encode(UITouch *), strlen(@encode(UITouch *))); i += strlen(@encode(UITouch *)); _typeEncoding[i] = '\0'; class_addMethod(_logos_class$SpringBoard$SBLockScreenNotificationCell, @selector(gestureRecognizer:shouldReceiveTouch:), (IMP)&_logos_method$SpringBoard$SBLockScreenNotificationCell$gestureRecognizer$shouldReceiveTouch$, _typeEncoding); }MSHookMessageEx(_logos_metaclass$SpringBoard$SBLockScreenNotificationCell, @selector(rowHeightForTitle:subtitle:body:maxLines:attachmentSize:secondaryContentSize:datesVisible:rowWidth:includeUnlockActionText:), (IMP)&_logos_meta_method$SpringBoard$SBLockScreenNotificationCell$rowHeightForTitle$subtitle$body$maxLines$attachmentSize$secondaryContentSize$datesVisible$rowWidth$includeUnlockActionText$, (IMP*)&_logos_meta_orig$SpringBoard$SBLockScreenNotificationCell$rowHeightForTitle$subtitle$body$maxLines$attachmentSize$secondaryContentSize$datesVisible$rowWidth$includeUnlockActionText$);MSHookMessageEx(_logos_class$SpringBoard$SBLockScreenNotificationCell, @selector(_updateUnlockText:), (IMP)&_logos_method$SpringBoard$SBLockScreenNotificationCell$_updateUnlockText$, (IMP*)&_logos_orig$SpringBoard$SBLockScreenNotificationCell$_updateUnlockText$);Class _logos_class$SpringBoard$SBLockScreenNotificationListView = objc_getClass("SBLockScreenNotificationListView"); MSHookMessageEx(_logos_class$SpringBoard$SBLockScreenNotificationListView, @selector(initWithFrame:), (IMP)&_logos_method$SpringBoard$SBLockScreenNotificationListView$initWithFrame$, (IMP*)&_logos_orig$SpringBoard$SBLockScreenNotificationListView$initWithFrame$);MSHookMessageEx(_logos_class$SpringBoard$SBLockScreenNotificationListView, @selector(tableView:cellForRowAtIndexPath:), (IMP)&_logos_method$SpringBoard$SBLockScreenNotificationListView$tableView$cellForRowAtIndexPath$, (IMP*)&_logos_orig$SpringBoard$SBLockScreenNotificationListView$tableView$cellForRowAtIndexPath$);{ char _typeEncoding[1024]; unsigned int i = 0; _typeEncoding[i] = 'v'; i += 1; _typeEncoding[i] = '@'; i += 1; _typeEncoding[i] = ':'; i += 1; _typeEncoding[i] = '\0'; class_addMethod(_logos_class$SpringBoard$SBLockScreenNotificationListView, @selector(_xen_reloadSeparatorStyleForSetup), (IMP)&_logos_method$SpringBoard$SBLockScreenNotificationListView$_xen_reloadSeparatorStyleForSetup, _typeEncoding); }MSHookMessageEx(_logos_class$SpringBoard$SBLockScreenNotificationListView, @selector(tableView:heightForRowAtIndexPath:), (IMP)&_logos_method$SpringBoard$SBLockScreenNotificationListView$tableView$heightForRowAtIndexPath$, (IMP*)&_logos_orig$SpringBoard$SBLockScreenNotificationListView$tableView$heightForRowAtIndexPath$);{ char _typeEncoding[1024]; unsigned int i = 0; memcpy(_typeEncoding + i, @encode(NSString*), strlen(@encode(NSString*))); i += strlen(@encode(NSString*)); _typeEncoding[i] = '@'; i += 1; _typeEncoding[i] = ':'; i += 1; memcpy(_typeEncoding + i, @encode(NSIndexPath*), strlen(@encode(NSIndexPath*))); i += strlen(@encode(NSIndexPath*)); _typeEncoding[i] = '\0'; class_addMethod(_logos_class$SpringBoard$SBLockScreenNotificationListView, @selector(XENBundleIdentifierForIndexPath:), (IMP)&_logos_method$SpringBoard$SBLockScreenNotificationListView$XENBundleIdentifierForIndexPath$, _typeEncoding); }{ char _typeEncoding[1024]; unsigned int i = 0; memcpy(_typeEncoding + i, @encode(BOOL), strlen(@encode(BOOL))); i += strlen(@encode(BOOL)); _typeEncoding[i] = '@'; i += 1; _typeEncoding[i] = ':'; i += 1; memcpy(_typeEncoding + i, @encode(NSIndexPath*), strlen(@encode(NSIndexPath*))); i += strlen(@encode(NSIndexPath*)); _typeEncoding[i] = '\0'; class_addMethod(_logos_class$SpringBoard$SBLockScreenNotificationListView, @selector(XENShouldShowIndexPath:), (IMP)&_logos_method$SpringBoard$SBLockScreenNotificationListView$XENShouldShowIndexPath$, _typeEncoding); }MSHookMessageEx(_logos_class$SpringBoard$SBLockScreenNotificationListView, @selector(layoutSubviews), (IMP)&_logos_method$SpringBoard$SBLockScreenNotificationListView$layoutSubviews, (IMP*)&_logos_orig$SpringBoard$SBLockScreenNotificationListView$layoutSubviews);MSHookMessageEx(_logos_class$SpringBoard$SBLockScreenNotificationListView, @selector(setFrame:), (IMP)&_logos_method$SpringBoard$SBLockScreenNotificationListView$setFrame$, (IMP*)&_logos_orig$SpringBoard$SBLockScreenNotificationListView$setFrame$);MSHookMessageEx(_logos_class$SpringBoard$SBLockScreenNotificationListView, @selector(hidden), (IMP)&_logos_method$SpringBoard$SBLockScreenNotificationListView$hidden, (IMP*)&_logos_orig$SpringBoard$SBLockScreenNotificationListView$hidden);MSHookMessageEx(_logos_class$SpringBoard$SBLockScreenNotificationListView, @selector(setHidden:), (IMP)&_logos_method$SpringBoard$SBLockScreenNotificationListView$setHidden$, (IMP*)&_logos_orig$SpringBoard$SBLockScreenNotificationListView$setHidden$);{ char _typeEncoding[1024]; unsigned int i = 0; _typeEncoding[i] = 'v'; i += 1; _typeEncoding[i] = '@'; i += 1; _typeEncoding[i] = ':'; i += 1; _typeEncoding[i] = '@'; i += 1; _typeEncoding[i] = '\0'; class_addMethod(_logos_class$SpringBoard$SBLockScreenNotificationListView, @selector(handleActionFromTappedCellWithContext:), (IMP)&_logos_method$SpringBoard$SBLockScreenNotificationListView$handleActionFromTappedCellWithContext$, _typeEncoding); }Class _logos_class$SpringBoard$SBLockScreenBulletinCell = objc_getClass("SBLockScreenBulletinCell"); Class _logos_metaclass$SpringBoard$SBLockScreenBulletinCell = object_getClass(_logos_class$SpringBoard$SBLockScreenBulletinCell); MSHookMessageEx(_logos_metaclass$SpringBoard$SBLockScreenBulletinCell, @selector(rowHeightForTitle:subtitle:body:maxLines:attachmentSize:secondaryContentSize:datesVisible:rowWidth:includeUnlockActionText:), (IMP)&_logos_meta_method$SpringBoard$SBLockScreenBulletinCell$rowHeightForTitle$subtitle$body$maxLines$attachmentSize$secondaryContentSize$datesVisible$rowWidth$includeUnlockActionText$, (IMP*)&_logos_meta_orig$SpringBoard$SBLockScreenBulletinCell$rowHeightForTitle$subtitle$body$maxLines$attachmentSize$secondaryContentSize$datesVisible$rowWidth$includeUnlockActionText$);MSHookMessageEx(_logos_class$SpringBoard$SBLockScreenBulletinCell, @selector(_updateUnlockText:), (IMP)&_logos_method$SpringBoard$SBLockScreenBulletinCell$_updateUnlockText$, (IMP*)&_logos_orig$SpringBoard$SBLockScreenBulletinCell$_updateUnlockText$);Class _logos_class$SpringBoard$SBTableViewCellActionButton = objc_getClass("SBTableViewCellActionButton"); MSHookMessageEx(_logos_class$SpringBoard$SBTableViewCellActionButton, @selector(setBackgroundColor:withBlendMode:), (IMP)&_logos_method$SpringBoard$SBTableViewCellActionButton$setBackgroundColor$withBlendMode$, (IMP*)&_logos_orig$SpringBoard$SBTableViewCellActionButton$setBackgroundColor$withBlendMode$);Class _logos_class$SpringBoard$NCNotificationPriorityListViewController = objc_getClass("NCNotificationPriorityListViewController"); MSHookMessageEx(_logos_class$SpringBoard$NCNotificationPriorityListViewController, @selector(collectionView:layout:sizeForItemAtIndexPath:), (IMP)&_logos_method$SpringBoard$NCNotificationPriorityListViewController$collectionView$layout$sizeForItemAtIndexPath$, (IMP*)&_logos_orig$SpringBoard$NCNotificationPriorityListViewController$collectionView$layout$sizeForItemAtIndexPath$);{ char _typeEncoding[1024]; unsigned int i = 0; memcpy(_typeEncoding + i, @encode(CGFloat), strlen(@encode(CGFloat))); i += strlen(@encode(CGFloat)); _typeEncoding[i] = '@'; i += 1; _typeEncoding[i] = ':'; i += 1; memcpy(_typeEncoding + i, @encode(CGFloat), strlen(@encode(CGFloat))); i += strlen(@encode(CGFloat)); _typeEncoding[i] = '\0'; class_addMethod(_logos_class$SpringBoard$NCNotificationPriorityListViewController, @selector(_xen_heightForCurrentCellStyling:), (IMP)&_logos_method$SpringBoard$NCNotificationPriorityListViewController$_xen_heightForCurrentCellStyling$, _typeEncoding); }{ char _typeEncoding[1024]; unsigned int i = 0; memcpy(_typeEncoding + i, @encode(NSString*), strlen(@encode(NSString*))); i += strlen(@encode(NSString*)); _typeEncoding[i] = '@'; i += 1; _typeEncoding[i] = ':'; i += 1; memcpy(_typeEncoding + i, @encode(NSIndexPath*), strlen(@encode(NSIndexPath*))); i += strlen(@encode(NSIndexPath*)); _typeEncoding[i] = '\0'; class_addMethod(_logos_class$SpringBoard$NCNotificationPriorityListViewController, @selector(_xen_bundleIdentifierForIndexPath:), (IMP)&_logos_method$SpringBoard$NCNotificationPriorityListViewController$_xen_bundleIdentifierForIndexPath$, _typeEncoding); }{ char _typeEncoding[1024]; unsigned int i = 0; memcpy(_typeEncoding + i, @encode(BOOL), strlen(@encode(BOOL))); i += strlen(@encode(BOOL)); _typeEncoding[i] = '@'; i += 1; _typeEncoding[i] = ':'; i += 1; memcpy(_typeEncoding + i, @encode(NSIndexPath*), strlen(@encode(NSIndexPath*))); i += strlen(@encode(NSIndexPath*)); _typeEncoding[i] = '\0'; class_addMethod(_logos_class$SpringBoard$NCNotificationPriorityListViewController, @selector(_xen_shouldShowIndexPath:), (IMP)&_logos_method$SpringBoard$NCNotificationPriorityListViewController$_xen_shouldShowIndexPath$, _typeEncoding); }Class _logos_class$SpringBoard$SBLockScreenNotificationListController = objc_getClass("SBLockScreenNotificationListController"); MSHookMessageEx(_logos_class$SpringBoard$SBLockScreenNotificationListController, @selector(_updateModelAndViewForAdditionOfItem:), (IMP)&_logos_method$SpringBoard$SBLockScreenNotificationListController$_updateModelAndViewForAdditionOfItem$, (IMP*)&_logos_orig$SpringBoard$SBLockScreenNotificationListController$_updateModelAndViewForAdditionOfItem$);MSHookMessageEx(_logos_class$SpringBoard$SBLockScreenNotificationListController, @selector(_updateModelForRemovalOfItem:updateView:), (IMP)&_logos_method$SpringBoard$SBLockScreenNotificationListController$_updateModelForRemovalOfItem$updateView$, (IMP*)&_logos_orig$SpringBoard$SBLockScreenNotificationListController$_updateModelForRemovalOfItem$updateView$);{ char _typeEncoding[1024]; unsigned int i = 0; memcpy(_typeEncoding + i, @encode(NSArray*), strlen(@encode(NSArray*))); i += strlen(@encode(NSArray*)); _typeEncoding[i] = '@'; i += 1; _typeEncoding[i] = ':'; i += 1; _typeEncoding[i] = '\0'; class_addMethod(_logos_class$SpringBoard$SBLockScreenNotificationListController, @selector(_xen_listItems), (IMP)&_logos_method$SpringBoard$SBLockScreenNotificationListController$_xen_listItems, _typeEncoding); }MSHookMessageEx(_logos_class$SpringBoard$SBLockScreenNotificationListController, @selector(turnOnScreenIfNecessaryForItem:withCompletion:), (IMP)&_logos_method$SpringBoard$SBLockScreenNotificationListController$turnOnScreenIfNecessaryForItem$withCompletion$, (IMP*)&_logos_orig$SpringBoard$SBLockScreenNotificationListController$turnOnScreenIfNecessaryForItem$withCompletion$);Class _logos_class$SpringBoard$NCNotificationPriorityList = objc_getClass("NCNotificationPriorityList"); MSHookMessageEx(_logos_class$SpringBoard$NCNotificationPriorityList, @selector(insertNotificationRequest:), (IMP)&_logos_method$SpringBoard$NCNotificationPriorityList$insertNotificationRequest$, (IMP*)&_logos_orig$SpringBoard$NCNotificationPriorityList$insertNotificationRequest$);MSHookMessageEx(_logos_class$SpringBoard$NCNotificationPriorityList, @selector(removeNotificationRequest:), (IMP)&_logos_method$SpringBoard$NCNotificationPriorityList$removeNotificationRequest$, (IMP*)&_logos_orig$SpringBoard$NCNotificationPriorityList$removeNotificationRequest$);Class _logos_class$SpringBoard$SBLockScreenBatteryChargingView = objc_getClass("SBLockScreenBatteryChargingView"); MSHookMessageEx(_logos_class$SpringBoard$SBLockScreenBatteryChargingView, @selector(setFrame:), (IMP)&_logos_method$SpringBoard$SBLockScreenBatteryChargingView$setFrame$, (IMP*)&_logos_orig$SpringBoard$SBLockScreenBatteryChargingView$setFrame$);Class _logos_class$SpringBoard$SBLockScreenNotificationTableView = objc_getClass("SBLockScreenNotificationTableView"); MSHookMessageEx(_logos_class$SpringBoard$SBLockScreenNotificationTableView, @selector(setAllowsSelection:), (IMP)&_logos_method$SpringBoard$SBLockScreenNotificationTableView$setAllowsSelection$, (IMP*)&_logos_orig$SpringBoard$SBLockScreenNotificationTableView$setAllowsSelection$);Class _logos_class$SpringBoard$SBSystemLocalNotificationAlert = objc_getClass("SBSystemLocalNotificationAlert"); MSHookMessageEx(_logos_class$SpringBoard$SBSystemLocalNotificationAlert, @selector(willDeactivateForReason:), (IMP)&_logos_method$SpringBoard$SBSystemLocalNotificationAlert$willDeactivateForReason$, (IMP*)&_logos_orig$SpringBoard$SBSystemLocalNotificationAlert$willDeactivateForReason$);Class _logos_class$SpringBoard$SBLockScreenFullscreenBulletinViewController = objc_getClass("SBLockScreenFullscreenBulletinViewController"); MSHookMessageEx(_logos_class$SpringBoard$SBLockScreenFullscreenBulletinViewController, @selector(setBulletinItem:), (IMP)&_logos_method$SpringBoard$SBLockScreenFullscreenBulletinViewController$setBulletinItem$, (IMP*)&_logos_orig$SpringBoard$SBLockScreenFullscreenBulletinViewController$setBulletinItem$);MSHookMessageEx(_logos_class$SpringBoard$SBLockScreenFullscreenBulletinViewController, @selector(performSnoozeAction), (IMP)&_logos_method$SpringBoard$SBLockScreenFullscreenBulletinViewController$performSnoozeAction, (IMP*)&_logos_orig$SpringBoard$SBLockScreenFullscreenBulletinViewController$performSnoozeAction);MSHookMessageEx(_logos_class$SpringBoard$SBLockScreenFullscreenBulletinViewController, @selector(performDismissAction), (IMP)&_logos_method$SpringBoard$SBLockScreenFullscreenBulletinViewController$performDismissAction, (IMP*)&_logos_orig$SpringBoard$SBLockScreenFullscreenBulletinViewController$performDismissAction);MSHookMessageEx(_logos_class$SpringBoard$SBLockScreenFullscreenBulletinViewController, @selector(lockButtonPressed:), (IMP)&_logos_method$SpringBoard$SBLockScreenFullscreenBulletinViewController$lockButtonPressed$, (IMP*)&_logos_orig$SpringBoard$SBLockScreenFullscreenBulletinViewController$lockButtonPressed$);MSHookMessageEx(_logos_class$SpringBoard$SBLockScreenFullscreenBulletinViewController, @selector(viewDidAppear:), (IMP)&_logos_method$SpringBoard$SBLockScreenFullscreenBulletinViewController$viewDidAppear$, (IMP*)&_logos_orig$SpringBoard$SBLockScreenFullscreenBulletinViewController$viewDidAppear$);Class _logos_class$SpringBoard$SBFUserAuthenticationController = objc_getClass("SBFUserAuthenticationController"); MSHookMessageEx(_logos_class$SpringBoard$SBFUserAuthenticationController, @selector(_setSecureMode:postNotification:), (IMP)&_logos_method$SpringBoard$SBFUserAuthenticationController$_setSecureMode$postNotification$, (IMP*)&_logos_orig$SpringBoard$SBFUserAuthenticationController$_setSecureMode$postNotification$);Class _logos_class$SpringBoard$SBDashBoardMesaUnlockBehaviorConfiguration = objc_getClass("SBDashBoardMesaUnlockBehaviorConfiguration"); MSHookMessageEx(_logos_class$SpringBoard$SBDashBoardMesaUnlockBehaviorConfiguration, @selector(_isAccessibilityRestingUnlockPreferenceEnabled), (IMP)&_logos_method$SpringBoard$SBDashBoardMesaUnlockBehaviorConfiguration$_isAccessibilityRestingUnlockPreferenceEnabled, (IMP*)&_logos_orig$SpringBoard$SBDashBoardMesaUnlockBehaviorConfiguration$_isAccessibilityRestingUnlockPreferenceEnabled);Class _logos_class$SpringBoard$XENShortcutModule = objc_getClass("XENShortcutModule"); MSHookMessageEx(_logos_class$SpringBoard$XENShortcutModule, @selector(isRestricted), (IMP)&_logos_method$SpringBoard$XENShortcutModule$isRestricted, (IMP*)&_logos_orig$SpringBoard$XENShortcutModule$isRestricted);MSHookMessageEx(_logos_class$SpringBoard$XENShortcutModule, @selector(activateAppWithDisplayID:url:), (IMP)&_logos_method$SpringBoard$XENShortcutModule$activateAppWithDisplayID$url$, (IMP*)&_logos_orig$SpringBoard$XENShortcutModule$activateAppWithDisplayID$url$);MSHookMessageEx(_logos_class$SpringBoard$XENShortcutModule, @selector(activateAppWithDisplayID:url:unlockIfNecessary:), (IMP)&_logos_method$SpringBoard$XENShortcutModule$activateAppWithDisplayID$url$unlockIfNecessary$, (IMP*)&_logos_orig$SpringBoard$XENShortcutModule$activateAppWithDisplayID$url$unlockIfNecessary$);Class _logos_class$SpringBoard$SBApplication = objc_getClass("SBApplication"); MSHookMessageEx(_logos_class$SpringBoard$SBApplication, @selector(boolForActivationSetting:), (IMP)&_logos_method$SpringBoard$SBApplication$boolForActivationSetting$, (IMP*)&_logos_orig$SpringBoard$SBApplication$boolForActivationSetting$);Class _logos_class$SpringBoard$SBWorkspaceTransaction = objc_getClass("SBWorkspaceTransaction"); MSHookMessageEx(_logos_class$SpringBoard$SBWorkspaceTransaction, @selector(_performDeviceCoherencyCheck), (IMP)&_logos_method$SpringBoard$SBWorkspaceTransaction$_performDeviceCoherencyCheck, (IMP*)&_logos_orig$SpringBoard$SBWorkspaceTransaction$_performDeviceCoherencyCheck);Class _logos_class$SpringBoard$SBAlertToAppsWorkspaceTransaction = objc_getClass("SBAlertToAppsWorkspaceTransaction"); MSHookMessageEx(_logos_class$SpringBoard$SBAlertToAppsWorkspaceTransaction, @selector(_performDeviceCoherencyCheck), (IMP)&_logos_method$SpringBoard$SBAlertToAppsWorkspaceTransaction$_performDeviceCoherencyCheck, (IMP*)&_logos_orig$SpringBoard$SBAlertToAppsWorkspaceTransaction$_performDeviceCoherencyCheck);Class _logos_class$SpringBoard$SBMainWorkspace = objc_getClass("SBMainWorkspace"); MSHookMessageEx(_logos_class$SpringBoard$SBMainWorkspace, @selector(_preflightTransitionRequest:), (IMP)&_logos_method$SpringBoard$SBMainWorkspace$_preflightTransitionRequest$, (IMP*)&_logos_orig$SpringBoard$SBMainWorkspace$_preflightTransitionRequest$);Class _logos_class$SpringBoard$CNContactGridViewController = objc_getClass("CNContactGridViewController"); MSHookMessageEx(_logos_class$SpringBoard$CNContactGridViewController, @selector(viewControllerForActionsView:), (IMP)&_logos_method$SpringBoard$CNContactGridViewController$viewControllerForActionsView$, (IMP*)&_logos_orig$SpringBoard$CNContactGridViewController$viewControllerForActionsView$);Class _logos_class$SpringBoard$CNContact = objc_getClass("CNContact"); MSHookMessageEx(_logos_class$SpringBoard$CNContact, @selector(assertKeyIsAvailable:), (IMP)&_logos_method$SpringBoard$CNContact$assertKeyIsAvailable$, (IMP*)&_logos_orig$SpringBoard$CNContact$assertKeyIsAvailable$);MSHookMessageEx(_logos_class$SpringBoard$CNContact, @selector(assertKeysAreAvailable:), (IMP)&_logos_method$SpringBoard$CNContact$assertKeysAreAvailable$, (IMP*)&_logos_orig$SpringBoard$CNContact$assertKeysAreAvailable$);Class _logos_class$SpringBoard$CNPropertyAction = objc_getClass("CNPropertyAction"); MSHookMessageEx(_logos_class$SpringBoard$CNPropertyAction, @selector(performActionForItem:sender:), (IMP)&_logos_method$SpringBoard$CNPropertyAction$performActionForItem$sender$, (IMP*)&_logos_orig$SpringBoard$CNPropertyAction$performActionForItem$sender$);Class _logos_class$SpringBoard$CNPropertySendMessageAction = objc_getClass("CNPropertySendMessageAction"); MSHookMessageEx(_logos_class$SpringBoard$CNPropertySendMessageAction, @selector(performActionForItem:sender:), (IMP)&_logos_method$SpringBoard$CNPropertySendMessageAction$performActionForItem$sender$, (IMP*)&_logos_orig$SpringBoard$CNPropertySendMessageAction$performActionForItem$sender$);Class _logos_class$SpringBoard$CNPropertyFaceTimeAction = objc_getClass("CNPropertyFaceTimeAction"); MSHookMessageEx(_logos_class$SpringBoard$CNPropertyFaceTimeAction, @selector(performActionForItem:sender:), (IMP)&_logos_method$SpringBoard$CNPropertyFaceTimeAction$performActionForItem$sender$, (IMP*)&_logos_orig$SpringBoard$CNPropertyFaceTimeAction$performActionForItem$sender$);Class _logos_class$SpringBoard$SpringBoard = objc_getClass("SpringBoard"); MSHookMessageEx(_logos_class$SpringBoard$SpringBoard, @selector(openURL:), (IMP)&_logos_method$SpringBoard$SpringBoard$openURL$, (IMP*)&_logos_orig$SpringBoard$SpringBoard$openURL$);MSHookMessageEx(_logos_class$SpringBoard$SpringBoard, @selector(_handlePhysicalButtonEvent:), (IMP)&_logos_method$SpringBoard$SpringBoard$_handlePhysicalButtonEvent$, (IMP*)&_logos_orig$SpringBoard$SpringBoard$_handlePhysicalButtonEvent$);MSHookMessageEx(_logos_class$SpringBoard$SpringBoard, @selector(setStatusBarHidden:withAnimation:), (IMP)&_logos_method$SpringBoard$SpringBoard$setStatusBarHidden$withAnimation$, (IMP*)&_logos_orig$SpringBoard$SpringBoard$setStatusBarHidden$withAnimation$);{ char _typeEncoding[1024]; unsigned int i = 0; _typeEncoding[i] = 'v'; i += 1; _typeEncoding[i] = '@'; i += 1; _typeEncoding[i] = ':'; i += 1; _typeEncoding[i] = '\0'; class_addMethod(_logos_class$SpringBoard$SpringBoard, @selector(_xen_showPeekUI), (IMP)&_logos_method$SpringBoard$SpringBoard$_xen_showPeekUI, _typeEncoding); }{ char _typeEncoding[1024]; unsigned int i = 0; _typeEncoding[i] = 'v'; i += 1; _typeEncoding[i] = '@'; i += 1; _typeEncoding[i] = ':'; i += 1; memcpy(_typeEncoding + i, @encode(XENPeekEvent), strlen(@encode(XENPeekEvent))); i += strlen(@encode(XENPeekEvent)); _typeEncoding[i] = '\0'; class_addMethod(_logos_class$SpringBoard$SpringBoard, @selector(_xen_hidePeekUIWithEvent:), (IMP)&_logos_method$SpringBoard$SpringBoard$_xen_hidePeekUIWithEvent$, _typeEncoding); }MSHookMessageEx(_logos_class$SpringBoard$SpringBoard, @selector(_handleMenuButtonEvent), (IMP)&_logos_method$SpringBoard$SpringBoard$_handleMenuButtonEvent, (IMP*)&_logos_orig$SpringBoard$SpringBoard$_handleMenuButtonEvent);MSHookMessageEx(_logos_class$SpringBoard$SpringBoard, @selector(handleMenuDoubleTap), (IMP)&_logos_method$SpringBoard$SpringBoard$handleMenuDoubleTap, (IMP*)&_logos_orig$SpringBoard$SpringBoard$handleMenuDoubleTap);{ char _typeEncoding[1024]; unsigned int i = 0; _typeEncoding[i] = 'v'; i += 1; _typeEncoding[i] = '@'; i += 1; _typeEncoding[i] = ':'; i += 1; _typeEncoding[i] = '\0'; class_addMethod(_logos_class$SpringBoard$SpringBoard, @selector(xen_dismissContentEditor), (IMP)&_logos_method$SpringBoard$SpringBoard$xen_dismissContentEditor, _typeEncoding); }Class _logos_class$SpringBoard$LSApplicationWorkspace = objc_getClass("LSApplicationWorkspace"); MSHookMessageEx(_logos_class$SpringBoard$LSApplicationWorkspace, @selector(openURL:withOptions:), (IMP)&_logos_method$SpringBoard$LSApplicationWorkspace$openURL$withOptions$, (IMP*)&_logos_orig$SpringBoard$LSApplicationWorkspace$openURL$withOptions$);Class _logos_class$SpringBoard$SBPluginManager = objc_getClass("SBPluginManager"); MSHookMessageEx(_logos_class$SpringBoard$SBPluginManager, @selector(loadPluginBundle:), (IMP)&_logos_method$SpringBoard$SBPluginManager$loadPluginBundle$, (IMP*)&_logos_orig$SpringBoard$SBPluginManager$loadPluginBundle$);Class _logos_class$SpringBoard$SBAlertWindow = objc_getClass("SBAlertWindow"); MSHookMessageEx(_logos_class$SpringBoard$SBAlertWindow, @selector(sendEvent:), (IMP)&_logos_method$SpringBoard$SBAlertWindow$sendEvent$, (IMP*)&_logos_orig$SpringBoard$SBAlertWindow$sendEvent$);Class _logos_class$SpringBoard$SBBacklightController = objc_getClass("SBBacklightController"); MSHookMessageEx(_logos_class$SpringBoard$SBBacklightController, @selector(defaultLockScreenDimInterval), (IMP)&_logos_method$SpringBoard$SBBacklightController$defaultLockScreenDimInterval, (IMP*)&_logos_orig$SpringBoard$SBBacklightController$defaultLockScreenDimInterval);MSHookMessageEx(_logos_class$SpringBoard$SBBacklightController, @selector(defaultLockScreenDimIntervalWhenNotificationsPresent), (IMP)&_logos_method$SpringBoard$SBBacklightController$defaultLockScreenDimIntervalWhenNotificationsPresent, (IMP*)&_logos_orig$SpringBoard$SBBacklightController$defaultLockScreenDimIntervalWhenNotificationsPresent);Class _logos_class$SpringBoard$SBManualIdleTimer = objc_getClass("SBManualIdleTimer"); MSHookMessageEx(_logos_class$SpringBoard$SBManualIdleTimer, @selector(initWithInterval:userEventInterface:), (IMP)&_logos_method$SpringBoard$SBManualIdleTimer$initWithInterval$userEventInterface$, (IMP*)&_logos_orig$SpringBoard$SBManualIdleTimer$initWithInterval$userEventInterface$);Class _logos_class$SpringBoard$_NowPlayingArtView = objc_getClass("_NowPlayingArtView"); MSHookMessageEx(_logos_class$SpringBoard$_NowPlayingArtView, @selector(layoutSubviews), (IMP)&_logos_method$SpringBoard$_NowPlayingArtView$layoutSubviews, (IMP*)&_logos_orig$SpringBoard$_NowPlayingArtView$layoutSubviews);Class _logos_class$SpringBoard$UICollectionView = objc_getClass("UICollectionView"); MSHookMessageEx(_logos_class$SpringBoard$UICollectionView, @selector(hitTest:withEvent:), (IMP)&_logos_method$SpringBoard$UICollectionView$hitTest$withEvent$, (IMP*)&_logos_orig$SpringBoard$UICollectionView$hitTest$withEvent$);Class _logos_class$SpringBoard$MPUSystemMediaControlsViewController = objc_getClass("MPUSystemMediaControlsViewController"); { char _typeEncoding[1024]; unsigned int i = 0; memcpy(_typeEncoding + i, @encode(MPUSystemMediaControlsView*), strlen(@encode(MPUSystemMediaControlsView*))); i += strlen(@encode(MPUSystemMediaControlsView*)); _typeEncoding[i] = '@'; i += 1; _typeEncoding[i] = ':'; i += 1; _typeEncoding[i] = '\0'; class_addMethod(_logos_class$SpringBoard$MPUSystemMediaControlsViewController, @selector(_xen_mediaView), (IMP)&_logos_method$SpringBoard$MPUSystemMediaControlsViewController$_xen_mediaView, _typeEncoding); }MSHookMessageEx(_logos_class$SpringBoard$MPUSystemMediaControlsViewController, @selector(_imageForTransportButtonWithControlType:), (IMP)&_logos_method$SpringBoard$MPUSystemMediaControlsViewController$_imageForTransportButtonWithControlType$, (IMP*)&_logos_orig$SpringBoard$MPUSystemMediaControlsViewController$_imageForTransportButtonWithControlType$);Class _logos_class$SpringBoard$SBUIControlCenterButton = objc_getClass("SBUIControlCenterButton"); MSHookMessageEx(_logos_class$SpringBoard$SBUIControlCenterButton, @selector(initWithFrame:), (IMP)&_logos_method$SpringBoard$SBUIControlCenterButton$initWithFrame$, (IMP*)&_logos_orig$SpringBoard$SBUIControlCenterButton$initWithFrame$);MSHookMessageEx(_logos_class$SpringBoard$SBUIControlCenterButton, @selector(_backgroundImage), (IMP)&_logos_method$SpringBoard$SBUIControlCenterButton$_backgroundImage, (IMP*)&_logos_orig$SpringBoard$SBUIControlCenterButton$_backgroundImage);MSHookMessageEx(_logos_class$SpringBoard$SBUIControlCenterButton, @selector(_glyphImageForState:), (IMP)&_logos_method$SpringBoard$SBUIControlCenterButton$_glyphImageForState$, (IMP*)&_logos_orig$SpringBoard$SBUIControlCenterButton$_glyphImageForState$);MSHookMessageEx(_logos_class$SpringBoard$SBUIControlCenterButton, @selector(layoutSubviews), (IMP)&_logos_method$SpringBoard$SBUIControlCenterButton$layoutSubviews, (IMP*)&_logos_orig$SpringBoard$SBUIControlCenterButton$layoutSubviews);MSHookMessageEx(_logos_class$SpringBoard$SBUIControlCenterButton, @selector(_updateEffects), (IMP)&_logos_method$SpringBoard$SBUIControlCenterButton$_updateEffects, (IMP*)&_logos_orig$SpringBoard$SBUIControlCenterButton$_updateEffects);MSHookMessageEx(_logos_class$SpringBoard$SBUIControlCenterButton, @selector(_updateForStateChange), (IMP)&_logos_method$SpringBoard$SBUIControlCenterButton$_updateForStateChange, (IMP*)&_logos_orig$SpringBoard$SBUIControlCenterButton$_updateForStateChange);Class _logos_class$SpringBoard$SBCCButtonLikeSectionView = objc_getClass("SBCCButtonLikeSectionView"); MSHookMessageEx(_logos_class$SpringBoard$SBCCButtonLikeSectionView, @selector(initWithFrame:), (IMP)&_logos_method$SpringBoard$SBCCButtonLikeSectionView$initWithFrame$, (IMP*)&_logos_orig$SpringBoard$SBCCButtonLikeSectionView$initWithFrame$);MSHookMessageEx(_logos_class$SpringBoard$SBCCButtonLikeSectionView, @selector(_updateEffects), (IMP)&_logos_method$SpringBoard$SBCCButtonLikeSectionView$_updateEffects, (IMP*)&_logos_orig$SpringBoard$SBCCButtonLikeSectionView$_updateEffects);MSHookMessageEx(_logos_class$SpringBoard$SBCCButtonLikeSectionView, @selector(layoutSubviews), (IMP)&_logos_method$SpringBoard$SBCCButtonLikeSectionView$layoutSubviews, (IMP*)&_logos_orig$SpringBoard$SBCCButtonLikeSectionView$layoutSubviews);MSHookMessageEx(_logos_class$SpringBoard$SBCCButtonLikeSectionView, @selector(_backgroundImageWithRoundCorners:), (IMP)&_logos_method$SpringBoard$SBCCButtonLikeSectionView$_backgroundImageWithRoundCorners$, (IMP*)&_logos_orig$SpringBoard$SBCCButtonLikeSectionView$_backgroundImageWithRoundCorners$);MSHookMessageEx(_logos_class$SpringBoard$SBCCButtonLikeSectionView, @selector(setSelected:), (IMP)&_logos_method$SpringBoard$SBCCButtonLikeSectionView$setSelected$, (IMP*)&_logos_orig$SpringBoard$SBCCButtonLikeSectionView$setSelected$);MSHookMessageEx(_logos_class$SpringBoard$SBCCButtonLikeSectionView, @selector(buttonTapped:), (IMP)&_logos_method$SpringBoard$SBCCButtonLikeSectionView$buttonTapped$, (IMP*)&_logos_orig$SpringBoard$SBCCButtonLikeSectionView$buttonTapped$);MSHookMessageEx(_logos_class$SpringBoard$SBCCButtonLikeSectionView, @selector(_shouldUseButtonAppearance), (IMP)&_logos_method$SpringBoard$SBCCButtonLikeSectionView$_shouldUseButtonAppearance, (IMP*)&_logos_orig$SpringBoard$SBCCButtonLikeSectionView$_shouldUseButtonAppearance);Class _logos_class$SpringBoard$SBCCBrightnessSectionController = objc_getClass("SBCCBrightnessSectionController"); MSHookMessageEx(_logos_class$SpringBoard$SBCCBrightnessSectionController, @selector(_shouldDarkenBackground), (IMP)&_logos_method$SpringBoard$SBCCBrightnessSectionController$_shouldDarkenBackground, (IMP*)&_logos_orig$SpringBoard$SBCCBrightnessSectionController$_shouldDarkenBackground);{ char _typeEncoding[1024]; unsigned int i = 0; memcpy(_typeEncoding + i, @encode(SBUIControlCenterSlider*), strlen(@encode(SBUIControlCenterSlider*))); i += strlen(@encode(SBUIControlCenterSlider*)); _typeEncoding[i] = '@'; i += 1; _typeEncoding[i] = ':'; i += 1; _typeEncoding[i] = '\0'; class_addMethod(_logos_class$SpringBoard$SBCCBrightnessSectionController, @selector(xen_slider), (IMP)&_logos_method$SpringBoard$SBCCBrightnessSectionController$xen_slider, _typeEncoding); }Class _logos_class$SpringBoard$SBUIControlCenterSlider = objc_getClass("SBUIControlCenterSlider"); MSHookMessageEx(_logos_class$SpringBoard$SBUIControlCenterSlider, @selector(_valueImageForImage:state:), (IMP)&_logos_method$SpringBoard$SBUIControlCenterSlider$_valueImageForImage$state$, (IMP*)&_logos_orig$SpringBoard$SBUIControlCenterSlider$_valueImageForImage$state$);MSHookMessageEx(_logos_class$SpringBoard$SBUIControlCenterSlider, @selector(setAdjusting:), (IMP)&_logos_method$SpringBoard$SBUIControlCenterSlider$setAdjusting$, (IMP*)&_logos_orig$SpringBoard$SBUIControlCenterSlider$setAdjusting$);MSHookMessageEx(_logos_class$SpringBoard$SBUIControlCenterSlider, @selector(layoutSubviews), (IMP)&_logos_method$SpringBoard$SBUIControlCenterSlider$layoutSubviews, (IMP*)&_logos_orig$SpringBoard$SBUIControlCenterSlider$layoutSubviews);MSHookMessageEx(_logos_class$SpringBoard$SBUIControlCenterSlider, @selector(setMaximumTrackImage:forState:), (IMP)&_logos_method$SpringBoard$SBUIControlCenterSlider$setMaximumTrackImage$forState$, (IMP*)&_logos_orig$SpringBoard$SBUIControlCenterSlider$setMaximumTrackImage$forState$);MSHookMessageEx(_logos_class$SpringBoard$SBUIControlCenterSlider, @selector(setMinimumTrackImage:forState:), (IMP)&_logos_method$SpringBoard$SBUIControlCenterSlider$setMinimumTrackImage$forState$, (IMP*)&_logos_orig$SpringBoard$SBUIControlCenterSlider$setMinimumTrackImage$forState$);MSHookMessageEx(_logos_class$SpringBoard$SBUIControlCenterSlider, @selector(setThumbImage:forState:), (IMP)&_logos_method$SpringBoard$SBUIControlCenterSlider$setThumbImage$forState$, (IMP*)&_logos_orig$SpringBoard$SBUIControlCenterSlider$setThumbImage$forState$);{ char _typeEncoding[1024]; unsigned int i = 0; _typeEncoding[i] = 'v'; i += 1; _typeEncoding[i] = '@'; i += 1; _typeEncoding[i] = ':'; i += 1; _typeEncoding[i] = '\0'; class_addMethod(_logos_class$SpringBoard$SBUIControlCenterSlider, @selector(_xen_setTrackImagesForCurrentTheme), (IMP)&_logos_method$SpringBoard$SBUIControlCenterSlider$_xen_setTrackImagesForCurrentTheme, _typeEncoding); }Class _logos_class$SpringBoard$XENControlCenterViewController = objc_getClass("XENControlCenterViewController"); MSHookMessageEx(_logos_class$SpringBoard$XENControlCenterViewController, @selector(init), (IMP)&_logos_method$SpringBoard$XENControlCenterViewController$init, (IMP*)&_logos_orig$SpringBoard$XENControlCenterViewController$init);MSHookMessageEx(_logos_class$SpringBoard$XENControlCenterViewController, @selector(_layoutScrollView), (IMP)&_logos_method$SpringBoard$XENControlCenterViewController$_layoutScrollView, (IMP*)&_logos_orig$SpringBoard$XENControlCenterViewController$_layoutScrollView);MSHookMessageEx(_logos_class$SpringBoard$XENControlCenterViewController, @selector(_addContentViewController:), (IMP)&_logos_method$SpringBoard$XENControlCenterViewController$_addContentViewController$, (IMP*)&_logos_orig$SpringBoard$XENControlCenterViewController$_addContentViewController$);MSHookMessageEx(_logos_class$SpringBoard$XENControlCenterViewController, @selector(controlCenterSystemAgent), (IMP)&_logos_method$SpringBoard$XENControlCenterViewController$controlCenterSystemAgent, (IMP*)&_logos_orig$SpringBoard$XENControlCenterViewController$controlCenterSystemAgent);Class _logos_class$SpringBoard$AVFlashlight = objc_getClass("AVFlashlight"); MSHookMessageEx(_logos_class$SpringBoard$AVFlashlight, @selector(init), (IMP)&_logos_method$SpringBoard$AVFlashlight$init, (IMP*)&_logos_orig$SpringBoard$AVFlashlight$init);Class _logos_class$SpringBoard$MPUMediaControlsVolumeView = objc_getClass("MPUMediaControlsVolumeView"); MSHookMessageEx(_logos_class$SpringBoard$MPUMediaControlsVolumeView, @selector(layoutSubviews), (IMP)&_logos_method$SpringBoard$MPUMediaControlsVolumeView$layoutSubviews, (IMP*)&_logos_orig$SpringBoard$MPUMediaControlsVolumeView$layoutSubviews);MSHookMessageEx(_logos_class$SpringBoard$MPUMediaControlsVolumeView, @selector(updateSystemVolumeLevel), (IMP)&_logos_method$SpringBoard$MPUMediaControlsVolumeView$updateSystemVolumeLevel, (IMP*)&_logos_orig$SpringBoard$MPUMediaControlsVolumeView$updateSystemVolumeLevel);MSHookMessageEx(_logos_class$SpringBoard$MPUMediaControlsVolumeView, @selector(volumeController:volumeValueDidChange:), (IMP)&_logos_method$SpringBoard$MPUMediaControlsVolumeView$volumeController$volumeValueDidChange$, (IMP*)&_logos_orig$SpringBoard$MPUMediaControlsVolumeView$volumeController$volumeValueDidChange$);{ char _typeEncoding[1024]; unsigned int i = 0; _typeEncoding[i] = 'v'; i += 1; _typeEncoding[i] = '@'; i += 1; _typeEncoding[i] = ':'; i += 1; _typeEncoding[i] = '@'; i += 1; _typeEncoding[i] = '\0'; class_addMethod(_logos_class$SpringBoard$MPUMediaControlsVolumeView, @selector(_xen_volumeChangeStarted:), (IMP)&_logos_method$SpringBoard$MPUMediaControlsVolumeView$_xen_volumeChangeStarted$, _typeEncoding); }{ char _typeEncoding[1024]; unsigned int i = 0; _typeEncoding[i] = 'v'; i += 1; _typeEncoding[i] = '@'; i += 1; _typeEncoding[i] = ':'; i += 1; _typeEncoding[i] = '@'; i += 1; _typeEncoding[i] = '\0'; class_addMethod(_logos_class$SpringBoard$MPUMediaControlsVolumeView, @selector(_xen_volumeValueChanged:), (IMP)&_logos_method$SpringBoard$MPUMediaControlsVolumeView$_xen_volumeValueChanged$, _typeEncoding); }{ char _typeEncoding[1024]; unsigned int i = 0; _typeEncoding[i] = 'v'; i += 1; _typeEncoding[i] = '@'; i += 1; _typeEncoding[i] = ':'; i += 1; _typeEncoding[i] = '@'; i += 1; _typeEncoding[i] = '\0'; class_addMethod(_logos_class$SpringBoard$MPUMediaControlsVolumeView, @selector(_xen_volumeStoppedChange:), (IMP)&_logos_method$SpringBoard$MPUMediaControlsVolumeView$_xen_volumeStoppedChange$, _typeEncoding); }Class _logos_class$SpringBoard$SBDashBoardView = objc_getClass("SBDashBoardView"); MSHookMessageEx(_logos_class$SpringBoard$SBDashBoardView, @selector(_layoutPageControl), (IMP)&_logos_method$SpringBoard$SBDashBoardView$_layoutPageControl, (IMP*)&_logos_orig$SpringBoard$SBDashBoardView$_layoutPageControl);Class _logos_class$SpringBoard$UIDevice = objc_getClass("UIDevice"); MSHookMessageEx(_logos_class$SpringBoard$UIDevice, @selector(userInterfaceIdiom), (IMP)&_logos_method$SpringBoard$UIDevice$userInterfaceIdiom, (IMP*)&_logos_orig$SpringBoard$UIDevice$userInterfaceIdiom);Class _logos_class$SpringBoard$SBCCButtonLayoutView = objc_getClass("SBCCButtonLayoutView"); MSHookMessageEx(_logos_class$SpringBoard$SBCCButtonLayoutView, @selector(layoutSubviews), (IMP)&_logos_method$SpringBoard$SBCCButtonLayoutView$layoutSubviews, (IMP*)&_logos_orig$SpringBoard$SBCCButtonLayoutView$layoutSubviews);MSHookMessageEx(_logos_class$SpringBoard$SBCCButtonLayoutView, @selector(interButtonPadding), (IMP)&_logos_method$SpringBoard$SBCCButtonLayoutView$interButtonPadding, (IMP*)&_logos_orig$SpringBoard$SBCCButtonLayoutView$interButtonPadding);Class _logos_class$SpringBoard$SBCCButtonLikeSectionSplitView = objc_getClass("SBCCButtonLikeSectionSplitView"); MSHookMessageEx(_logos_class$SpringBoard$SBCCButtonLikeSectionSplitView, @selector(_landscapeInsetsForSection), (IMP)&_logos_method$SpringBoard$SBCCButtonLikeSectionSplitView$_landscapeInsetsForSection, (IMP*)&_logos_orig$SpringBoard$SBCCButtonLikeSectionSplitView$_landscapeInsetsForSection);MSHookMessageEx(_logos_class$SpringBoard$SBCCButtonLikeSectionSplitView, @selector(_useLandscapeBehavior), (IMP)&_logos_method$SpringBoard$SBCCButtonLikeSectionSplitView$_useLandscapeBehavior, (IMP*)&_logos_orig$SpringBoard$SBCCButtonLikeSectionSplitView$_useLandscapeBehavior);Class _logos_class$SpringBoard$EKBBTodayProvider = objc_getClass("EKBBTodayProvider"); MSHookMessageEx(_logos_class$SpringBoard$EKBBTodayProvider, @selector(_refreshUpcomingEventBulletin), (IMP)&_logos_method$SpringBoard$EKBBTodayProvider$_refreshUpcomingEventBulletin, (IMP*)&_logos_orig$SpringBoard$EKBBTodayProvider$_refreshUpcomingEventBulletin);MSHookMessageEx(_logos_class$SpringBoard$EKBBTodayProvider, @selector(_refreshBirthdayBulletin), (IMP)&_logos_method$SpringBoard$EKBBTodayProvider$_refreshBirthdayBulletin, (IMP*)&_logos_orig$SpringBoard$EKBBTodayProvider$_refreshBirthdayBulletin);Class _logos_class$SpringBoard$UIVisualEffectView = objc_getClass("UIVisualEffectView"); MSHookMessageEx(_logos_class$SpringBoard$UIVisualEffectView, @selector(hitTest:withEvent:), (IMP)&_logos_method$SpringBoard$UIVisualEffectView$hitTest$withEvent$, (IMP*)&_logos_orig$SpringBoard$UIVisualEffectView$hitTest$withEvent$);Class _logos_class$SpringBoard$LPPageController = objc_getClass("LPPageController"); MSHookMessageEx(_logos_class$SpringBoard$LPPageController, @selector(calculateStartIndex:), (IMP)&_logos_method$SpringBoard$LPPageController$calculateStartIndex$, (IMP*)&_logos_orig$SpringBoard$LPPageController$calculateStartIndex$);MSHookMessageEx(_logos_class$SpringBoard$LPPageController, @selector(realPageCount), (IMP)&_logos_method$SpringBoard$LPPageController$realPageCount, (IMP*)&_logos_orig$SpringBoard$LPPageController$realPageCount);MSHookMessageEx(_logos_class$SpringBoard$LPPageController, @selector(pageAtOffset:), (IMP)&_logos_method$SpringBoard$LPPageController$pageAtOffset$, (IMP*)&_logos_orig$SpringBoard$LPPageController$pageAtOffset$);MSHookMessageEx(_logos_class$SpringBoard$LPPageController, @selector(pageAtAbsoluteIndex:), (IMP)&_logos_method$SpringBoard$LPPageController$pageAtAbsoluteIndex$, (IMP*)&_logos_orig$SpringBoard$LPPageController$pageAtAbsoluteIndex$);MSHookMessageEx(_logos_class$SpringBoard$LPPageController, @selector(layoutLockScreenView:), (IMP)&_logos_method$SpringBoard$LPPageController$layoutLockScreenView$, (IMP*)&_logos_orig$SpringBoard$LPPageController$layoutLockScreenView$);MSHookMessageEx(_logos_class$SpringBoard$LPPageController, @selector(layoutPages), (IMP)&_logos_method$SpringBoard$LPPageController$layoutPages, (IMP*)&_logos_orig$SpringBoard$LPPageController$layoutPages);MSHookMessageEx(_logos_class$SpringBoard$LPPageController, @selector(addPage:), (IMP)&_logos_method$SpringBoard$LPPageController$addPage$, (IMP*)&_logos_orig$SpringBoard$LPPageController$addPage$);{ char _typeEncoding[1024]; unsigned int i = 0; _typeEncoding[i] = '@'; i += 1; _typeEncoding[i] = '@'; i += 1; _typeEncoding[i] = ':'; i += 1; _typeEncoding[i] = '\0'; class_addMethod(_logos_class$SpringBoard$LPPageController, @selector(_xen_sortedPages), (IMP)&_logos_method$SpringBoard$LPPageController$_xen_sortedPages, _typeEncoding); }Class _logos_class$SpringBoard$LPPage = objc_getClass("LPPage"); MSHookMessageEx(_logos_class$SpringBoard$LPPage, @selector(supportsBackgroundAlpha), (IMP)&_logos_method$SpringBoard$LPPage$supportsBackgroundAlpha, (IMP*)&_logos_orig$SpringBoard$LPPage$supportsBackgroundAlpha);Class _logos_class$SpringBoard$SBUIPasscodeLockViewBase = objc_getClass("SBUIPasscodeLockViewBase"); MSHookMessageEx(_logos_class$SpringBoard$SBUIPasscodeLockViewBase, @selector(_noteDeviceHasBeenUnlockedOnceSinceBoot:), (IMP)&_logos_method$SpringBoard$SBUIPasscodeLockViewBase$_noteDeviceHasBeenUnlockedOnceSinceBoot$, (IMP*)&_logos_orig$SpringBoard$SBUIPasscodeLockViewBase$_noteDeviceHasBeenUnlockedOnceSinceBoot$);MSHookMessageEx(_logos_class$SpringBoard$SBUIPasscodeLockViewBase, @selector(_setLuminosityBoost:), (IMP)&_logos_method$SpringBoard$SBUIPasscodeLockViewBase$_setLuminosityBoost$, (IMP*)&_logos_orig$SpringBoard$SBUIPasscodeLockViewBase$_setLuminosityBoost$);{ char _typeEncoding[1024]; unsigned int i = 0; _typeEncoding[i] = 'v'; i += 1; _typeEncoding[i] = '@'; i += 1; _typeEncoding[i] = ':'; i += 1; _typeEncoding[i] = '\0'; class_addMethod(_logos_class$SpringBoard$SBUIPasscodeLockViewBase, @selector(_xen_layoutForHidingViews), (IMP)&_logos_method$SpringBoard$SBUIPasscodeLockViewBase$_xen_layoutForHidingViews, _typeEncoding); }Class _logos_class$SpringBoard$SBNotificationCenterController = objc_getClass("SBNotificationCenterController"); Class _logos_metaclass$SpringBoard$SBNotificationCenterController = object_getClass(_logos_class$SpringBoard$SBNotificationCenterController); MSHookMessageEx(_logos_class$SpringBoard$SBNotificationCenterController, @selector(isVisible), (IMP)&_logos_method$SpringBoard$SBNotificationCenterController$isVisible, (IMP*)&_logos_orig$SpringBoard$SBNotificationCenterController$isVisible);MSHookMessageEx(_logos_class$SpringBoard$SBNotificationCenterController, @selector(shouldRequestWidgetRemoteViewControllers), (IMP)&_logos_method$SpringBoard$SBNotificationCenterController$shouldRequestWidgetRemoteViewControllers, (IMP*)&_logos_orig$SpringBoard$SBNotificationCenterController$shouldRequestWidgetRemoteViewControllers);{ char _typeEncoding[1024]; unsigned int i = 0; _typeEncoding[i] = 'v'; i += 1; _typeEncoding[i] = '@'; i += 1; _typeEncoding[i] = ':'; i += 1; memcpy(_typeEncoding + i, @encode(BOOL), strlen(@encode(BOOL))); i += strlen(@encode(BOOL)); _typeEncoding[i] = '\0'; class_addMethod(_logos_metaclass$SpringBoard$SBNotificationCenterController, @selector(_xen_setRequestVisible:), (IMP)&_logos_meta_method$SpringBoard$SBNotificationCenterController$_xen_setRequestVisible$, _typeEncoding); }Class _logos_class$SpringBoard$SBNotificationCenterLayoutViewController = objc_getClass("SBNotificationCenterLayoutViewController"); { char _typeEncoding[1024]; unsigned int i = 0; memcpy(_typeEncoding + i, @encode(NSSet*), strlen(@encode(NSSet*))); i += strlen(@encode(NSSet*)); _typeEncoding[i] = '@'; i += 1; _typeEncoding[i] = ':'; i += 1; _typeEncoding[i] = '\0'; class_addMethod(_logos_class$SpringBoard$SBNotificationCenterLayoutViewController, @selector(xen_defaultEnabledIDs), (IMP)&_logos_method$SpringBoard$SBNotificationCenterLayoutViewController$xen_defaultEnabledIDs, _typeEncoding); }{ char _typeEncoding[1024]; unsigned int i = 0; memcpy(_typeEncoding + i, @encode(NSMutableDictionary *), strlen(@encode(NSMutableDictionary *))); i += strlen(@encode(NSMutableDictionary *)); _typeEncoding[i] = '@'; i += 1; _typeEncoding[i] = ':'; i += 1; _typeEncoding[i] = '\0'; class_addMethod(_logos_class$SpringBoard$SBNotificationCenterLayoutViewController, @selector(xen_identifiersToDatums), (IMP)&_logos_method$SpringBoard$SBNotificationCenterLayoutViewController$xen_identifiersToDatums, _typeEncoding); }{ char _typeEncoding[1024]; unsigned int i = 0; memcpy(_typeEncoding + i, @encode(NSMutableDictionary *), strlen(@encode(NSMutableDictionary *))); i += strlen(@encode(NSMutableDictionary *)); _typeEncoding[i] = '@'; i += 1; _typeEncoding[i] = ':'; i += 1; _typeEncoding[i] = '\0'; class_addMethod(_logos_class$SpringBoard$SBNotificationCenterLayoutViewController, @selector(xen_dataSourceIdentifiersToDatumIdentifiers), (IMP)&_logos_method$SpringBoard$SBNotificationCenterLayoutViewController$xen_dataSourceIdentifiersToDatumIdentifiers, _typeEncoding); }Class _logos_class$SpringBoard$SBUIPasscodeLockViewWithKeyboard = objc_getClass("SBUIPasscodeLockViewWithKeyboard"); { char _typeEncoding[1024]; unsigned int i = 0; _typeEncoding[i] = 'v'; i += 1; _typeEncoding[i] = '@'; i += 1; _typeEncoding[i] = ':'; i += 1; _typeEncoding[i] = '\0'; class_addMethod(_logos_class$SpringBoard$SBUIPasscodeLockViewWithKeyboard, @selector(_xen_layoutForHidingViews), (IMP)&_logos_method$SpringBoard$SBUIPasscodeLockViewWithKeyboard$_xen_layoutForHidingViews, _typeEncoding); }Class _logos_class$SpringBoard$SBUIPasscodeTextField = objc_getClass("SBUIPasscodeTextField"); MSHookMessageEx(_logos_class$SpringBoard$SBUIPasscodeTextField, @selector(alpha), (IMP)&_logos_method$SpringBoard$SBUIPasscodeTextField$alpha, (IMP*)&_logos_orig$SpringBoard$SBUIPasscodeTextField$alpha);MSHookMessageEx(_logos_class$SpringBoard$SBUIPasscodeTextField, @selector(setAlpha:), (IMP)&_logos_method$SpringBoard$SBUIPasscodeTextField$setAlpha$, (IMP*)&_logos_orig$SpringBoard$SBUIPasscodeTextField$setAlpha$);MSHookMessageEx(_logos_class$SpringBoard$SBUIPasscodeTextField, @selector(backgroundColor), (IMP)&_logos_method$SpringBoard$SBUIPasscodeTextField$backgroundColor, (IMP*)&_logos_orig$SpringBoard$SBUIPasscodeTextField$backgroundColor);MSHookMessageEx(_logos_class$SpringBoard$SBUIPasscodeTextField, @selector(setBackgroundColor:), (IMP)&_logos_method$SpringBoard$SBUIPasscodeTextField$setBackgroundColor$, (IMP*)&_logos_orig$SpringBoard$SBUIPasscodeTextField$setBackgroundColor$);Class _logos_class$SpringBoard$CBRGradientView = objc_getClass("CBRGradientView"); MSHookMessageEx(_logos_class$SpringBoard$CBRGradientView, @selector(setFrame:), (IMP)&_logos_method$SpringBoard$CBRGradientView$setFrame$, (IMP*)&_logos_orig$SpringBoard$CBRGradientView$setFrame$);}
        
        CFNotificationCenterRef r = CFNotificationCenterGetDarwinNotifyCenter();
        CFNotificationCenterAddObserver(r, NULL, XENSettingsChanged, CFSTR("com.matchstic.xen/settingschanged"), NULL, 0);
#if USE_PEEK==1
        CFNotificationCenterAddObserver(r, NULL, &handleProximityFar, CFSTR("com.matchstic.xen/proxFar"), NULL, 0);
        CFNotificationCenterAddObserver(r, NULL, &handleProximityNear, CFSTR("com.matchstic.xen/proxNear"), NULL, 0);
#endif
        CFNotificationCenterAddObserver(r, NULL, showContentEditPanel, CFSTR("com.matchstic.xen/showcontentedit"), NULL, 0);
        
    } else if (!prefs && [[UIDevice currentDevice].systemVersion floatValue] <= 9.3) {
        
        #if USE_PEEK==1
        {}
        
#if TARGET_IPHONE_SIMULATOR==0
        MSHookFunction(IOHIDEventSystemOpen, $IOHIDEventSystemOpen, &ori_IOHIDEventSystemOpen);
#endif
        
        CFNotificationCenterRef r = CFNotificationCenterGetDarwinNotifyCenter();
        CFNotificationCenterAddObserver(r, NULL, &disableProximityMonitoring, CFSTR("com.matchstic.xen/disableProx"), NULL, 0);
        CFNotificationCenterAddObserver(r, NULL, &enableProximityMonitoring, CFSTR("com.matchstic.xen/enableProx"), NULL, 0);
        #endif
    }
}
