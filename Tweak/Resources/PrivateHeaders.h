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
#import "XENBlurBackedImageProvider.h"
#import <UIKit/UIKit.h>

#define XENlog(args...) XLog(__FILE__,__LINE__,__PRETTY_FUNCTION__,args);

@protocol SBUIPasscodeLockView <NSObject>
@property (nonatomic,readonly) int style;
@property (nonatomic,readonly) NSString *passcode;
@property (assign,nonatomic) unsigned long long biometricMatchMode;
@required
-(void)setDelegate:(id)arg1;
-(int)style;
-(void)reset;
-(void)setBackgroundAlpha:(double)arg1;
-(void)setBackgroundLegibilitySettingsProvider:(id)arg1;
-(NSString *)passcode;
-(void)resetForFailedPasscode;
-(unsigned long long)biometricMatchMode;
-(void)resetForScreenOff;
-(void)resetForFailedMesaAttemptWithStatusText:(id)arg1 andSubtitle:(id)arg2;
-(void)autofillForSuccessfulMesaAttemptWithCompletion:(/*^block*/id)arg1;
-(BOOL)playsKeypadSounds;
-(BOOL)showsStatusField;
-(BOOL)showsEmergencyCallButton;
-(double)backgroundAlpha;
-(void)setBiometricMatchMode:(unsigned long long)arg1;
@end

@interface SBDashBoardViewController : UIViewController
- (id)dashBoardView;
- (void)invalidateLockScreenActionContext;
- (unsigned long long)_indexOfMainPage;
@property(nonatomic) unsigned long long lastSettledPageIndex;
- (void)activatePage:(unsigned long long)arg1 animated:(_Bool)arg2 withCompletion:(id)arg3;
@property(readonly, nonatomic) id notificationDestination;
@property(copy, nonatomic) NSArray *pageViewControllers;
-(id)_xen_fetchWithIdentifier:(NSString*)identifier andArray:(NSArray*)array;
@end

@interface SBDashBoardAppearance : NSObject
- (void)addComponent:(id)arg1;
- (void)unionAppearance:(id)arg1;
@property(copy, nonatomic) NSSet *components;
@end

@interface SBDashBoardBehavior : NSObject
+ (id)behaviorForProvider:(id)arg1;
+ (id)behavior;
@property(nonatomic) unsigned int restrictedCapabilities;
@property(nonatomic) int notificationBehavior;
@property(nonatomic) long long scrollingStrategy;
@property(nonatomic) int scrollingMode; // Gone in 10.1...
@property(nonatomic) int idleWarnMode;
@property(nonatomic) int idleTimerMode;
@property(nonatomic) int idleTimerDuration;

@end

@interface SBDashBoardRegion : NSObject
+ (id)regionForCoordinateSpace:(id)arg1 withExtent:(CGRect)arg2;
@property(nonatomic) __weak id provider;
@property(nonatomic) __weak id identity;
@property(nonatomic) long long role;
@end

@interface SBDashBoardComponent : NSObject
+ (id)tinting;
+ (id)wallpaper;
+ (id)slideableContent;
+ (id)pageContent;
+ (id)pageControl;
+ (id)statusBar;
+ (id)dateView;
@property(nonatomic) CGPoint offset;
@property(nonatomic) long long type;
@property(nonatomic) double alpha; // @synthesize alpha=_alpha;
- (id)offset:(CGPoint)arg1;
- (id)legibilitySettings:(id)arg1;
- (id)view:(id)arg1;
- (id)value:(id)arg1;
- (id)string:(id)arg1;
- (id)flag:(long long)arg1;
- (id)hidden:(_Bool)arg1;
- (id)identifier:(id)arg1;
- (id)priority:(long long)arg1;
@end

@interface SBDashBoardPageViewController : UIViewController
@property(readonly, copy, nonatomic) SBDashBoardAppearance *activeAppearance;
//@property(readonly, copy, nonatomic) SBDashBoardBehavior *activeBehavior;
@property(readonly, copy, nonatomic) NSString *appearanceIdentifier;
@property(readonly, nonatomic) UIColor *backgroundColor;
@property(readonly, nonatomic) long long backgroundStyle;
@property(readonly, copy, nonatomic) NSString *dashBoardIdentifier;
@property(readonly, nonatomic) long long idleTimerDuration;
@property(readonly, nonatomic) long long presentationStyle;
@property(readonly, nonatomic) long long presentationTransition;
@property(readonly, nonatomic) long long presentationType;
@property(readonly, nonatomic) long long scrollingStrategy;

+ (unsigned long long)requiredCapabilities;
+ (_Bool)isAvailableForConfiguration;

-(NSString*)_xen_identifier;
-(NSString*)_xen_name;
@end

@interface SBDashBoardTodayPageViewController : SBDashBoardPageViewController
@end
@interface SBDashBoardCameraPageViewController : SBDashBoardPageViewController
@end
@interface SBDashBoardMainPageViewController : SBDashBoardPageViewController
@end

@interface SBDashBoardPageViewBase : UIView
@property(nonatomic) __weak SBDashBoardPageViewController *pageViewController;
@end

@interface UIImage (Private)
- (id)_flatImageWithColor:(id)arg1;
@end

@interface _UILegibilityView : UIView
@property (nonatomic, retain) UIImageView *imageView;
- (void)setImage:(id)arg1 shadowImage:(id)arg2;
@end

@interface SBDashBoardPageControl : UIPageControl
- (id)_currentPageIndicatorColor;
- (id)_pageIndicatorColor;
- (id)_cameraIndicatorImage:(_Bool)arg1;
- (id)_pageIndicatorImage:(_Bool)arg1;
- (id)_xen_unlockIndicatorImage:(BOOL)arg1;
@end

@interface SBLockScreenNotificationListController : NSObject
@property(retain, nonatomic) id lockScreenActionContext;
-(NSArray*)_xen_listItems;
@end

@interface SBAlertView : UIView
@end

@interface SBAlertWindow : UIWindow {
    UIViewController *_alertWindowController;
}
@end

@interface SBLockScreenView : SBAlertView
-(void)_updateBlurAndPasscodeView:(id)view forPercentScrolled:(CGFloat)percentScrolled;
- (void)_setCurrentBlurRadius:(CGFloat)radius;
-(id)_averageWallpaperColorForFrame:(CGRect)frame;
- (id)_effectiveStatusBarColor;
@property(readonly, retain, nonatomic) UIScrollView *scrollView;
@end

@interface SBLockScreenScrollView : UIScrollView {
    id<SBUIPasscodeLockView> _passcodeView;
    SBLockScreenView* _lockScreenView;
}
@property(assign, nonatomic) SBLockScreenView *lockScreenView;
@property(assign, nonatomic) id<SBUIPasscodeLockView> passcodeView;
-(void)setUserInteractionEnabled:(BOOL)enabled;
-(BOOL)gestureRecognizer:(id)recognizer shouldReceiveTouch:(id)touch;
-(BOOL)touchesShouldCancelInContentView:(id)touches;
@end

@interface SBUIPasscodeLockViewBase : UIView
@property double backgroundAlpha;
@property unsigned long long biometricMatchMode;
@property UIColor * customBackgroundColor;
@property /*<SBUIPasscodeLockViewDelegate> */ id delegate;
@property unsigned long long statusState;
@property int style;
- (void)_evaluateLuminance;
- (void)_clearBrightnessChangeTimer;
- (bool)_isBoundsPortraitOriented;
- (void)_noteScreenBrightnessDidChange;
- (void)_noteDeviceHasBeenUnlockedOnceSinceBoot:(bool)arg1;
- (long long)_orientation;
- (void)_resetForFailedMesaAttempt;
- (void)_resetForFailedPasscode:(bool)arg1;
- (void)_resetStatusText;
- (void)_setStatusSubtitleText:(id)arg1;
- (void)_setStatusText:(id)arg1;
- (double)backgroundAlpha;
- (id)delegate;
- (id)initWithFrame:(CGRect)arg1;
- (id)passcode;
- (bool)playsKeypadSounds;
- (void)reset;
- (void)resetForFailedMesaAttemptWithStatusText:(id)arg1 andSubtitle:(id)arg2;
- (void)resetForFailedPasscode;
- (void)resetForScreenOff;
- (void)setCustomBackgroundColor:(UIColor*)arg1; // iOS 10.
- (void)setBackgroundAlpha:(double)arg1;
- (void)setScreenOn:(bool)arg1;
- (void)setPlaysKeypadSounds:(bool)arg1;
- (void)setShowsEmergencyCallButton:(bool)arg1;
- (void)setShouldResetForFailedPasscodeAttempt:(bool)arg1;
- (bool)shouldResetForFailedPasscodeAttempt;
- (bool)showsEmergencyCallButton;
- (bool)showsStatusField;
- (BOOL)_xen_deviceUnlockedOnceSinceBoot;

-(void)_xen_layoutForHidingViews;
@end

@interface SBUIPasscodeLockViewWithKeyboard : SBUIPasscodeLockViewBase
@end

@interface SBUIPasscodeLockViewWithKeypad : SBUIPasscodeLockViewBase
@end

@interface SBLockScreenManager : NSObject
+(instancetype)sharedInstance;
-(void)enableLostModePlugin;
-(BOOL)isInLostMode;
-(BOOL)attemptUnlockWithPasscode:(id)passcode;
-(void)startUIUnlockFromSource:(int)source withOptions:(id)options;
-(void)unlockUIFromSource:(int)source withOptions:(id)options;
- (void)setBioUnlockingDisabled:(BOOL)disabled forRequester:(id)requester;
- (void)setBiometricAutoUnlockingDisabled:(_Bool)arg1 forReason:(id)arg2;
@end

@interface SBFUserAuthenticationController : NSObject
+ (bool)_isInBioUnlockState;
+ (bool)_isInGracePeriodState;
- (bool)isAuthenticated;
- (void)notePasscodeEntryBegan;
- (void)notePasscodeEntryCancelled;
- (BOOL)hasAuthenticatedAtLeastOnceSinceBoot;
- (bool)hasPasscodeSet;
@end

@interface SBDashBoardPasscodeViewController : UIViewController
@property(nonatomic) __weak id delegate;
- (id)initWithOptions:(unsigned long long)arg1;
- (SBUIPasscodeLockViewBase*)_xen_passcodeLockView;
-(UIView*)_xen_backgroundView;
- (void)_passcodeLockViewPasscodeEntered:(id)arg1 viaMesa:(_Bool)arg2;
- (void)dismiss; // inherited
- (void)sendAction:(id)arg1; // inherited
@end

@interface SBBacklightController : NSObject
+(id)sharedInstance;
-(void)resetLockScreenIdleTimer;
-(void)cancelLockScreenIdleTimer;
-(void)turnOnScreenFullyWithBacklightSource:(int)arg1;
@end

@interface _UIBackdropViewSettings : NSObject
+ (id)settingsForStyle:(int)arg1;
+ (id)settingsForPrivateStyle:(int)arg1;
+ (id)settingsForPrivateStyle:(long long)arg1 graphicsQuality:(long long)arg2;
- (void)setColorTint:(id)arg1;
- (void)setColorTintAlpha:(CGFloat)arg1;
@property BOOL enabled;
@end

@interface _UIBackdropView : UIView
@property bool applySettingsAfterLayout;
- (id)initWithFrame:(CGRect)arg1 autosizesToFitSuperview:(BOOL)arg2 settings:(id)arg3;
- (id)initWithPrivateStyle:(int)arg1;
- (id)initWithSettings:(id)arg1;
- (id)initWithStyle:(int)arg1;
- (void)setBlurFilterWithRadius:(CGFloat)arg1 blurQuality:(id)arg2 blurHardEdges:(int)arg3;
- (void)setBlurFilterWithRadius:(CGFloat)arg1 blurQuality:(id)arg2;
- (void)setBlurHardEdges:(int)arg1;
- (void)setBlurQuality:(id)arg1;
- (void)setBlurRadius:(CGFloat)arg1;
- (void)setBlurRadiusSetOnce:(BOOL)arg1;
- (void)setBlursBackground:(BOOL)arg1;
- (void)setBlursWithHardEdges:(BOOL)arg1;
- (void)transitionToSettings:(id)arg1;
-(UIView*)contentView;
@property (nonatomic, strong) _UIBackdropViewSettings *inputSettings;
@end

@interface SBNotificationCell : UITableViewCell
@property(readonly, assign, nonatomic) UIView* attachmentView;
@property(assign, nonatomic) CGFloat secondaryTextHeight;
@property(retain, nonatomic) UILabel* eventDateLabel;
@property(retain, nonatomic) UILabel* relevanceDateLabel;
@property(readonly, assign, nonatomic) UILabel* secondaryLabel;
@property(readonly, assign, nonatomic) UILabel* subtitleLabel;
@property(readonly, assign, nonatomic) UILabel* primaryLabel;
@property(readonly, assign, nonatomic) UIView* iconView;
@property(readonly, assign, nonatomic) CGRect contentBounds;
@property(readonly, assign, nonatomic) UIView* realContentView; // Add things to this.
@end

@interface SBTableViewCellActionButton : UIButton {
    UIView* _backgroundView;
}
-(void)setBackgroundColor:(id)color withBlendMode:(int)blendMode;
-(UIVisualEffect *)backgroundEffect;
-(void)setBackgroundEffect:(UIVisualEffect *)arg1;
@end

@interface SBAwayListItem : NSObject
@end

@interface SBSnoozedAlarmListItem : SBAwayListItem
@property(retain, nonatomic) UILocalNotification *localNotification;
@end

@protocol SBLockScreenNotificationModel
- (SBAwayListItem *)listItemAtIndexPath:(NSIndexPath *)arg1;
@end

@interface BBAction : NSObject
+ (id)actionWithLaunchBundleID:(id)arg1 callblock:(id /* block */)arg2;
@end

@interface BBBulletin : NSObject
@property(copy, nonatomic) NSString *sectionID;
@property(copy, nonatomic) NSString *title;
@property(copy, nonatomic) NSString *message;
@property(copy, nonatomic) BBAction *defaultAction;
@property(retain, nonatomic) NSDate *date;
@property(copy, nonatomic) NSString *bulletinID;
@property(retain, nonatomic) NSDate *publicationDate;
@property(retain, nonatomic) NSDate *lastInterruptDate;
@property(nonatomic) BOOL showsMessagePreview;
@property(nonatomic) BOOL clearable;
@end

@interface NCNotificationRequest : NSObject
@property (nonatomic, readonly) BBBulletin *bulletin;
@property (nonatomic, readonly, copy) NSString *categoryIdentifier;
@property (nonatomic, readonly) unsigned long long collapsedNotificationsCount;
@property (nonatomic, readonly) bool isCollapsedNotification;
@property (nonatomic, readonly, copy) NSString *notificationIdentifier;
@property (nonatomic, readonly, copy) NSString *parentSectionIdentifier;
@property (nonatomic, readonly, copy) NSString *sectionIdentifier;
@end

@interface NCNotificationPriorityList : NSObject
- (id)requestAtIndex:(unsigned long long)arg1;
@end

@interface NCNotificationPriorityListViewController : UICollectionViewController
@property (nonatomic, retain) NCNotificationPriorityList *notificationRequestList;
-(NSString*)_xen_bundleIdentifierForIndexPath:(NSIndexPath*)indexPath;
-(BOOL)_xen_shouldShowIndexPath:(NSIndexPath*)indexPath;
-(CGFloat)_xen_heightForCurrentCellStyling:(CGFloat)defaultHeight;
@end

@interface SBAwayBulletinListItem : SBAwayListItem
@property(retain) BBBulletin* activeBulletin;
- (UIImage*)iconImage;
-(id)title;
-(Class)class;
-(BOOL)canSnooze;
@end

@interface SBSnoozedAlarmBulletinListItem : SBAwayBulletinListItem
@end

@interface SBLockScreenNotificationTableView : UITableView {
}
-(void)_setSeparatorBackdropOverlayBlendMode:(int)mode;
-(int)_separatorBackdropOverlayBlendMode;
@end

@protocol SBLockScreenNotificationViewDelegate
-(void)noteListViewReadyForModelUpdate;
-(void)listView:(id)view cellDidEndScrolling:(id)cell;
-(void)listView:(id)view cellDidBeginScrolling:(id)cell;
-(void)listViewDidEndScrolling:(id)listView;
-(void)listViewDidBeginScrolling:(id)listView;
-(id)lockScreenScrollView;
-(void)noteUnlockActionChanged:(id)changed;
-(void)handleLockScreenActionWithContext:(id)context;
@end

@interface SBLockScreenNotificationListView : UIView {
    SBLockScreenNotificationTableView* _tableView;
    id<SBLockScreenNotificationModel> _model;
}

@property(assign, nonatomic) id<SBLockScreenNotificationViewDelegate> delegate;

-(void)_resetAllFadeTimers;
-(_Bool)_disableIdleTimer:(_Bool)arg1;
-(void)handleActionFromTappedCellWithContext:(id)context;

// Extra shit!
-(NSString*)XENBundleIdentifierForIndexPath:(NSIndexPath*)indexPath;
-(BOOL)XENShouldShowIndexPath:(NSIndexPath*)indexPath;
-(void)_xen_reloadSeparatorStyleForSetup;
@end

@interface SBLockScreenNotificationCell : SBNotificationCell {
    UILabel* _unlockTextLabel;
}
@property(retain, nonatomic) UIButton* actionButton;
@property(readonly, assign, nonatomic) UIScrollView* contentScrollView;
@property(retain, nonatomic) id lockScreenActionContext;
@property (nonatomic, weak) SBLockScreenNotificationListView *delegate;
-(void)layoutSubviews;
-(void)_updateUnlockText:(id)text;
- (id)_vibrantTextColor;
-(UILabel*)XENUnlockTextLabel;
@end

@interface SBIconImageView : UIView
-(void)setIcon:(id)icon location:(int)location animated:(BOOL)animated;
@end

@interface SBIconModel : NSObject
-(id)applicationIconForBundleIdentifier:(id)bundleIdentifier;
@end

@interface SBIconController : NSObject
-(id)model;
+(id)sharedInstance;
@end

@interface SBSCardItem : NSObject <NSCopying, NSSecureCoding>
@property(copy, nonatomic) UIImage *thumbnail; // @synthesize thumbnail=_thumbnail;
@property(copy, nonatomic) NSString *bundleName; // @synthesize bundleName=_bundleName;
@property(nonatomic) BOOL requiresPasscode; // @synthesize requiresPasscode=_requiresPasscode;
@property(copy, nonatomic) NSData *iconData; // @synthesize iconData=_iconData;
@property(copy, nonatomic) NSString *identifier; // @synthesize identifier=_identifier;
@end

@interface SBAwayCardListItem : SBAwayListItem
@property(retain, nonatomic) UIImage *iconImage;
@property(retain, nonatomic) UIImage *cardThumbnail;
@property(readonly, nonatomic) NSString *body;
@property(readonly, nonatomic) NSString *title;
@property(copy, nonatomic) SBSCardItem *cardItem;
- (_Bool)inertWhenLocked;
- (id)sortDate;
- (NSString*)title;
- (void)dealloc;
@end

@interface SBAwaySystemAlertItem : SBAwayListItem
- (_Bool)isAlarm;
- (void)buttonPressed;
- (id)sortDate;
- (id)iconImage;
- (id)title;
- (id)message;
- (void)setCurrentAlert:(id)arg1;
- (id)currentAlert;
- (void)dealloc;
- (id)initWithSystemAlert:(id)arg1;
- (id)init;

@end

@interface SBFLockScreenDateView : UIView
+(CGFloat)defaultHeight;
- (double)timeBaselineOffsetFromOrigin;
@end

@interface SBLockOverlayContext : NSObject
@property(readonly, assign, nonatomic) unsigned priority;
@property(readonly, assign, nonatomic) UIViewController* viewController;
@end

@interface SBLockScreenFullscreenBulletinViewController : UIViewController {
    UIView* _bulletinView;
}
@property(retain, nonatomic) SBAwayBulletinListItem* bulletinItem;
-(BOOL)isPlayingSound;
-(void)performSnoozeAction;
-(id)_snoozeAction;
-(BOOL)_hasSnoozeAction;
-(id)_dismissAction;
-(void)performDismissAction;
-(id)_alternateAction;
-(BOOL)_hasAlternateAction;
-(void)performAlternateAction;
-(id)_titleForAlternateActionButton;
@end

@interface SBCCShortcutModule : NSObject {
    NSString* _displayID;
    NSURL* _url;
}
@property(copy, nonatomic, setter=setURL:) NSURL* url;
@property(copy, nonatomic) NSString* displayID;
+(id)identifier;
-(void)activateAppWithDisplayID:(id)displayID url:(id)url;
-(void)activateAppWithDisplayID:(id)arg1 url:(id)arg2 unlockIfNecessary:(bool)arg3;
-(void)activateApp;
-(BOOL)_toggleState;
-(BOOL)isRestricted;
-(id)aggdKey;
-(id)displayName;
-(id)identifier;
-(void)dealloc;
@end

@interface SBLockScreenView (IOS9)
- (int)lockScreenPageForPageNumber:(int)pageNumber;
- (int)pageNumberForLockScreenPage:(int)lockScreenPage;
- (void)setBottomGrabberHidden:(BOOL)hidden forRequester:(id)requester;
- (void)setBottomLeftGrabberHidden:(BOOL)hidden forRequester:(id)requester;
- (void)setTopGrabberHidden:(BOOL)hidden forRequester:(id)requester;
-(void)_xen_relayoutDateView;
-(void)_layoutSlideToUnlockView;
@end

@interface SBLockScreenViewController : UIViewController
@property(retain, nonatomic, setter=_setBioLockScreenActionContext:) id _bioLockScreenActionContext;
-(id)_wallpaperLegibilitySettings;
-(SBLockScreenNotificationListController*)_notificationController;
-(UIView*)lockScreenScrollView;
- (void)prepareForExternalUIUnlock;
- (id)lockScreenView;
- (void)setUnlockActionContext:(id)context;
- (void)setCustomLockScreenActionContext:(id)context;
@end

@interface SBDashBoardLegibilityProvider : NSObject
- (id)_wallpaperLegibilitySettings;
@end

@interface SpringBoard : UIApplication
-(void)_xen_showPeekUI;
-(void)_xen_hidePeekUIWithEvent:(int)event;
-(void)requestDeviceUnlock;
@end

@interface SpringBoard (Passcode)
@property(readonly, nonatomic) SBFUserAuthenticationController *authenticationController;
@end

@interface SBUserAgent : NSObject
+ (id)sharedUserAgent;
- (void)undimScreen;
- (void)dimScreen:(BOOL)screen;
- (void)lockAndDimDevice;
@end

@interface _UILegibilitySettings : NSObject
@property (nonatomic, retain) UIColor *contentColor;
@property (nonatomic) CGFloat imageOutset;
@property (nonatomic) CGFloat minFillHeight;
@property (nonatomic, retain) UIColor *primaryColor;
@property (nonatomic, retain) UIColor *secondaryColor;
@property (nonatomic) CGFloat shadowAlpha;
@property (nonatomic, retain) UIColor *shadowColor;
@property (nonatomic, copy) NSString *shadowCompositingFilterName;
@property (nonatomic) CGFloat shadowRadius;
@property (nonatomic) int style;
- (id)initWithContentColor:(id)arg1 contrast:(double)arg2;
@end

@interface SBPagedScrollView : UIScrollView
@end

@interface SBDashBoardView : UIView
@property(retain, nonatomic) _UILegibilitySettings *legibilitySettings;
@property(retain, nonatomic) SBPagedScrollView *scrollView;
@end

@interface SBControlCenterController : UIViewController
+ (id)sharedInstance;
- (id)controlCenterSystemAgentForControlCenterViewController:(id)arg1;
@end

@interface SBControlCenterSystemAgent : NSObject
- (void)activateAppWithDisplayID:(id)arg1 url:(id)arg2 unlockIfNecessary:(_Bool)arg3;
@end

@interface SBFWallpaperView : UIView
- (void)_updateLegibilitySettingsForAverageColor:(id)arg1 notify:(bool)arg2;
@end

@interface SBWallpaperController : NSObject
+ (instancetype)sharedInstance;
- (SBFWallpaperView*)_activeWallpaperView;
- (void)setLockscreenOnlyWallpaperAlpha:(CGFloat)alpha;
- (id)_newWallpaperViewForProcedural:(id)proceduralWallpaper orImage:(UIImage *)image;
- (id)_newWallpaperViewForProcedural:(id)proceduralWallpaper orImage:(UIImage *)image forVariant:(int)variant; //iOS 7.1
- (id)_newWallpaperViewForProcedural:(id)proceduralWallpaper orImage:(UIImage *)image withVideo:(id)video forVariant:(int)variant; //iOS 7.1
- (id)_clearWallpaperView:(id *)wallpaperView;
- (void)_handleWallpaperChangedForVariant:(NSUInteger)variant;
- (void)_updateSeparateWallpaper;
- (void)_updateSharedWallpaper;
- (void)_reconfigureBlurViewsForVariant:(NSUInteger)variant;
- (void)_updateBlurImagesForVariant:(NSUInteger)variant;
-(void)setActiveOrientationSource:(int)source andUpdateToOrientation:(int)orientation usingCrossfadeToBlack:(BOOL)black;
-(void)endRequiringWithReason:(id)reason;
-(void)beginRequiringWithReason:(id)reason;
-(BOOL)removeHomescreenStyleForPriority:(int)priority withAnimationFactory:(id)animationFactory;
- (void)setVariant:(int)variant withOutAnimationFactory:(id)outAnimationFactory inAnimationFactory:(id)animationFactory completion:(id)completion;
-(UIWindow*)_window;
- (id)legibilitySettingsForVariant:(int)variant;
@end

@interface SBFStaticWallpaperView : UIView
- (instancetype)initWithFrame:(CGRect)frame wallpaperImage:(UIImage *)wallpaperImage;
- (UIImageView *)contentView;
- (void)setVariant:(NSUInteger)variant;
- (void)setZoomFactor:(CGFloat)zoomFactor;
@end

@interface _SBFakeBlurView : UIView
+ (UIImage *)_imageForStyle:(int *)style withSource:(SBFStaticWallpaperView *)source;
- (void)updateImageWithSource:(id)source;
- (void)reconfigureWithSource:(id)source;
@end

@interface SBDisplayItem : NSObject
+ (id)displayItemWithType:(NSString *)type displayIdentifier:(id)identifier;
@end

@interface SBAppSwitcherSnapshotView : UIView
+ (id)appSwitcherSnapshotViewForDisplayItem:(id)displayItem orientation:(int)orientation preferringDownscaledSnapshot:(BOOL)snapshot loadAsync:(BOOL)async withQueue:(id)queue;
@end

@interface SBAppViewStatusBarDescriptor : NSObject
+ (id)statusBarDescriptorWithForceHidden:(BOOL)forceHidden;
@end

@interface SBApplicationController : NSObject
+ (id)sharedInstance;
- (id)applicationWithBundleIdentifier:(id)bundleIdentifier;
@end

@interface SBApplication : NSObject
- (id)mainSceneID;
- (id)_screenFromSceneID:(id)sceneID;
@end

@interface SBUIController : NSObject
+ (id)zoomViewForApplication:(id)application sceneID:(id)anId interfaceOrientation:(int)orientation statusBarDescriptor:(id)descriptor decodeImage:(BOOL)image;
+ (id)zoomViewWithIOSurfaceSnapshotOfApp:(id)app sceneID:(id)anId screen:(id)screen statusBarDescriptor:(id)descriptor;
@end

@interface SBSlideToUnlockFailureRecognizer : NSObject
@property(retain, nonatomic) UIView *relativeView;
@end

@interface _UIPhysicalButton : NSObject
@property long long type;
@end

@interface UIPhysicalButtonsEvent : NSObject
@property(retain, nonatomic) _UIPhysicalButton *_triggeringPhysicalButton;
@end

@interface SBControlCenterSectionViewController : UIViewController
@property(readonly, copy) NSString *debugDescription;
//@property(assign, nonatomic) id<SBControlCenterSectionViewControllerDelegate> delegate;
@property(readonly, copy) NSString *description;
@property(readonly, assign) unsigned hash;
@property(readonly, copy, nonatomic) NSString *sectionIdentifier;
@property(readonly, assign) Class superclass;
+ (Class)viewClass;
- (CGSize)contentSizeForOrientation:(int)orientation;
- (void)controlCenterDidDismiss;
- (void)controlCenterDidFinishTransition;
- (void)controlCenterWillBeginTransition;
- (void)controlCenterWillPresent;
- (BOOL)enabledForOrientation:(int)orientation;
- (void)loadView;
- (void)noteSettingsDidUpdate:(id)noteSettings;
- (id)view;
@end

@interface SBControlCenterSettings : NSObject
@property(assign) float backgroundAlphaFactor;
@property(assign) float controlAlpha;
@property(assign) float controlAlpha1x;
@property(assign) float disabledAlpha;
@property(assign) float disabledAlpha1x;
@property(assign) float glowAlpha;
@property(assign) float highlightAlpha;
@property(retain) UIColor *highlightColor;
@property(assign) float maxControlAlpha;
@property(assign) float minControlAlpha;
- (void)setDefaultValues;
@end

@interface SBUIControlCenterSlider : UISlider
-(void)setAdjusting:(BOOL)arg1;
-(void)_xen_setTrackImagesForCurrentTheme;
@end

@interface SBCCSettingsSectionController : SBControlCenterSectionViewController
@end

@interface SBCCBrightnessSectionController : SBControlCenterSectionViewController
-(SBUIControlCenterSlider*)xen_slider;
@end

@interface SBCCAirStuffSectionController : SBControlCenterSectionViewController
@end

@interface SBCCQuickLaunchSectionController : SBControlCenterSectionViewController
@end

@interface SBUIControlCenterVisualEffect : UIVisualEffect {
    int  _style;
}
//+ (id)effectWithStyle:(int)arg1;
- (id)copyWithZone:(id)arg1;
- (id)effectConfig;
@end

@interface MPUMediaControlsVolumeView : UIView
- (id)initWithStyle:(int)arg1;
@property (nonatomic, readonly) SBUIControlCenterSlider *slider;
@end

@interface SBUIControlCenterButton : UIView {
    UIVisualEffect *_highlightedStateEffect;
    UIVisualEffect *_normalStateEffect;
}
- (BOOL)isCircleButton;
- (long long)_currentState;
- (void)_updateForStateChange;
- (void)_updateEffects;
@end

@interface SBControlCenterButton: SBUIControlCenterButton
@end

@interface SBCCButtonLikeSectionSplitView : UIView
@end

@interface SBCCButtonLikeSectionView : UIView {
    UIVisualEffect *_normalStateEffect;
    UIVisualEffect *_highlightedStateEffect;
}
- (void)_updateEffects;
- (BOOL)isHighlighted;
-(void)_updateBackgroundForStateChange;
@end

@interface AVFlashlight : NSObject
- (void)dealloc;
- (id)init;
- (BOOL)isAvailable;
@end

@interface MPUTransportControlsView : UIView
@end

@interface MPUTransportControl : NSObject
- (int)type;
@end

@interface MPUTransportButton : UIButton
- (void)setTransportButtonImage:(id)arg1;
- (void)setTransportButtonImageViewContentMode:(int)arg1;
- (id)transportButtonImage;
@end

@interface MPUTransportControlMediaRemoteController : NSObject
- (BOOL)isPlaying;
@end

@interface MPUSystemMediaControlsView : UIView
@property (nonatomic, readonly) MPUMediaControlsVolumeView *volumeView;
@end

@interface MPUSystemMediaControlsViewController : UIViewController
-(MPUSystemMediaControlsView*)_xen_mediaView;
- (id)initWithStyle:(int)arg1;
@end

@protocol LPPage <NSObject>
- (long long)priority;
- (UIView *)view;

@optional
- (double)backgroundAlpha;
- (_Bool)isTimeEnabled;
- (double)idleTimerInterval;
- (void)pageDidDismiss;
- (void)pageWillDismiss;
- (void)pageDidPresent;
- (void)pageWillPresent;
@end

@protocol SBWidgetViewControllerDelegate <NSObject>
@optional
- (int)activeLayoutModeForWidget:(id)widget;
- (void)attemptReconnectionAfterUnanticipatedDisconnection:(id)disconnection;
- (void)contentAvailabilityDidChangeForWidget:(id)contentAvailability;
- (id)extensionForWidget:(id)widget;
- (UIEdgeInsets)marginInsetsForWidget:(id)widget;
- (CGSize)maxSizeForWidget:(id)widget;
- (void)remoteViewControllerDidConnectForWidget:(id)remoteViewController;
- (BOOL)shouldRequestWidgetRemoteViewControllers;
- (id)widget:(id)widget didUpdatePreferredHeight:(CGFloat)height completion:(id)completion;
- (void)widget:(id)widget requestsLaunchOfURL:(id)url;
- (BOOL)widgetShouldAttemptReconnectionAfterUnanticipatedDisconnection:(id)widget;
@end

@interface SBWidgetViewController : UIViewController
@property(copy, nonatomic) NSString *appBundleID;
@property(assign, nonatomic) id<SBWidgetViewControllerDelegate> delegate;
@property(assign, nonatomic) BOOL hasContent;
@property(readonly, assign, nonatomic) BOOL implementsPerformUpdate;
//@property(readonly, assign, nonatomic, getter=isInternal) BOOL internal;
@property(assign, nonatomic) int requestState;
@property(readonly, copy, nonatomic) NSString *widgetIdentifier;
+ (id)widgetViewControllerWithIdentifier:(id)identifier bundlePath:(id)path;
- (id)_cancelTouches;
- (id)initWithWidgetIdentifier:(id)widgetIdentifier bundlePath:(id)path;
- (void)connectRemoteViewControllerWithCompletionHandler:(id)completionHandler;
- (void)disconnectRemoteViewControllerWithCompletionHandler:(id)completionHandler;
- (void)hostDidDismiss;
- (void)hostDidPresent;
- (void)hostWillDismiss;
- (void)hostWillPresent;
- (void)captureSnapshotWithCompletionHandler:(id)completionHandler;
- (void)insertSnapshotWithCompletionHandler:(id)completionHandler;
- (void)invalidateCachedSnapshotWithCompletionHandler:(id)completionHandler;
- (void)performUpdateWithCompletionHandler:(id)completionHandler;
- (void)requestInsertionOfRemoteViewWithCompletionHandler:(id)completionHandler;
- (void)requestPreferredViewHeightWithHandler:(id)handler;
- (void)updateContentWidth:(float)width;
- (void)validateSnapshotViewForActiveLayoutMode;
@end

@interface NSExtension : NSObject
@property (nonatomic, readonly) BOOL optedIn;
@property (nonatomic, copy) NSDictionary *infoDictionary;
@property (nonatomic, copy) NSDictionary *attributes;
@property (setter=_setExtensionBundle:, nonatomic, retain) NSBundle *_extensionBundle;
- (void)_kill:(int)arg1;
@end

@interface NCWidgetDatum : NSObject {
    id _representedExtension;
}

@property (nonatomic, readonly, copy) NSString *datumIdentifier;
@property (readonly, copy) NSString *debugDescription;
@property (readonly, copy) NSString *description;
@property (readonly) unsigned int hash;
@property (nonatomic, readonly) NSExtension *representedExtension;
@property (readonly) Class superclass;

- (id)datumIdentifier;
- (void)dealloc;
- (id)description;
- (unsigned int)hash;
- (id)initWithExtension:(id)arg1;
- (BOOL)isEqual:(id)arg1;
- (id)representedExtension;

@end

@interface SBWidgetRowInfo : NSObject {
    SBWidgetViewController *_widget;
    CGFloat _preferredViewHeight;
    BOOL _visible;
    struct {
        unsigned isRePushingUpdates : 1;
    } _widgetBulletinInfoFlags;
}
@property(assign, nonatomic) CGFloat preferredViewHeight;
@property(readonly, assign, nonatomic) NCWidgetDatum *representedWidgetDatum;
@property(retain, nonatomic) SBWidgetViewController *widget;
+ (id)infoWithRepresentedObject:(id)representedObject;
- (id)_sectionIcon;
- (void)dealloc;
- (id)displayName;
- (float)heightForReusableViewForNotificationCenterTableViewController:(id)notificationCenterTableViewController layoutMode:(int)mode sectionLocation:(int)location;
- (id)icon;
- (id)identifier;
- (void)populateReusableView:(id)view;
- (Class)reusableViewClass;
- (id)reusableViewIdentifier;
- (id)settingsIcon;
@end

@interface SBWidgetSectionInfo : NSObject {
    NSString *_identifier;
    SBWidgetRowInfo *_widgetRowInfo;
}
@property(copy, nonatomic) NSString *identifier;
@property(retain, nonatomic) SBWidgetRowInfo *widgetRowInfo;
+ (instancetype)sectionInfoWithIdentifier:(NSString*)identifier;
- (void)dealloc;
- (id)description;
- (void)populateReusableView:(id)view;
- (Class)reusableViewClass;
@end

@interface _SBWidgetRemoteViewController : NSObject
- (id)disconnect;
@end

@interface _SBWidgetViewControllerOutOfProcess : SBWidgetViewController
@property(assign, nonatomic, getter=_didRequestViewInset, setter=_setDidRequestViewInset:) BOOL didRequestViewInset;
@property(retain, nonatomic, getter=_remoteViewController, setter=_setRemoteViewController:) _SBWidgetRemoteViewController *remoteViewController;
- (UIEdgeInsets)_marginInsets;
- (CGSize)_maxSize;
- (BOOL)_isRemoteViewVisible;
@end

@interface SBNotificationCenterController : NSObject
+ (instancetype)sharedInstance;
- (void)widget:(id)widget requestsLaunchOfURL:(id)url;
+(void)_xen_setRequestVisible:(BOOL)visible;
- (void)invalidateLockScreenActionContext;
@end

@interface NCDataSourceManager : NSObject {
    NSMutableDictionary * _identifiersToSnippetChangeHandlers;
    NSMutableDictionary * _identifiersToWidgetChangeHandlers;
    //NCSnippetDataSourceManager * _snippetDataSourceManager;
    //NCWidgetDataSourceManager * _widgetDataSourceManager;
}

@property (readonly, copy) NSString *debugDescription;
@property (readonly, copy) NSString *description;
@property (readonly) unsigned int hash;
@property (readonly) Class superclass;

+ (id)__sharedInstance;
+ (void)requestSharedDataSourceManager:(id /* block */)arg1;

- (void)_begin:(id /* block */)arg1;
- (void)_start:(id /* block */)arg1;
- (void)_stop:(id /* block */)arg1;
- (void)addSnippetDataSourceChangeHandler:(id /* block */)arg1 forIdentifier:(id)arg2;
- (void)addWidgetDataSourceChangeHandler:(id /* block */)arg1 forIdentifier:(id)arg2;
- (void)childDataSourceManagerDataSourcesDidChange:(id)arg1;
- (void)dealloc;
- (void)removeChangeHandlersWithIdentifier:(id)arg1;

@end

@interface NCWidgetDataSource : NSObject {
    //_NCConcreteDataSource *_concreteDataSource;
    NSString *_dataSourceIdentifier;
}

@property (nonatomic, readonly) NSString *dataSourceIdentifier;
@property (readonly, copy) NSString *debugDescription;
@property (readonly, copy) NSString *description;
@property (readonly) unsigned int hash;
@property (nonatomic, readonly) NSString *parentDataSourceIdentifier;
@property (readonly) Class superclass;
@property (nonatomic, readonly) NSArray *widgetIdentifiers;

- (void)addWidgetObserver:(id)arg1 completion:(id /* block */)arg2;
- (id)dataSourceIdentifier;
- (void)dealloc;
- (id)description;
- (id)initWithIdentifier:(id)arg1;
- (BOOL)isEqual:(id)arg1;
- (id)parentDataSourceIdentifier;
- (void)removeDatumWithIdentifier:(id)arg1;
- (void)removeWidgetObserver:(id)arg1 completion:(id /* block */)arg2;
- (void)replaceWithDatum:(id)arg1;
- (id)widgetDatumWithIdentifier:(id)arg1;
- (id)widgetIdentifiers;

@end

@interface SBWidgetHandlingNCColumnViewController : NSObject
+ (id)interfaceItemForDatum:(id)datum fromDataSourceWithIdentifier:(id)identifier;
@end

@interface BCBatteryDeviceController : NSObject
@property (nonatomic, readonly) NSArray *connectedDevices;
+ (instancetype)sharedInstance;
- (void)addDeviceChangeHandler:(id /* block */)arg1 withIdentifier:(id)arg2;
- (void)removeDeviceChangeHandlerWithIdentifier:(id)arg1;
@end

@protocol CMPocketStateDelegate <NSObject>
- (void)pocketStateManager:(/*CMPocketStateManager **/ id)arg1 didUpdateState:(long long)arg2;
@end

@interface CMPocketStateManager : NSObject {
    //<CMPocketStateDelegate> * _delegate;
    int  fCachedState;
    //struct Dispatcher { int (**x1)(); id x2; /* Warning: Unrecognized filer type: '' using 'void*' */ void*x3; void*x4; void*x5; void*x6; void*x7; void*x8; unsigned int x9; void*x10; void*x11; void*x12; void*x13; void*x14; void*x15; void*x16; } * fDispatcher;
    double  fMaxMonitorTime;
    NSObject<OS_dispatch_queue> * fPrivateQueue;
    id /* block */  fQueryBlock;
    NSObject<OS_dispatch_queue> * fQueryQueue;
    NSObject<OS_dispatch_source> * fQueryTimer;
}

@property (nonatomic) id<CMPocketStateDelegate> delegate;

+ (void)initialize;
+ (BOOL)isPocketStateAvailable;

- (void)_disableDispatcher;
- (void)addToAggdScalarWithName:(id)arg1 andScalar:(unsigned long long)arg2;
- (void)dealloc;
- (id<CMPocketStateDelegate>)delegate;
- (id)externalStateToString:(int)arg1;
- (id)init;
- (void)onNotification:(id)arg1;
- (void)onPocketStateUpdated:(int)arg1;
- (void)queryStateOntoQueue:(id)arg1 andMonitorFor:(double)arg2 withTimeout:(double)arg3 andHandler:(id /* block */)arg4;
- (void)queryStateOntoQueue:(id)arg1 withTimeout:(double)arg2 andHandler:(id /* block */)arg3;
- (void)setDelegate:(id<CMPocketStateDelegate>)arg1;
- (int)translateInternalState:(int)arg1;

@end

@interface SBFLockScreenMetrics : NSObject
+ (double)dateViewBaselineY;
+ (float)dateBaselineOffsetFromTime;
+ (UIEdgeInsets)notificationListInsets;
+ (float)dateLabelFontSize;
@end

@interface SBLockScreenActionContext : NSObject
@end

@interface SBLockScreenActionContextFactory : NSObject
+ (instancetype)sharedInstance;
- (SBLockScreenActionContext*)lockScreenActionContextForBulletin:(BBBulletin*)bulletin withOrigin:(int)origin pluginActionsAllowed:(BOOL)allowed;
@end

@interface SBManualIdleTimer : NSObject
- (id)initWithInterval:(double)arg1 userEventInterface:(id)arg2;
- (id)initWithInterval:(double)arg1;
@end

