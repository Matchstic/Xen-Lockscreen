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

#import "XENResources.h"
#import "XENBaseViewController.h"
#import "XENLockPagesController.h"
#import "XENFirstBootController.h"
#import "XENHomeViewController.h"
#import "XENSecureWindow.h"
#import <CoreMotion/CoreMotion.h>
#include <sys/sysctl.h>
#import <substrate.h>
#import <malloc/malloc.h>
#include <CoreFoundation/CFLogUtilities.h>

@interface SBLockScreenManager (Unlocking)
- (_Bool)_finishUIUnlockFromSource:(int)arg1 withOptions:(id)arg2;
@end

static NSMutableArray *controllersToFadeOnHomeUp;
static NSMutableArray *availableControllers;
static NSMutableArray *lockpagesControllers;
static NSMutableArray *firstBootControllers;

static NSArray *enabledIdentifiers;
static NSDictionary *settings;
static NSDictionary *currentThemeDict;
static NSBundle *strings;
static __weak SBLockScreenView *lockscreenView;
static NSString *currentlyFullscreenNotificationApplicationIdentifier;
static __weak SBLockScreenNotificationListView *notificationListView;
static __weak SBLockScreenViewController *lsViewController;
static NSMutableArray *notificationBundleIdentifiers;
static NSMutableDictionary *notificationBundleIdentifiersWithCount;
static __weak UIView *timeView;
static int currentOrientation = 1;
static NSMutableSet *dontCancelTouchesInTheseViews;
static __weak _UIBackdropView *wallpaperBackdropView;
static UIWindow *contentEditWindow;
static __strong id cachedArrangementController;
static BOOL isEditMode;
static BOOL editFromSetup;
static BOOL isScreenOn;
static BOOL unlockedSinceBoot;
static BOOL passcodeLocked;
static BOOL slideUpPasscodeVisible = NO;
static BOOL shouldOverrideNextURLLaunch;
static BOOL isPageEditInSetup;
static BOOL togglesConfiguring;
static NSDateFormatter *dateFormatter;
static NSUserDefaults *PHDefaults;
static NSUserDefaults *WNDefaults;

// cached toggles info
static UIImage *cachedToggleCircleBackground;
static BOOL cachedHasNoToggleCircleBackground;
static UIImage *cachedToggleSquareBackground;
static BOOL cachedHasNoToggleSquareBackground;
static UIImage *cachedAirstuffBackground;
static BOOL cachedHasNoAirstuffBackground;
static NSMutableDictionary *cachedGlyphImages;

// Cached notifications icons.
static NSMutableDictionary *cachedNotificationsIcons;

@interface LPPageController : NSObject
+ (id)sharedInstance;
- (id)pages;
- (NSMutableArray*)_xen_sortedPages;
@end

@interface UIApplication (Private)
- (id)statusBarWindow;
@end

@interface IS2System : NSObject
+ (int)ramFree;
@end

@interface UIImage (Private2)
+(id)_applicationIconImageForBundleIdentifier:(NSString*)displayIdentifier format:(int)form scale:(CGFloat)scale;
@end

@interface FCForecastSettings : NSObject
+(instancetype)settings;
-(BOOL)showCurrentWeatherInClock;
@end


@implementation XENResources

#pragma mark System functions

void XLog(const char *file, int lineNumber, const char *functionName, NSString *format, ...) {
    // Type to hold information about variable arguments.
    
    if (![XENResources debugLogging]) {
        return;
    }
    
    va_list ap;
    
    // Initialize a variable argument list.
    va_start (ap, format);
    
    // NSLog only adds a newline to the end of the NSLog format if
    // one is not already there.
    // Here we are utilizing this feature of NSLog()
    if (![format hasSuffix: @"\n"]) {
        format = [format stringByAppendingString: @"\n"];
    }
    
    NSString *body = [[NSString alloc] initWithFormat:format arguments:ap];
    
    // End using variable argument list.
    va_end(ap);
    
    NSString *fileName = [[NSString stringWithUTF8String:file] lastPathComponent];
    
    //CFLog(kCFLogLevelInfo, (__bridge CFStringRef)[NSString stringWithFormat:@"Xen :: (%s:%d) %s", [fileName UTF8String],
                                         //lineNumber, [body UTF8String]]);
    
    NSLog(@"Xen :: (%s:%d) %s", [fileName UTF8String], lineNumber, [body UTF8String]);
    
    // Append to log file
    /*NSString *txtFileName = @"/var/mobile/Documents/XenDebug.txt";
    NSString *final = [NSString stringWithFormat:@"(%s:%d) %s", [fileName UTF8String],
                       lineNumber, [body UTF8String]];
    
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:txtFileName];
    if (fileHandle) {
        [fileHandle seekToEndOfFile];
        [fileHandle writeData:[final dataUsingEncoding:NSUTF8StringEncoding]];
        [fileHandle closeFile];
    } else{
        [final writeToFile:txtFileName
                atomically:NO
                  encoding:NSStringEncodingConversionAllowLossy
                     error:nil];
    }*/
}

+(void)printViewHierarchyOfView:(UIView*)view {
    UIView *currentView = view;
    static int depth = 0;
    
    NSMutableString *star = [@"" mutableCopy];
        
    for (int i = 0; i < depth; i++) {
        [star appendString:@"*"];
    }
        
    NSLog(@"%@ %@", star, currentView);
    
    if ([[view subviews] count] > 0) depth++; else depth--;
    
    for (UIView *subview in view.subviews) {
        [XENResources printViewHierarchyOfView:subview];
    }
}

+(NSMutableArray*)allSubviewsForView:(UIView*)view {
    NSMutableArray *arr = [[NSMutableArray alloc] init];
    [arr addObject:view];
    for (UIView *subview in view.subviews) {
        [arr addObjectsFromArray:(NSArray*)[self allSubviewsForView:subview]];
    }
    return arr;
}

+ (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize {
    //UIGraphicsBeginImageContext(newSize);
    // In next line, pass 0.0 to use the current device's pixel scaling factor (and thus account for Retina resolution).
    // Pass 1.0 to force exact pixel size.
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

+(BOOL)isViewOnXen:(UIView*)view {
    return [view isDescendantOfView:lockscreenView];
}

+(CGSize)getSizeForText:(NSString *)text maxWidth:(CGFloat)width font:(NSString *)fontName fontSize:(float)fontSize {
    CGSize constraintSize;
    constraintSize.height = MAXFLOAT;
    constraintSize.width = width;
    NSDictionary *attributesDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                          [UIFont fontWithName:fontName size:fontSize], NSFontAttributeName,
                                          nil];
    
    CGRect frame = [text boundingRectWithSize:constraintSize
                                      options:NSStringDrawingUsesLineFragmentOrigin
                                   attributes:attributesDictionary
                                      context:nil];
    
    CGSize stringSize = frame.size;
    return stringSize;
}

+(CGRect)boundedRectForFont:(UIFont*)font andText:(NSString*)text width:(CGFloat)width {
    if (!text || !font) {
        return CGRectZero;
    }
    
    if (![text isKindOfClass:[NSAttributedString class]]) {
        NSAttributedString *attributedText = [[NSAttributedString alloc] initWithString:text attributes:@{NSFontAttributeName:font}];
        CGRect rect = [attributedText boundingRectWithSize:(CGSize){width, CGFLOAT_MAX}
                                                   options:NSStringDrawingUsesLineFragmentOrigin
                                                   context:nil];
        return rect;
    } else {
        return [(NSAttributedString*)text boundingRectWithSize:(CGSize){width, CGFLOAT_MAX}
                                                       options:NSStringDrawingUsesLineFragmentOrigin
                                                       context:nil];
    }
}

+(BOOL)setLockscreenView:(id)view {
    BOOL res = lockscreenView == nil;
    
    lockscreenView = view;
    
    if (res) {
        // Update since we now have the LS.
        [[NSNotificationCenter defaultCenter] postNotificationName:@"XENLegibibilityDidChange" object:nil];
    }
    
    return res;
}

+(UIWindow*)contentEditWindow {
    if (!contentEditWindow) {
        contentEditWindow = [[XENSecureWindow alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)];
        contentEditWindow.windowLevel = 1000;
        contentEditWindow.backgroundColor = [UIColor clearColor];
    }
    
    return contentEditWindow;
}

+(void)hideContentEditWindow {
    contentEditWindow.hidden = YES;
    
    for (UIView *view in contentEditWindow.subviews) {
        [view removeFromSuperview];
    }
    
    contentEditWindow = nil;
    cachedArrangementController = nil;
    isEditMode = NO;
    
    if (editFromSetup) {
        [self moveUpDownWallpaperWindowForSetup:YES];
    }
}

+(void)cacheArrangementController:(id)controller {
    cachedArrangementController = controller;
}

+(void)moveUpDownWallpaperWindow:(BOOL)moveToOrigLocation {
    long long orient = 0;
    
    if (moveToOrigLocation) {
        // Don't require wallpaper
        [[objc_getClass("SBWallpaperController") sharedInstance] endRequiringWithReason:@"Content Page Editor Showing"];
        [[objc_getClass("SBWallpaperController") sharedInstance] setActiveOrientationSource:0x0 andUpdateToOrientation:(int)orient usingCrossfadeToBlack:NO];
        
        // Switch back to homescreen wallpaper
        [[objc_getClass("SBWallpaperController") sharedInstance] setVariant:1 withOutAnimationFactory:nil inAnimationFactory:nil completion:nil];
    } else {
        // Require wallpaper
        [[objc_getClass("SBWallpaperController") sharedInstance] beginRequiringWithReason:@"Content Page Editor Showing"];
        [[objc_getClass("SBWallpaperController") sharedInstance] setActiveOrientationSource:0x3 andUpdateToOrientation:(int)orient usingCrossfadeToBlack:NO];
        
        // Switch to lockscreen wallpaper.
        [[objc_getClass("SBWallpaperController") sharedInstance] setVariant:0 withOutAnimationFactory:nil inAnimationFactory:nil completion:nil];
    }
    
    [[objc_getClass("SBWallpaperController") sharedInstance] _window].windowLevel = (moveToOrigLocation ? -2.0 : 1000);
}

+(void)moveUpDownWallpaperWindowForSetup:(BOOL)moveToOrigLocation {
    [[objc_getClass("SBWallpaperController") sharedInstance] _window].windowLevel = (moveToOrigLocation ? 1049 : 1084);
}

+(UIWindow*)wallpapeWindow {
    return [[objc_getClass("SBWallpaperController") sharedInstance] _window];
}

+(BOOL)isCurrentDeviceOld {
    // Get hardware verison.
    size_t buflen = 0x80;
    char buf[buflen];
        
    if (sysctlbyname("hw.model", buf, &buflen, NULL, 0) != 0) {
        return 1;
    }
        
    int isOld = strcmp(buf, "K93AP") == 0 ||
    strcmp(buf, "K94AP") == 0 ||
    strcmp(buf, "K95AP") == 0 ||
    strcmp(buf, "K93AAP") == 0 ||
    strcmp(buf, "N94AP") == 0 ||
    strcmp(buf, "N78AP") == 0 ||
    strcmp(buf, "N78AAP") == 0 ||
    strcmp(buf, "N41AP") == 0 ||
    strcmp(buf, "N42AP") == 0;
        
    return isOld;
}

+(BOOL)unlockedOnceSinceBoot {
    return unlockedSinceBoot;
}

+(void)setUnlockedSinceBoot:(BOOL)unlocked {
    unlockedSinceBoot = unlocked;
}

+(void)setIsPasscodeLocked:(BOOL)isLocked {
    passcodeLocked = isLocked;
}

+(BOOL)isPasscodeLocked {
    return passcodeLocked;
}

+(void)setSlideUpPasscodeVisible:(BOOL)visible {
    slideUpPasscodeVisible = visible;
}

+(BOOL)isSlideUpPasscodeVisible {
    return slideUpPasscodeVisible;
}

+(id)iconImageViewForBundleIdentifier:(NSString*)bundleIdentifier {
    if ([bundleIdentifier isEqualToString:@"com.apple.DuetHeuristic-BM"]) {
        // return image view with this icon.
        UIImageView *batteryIcon = [[UIImageView alloc] initWithImage:[self themedImageWithName:@"LowPowerOffIcon"]];
        batteryIcon.frame = CGRectMake(0, 0, (IS_IPAD ? 72 : 60), (IS_IPAD ? 72 : 60));
        return batteryIcon;
    }
    
    UIImage *icon;
    
    if (!bundleIdentifier) {
        // Wait, WTF.
        icon = [[UIImage alloc] init];
    } else if ([cachedNotificationsIcons objectForKey:bundleIdentifier]) {
        icon = [cachedNotificationsIcons objectForKey:bundleIdentifier];
    } else {
        @try {
            icon = [UIImage _applicationIconImageForBundleIdentifier:bundleIdentifier format:2 scale:[UIScreen mainScreen].scale];
        } @catch (NSException *e) {
            // Anemone is bad... Likes to crash if no bundleidentifier, or if not a "real" app.
            if (!icon) {
                icon = [[UIImage alloc] init];
            }
        }
        
        if (!icon) {
            icon = [[UIImage alloc] init];
        }
    }
    
    UIImageView *iconView = [[UIImageView alloc] initWithImage:icon];
    iconView.frame = CGRectMake(0, 0, (IS_IPAD ? 72 : 60), (IS_IPAD ? 72 : 60));
    iconView.opaque = NO;
    
    return iconView;
}

+(void)setCurrentOrientation:(int)orient {
    currentOrientation = orient;
}

+(int)getCurrentOrientation {
    return currentOrientation;
}

+(void)setScreenOnState:(BOOL)isOn {
    isScreenOn = isOn;
}

+(BOOL)getScreenOnState {
    return isScreenOn;
}

+(void)turnOnDisplay {
    SBLockScreenManager *manager = [objc_getClass("SBLockScreenManager") sharedInstance];
    
    NSDictionary *options = [NSDictionary dictionaryWithObjects:@[@YES, @YES] forKeys:@[@"SBUIUnlockOptionsStartFadeInAnimation", @"SBUIUnlockOptionsTurnOnScreenFirstKey"]];
    [manager unlockUIFromSource:6 withOptions:options];
}

+(NSDateFormatter*)sharedDateFormatter {
    if (!dateFormatter) {
        static dispatch_once_t p = 0;
        dispatch_once(&p, ^{
            dateFormatter = [[NSDateFormatter alloc] init];
        });
    }
    
    return dateFormatter;
}

#pragma mark Welcome heuristics

/*+(void)recordStart:(time_t)start {
    
}

+(int)currentWelcomeHeuristic {
    NSMutableDictionary *groups = [NSMutableDictionary dictionary];
    
    NSMutableArray *storedHeuristics = (settings[@"welcomeHeuristics"] ? settings[@"welcomeHeuristics"] : [@[] mutableCopy]);
    [storedHeuristics addObject:[NSNumber numberWithInt:5]];
    
    for (NSNumber *start in storedHeuristics) {
        
    }
}*/

+(BOOL)isPageEditInSetup {
    return isPageEditInSetup;
}
+(void)setIsPageEditInSetup:(BOOL)val {
    isPageEditInSetup = val;
}

#pragma mark Private APIs

+(void)resetLockscreenDimTimer {
    [(SBBacklightController*)[objc_getClass("SBBacklightController") sharedInstance] resetLockScreenIdleTimer];
}

+(void)cancelLockscreenDimTimer {
    [(SBBacklightController*)[objc_getClass("SBBacklightController") sharedInstance] cancelLockScreenIdleTimer];
}

+(BOOL)attemptToUnlockDeviceWithoutPasscode {
    if (!passcodeLocked) {
        XENlog(@"Unlocking device without passcode");
        
        SBLockScreenManager *manager = [objc_getClass("SBLockScreenManager") sharedInstance];
        
        int source = [UIDevice currentDevice].systemVersion.floatValue < 10.0 ? 0 : 0xb;
        if ([UIDevice currentDevice].systemVersion.floatValue < 10) {
            NSDictionary *options = [NSDictionary dictionaryWithObjects:@[@YES] forKeys:@[@"SBUIUnlockOptionsNoPasscodeAnimationKey"]];
            
            [manager startUIUnlockFromSource:source withOptions:options];
        } else {
            // We will cheat a little and avoid situations where we may have our unlock request
            // ignored by Apple.
            
            // First, a sanity check.
            SBFUserAuthenticationController *auth = [(SpringBoard*)[UIApplication sharedApplication] authenticationController];
            if (![auth isAuthenticated]) {
                XENlog(@"Aborting unlock attempt; user is not authenticated");
                return NO;
            }
            
            NSDictionary *options = [NSDictionary dictionaryWithObjects:@[@YES, @YES] forKeys:@[@"SBUIUnlockOptionsTurnOnScreenFirstKey", @"SBUIUnlockOptionsStartFadeInAnimation"]];
            
            [manager _finishUIUnlockFromSource:source withOptions:options];
        }
        
        return YES;
    }
    
    return NO;
}

+(void)_showPasscode {
    // Move to passcode UI.
    XENHomeViewController *controller = [XENResources controllerWithIdentifier:@"com.matchstic.home"];
    [controller _showPasscode];
}

+(void)setShouldOverrideNextURLLaunch:(BOOL)val {
    shouldOverrideNextURLLaunch = val;
}

+(BOOL)shouldOverrideNextURLLaunch {
    return shouldOverrideNextURLLaunch;
}

+(void)openURLWithPasscodeIfNeeded:(NSURL*)url {
    // Enforce calling on the main thread!
    dispatch_async(dispatch_get_main_queue(), ^{
         [[objc_getClass("SBNotificationCenterController") sharedInstance] widget:nil requestsLaunchOfURL:url];
    });
}

+(void)updateLockscreenBlurPercentage:(CGFloat)percent withPasscodeView:(id)view {
   // XENHomeViewController *controller = [XENResources controllerWithIdentifier:@"com.matchstic.home"];
    [lockscreenView _setCurrentBlurRadius:30 * percent];
}

+(BOOL)shouldUseDarkColouration {
    UIColor *colour = [XENResources effectiveLegibilityColor];
    
    CGFloat red, blue, green, alpha;
    
    [colour getRed:&red green:&green blue:&blue alpha:&alpha];
    
    CGFloat brightness = red * 0.3 + green * 0.59 + blue * 0.11;
    
    return brightness < 0.5;
}

+(UIColor*)effectiveLegibilityColor {
    if (isEditMode) {
        _UILegibilitySettings *settings = [[objc_getClass("SBWallpaperController") sharedInstance] legibilitySettingsForVariant:0];
        return settings.primaryColor;
    } else {
        if ([lockscreenView respondsToSelector:@selector(_effectiveStatusBarColor)]) {
            return [lockscreenView _effectiveStatusBarColor];
        } else if ([lsViewController respondsToSelector:@selector(dashBoardView)]) {
            SBDashBoardView *view = [(SBDashBoardViewController*)lsViewController dashBoardView];
            return view.legibilitySettings.primaryColor;
        }
    }
    
    return [UIColor whiteColor];
}

+(void)setGrabbersFade:(CGFloat)alpha {
    
}

+(void)setPasscodeFirstResponder:(BOOL)become {
    XENHomeViewController *controller = [XENResources controllerWithIdentifier:@"com.matchstic.home"];
    
    if (become) {
        [[controller passcodeView] becomeFirstResponder];
    } else {
        [[controller passcodeView] resignFirstResponder];
    }
}

+(SBLockScreenViewController*)lsViewController {
    return lsViewController;
}

+(void)setLsViewController:(SBLockScreenViewController*)controller {
    lsViewController = controller;
}

+(void)setLockscreenActionContext:(id)context {
#warning TODO: iOS 10.
    if ([lsViewController respondsToSelector:@selector(invalidateLockScreenActionContext)]) {
        [(SBDashBoardViewController*)lsViewController invalidateLockScreenActionContext];
    } else {
        [lsViewController _notificationController].lockScreenActionContext = context;
        lsViewController._bioLockScreenActionContext = context;
        [lsViewController setUnlockActionContext:context];
        [lsViewController setCustomLockScreenActionContext:context];
    
        if (!context)
            [[objc_getClass("SBNotificationCenterController") sharedInstance] invalidateLockScreenActionContext];
    }
}

+(void)setPreferenceKey:(NSString*)key withValue:(id)value andPost:(BOOL)post {
    if (!key || !value) {
        NSLog(@"Not setting value, as one of the arguments is null");
        return;
    }
    
    CFPreferencesAppSynchronize(CFSTR("com.matchstic.xen"));
    NSMutableDictionary *settings = [(__bridge NSDictionary *)CFPreferencesCopyMultiple(CFPreferencesCopyKeyList(CFSTR("com.matchstic.xen"), kCFPreferencesCurrentUser, kCFPreferencesAnyHost), CFSTR("com.matchstic.xen"), kCFPreferencesCurrentUser, kCFPreferencesAnyHost) mutableCopy];
    
    [settings setObject:value forKey:key];
    
    // Write to CFPreferences
    CFPreferencesSetValue ((__bridge CFStringRef)key, (__bridge CFPropertyListRef)value, CFSTR("com.matchstic.xen"), kCFPreferencesCurrentUser, kCFPreferencesCurrentHost);
    
    [settings writeToFile:@"/var/mobile/Library/Preferences/com.matchstic.xen.plist" atomically:YES];
    
    if (post) {
        // Notify that we've changed!
        CFStringRef toPost = (__bridge CFStringRef)@"com.matchstic.xen/settingschanged";
        if (toPost) CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), toPost, NULL, NULL, YES);
    }
}

+(NSString*)imageSuffix {
    NSString *suffix = @"";
    switch ((int)[UIScreen mainScreen].scale) {
        case 2:
            suffix = @"@2x";
            break;
        case 3:
            suffix = @"@3x";
            break;
            
        default:
            break;
    }
    
    return [NSString stringWithFormat:@"%@.png", suffix];
}

+(BOOL)isForecastInstalledAndPutInClock {
    if (objc_getClass("FCForecastSettings")) {
        return [[objc_getClass("FCForecastSettings") settings] showCurrentWeatherInClock];
    }
    
    return NO;
}

+(BOOL)isNoctisInstalled {
    return [[NSFileManager defaultManager] fileExistsAtPath:@"/Library/MobileSubstrate/DynamicLibraries/Noctis.dylib"];
}

+(BOOL)isNoctisEnabled {
    return NO;
}

+(CGFloat)calculateAdditionalOffsetForDateView:(SBFLockScreenDateView*)_dateView withCurrentOffset:(CGFloat)offset {
    // Use notification list view padding, clock height etc.
    
    if ([self isForecastInstalledAndPutInClock]) {
        // Don't adjust the clock if Forecast is present, because, it's weird.
        return 0.0;
    }
    
    if (!_dateView) {
        _dateView = MSHookIvar<SBFLockScreenDateView*>([lsViewController lockScreenView], "_dateView");
        offset = [_dateView timeBaselineOffsetFromOrigin];
    } else if (offset <= 0) {
        return 0.0;
    }
    
    if (![XENResources useGroupedNotifications]) {
        return 0.0;
    } else if ([XENResources useGroupedNotifications] && [XENResources usingPriorityHubCompatiblityMode]) {
        return 0.0;
    }
    
    CGFloat baseY = [objc_getClass("SBFLockScreenMetrics") dateViewBaselineY];
    baseY -= offset;
    
    CGFloat height = [objc_getClass("SBFLockScreenDateView") defaultHeight] + [objc_getClass("SBFLockScreenMetrics") dateLabelFontSize] + 5;
    
    // This is where the grouped icon will sit.
    CGFloat notificationY = [objc_getClass("SBFLockScreenMetrics") notificationListInsets].top;
    notificationY -= (IS_IPAD ? 72 : 60) - (IS_IPAD ? 10 : 5);
    if (SCREEN_MAX_LENGTH >= 736) {
        notificationY -= 10; // Extra bit for 6 Plus.
    } // Handling for iPhone 5 and smaller etc is done by the insets hooks.
    
    CGFloat actualoffset = (height + baseY) - notificationY;
    
    return (actualoffset > 0 ? actualoffset + 5 : 0.0);
}

#pragma mark Handling of wallpaper blur view

+(UIView*)wallpaperBlurView {
    return wallpaperBackdropView;
}

+(void)setWallpaperBlurView:(_UIBackdropView*)blur {
    wallpaperBackdropView = blur;
}

+(void)setWallpaperBlurPercentage:(CGFloat)percent withDuration:(CGFloat)duration {
    [UIView animateWithDuration:duration animations:^{
        wallpaperBackdropView.alpha = percent;
        if ([wallpaperBackdropView respondsToSelector:@selector(setBlurRadius:)])
            [wallpaperBackdropView setBlurRadius:30 * percent];
    }];
    
    [self setFakeSBStatusBarAlphaIfNecessary:percent withDuration:duration];
}

+(void)setFakeSBStatusBarAlphaIfNecessary:(CGFloat)alpha withDuration:(CGFloat)duration {
    if (![XENResources shouldUseDarkColouration]) {
        return;
    }
    
    if (lockscreenView) {
        UIView *fakeStatusBar = MSHookIvar<UIView*>(lockscreenView, "_fakePasscodeStatusBarView");
        UIView *statusBarWindow = [[UIApplication sharedApplication] statusBarWindow];
    
        [UIView animateWithDuration:duration animations:^{
            fakeStatusBar.alpha = alpha;
            statusBarWindow.alpha = 1.0 - alpha;
        }];
    } else {
        UIView *statusBarWindow = [[UIApplication sharedApplication] statusBarWindow];
        
        [UIView animateWithDuration:duration animations:^{
            statusBarWindow.alpha = 1.0 - alpha;
        }];
    }
}

#pragma mark Handle storing and retrieving data on fullscreen application for notifications

+(void)setCurrentlyShownNotificationAppIdentifier:(NSString*)bundleIdentifier {
    currentlyFullscreenNotificationApplicationIdentifier = bundleIdentifier;
}

+(NSString*)currentlyShownNotificationAppIdentifier {
    if (!currentlyFullscreenNotificationApplicationIdentifier || [currentlyFullscreenNotificationApplicationIdentifier isEqualToString:@""]) {
        return @"";
    } else {
        return currentlyFullscreenNotificationApplicationIdentifier;
    }
}

+(NSString*)identifierForListItem:(SBAwayListItem *)listItem {
    // CHECKME: Handle iOS 10.
    if ([listItem isKindOfClass:objc_getClass("NCNotificationRequest")]) {
        return [(NCNotificationRequest*)listItem sectionIdentifier];
    }
    
    if ([listItem isKindOfClass:[objc_getClass("SBAwayBulletinListItem") class]] || [listItem isKindOfClass:[objc_getClass("SBSnoozedAlarmBulletinListItem") class]])
        return [[(SBAwayBulletinListItem*)listItem activeBulletin] sectionID];
    else if ([listItem isKindOfClass:[objc_getClass("SBSnoozedAlarmListItem") class]]) {
        return @"com.apple.mobiletimer";
    }
    else if ([listItem isKindOfClass:[objc_getClass("SBAwayCardListItem") class]])
        return [[(SBAwayCardListItem*)listItem cardItem] identifier];
    else if ([listItem isKindOfClass:[objc_getClass("SBAwaySystemAlertItem") class]])
        return @"systemAlert";
    else
        return @"noIdentifier";
}

+(NSArray*)allNotificationBundleIdentifiers {
    // DEBUG.
    
    if (!notificationBundleIdentifiers) {
        notificationBundleIdentifiers = [NSMutableArray array];
        notificationBundleIdentifiersWithCount = [NSMutableDictionary dictionary];
        
        // If nil, make sure to load up all available identifiers from Apple's data source. It's possible that there are actually notifications still.
        // TODO: Needs iOS 10 support... :(
        /*int currentValue = 0;
        
        for (id item in [[lsViewController _notificationController] _xen_listItems]) {
            NSString *identifier = [XENResources identifierForListItem:item];
            
            if (![notificationBundleIdentifiers containsObject:identifier])
                [notificationBundleIdentifiers insertObject:identifier atIndex:0];
            
            if ([[notificationBundleIdentifiersWithCount allKeys] containsObject:identifier]) {
                currentValue = [notificationBundleIdentifiersWithCount[identifier] intValue];
            } else {
                currentValue = 0;
            }
            
            [notificationBundleIdentifiersWithCount setObject:[NSNumber numberWithInt:currentValue + 1] forKey:identifier];
        }*/
    }
    
    return notificationBundleIdentifiers;
}

+(BOOL)addNotificationBundleIdentifier:(NSString*)identifier {
    BOOL returnValue = NO;
    
    if (!notificationBundleIdentifiers) {
        notificationBundleIdentifiers = [NSMutableArray array];
    }
    
    if (![notificationBundleIdentifiers containsObject:identifier])
        [notificationBundleIdentifiers insertObject:identifier atIndex:0];
    
    if (!notificationBundleIdentifiersWithCount) {
        notificationBundleIdentifiersWithCount = [NSMutableDictionary dictionary];
    }
    
    int currentValue = 0;
    if ([[notificationBundleIdentifiersWithCount allKeys] containsObject:identifier]) {
        currentValue = [notificationBundleIdentifiersWithCount[identifier] intValue];
    } else {
        returnValue = YES;
    }
    
    [notificationBundleIdentifiersWithCount setObject:[NSNumber numberWithInt:currentValue + 1] forKey:identifier];
    
    return returnValue;
}

+(int)removeNotificationBundleIdentifier:(NSString*)identifier {
    int currentValue = [notificationBundleIdentifiersWithCount[identifier] intValue];
    
    XENlog(@"REQUESTING REMOVAL OF NOTIF, %@, WITH CURRENTVALUE == %d", identifier, currentValue);
    
    if (currentValue - 1 <= 0) {
        int index = 0;
        for (NSString *object in [notificationBundleIdentifiers copy]) {
            if ([object isEqualToString:identifier]) {
                [notificationBundleIdentifiers removeObject:object];
                break;
            }
            index++;
        }
        
        [notificationBundleIdentifiersWithCount removeObjectForKey:identifier];
        
        return index;
    } else {
        [notificationBundleIdentifiersWithCount setObject:[NSNumber numberWithInt:currentValue - 1] forKey:identifier];
        return -1;
    }
}

+(void)setTogglesConfiguring:(BOOL)arg1 {
    togglesConfiguring = arg1;
}

+(BOOL)isTogglesConfiguring {
    return togglesConfiguring;
}

+(UIView*)notificationListView {
    return notificationListView;
}

+(void)setNotificationListView:(UIView*)listView {
    notificationListView = (SBLockScreenNotificationListView*)listView;
}

+(void)reloadNotificationListView {
#warning TODO iOS 10.
    UITableView *notificationsTableView = MSHookIvar<UITableView*>(notificationListView, "_tableView");
    
    if (notificationsTableView)
        [notificationsTableView reloadData];
    
    //Reset screen off timer and notification cell fade timer
    if (notificationListView) {
        [notificationListView _disableIdleTimer:YES];
        [notificationListView _disableIdleTimer:NO];
        [notificationListView _resetAllFadeTimers];
    }
}

+(void)reloadNotificationListViewSeparators {
    [notificationListView _xen_reloadSeparatorStyleForSetup];
}

+(int)countOfNotificationsForBundleIdentifier:(NSString*)bundleIdentifier {
    return [notificationBundleIdentifiersWithCount[bundleIdentifier] intValue];
}

#pragma mark View controller methods

+(void)registerControllerForFadeOnHomeArrowUp:(UIViewController*)controller {
    if (!controllersToFadeOnHomeUp) {
        controllersToFadeOnHomeUp = [NSMutableArray array];
    }
    
    [controllersToFadeOnHomeUp addObject:[NSValue valueWithNonretainedObject:controller]];
}

+(void)applyFadeToControllers:(CGFloat)alpha {
    for (NSValue *value in [controllersToFadeOnHomeUp copy]) {
        UIViewController *controller = [value nonretainedObjectValue];
        
        if (controller && [controller.view superview]) {
            controller.view.alpha = alpha;
        } else {
            [controllersToFadeOnHomeUp removeObject:value];
        }
    }
}

+(void)clearFadeOnHomeArrowUp {
    [controllersToFadeOnHomeUp removeAllObjects];
    controllersToFadeOnHomeUp = nil;
}

+(void)clearDontTouchViews {
    [dontCancelTouchesInTheseViews removeAllObjects];
    dontCancelTouchesInTheseViews = nil;
}

+(NSArray*)subclassesOfViewControllers {
    int numClasses = objc_getClassList(NULL, 0);
    Class *classes = NULL;
    
    classes = (Class*)malloc(sizeof(Class) * numClasses);
    numClasses = objc_getClassList(classes, numClasses);
    
    NSMutableArray *result = [NSMutableArray array];
    for (NSInteger i = 0; i < numClasses; i++) {
        Class superClass = classes[i];
        do {
            superClass = class_getSuperclass(superClass);
        } while (superClass && superClass != objc_getClass("XENBaseViewController"));
        
        if (superClass == nil || [classes[i] isEqual:[XENLockPagesController class]] || [classes[i] isEqual:[XENFirstBootController class]]) {
            continue;
        }
        
        [result addObject:classes[i]];
    }
    
    free(classes);
    
    return result;
}

+(NSArray*)availableViewControllers {
    if (!availableControllers) {
        availableControllers = [NSMutableArray array];
        
        NSArray *array = [XENResources subclassesOfViewControllers];
        for (int i = 0; i < [array count]; i++) {
            id obj = [array objectAtIndex:i];
            
            if (class_isMetaClass(object_getClass(obj)) && [obj supportsCurrentiOSVersion]) {
                XENBaseViewController *controller = [[obj alloc] init];
                [availableControllers addObject:controller];
            }
        }
    }
    
    return availableControllers;
}

+(id)controllerWithIdentifier:(NSString*)identifier {
    for (XENBaseViewController *cont in [XENResources availableViewControllers]) {
        if ([[cont uniqueIdentifier] isEqualToString:identifier]) {
            return cont;
        }
    }
    
    if (!lockpagesControllers) {
        [self didSortLockPages];
    }
    
    for (XENLockPagesController *cont in lockpagesControllers) {
        if ([[cont uniqueIdentifier] isEqualToString:identifier]) {
            return cont;
        }
    }
    
    // Finally, check through first boot controllers.
    
    if (firstBootControllers) {
        for (XENLockPagesController *cont in firstBootControllers) {
            if ([[cont uniqueIdentifier] isEqualToString:identifier]) {
                return cont;
            }
        }
    }
    
    return nil;
}

+(void)relayourLockPagesControllers {
    for (XENLockPagesController *cont in lockpagesControllers) {
        [cont relayoutSubview];
    }
}

#pragma mark Scroll view touch canceling shizzle

+(void)preventScrollViewCancelling:(UIView*)view {
    if (!dontCancelTouchesInTheseViews) {
        dontCancelTouchesInTheseViews = [NSMutableSet set];
    }
    
    [dontCancelTouchesInTheseViews addObject:[NSValue valueWithNonretainedObject:view]];
}

+(NSSet*)dontCancelTouchesInTheseViews {
    return dontCancelTouchesInTheseViews;
}

+(BOOL)canWidgetsLaunchURL {
    // Check if main scrollview is scrolling.
    
    if (lockscreenView.scrollView.isDragging || lockscreenView.scrollView.isTracking) {
        return NO;
    }
    
    return YES;
}

#pragma mark Resource loading

+(NSString*)themedResourceFilePathWithName:(NSString*)name andExtension:(NSString*)ext {
    NSString *theme = (settings[@"lockTheme"] ? settings[@"lockTheme"] : @"BLUR");
    return [self resourceFilePathWithName:name extension:ext andTheme:theme];
}

+(NSString*)resourceFilePathWithName:(NSString*)name extension:(NSString*)ext andTheme:(NSString*)theme {
    NSString *suffix = @"";
    switch ((int)[UIScreen mainScreen].scale) {
        case 2:
            suffix = @"@2x";
            break;
        case 3:
            suffix = @"@3x";
            break;
            
        default:
            break;
    }
    
    suffix = [NSString stringWithFormat:@"%@.%@", suffix, ext];
    NSString *filepath;
    
    if ([self isCurrentThemeLegacy] && ![theme isEqualToString:@"BLUR"]) {
        filepath = [NSString stringWithFormat:@"/Library/Application Support/Convergance/Themes/%@/%@%@", theme, [self mapNewNameToLegacyName:name], suffix];
    } else {
        filepath = [NSString stringWithFormat:@"/Library/Application Support/Xen/Themes/%@/%@%@", theme, name, suffix];
    }
    
    if ((int)[UIScreen mainScreen].scale == 3) {
        // may need to check that @3x exists, else fallback to @2x.
        if (![[NSFileManager defaultManager] fileExistsAtPath:filepath]) {
            suffix = @"@2x";
            if ([self isCurrentThemeLegacy] && ![theme isEqualToString:@"BLUR"]) {
                filepath = [NSString stringWithFormat:@"/Library/Application Support/Convergance/Themes/%@/%@%@", theme, [self mapNewNameToLegacyName:name], suffix];
            } else {
                filepath = [NSString stringWithFormat:@"/Library/Application Support/Xen/Themes/%@/%@%@", theme, name, suffix];
            }
        }
    }
    
    return filepath;
}

+(BOOL)isCurrentThemeLegacy {
    id value = settings[@"themeIsLegacy"];
    return (value ? [value boolValue] : NO);
}

+(NSString*)mapNewNameToLegacyName:(NSString*)input {
    // handle toggles.
    if ([input hasPrefix:@"Toggles/Glyphs/"]) {
        return [self getLegacyToggleName:[input stringByReplacingOccurrencesOfString:@"Toggles/Glyphs/" withString:@""]];
    }
    
    if ([input isEqualToString:@"UpArrow"]) return @"up";
    if ([input isEqualToString:@"SliderMin"]) return @"slider_min";
    if ([input isEqualToString:@"SliderMax"]) return @"slider_max";
    if ([input isEqualToString:@"SliderThumb"]) return @"slider_thumb";
    if ([input isEqualToString:@"SlideIndicator"]) return @"LockSlideIndicator";
    if ([input isEqualToString:@"MusicForward"]) return @"LockMusicForward";
    if ([input isEqualToString:@"MusicPlay"]) return @"LockMusicPlay";
    if ([input isEqualToString:@"MusicPause"]) return @"LockMusicPause";
    if ([input isEqualToString:@"MusicRewind"]) return @"LockMusicRewind";
    if ([input isEqualToString:@"MusicStar"]) return @"LockMusicStar";
    
    return input;
}

+(NSString*)getLegacyToggleName:(NSString*)input {
    NSString *toggleName = @"";
    BOOL enabled = [input hasSuffix:@"enabled"];
    
    NSString *i = [input stringByReplacingOccurrencesOfString:@"-enabled" withString:@""];
    i = [i stringByReplacingOccurrencesOfString:@"-disabled" withString:@""];
    
    if ([i isEqualToString:@"airplaneMode"]) toggleName = @"airplane-mode";
    else if ([i isEqualToString:@"doNotDisturb"]) toggleName = @"do-not-disturb";
    else toggleName = i;
    
    return [NSString stringWithFormat:@"LockToggles/com.a3tweaks.%@-glyph-%@", toggleName, (enabled ? @"on" : @"off")];
}

+(UIImage*)themedImageWithName:(NSString*)imageName {
    UIImage *image = [UIImage imageWithContentsOfFile:[XENResources themedResourceFilePathWithName:imageName andExtension:@"png"]];
    
    if (!image) {
        // Pull default image instead from BLUR.
        image = [UIImage imageWithContentsOfFile:[XENResources resourceFilePathWithName:imageName extension:@"png" andTheme:@"BLUR"]];
    }
    
    return image;
}

+(NSString*)localisedStringForKey:(NSString*)key value:(NSString*)val {
    if (!strings) {
        return val;
    }
    return [strings localizedStringForKey:key value:val table:nil];
}

+(NSString*)tapToOpenTextForBundleIdentifier:(NSString*)bundleIdentifier {
    NSString *text = [XENResources localisedStringForKey:@"tap to open" value:@"tap to open"];
    
    /*if ([bundleIdentifier isEqualToString:@"com.apple.MobileSMS"] ||
        [bundleIdentifier isEqualToString:@"com.facebook.Messenger"] ||
        [bundleIdentifier isEqualToString:@"com.apple.mobilemail"]) {
        text = [XENResources localisedStringForKey:@"tap to reply" value:@"tap to reply"];
    } else*/ if ([bundleIdentifier isEqualToString:@"com.apple.mobilephone"]) {
        text = [XENResources localisedStringForKey:@"tap to call" value:@"tap to call"];
    }
    
    return text;
}

+(UIColor*)textColour {
    return [XENResources shouldUseDarkColouration] ? [UIColor darkGrayColor] : [UIColor whiteColor];
}

#pragma mark Toggles theming

+(UIColor*)togglesGlyphTintForState:(int)state isCircle:(BOOL)isCircle {
    NSDictionary *colorData;
    if (isCircle)
        colorData = [currentThemeDict objectForKey:(state == 0 ? @"togglesDisabledColor" : @"togglesEnabledColor")];
    else
        colorData = [currentThemeDict objectForKey:(state == 0 ? @"togglesSquaredDisabledColor" : @"togglesSquaredEnabledColor")];
    
    if (!colorData /*&& ![self isCurrentThemeLegacy]*/ ) {
        return nil;
    }/* else if ([self isCurrentThemeLegacy]) {
        // Attempt to load from the theme's LockToggles/Info.plist
        NSString *filePath = [NSString stringWithFormat:@"/Library/Application Support/Convergance/Themes/%@/LockToggles/Info.plist", settings[@"lockTheme"]];
        NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:filePath];
        
        if (!dict) {
            // Well, shit. Go by Convergance's defaults.
            if (state == 0) {
                return [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.3];
            } else {
                return [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.9];
            }
        } else {
            NSArray *layers = dict[@"layers"];
            NSDictionary *dict1 = layers[0];
            
            if ([dict1 objectForKey:@"state"]) {
                // Will have different tints for on/off
                NSDictionary *colours;
                if (state) {
                    colours = dict[@"layers-on"][0];
                } else {
                    colours = dict[@"layers-off"][0];
                }
                
                CGFloat opacity = [colours[@"opacity"] floatValue];
                NSString *hex = colours[@"color"];
                
                unsigned rgbValue = 0;
                NSScanner *scanner = [NSScanner scannerWithString:hex];
                [scanner setScanLocation:1]; // bypass '#' character
                [scanner scanHexInt:&rgbValue];
                return [UIColor colorWithRed:((rgbValue & 0xFF0000) >> 16)/255.0 green:((rgbValue & 0xFF00) >> 8)/255.0 blue:(rgbValue & 0xFF)/255.0 alpha:opacity];
            } else {
                // Assumed to not have tints.
                return nil;
            }
        }
    }*/
    
    CGFloat red = [[colorData objectForKey:@"red"] floatValue];
    CGFloat green = [[colorData objectForKey:@"green"] floatValue];
    CGFloat blue = [[colorData objectForKey:@"blue"] floatValue];
    CGFloat alpha = [[colorData objectForKey:@"alpha"] floatValue];
    
    UIColor *color = [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
    
    return color;
}

// Returns nil to signify a blurred BG.
+(UIImage*)backgroundForTogglesIsCircle:(BOOL)isCircle {
    if ([self isCurrentThemeLegacy]) {
        return nil;
    }
    
    // TODO: Quite frankly, I don't why the commented out code doesn't work.
    // It leads to Xen toggles having the usual unthemed blur, for whatever reason, even though the damn
    // logic works fine if you think it through. Wtf, Apple. Seriously.
    
    //if (isCircle) {
        if (!cachedToggleCircleBackground && !cachedHasNoToggleCircleBackground) {
            // Assume blurred BG unless an image is provided.
            cachedToggleCircleBackground = [XENResources themedImageWithName:(isCircle ? @"Toggles/TogglesBackgroundCircle" : @"Toggles/TogglesBackgroundSquared")];
            if (!cachedToggleCircleBackground) {
                cachedHasNoToggleCircleBackground = YES;
            }
        }
    
        return cachedToggleCircleBackground;
    /*} else {
        if (!cachedToggleSquareBackground && !cachedHasNoToggleSquareBackground) {
            // Assume blurred BG unless an image is provided.
            cachedToggleSquareBackground = [XENResources themedImageWithName:(isCircle ? @"Toggles/TogglesBackgroundCircle" : @"Toggles/TogglesBackgroundSquared")];
            if (!cachedToggleSquareBackground)
                cachedHasNoToggleSquareBackground = YES;
        }
        
        return cachedToggleSquareBackground;
    }*/
}

+(UIImage*)glyphForToggleWithName:(NSString*)name andState:(int)state {
    NSString *endName = [NSString stringWithFormat:@"Toggles/Glyphs/%@-%@", name, (state == 0 ? @"disabled" : @"enabled")];
    
    if (!cachedGlyphImages) {
        cachedGlyphImages = [NSMutableDictionary dictionary];
    }
    
    id output = [cachedGlyphImages objectForKey:endName];
    if (!output) {
        UIImage *img = [XENResources themedImageWithName:endName];
        
        if (!img) {
            [cachedGlyphImages setObject:[NSNumber numberWithBool:NO] forKey:endName];
            
            return nil;
        } else {
            [cachedGlyphImages setObject:img forKey:endName];
            
            return img;
        }
    } else if ([[output class] isSubclassOfClass:[UIImage class]]) {
        return output;
    } else {
        return nil;
    }
}

+(BOOL)togglesGlyphsAreFullColour {
    id value = currentThemeDict[@"togglesGlyphsAreFullColour"];
    return (value ? [value boolValue] : NO);
}

+(UIImage*)backgroundForTogglesAirStuff {
    if ([self isCurrentThemeLegacy]) {
        /*UIGraphicsBeginImageContextWithOptions(CGSizeMake(40, 55), NO, 0.0);
        UIImage *blank = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
            
        return [blank resizableImageWithCapInsets:UIEdgeInsetsMake(0, 10, 0, 10)];*/
        return nil;
    }
    
    // Assume blurred BG unless an image is provided.
    if (!cachedAirstuffBackground && !cachedHasNoAirstuffBackground) {
        cachedAirstuffBackground = [[XENResources themedImageWithName:@"Toggles/TogglesBackgroundAirStuff"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 10, 0, 10)];
        if (!cachedAirstuffBackground) cachedHasNoAirstuffBackground = YES;
    }
    
    return cachedAirstuffBackground;
}

+(BOOL)togglesTintWithWallpaper {
    id value = currentThemeDict[@"togglesTintWithWallpaper"];
    return (value ? [value boolValue] : YES);
}

#pragma mark Save new controller layout

+(void)saveNewControllerIdentifiersLayout:(NSArray*)identifiers {
    NSMutableDictionary *dict = [settings mutableCopy];
    
    [dict setObject:identifiers forKey:@"controllerIdentifiers"];
    
    CFPreferencesSetValue (CFSTR("controllerIdentifiers"), (__bridge CFPropertyListRef)identifiers, CFSTR("com.matchstic.xen"), kCFPreferencesCurrentUser, kCFPreferencesCurrentHost);
    [dict writeToFile:@"/var/mobile/Library/Preferences/com.matchstic.xen.plist" atomically:YES];
    
    [XENResources reloadSettings];
}

#pragma mark Notification icons caching

+(void)cacheNotificationForListItem:(SBAwayListItem*)listItem {
#warning TODO: Handle iOS 10.
    
    NSString *identifier = [self identifierForListItem:listItem];
    UIImage *icon = nil;
    
    if ([listItem isKindOfClass:objc_getClass("SBSnoozedAlarmListItem")] ||
        [listItem isKindOfClass:objc_getClass("SBSnoozedAlarmBulletinListItem")] ||
        [listItem isKindOfClass:objc_getClass("SBAwayBulletinListItem")]) {
        // Just return out of here, please!
        // Icon can be handled nicely without a cached copy.
        
        return;
    } else if ([listItem isKindOfClass:objc_getClass("SBAwayCardListItem")]) {
        icon = [(SBAwayCardListItem*)listItem iconImage];
    } else if ([listItem isKindOfClass:objc_getClass("SBAwaySystemAlertItem")]) {
        icon = [(SBAwaySystemAlertItem*)listItem iconImage];
    }
    
    // Handle the case where somehow an icon still hasn't been found yet
    if (!icon)
        icon = [[UIImage alloc] init];
    
    if (!cachedNotificationsIcons) {
        cachedNotificationsIcons = [NSMutableDictionary dictionary];
    }
    
    if (![cachedNotificationsIcons objectForKey:identifier])
        [cachedNotificationsIcons setObject:icon forKey:identifier];
}

+(UIImage*)cachedNotificationIconForIdentifier:(NSString*)identifier {
    return [cachedNotificationsIcons objectForKey:identifier];
}

#pragma mark Settings - General

+(BOOL)enabled {
    if (didEndGraceMode) return NO;
    else if (isEditMode) {
        return YES;
    }
    
    id value = settings[@"enabled"];
    return (value ? [value boolValue] : YES);
}

+(NSArray*)_enabledIdentifiersForPageArrangement:(BOOL)isArrangement {
    // Support transition to Apple pages on iOS versions.
    NSString *compatHomeId = [UIDevice currentDevice].systemVersion.floatValue < 10.0 ? @"com.matchstic.home" : @"com.apple.main";
    NSString *compatWidgetsId = [UIDevice currentDevice].systemVersion.floatValue < 10.0 ? @"com.matchstic.ncwidgets" : @"com.apple.today";
    
    NSMutableArray *array = [settings[@"controllerIdentifiers"] mutableCopy];
    if (!array) {
        NSString *defaultToggles = @"com.matchstic.toggles.iphone";
        if (IS_IPAD) defaultToggles = @"com.matchstic.toggles.ipad";
        if ([UIDevice currentDevice].systemVersion.floatValue >= 10.0) defaultToggles = @"com.matchstic.toggles.ios10";
        
        array = [@[defaultToggles, compatHomeId, @"com.matchstic.launchpad"] mutableCopy];
    } else {
        // First, convert existing settings to current iOS version if needed.
        
        if ([array containsObject:@"com.matchstic.home"])
            [array replaceObjectAtIndex:[array indexOfObject:@"com.matchstic.home"] withObject:compatHomeId];
        if ([array containsObject:@"com.matchstic.ncwidgets"])
            [array replaceObjectAtIndex:[array indexOfObject:@"com.matchstic.ncwidgets"] withObject:compatWidgetsId];
        
        BOOL hasOldToggles = [array containsObject:@"com.matchstic.toggles.iphone"] || [array containsObject:@"com.matchstic.toggles.ipad"];
        if (hasOldToggles && [UIDevice currentDevice].systemVersion.floatValue >= 10.0) {
            if ([array containsObject:@"com.matchstic.toggles.iphone"])
                [array replaceObjectAtIndex:[array indexOfObject:@"com.matchstic.toggles.iphone"] withObject:@"com.matchstic.toggles.ios10"];
            if ([array containsObject:@"com.matchstic.toggles.ipad"])
                [array replaceObjectAtIndex:[array indexOfObject:@"com.matchstic.toggles.ipad"] withObject:@"com.matchstic.toggles.ios10"];
        }
    }
    
    if ([XENResources useSlideToUnlockMode]) {
        switch ([XENResources slideToUnlockModeDirection]) {
            case 0:
                [array removeObject:compatHomeId];
                [array removeObject:@"com.matchstic.passcode"];
                [array insertObject:@"com.matchstic.passcode" atIndex:0];
                [array insertObject:compatHomeId atIndex:1];
                break;
            case 2:
                [array removeObject:compatHomeId];
                [array removeObject:@"com.matchstic.passcode"];
                [array addObject:compatHomeId];
                [array addObject:@"com.matchstic.passcode"];
                break;
                
            default:
                break;
        }
    }
    
    if (lockpagesControllers.count > 0) {
        NSMutableArray *left = [NSMutableArray array];
        NSMutableArray *right = [NSMutableArray array];
        
        if ([self slideToUnlockModeDirection] == 2) {
            for (int i = 0; i < [array indexOfObject:compatHomeId]; i++) {
                [left insertObject:[array objectAtIndex:i] atIndex:i];
            }
            
            [right addObjectsFromArray:@[compatHomeId, @"com.matchstic.passcode"]];
        } else if ([self slideToUnlockModeDirection] == 1) {
            // Slide up.
            for (int i = 0; i < [array indexOfObject:compatHomeId]; i++) {
                [left insertObject:[array objectAtIndex:i] atIndex:i];
            }
            
            // Home is inbetween the two.
            
            int j = 0;
            for (int i = (int)[array indexOfObject:compatHomeId] + 1; i < array.count; i++) {
                [right insertObject:[array objectAtIndex:i] atIndex:j];
                j++;
            }
        } else {
            // Sliding left.
            [left addObjectsFromArray:@[@"com.matchstic.passcode", compatHomeId]];
            
            int j = 0;
            for (int i = (int)[array indexOfObject:compatHomeId] + 1; i < array.count; i++) {
                [right insertObject:[array objectAtIndex:i] atIndex:j];
                j++;
            }
        }
        
        // Add lockpages stuff. To the right if upwards/slide towards left, left if slide right.
        // Treat any prexisting pages in that direction as priority 0.
        // If a view is hidden, then ignore it.
        for (XENLockPagesController *cont in lockpagesControllers) {
            LPPage *page = [cont LPPage];
            if (![array containsObject:[cont uniqueIdentifier]] && ![page view].hidden) {
                // We can add this in the default position.
                if ([self slideToUnlockModeDirection] == 2) {
                    [left insertObject:[cont uniqueIdentifier] atIndex:0];
                } else {
                    [right addObject:[cont uniqueIdentifier]];
                }
                // If the page is saved but is hidden, kill it.
            } else if ([left containsObject:[cont uniqueIdentifier]] && [page view].hidden) {
                [left removeObject:[cont uniqueIdentifier]];
            } else if ([right containsObject:[cont uniqueIdentifier]] && [page view].hidden) {
                [right removeObject:[cont uniqueIdentifier]];
            }
        }
        
        if ([self slideToUnlockModeDirection] != 1) {
            [left addObjectsFromArray:right];
            array = [left mutableCopy];
        } else {
            [left addObject:compatHomeId];
            [left addObjectsFromArray:right];
            array = [left mutableCopy];
        }
        
        // Handle is something is removed.
        for (NSString* iden in [array copy]) {
            if (![self controllerWithIdentifier:iden])
                [array removeObject:iden];
        }
    }
    
    // If we're on iOS 10, make sure to add the camera page if needed.
    if ([UIDevice currentDevice].systemVersion.floatValue >= 10.0 && [XENResources iOS10CameraEnabled]) {
        int position = [XENResources iOS10CameraPosition];
        
        NSString *identifier = @"com.apple.camera";
        if (position == 0) {
            [array insertObject:identifier atIndex:0];
        } else {
            [array addObject:identifier];
        }
    }
    
    // We now have all the enabled pages. However... If this is first boot, we need to provide locked pages instead.
    // Everything except passcode and home will be locked.
    
    if (![XENResources hasUnlockedSinceFirstBoot] && !isArrangement) {
        NSMutableArray *firstBootArray = [NSMutableArray arrayWithCapacity:array.count];
        
        for (NSString *string in array) {
            if (![string isEqualToString:compatHomeId] && ![string isEqualToString:@"com.matchstic.passcode"]) {
                [firstBootArray addObject:[@"firstboot." stringByAppendingString:string]];
            } else {
                [firstBootArray addObject:string];
            }
        }
        
        array = firstBootArray;
        
        [XENResources setupFirstBootControllerWithIdentifierArray:array];
    }
    
    return array;
}

+(NSArray*)enabledControllerIdentifiers {
    // TODO: If first boot, ONLY home is allowed.
    if (enabledIdentifiers) {
        return enabledIdentifiers;
    }
    
    return [XENResources _enabledIdentifiersForPageArrangement:NO];
}

+(void)setupFirstBootControllerWithIdentifierArray:(NSArray*)identifiers {
    if (!firstBootControllers) {
        firstBootControllers = [NSMutableArray array];
    }
    
    for (NSString *string in identifiers) {
        if ([string hasPrefix:@"firstboot"]) {
            // Create controller.
            XENFirstBootController *cont = [[XENFirstBootController alloc] init];
            
            NSString *displayedName = @"";
            NSString *tempString = [string stringByReplacingOccurrencesOfString:@"firstboot." withString:@""];
            
            displayedName = [[XENResources controllerWithIdentifier:tempString] name];
            
            [cont setActualIdentifier:string andDisplayedName:displayedName];
            
            [firstBootControllers addObject:cont];
        }
    }
}

+(void)reloadSettings {
    NSDictionary *oldSettings = settings;
    
    CFPreferencesAppSynchronize(CFSTR("com.matchstic.xen"));
    settings = nil;
    
    settings = (__bridge NSDictionary *)CFPreferencesCopyMultiple(CFPreferencesCopyKeyList(CFSTR("com.matchstic.xen"), kCFPreferencesCurrentUser, kCFPreferencesAnyHost), CFSTR("com.matchstic.xen"), kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
    if (!strings)
        strings = [NSBundle bundleWithPath:@"/Library/Application Support/Xen/Strings.bundle"];
    
    NSString *theme = (settings[@"lockTheme"] ? settings[@"lockTheme"] : @"BLUR");
    NSString *filepath = @"";
    if ([self isCurrentThemeLegacy]) {
        filepath = [NSString stringWithFormat:@"/Library/Application Support/Convergance/Themes/%@/Info.plist", theme];
    } else {
        filepath = [NSString stringWithFormat:@"/Library/Application Support/Xen/Themes/%@/Info.plist", theme];
    }
    
    currentThemeDict = [NSDictionary dictionaryWithContentsOfFile:filepath];
    
    for (XENBaseViewController *controller in availableControllers) {
        // Each controller should handle itself for reloading settings.
        [controller resetViewForSettingsChange:oldSettings :settings];
    }
    
    cachedHasNoToggleCircleBackground = NO;
    cachedToggleCircleBackground = nil;
    
    cachedHasNoToggleSquareBackground = NO;
    cachedToggleSquareBackground = nil;
    
    cachedAirstuffBackground = nil;
    cachedHasNoAirstuffBackground = NO;
    
    [cachedGlyphImages removeAllObjects];
    
    [cachedNotificationsIcons removeAllObjects];
}

+(void)didSortLockPages {
    //XENlog(@"DID SORT LOCK PAGES");
    
    // Reload LockPages
    lockpagesControllers = [NSMutableArray array];
    
    // Add all lockpages shizzle; make sure the damn things are sorted!
    for (id<LPPage> page in [[objc_getClass("LPPageController") sharedInstance] _xen_sortedPages]) {
        XENLockPagesController *cont = [[XENLockPagesController alloc] init];
        [cont setPage:page];
        
        [lockpagesControllers addObject:cont];
    }
    
    // INVALIDATE ENABLED.
    enabledIdentifiers = nil;
    
    XENlog(@"Invalidated enabled controllers due to LockPages");
}

+(void)readyResourcesForNewLock {
    //[availableControllers removeAllObjects];
    //availableControllers = nil;
    
    NSArray *enabled = [self enabledControllerIdentifiers];
    
    for (XENBaseViewController* controller in availableControllers) {
        if ([enabled containsObject:[controller uniqueIdentifier]]) {
            [controller.view removeFromSuperview];
            [controller resetViewForUnlock];
        }
    }
    
    if (lockpagesControllers)
    for (XENLockPagesController *controller in lockpagesControllers) {
        [controller.view removeFromSuperview];
        [controller resetViewForUnlock];
    }
    
    //[lockpagesControllers removeAllObjects];
    //lockpagesControllers = nil;
    
    if (firstBootControllers)
    for (XENFirstBootController *controller in firstBootControllers) {
        [controller.view removeFromSuperview];
        [controller resetViewForUnlock];
    }
    
    [firstBootControllers removeAllObjects];
    firstBootControllers = nil;
    
    [controllersToFadeOnHomeUp removeAllObjects];
    controllersToFadeOnHomeUp = nil;
    
    currentlyFullscreenNotificationApplicationIdentifier = @"";
    
    strings = nil;
    
    [dontCancelTouchesInTheseViews removeAllObjects];
    dontCancelTouchesInTheseViews = nil;
    
    [XENResources resetNotificationBundleIdentifiers];
    
    enabledIdentifiers = nil;
    
    XENlog(@"XENResources -- all resources are now readied for a new lock...");
    XENlog(@"Free memory: %d", [objc_getClass("IS2System") ramFree]);
    XENlog(@"Page containers:\nLockPagesConts: %@\nFirstBootConts: %@\nFadeUpConts: %@\nDontCancelViews: %@", lockpagesControllers, firstBootControllers, controllersToFadeOnHomeUp, dontCancelTouchesInTheseViews);
    
    NSMutableString *allControllers = [@"Pages:\n" mutableCopy];
    
    for (XENBaseViewController *controller in availableControllers) {
        [allControllers appendFormat:@"%@, size: %zd\n", [controller description], malloc_size((__bridge const void *)controller)];
    }
    
    XENlog(allControllers);
    
    allControllers = nil;
    
    cachedHasNoToggleCircleBackground = NO;
    cachedToggleCircleBackground = nil;
    
    cachedHasNoToggleSquareBackground = NO;
    cachedToggleSquareBackground = nil;
    
    cachedAirstuffBackground = nil;
    cachedHasNoAirstuffBackground = NO;
    
    [cachedGlyphImages removeAllObjects];
}

+(void)resetNotificationBundleIdentifiers {
    [notificationBundleIdentifiers removeAllObjects];
    notificationBundleIdentifiers = nil;
    
    [notificationBundleIdentifiersWithCount removeAllObjects];
    notificationBundleIdentifiers = nil;
}

+(void)setLoadingInAsEditMode:(BOOL)arg1 {
    isEditMode = arg1;
}

+(BOOL)isLoadedInEditMode; {
    return isEditMode;
}

+(BOOL)isLoadedEditFromSetup {
    return editFromSetup;
}
+(void)setIsLoadedEditFromSetup:(BOOL)arg1 {
    editFromSetup = arg1;
}

+(BOOL)debugLogging {
    id value = settings[@"debugLogging"];
    return (value ? [value boolValue] : YES);
}

+(BOOL)hasUnlockedSinceFirstBoot {
    if ([[UIApplication sharedApplication] respondsToSelector:@selector(authenticationController)]) {
        SBFUserAuthenticationController *auth = [(SpringBoard*)[UIApplication sharedApplication] authenticationController];
        return [auth hasAuthenticatedAtLeastOnceSinceBoot];
    } else {
        return [[NSFileManager defaultManager] fileExistsAtPath:@"/tmp/com.matchstic.xen.reboot_flag"];
    }
}

+(BOOL)isCurrentlyLocked {
    return lsViewController != nil;
}

+(BOOL)hasDisplayedSetupUI {
    id value = settings[@"hasDisplayedSetupUI"];
    return (value ? [value boolValue] : NO);
}

#pragma mark Settings - Home

// TODO: Implement Slide to Unlock mode (for notifications).
+(BOOL)useSlideToUnlockMode {
    int direction = [XENResources slideToUnlockModeDirection];
    return direction == 0 || direction == 2;
}

+(int)slideToUnlockModeDirection {
    int defaultVal = [UIDevice currentDevice].systemVersion.floatValue < 10.0 ? 0 : 3;
    
    id value = settings[@"slideToUnlockModeDirection"];
    return (value ? [value intValue] : defaultVal);
}

+(BOOL)hideSlideIndicators {
    id value = settings[@"hideSlideIndicators"];
    return (value ? [value boolValue] : YES);
}

+(BOOL)hideClock {
    id value = settings[@"hideClock"];
    return (value ? [value boolValue] : NO);
}

+(BOOL)hideNCGrabber {
    id value = settings[@"hideNCGrabber"];
    return (value ? [value boolValue] : NO);
}

+(BOOL)hideCCGrabber {
    id value = settings[@"hideCCGrabber"];
    return (value ? [value boolValue] : NO);
}

+(BOOL)hidePageControlDots {
    id value = settings[@"hidePageControlDots"];
    return (value ? [value boolValue] : NO);
}

#pragma mark Settings - Welcome

+(BOOL)useWelcomeController {
    id value = settings[@"welcomeController"];
    return (value ? [value boolValue] : YES);
}

+(BOOL)welcomeUseVibrantFont {
    id value = settings[@"welcomeUseVibrantFont"];
    return (value ? [value boolValue] : YES);
}

+(int)welcomeAdjustedTimeForFire {
    // Return int that is hour-1 of the user's chosen time.
    NSDate *value = settings[@"welcomeWakeupTime"];
    
    if (!value) {
        // Running off 6am.
        return 5;
    }
    
    NSCalendar *gregorian = [NSCalendar currentCalendar];
    NSDateComponents *todayComponents = [gregorian components:(NSCalendarUnitMinute | NSCalendarUnitHour) fromDate:value];
    int nonAdjusted = (int)[todayComponents hour];
    //NSInteger theMinute = [todayComponents minute];
    
    if (nonAdjusted == 0) {
        return 23;
    } else {
        return nonAdjusted - 1;
    }
}

#pragma mark Settings - Media Artwork

+(int)mediaArtworkStyle {
    id value = settings[@"mediaStyle"];
    return (value ? [value intValue] : 1);
}

#pragma mark Settings - Notifications

+(BOOL)useXENNotificationUI {
    if ([self usingWatchNotificationsCompatibilityMode]) return NO;
    
    id value = settings[@"useXENNotificationUI"];
    return (value ? [value boolValue] : NO);
}

+(BOOL)useGroupedNotifications {
    if ([XENResources usingPriorityHubCompatiblityMode]) {
        return YES;
    }
    
    // DEBUG: If running iOS 10, no grouping allowed until we get it working.
    if ([UIDevice currentDevice].systemVersion.floatValue >= 10) {
        return NO;
    }
    
    id value = settings[@"useGroupedNotifications"];
    return (value ? [value boolValue] : NO);
}

+(BOOL)_noPH_useGroupedNotifications {
    // DEBUG: If running iOS 10, no grouping allowed until we get it working.
    if ([UIDevice currentDevice].systemVersion.floatValue >= 10) {
        return NO;
    }
    
    id value = settings[@"useGroupedNotifications"];
    return (value ? [value boolValue] : NO);
}

+(BOOL)isPriorityHubInstalledAndEnabled {
    if ([[NSFileManager defaultManager] fileExistsAtPath:@"/Library/MobileSubstrate/DynamicLibraries/PriorityHub.dylib"]) {
        if (!PHDefaults) {
            PHDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"com.thomasfinch.priorityhub"];
        }
        
        return [PHDefaults boolForKey:@"enabled"];
    } else {
        return NO;
    }
}

+(BOOL)usingPriorityHubCompatiblityMode {
    return [XENResources isPriorityHubInstalledAndEnabled];
    
    id value = settings[@"usePriorityHubMode"];
    return (value ? [value boolValue] : NO);
}

+(BOOL)usingWatchNotificationsCompatibilityMode {
    if ([[NSFileManager defaultManager] fileExistsAtPath:@"/Library/MobileSubstrate/DynamicLibraries/WatchNotifications.dylib"]) {
        if (!WNDefaults) {
            WNDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"me.thomasfinch.watchnotifications"];
        }
        
        return [WNDefaults boolForKey:@"enabled"];
    } else {
        return NO;
    }
    
    return NO;
}

+(int)notificationCellsPerRow {
    id value = settings[@"notificationCellsPerRow"];
    return (value ? [value intValue] : (IS_IPAD ? 4 : 3));
}

+(BOOL)autoExpandNotifications {
#if TARGET_IPHONE_SIMULATOR==1
    return NO;
#else
    if (![XENResources useGroupedNotifications])
        return NO;
    
    id value = settings[@"autoExpandNotifications"];
    return (value ? [value boolValue] : YES);
#endif
}

+(BOOL)blurBehindNotifications {
    if (![self useGroupedNotifications] && ![self useXENNotificationUI]) {
        return YES;
    }
    
    id value = settings[@"blurBehindNotifications"];
    return (value ? [value boolValue] : NO);
}

#pragma mark Settings - Launchpad

+(BOOL)requirePasscodeForLaunchpad {
    if (!passcodeLocked) {
        return NO;
    }
    
    // Currently broken on 10.
    if ([UIDevice currentDevice].systemVersion.floatValue >= 10) {
        return NO;
    }
    
    id value = settings[@"launchpadRequiresPasscode"];
    return (value ? [value boolValue] : NO);
}

+(NSArray*)enabledLaunchpadIdentifiers {
    id array = settings[@"launchpadIdentifiers"];
    return (array ? array : @[@"com.apple.MobileSMS", @"com.apple.Preferences", @"com.apple.calculator", @"com.apple.camera", @"com.apple.Maps"]);
}

+(CGFloat)launchpadIconSize {
    id temp = settings[@"launchpadIconSize"];
    return (temp ? [temp floatValue] : 1.0);
}

+(BOOL)launchpadIconsOnly {
    id value = settings[@"launchpadIconsOnly"];
    return (value ? [value boolValue] : NO);
}

+(BOOL)launchpadUseQuickDial {
    NSString *deviceType = [UIDevice currentDevice].model;
    
    // Only iPhone can define favourite contacts.
    if (![deviceType isEqualToString:@"iPhone"]){
        return NO;
    }
    
    // Temporarily disable the quick dialler on iOS 10 until we write our own UI for it.
    if ([UIDevice currentDevice].systemVersion.floatValue >= 10) {
        return NO;
    }
    
    id value = settings[@"launchpadUseQuickDial"];
    return (value ? [value boolValue] : YES);
}

#pragma mark Settings - Peek

+(BOOL)peekEnabled {
    if (![XENResources deviceSupportsPeek]) {
        return NO;
    }
    
    id value = settings[@"peekEnabled"];
    return (value ? [value boolValue] : NO);
}

+(CGFloat)peekSensitivity {
    id temp = settings[@"peekSensitivity"];
    int state = (temp ? [temp intValue] : 2);
    
    // 4 - Very Low
    // 3 - Low
    // 2 - Normal
    // 1 - High
    // 0 - Very High
    
    return state;
}

+(BOOL)peekShowDarkUI {
    id value = settings[@"peekShowDarkUI"];
    return (value ? [value boolValue] : YES);
}

+(BOOL)peekShowStatusBar {
    id value = settings[@"peekShowStatusBar"];
    return (value ? [value boolValue] : YES);
}

+(BOOL)peekShowNotifications {
    id value = settings[@"peekShowNotifications"];
    return (value ? [value boolValue] : YES);
}

+(int)peekMode {
    return ([XENResources peekIntervalDuration] == 0 ? 0 : 1);
    
    id value = settings[@"peekMode"];
    return (value ? [value intValue] : 1);
}

+(BOOL)deviceSupportsPeek {
    // Get hardware verison.
    size_t buflen = 0x80;
    char buf[buflen];
    
    sysctlbyname("hw.machine", buf, &buflen, NULL, 0);
    
    NSString *machineType = [NSString stringWithUTF8String:(buf ? buf : "")];
    
    if ([machineType rangeOfString:@"iPhone"].location != NSNotFound) {
        return YES;
    } else {
        return NO;
    }
}

/**
 @return Interval in minutes
 */
+(CGFloat)peekIntervalDuration {
    id value = settings[@"peekIntervalDuration"];
    return (value ? [value intValue] : 10.0);
}

#pragma mark Settings - Toggles

+(NSArray*)enabledStatisticsPanels {
    id array = settings[@"togglesStatsPanels"];
    return (array ? array : @[@"kCPU",
                              @"kRAM",
                              @"kStorage",
                              @"kUpload",
                              @"kDownload"]);
}

+(BOOL)shouldProvideCC {
    id value = settings[@"shouldProvideCC"];
    return (value ? [value boolValue] : YES);
}

#pragma mark Settings - Weather

// TODO: Put into settings.
+(BOOL)weatherShowAnimatedWallpaper {
    if (IS_IPAD || SCREEN_MAX_LENGTH < 568) // No iPad or 4S.
        return NO;
    
    id value = settings[@"weatherAnimatedWallpaper"];
    return (value ? [value boolValue] : YES);
}

+(int)weatherUpdateInterval {
    id value = settings[@"weatherUpdateInterval"];
    return (value ? [value intValue] : 30);
}

#pragma mark Settings - Calendar

+(BOOL)calendarShowColours {
    id value = settings[@"showCalendarColours"];
    return (value ? [value boolValue] : YES);
}

+(int)calendarDaysInAdvance {
    id value = settings[@"calendarDaysInAdvance"];
    return (value ? [value intValue] : 5);
}

+(int)calendarMode {
    id value = settings[@"calendarMode"];
    return (value ? [value intValue] : 2);
    
    // 0 - Per Day, 1 - Agenda only, 2 - Combined
}

// This is ONLY used on iPhone.
+(int)calendarDefaultPage {
    id value = settings[@"calendarDefaultPage"];
    return (value ? [value intValue] : 1);
    
    // 0 - Per Day, 1 - Agenda
}

#pragma mark Settings - NC Widgets

#warning Support iOS 10.
+(BOOL)widgetsAlternateColoursMode {
    id value = settings[@"widgetsAlternateColoursMode"];
    return (value ? [value boolValue] : NO);
}

#pragma mark Settings - iOS 10 Camera

+(BOOL)iOS10CameraEnabled {
    if (![objc_getClass("SBDashBoardCameraPageViewController") isAvailableForConfiguration]) {
        return NO;
    }
    
    // TODO: We need to correctly handle with the Camera page is disabled by the user somehow.
    if (![XENResources enabled]) {
        return YES;
    }
    
#if TARGET_IPHONE_SIMULATOR==1
    return NO;
#else
    id value = settings[@"iOS10CameraEnabled"];
    return (value ? [value boolValue] : YES);
#endif
}

+(int)iOS10CameraPosition {
    // 0 - far left, 1 - far right
    if ([XENResources useSlideToUnlockMode]) {
        // Handle appropriately.
        return [XENResources slideToUnlockModeDirection] == 0 ? 1 : 0;
    } else {
        id value = settings[@"iOS10CameraPosition"];
        return (value ? [value intValue] : 1);
    }
}

#pragma mark Settings - Advanced

+(double)lockScreenIdleTime {
    id temp = settings[@"lockScreenIdleTime"];
    return (temp ? [temp doubleValue] : 10.0);
}

// Not needed on iOS 10!
+(BOOL)hideCameraGrabber {
    id value = settings[@"hideCameraGrabber"];
    return (value ? [value boolValue] : YES);
}

+(BOOL)blurredBackground {
    if (UIAccessibilityIsReduceTransparencyEnabled()) {
        return NO;
    }
    
    id value = settings[@"useBlurredBackground"];
    return (value ? [value boolValue] : YES);
}

+(BOOL)blurredPasscodeBackground {
    id value = settings[@"useBlurredPasscodeBackground"];
    return (value ? [value boolValue] : YES);
}

@end
