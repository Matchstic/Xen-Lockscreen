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

#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <UIKit/UIKit.h>
#include <time.h>

#define orient3 [XENResources getCurrentOrientation]

#define SCREEN_MAX_LENGTH (MAX([UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height))
#define SCREEN_MIN_LENGTH (MIN([UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height))

#define SCREEN_HEIGHT (orient3 == 1 || orient3 == 2 ? SCREEN_MAX_LENGTH : SCREEN_MIN_LENGTH)
#define SCREEN_WIDTH (orient3 == 1 || orient3 == 2 ? SCREEN_MIN_LENGTH : SCREEN_MAX_LENGTH)

#define IS_IPAD (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)

#define NOTIFICATION_ICON_SIZE (IS_IPAD ? 45 : 32)
#define NOTIFICATION_COUNT_WIDTH (IS_IPAD ? 47 : 33)
#define NOTIFICATION_UI_SPACING 8
#define NOTIFICATION_CELL_WIDTH (NOTIFICATION_ICON_SIZE + NOTIFICATION_UI_SPACING + NOTIFICATION_COUNT_WIDTH + 5)
#define NOTIFICATION_CLOCK_MOVE_Y (SCREEN_HEIGHT * 0.05)
#define NOTIFICATION_CHARGING_MOVE_Y (SCREEN_HEIGHT * 0.035)
#define NOTIFICATION_CLOCK_MOVE_NO_GROUP (SCREEN_HEIGHT * 0.1)

#define TOP_CELL_MULTIPLIER 0.45
#define BOTTOM_CELL_MULTIPLIER 0.25

// Update at 20Hz.
#define ACCEL_UPDATE_INTERVAL (0.05)

static BOOL didEndGraceMode = NO;
static BOOL shownGraceEnded = NO;

@interface XENResources : NSObject

#pragma mark System functions

#if defined __cplusplus
extern "C" {
#endif
    
void XLog(const char *file, int lineNumber, const char *functionName, NSString *format, ...);
    
#if defined __cplusplus
};
#endif

+(void)printViewHierarchyOfView:(id)view;
+(NSMutableArray*)allSubviewsForView:(UIView*)view;
+ (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize;
+(BOOL)isViewOnXen:(UIView*)view;
+(BOOL)setLockscreenView:(id)view;
+(UIWindow*)contentEditWindow;
+(void)hideContentEditWindow;
+(void)cacheArrangementController:(id)controller;
+(void)moveUpDownWallpaperWindow:(BOOL)moveToOrigLocation;
+(void)moveUpDownWallpaperWindowForSetup:(BOOL)moveToOrigLocation;
+(UIWindow*)wallpapeWindow;
+(CGSize)getSizeForText:(NSString *)text maxWidth:(CGFloat)width font:(NSString *)fontName fontSize:(float)fontSize;
+(CGRect)boundedRectForFont:(UIFont*)font andText:(NSString*)text width:(CGFloat)width;
//+(BOOL)isCurrentDeviceOld;
+(id)iconImageViewForBundleIdentifier:(NSString*)bundleIdentifier;
+(void)setCurrentOrientation:(int)orient;
+(int)getCurrentOrientation;
+(void)setScreenOnState:(BOOL)isOn;
+(BOOL)getScreenOnState;
+(void)turnOnDisplay;

+(void)setPasscodeFirstResponder:(BOOL)become;
+(void)_showPasscode;

+(void)setShouldOverrideNextURLLaunch:(BOOL)val;
+(BOOL)shouldOverrideNextURLLaunch;
+(void)openURLWithPasscodeIfNeeded:(NSURL*)url;

+(NSDateFormatter*)sharedDateFormatter;

+(BOOL)unlockedOnceSinceBoot;
+(void)setUnlockedSinceBoot:(BOOL)unlocked;

#pragma mark Private APIs

+(void)resetLockscreenDimTimer;
+(void)cancelLockscreenDimTimer;
+(BOOL)attemptToUnlockDeviceWithoutPasscode;
+(BOOL)shouldUseDarkColouration;
+(void)updateLockscreenBlurPercentage:(CGFloat)percent withPasscodeView:(id)view;
+(UIColor*)effectiveLegibilityColor;
+(void)setGrabbersFade:(CGFloat)alpha;

+(void)setTogglesConfiguring:(BOOL)arg1;
+(BOOL)isTogglesConfiguring;
  
+(id)lsViewController;
+(void)setLsViewController:(id)controller;

+(void)setLockscreenActionContext:(id)context;

+(void)setPreferenceKey:(NSString*)key withValue:(id)value andPost:(BOOL)post;

+(NSString*)imageSuffix;

+(void)setIsPasscodeLocked:(BOOL)isLocked;
+(BOOL)isPasscodeLocked;
+(void)setSlideUpPasscodeVisible:(BOOL)visible;
+(BOOL)isSlideUpPasscodeVisible;

+(BOOL)isNoctisInstalled;
+(BOOL)isNoctisEnabled;

+(CGFloat)calculateAdditionalOffsetForDateView:(id)_dateView withCurrentOffset:(CGFloat)offset;

#pragma mark Handling of wallpaper blur view

+(UIView*)wallpaperBlurView;
+(void)setWallpaperBlurView:(id)blur;
+(void)setWallpaperBlurPercentage:(CGFloat)percent withDuration:(CGFloat)duration;
+(void)setFakeSBStatusBarAlphaIfNecessary:(CGFloat)alpha withDuration:(CGFloat)duration;

#pragma mark Stuff in setup

+(BOOL)isPageEditInSetup;
+(void)setIsPageEditInSetup:(BOOL)val;

#pragma mark Handle storing and retrieving data on fullscreen application for notifications

+(void)setCurrentlyShownNotificationAppIdentifier:(NSString*)bundleIdentifier;
+(NSString*)currentlyShownNotificationAppIdentifier;
+(NSArray*)allNotificationBundleIdentifiers;
/// @return YES if added as new application group
+(NSString*)identifierForListItem:(id)listItem;
+(BOOL)addNotificationBundleIdentifier:(NSString*)identifier;
/// @return Index of group to remove if necessary, else -1
+(int)removeNotificationBundleIdentifier:(NSString*)identifier;
+(UIView*)notificationListView;
+(void)setNotificationListView:(UIView*)listView;
+(void)reloadNotificationListView;
+(void)reloadNotificationListViewSeparators;
+(int)countOfNotificationsForBundleIdentifier:(NSString*)bundleIdentifier;

#pragma mark Methods for controllers

+(void)registerControllerForFadeOnHomeArrowUp:(UIViewController*)controller;
+(void)applyFadeToControllers:(CGFloat)alpha;
+(void)clearFadeOnHomeArrowUp;
+(void)clearDontTouchViews;
+(NSArray*)availableViewControllers;
+(id)controllerWithIdentifier:(NSString*)identifier;
+(void)relayourLockPagesControllers;
+(void)didSortLockPages;

#pragma mark Scroll view touch canceling shizzle

+(void)preventScrollViewCancelling:(UIView*)view;
+(NSSet*)dontCancelTouchesInTheseViews;

+(BOOL)canWidgetsLaunchURL;

#pragma mark Resource loading

+(NSString*)themedResourceFilePathWithName:(NSString*)name andExtension:(NSString*)ext;
+(UIImage*)themedImageWithName:(NSString*)imageName;
+(NSString*)localisedStringForKey:(NSString*)key value:(NSString*)val;
+(NSString*)tapToOpenTextForBundleIdentifier:(NSString*)bundleIdentifier;
+(UIColor*)textColour;

// Toggles theming
+(UIColor*)togglesGlyphTintForState:(int)state isCircle:(BOOL)isCircle;
+(UIImage*)backgroundForTogglesIsCircle:(BOOL)isCircle;
+(UIImage*)glyphForToggleWithName:(NSString*)name andState:(int)state;
+(BOOL)togglesTintWithWallpaper;
+(BOOL)togglesGlyphsAreFullColour;
+(UIImage*)backgroundForTogglesAirStuff;

#pragma mark Save new controller layout

+(void)saveNewControllerIdentifiersLayout:(NSArray*)identifiers;

#pragma mark Notification icon caching

+(void)cacheNotificationForListItem:(id)listItem;

#pragma mark Settings - General

+(BOOL)enabled;
+(NSArray*)enabledControllerIdentifiers;
+(NSArray*)_enabledIdentifiersForPageArrangement:(BOOL)isArrangement;
+(void)reloadSettings;
+(void)readyResourcesForNewLock;
+(void)resetNotificationBundleIdentifiers;
+(void)setLoadingInAsEditMode:(BOOL)arg1;
+(BOOL)isLoadedInEditMode;
+(BOOL)isLoadedEditFromSetup;
+(void)setIsLoadedEditFromSetup:(BOOL)arg1;
+(BOOL)hideClock;
+(BOOL)hideNCGrabber;
+(BOOL)hideCCGrabber;
+(BOOL)hidePageControlDots;

+(BOOL)hasUnlockedSinceFirstBoot;
+(BOOL)isCurrentlyLocked;

+(BOOL)hasDisplayedSetupUI;

#pragma mark Settings - Home

+(BOOL)useSlideToUnlockMode;
+(int)slideToUnlockModeDirection;
+(BOOL)hideSlideIndicators;

#pragma mark Settings - Welcome 

+(BOOL)useWelcomeController;
+(int)welcomeAdjustedTimeForFire;

#pragma mark Settings - Media Artwork

+(int)mediaArtworkStyle;

#pragma mark Settings - Notifications

+(BOOL)useXENNotificationUI;
+(BOOL)useGroupedNotifications;
+(BOOL)_noPH_useGroupedNotifications;
+(BOOL)usingPriorityHubCompatiblityMode;
+(BOOL)isPriorityHubInstalledAndEnabled;
+(int)notificationCellsPerRow;
+(BOOL)autoExpandNotifications;
+(BOOL)blurBehindNotifications;
+(BOOL)usingWatchNotificationsCompatibilityMode;

#pragma mark Settings - Launchpad

+(NSArray*)enabledLaunchpadIdentifiers;
+(BOOL)requirePasscodeForLaunchpad;
+(CGFloat)launchpadIconSize;
+(BOOL)launchpadIconsOnly;
+(BOOL)launchpadUseQuickDial;

#pragma mark Settings - Toggles

+(NSArray*)enabledStatisticsPanels;
+(BOOL)shouldProvideCC;

#pragma mark Settings - Peek

+(BOOL)peekEnabled;
+(CGFloat)peekSensitivity;
+(BOOL)peekShowStatusBar;
+(BOOL)peekShowNotifications;
+(BOOL)peekShowDarkUI;
+(int)peekMode;
+(CGFloat)peekIntervalDuration;
+(BOOL)deviceSupportsPeek;

#pragma mark Settings - Weather

+(BOOL)weatherShowAnimatedWallpaper;
+(int)weatherUpdateInterval;

#pragma mark Settings - Calendar

+(BOOL)calendarShowColours;
+(int)calendarDaysInAdvance;
+(int)calendarMode;
+(int)calendarDefaultPage;

#pragma mark Settings - NC Widgets

+(BOOL)widgetsAlternateColoursMode;

#pragma mark Settings - iOS 10 Camera

+(BOOL)iOS10CameraEnabled;
+(int)iOS10CameraPosition;

#pragma mark Settings - Advanced

+(double)lockScreenIdleTime;
+(BOOL)hideCameraGrabber;
+(BOOL)blurredBackground;
+(BOOL)blurredPasscodeBackground;

@end
