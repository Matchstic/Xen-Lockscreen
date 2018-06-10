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
 * Heads up, this controller will do some subview modifying of the wallpaper blur when going to the passcode.
 * This *shouldn't* be an issue, as it'll be reset once the up arrow is reset.
 */

#import "XENBaseViewController.h"
#import "XENHomeArrowView.h"
#import "XENNotificationsCollectionViewController.h"
#import "XENFullscreenBulletinViewController.h"
#import "XENTouchEatingWindow.h"
#import "XENWelcomeController.h"
#import "XENHomePasscodeViewController.h"

@protocol XENHomeDelegate <NSObject>
-(void)addWallpaperView:(UIView*)wallpaperView;
-(BOOL)onHomePage;
-(void)setScrollEnabled:(BOOL)enabled;
-(void)adjustSidersForUnlockPercent:(CGFloat)percent;
-(void)adjustSidesForFullscreenWithAlpha:(CGFloat)alpha;
@end

typedef enum : NSUInteger {
    kPeekEventButtonPress,
    kPeekEventOther,
    kPeekEventUnlock
} XENPeekEvent;

@interface XENHomeViewController : XENBaseViewController <XENHomeArrowDelegate, XENWelcomeControllerDelegate, SBDashBoardPasscodeViewControllerDelegate> {
    BOOL isLocked;
    //_UIBackdropView *wallpaperBlurView;
    CGFloat _topGrabberAlphaPeek;
    CGFloat _bottomGrabberAlphaPeek;
    CGFloat _continuityAlphaPeek;
    BOOL inPeek;
    UIView *_darkeningView;
    NSMutableArray *_blurRequests;
    BOOL _showingWelcome;
    BOOL _usingJellyLock;
    UIView *_iOS10PasscodeBackgroundView;
}

@property (nonatomic, strong) UIView *componentsView;
@property (nonatomic, strong) XENHomeArrowView *arrowView;
@property (nonatomic, strong) UIView *pluginView;
@property (nonatomic, strong) UIView *peekBackgroundView;
@property (nonatomic, strong) XENNotificationsCollectionViewController *notificationsController;
@property (nonatomic, strong) XENFullscreenBulletinViewController *fullscreenBulletinController;
@property (nonatomic, strong) XENWelcomeController *welcomeController;
@property (nonatomic, strong) XENTouchEatingWindow *touchStealingWindow;
@property (nonatomic, strong) UIView *passcodeView;
@property (nonatomic, weak) UIView *leftSider;
@property (nonatomic, weak) UIView *rightSider;
@property (nonatomic, weak) id<XENHomeDelegate> delegate;
@property (nonatomic, strong) SBDashBoardPasscodeViewController *iOS10PasscodeController;

-(void)addComponentToView:(UIView*)view;

-(void)updateNotificationsViewWithBundleIdentifier:(NSString*)bundleIdentifier;
-(void)removeBundleIdentfierFromNotificationsView:(NSString*)bundleIdentifier;
-(void)layoutNotificationsControllerIfAppropriate;

-(void)_showPasscode;
-(void)scrollToPage:(int)page completion:(id)completion;

-(BOOL)isDraggingSlideUpArrow;

-(void)addPluginViewToView:(UIView *)pluginView;
-(SBLockScreenView*)findLockscreenView:(UIView*)input;

-(void)addFullscreenBulletinWithNotification:(id)notification title:(id)title andSubtitle:(id)subtitle;
-(void)removeFullscreenBulletin;

-(void)passcodeWasCancelled;
-(void)handleReturningFromPasscodeView;
-(void)addPasscodeView:(UIView *)passcodeView;
-(void)addPasscodeViewiOS10;

-(void)bounce;

// Handle Peek feature.
-(void)hidePeekInterfaceForEvent:(XENPeekEvent)event;
-(void)initialisePeekInterfaceIfEnabled;

-(void)layoutPasscodeForLockPages;

-(void)invalidateNotificationFrame;

-(void)showWelcomeController;

-(void)deconstruct;

// View management
-(void)configureViewForLock;
-(void)resetViewForUnlock;
-(void)resetViewForSettingsChange:(NSDictionary*)oldSettings :(NSDictionary*)newSettings;

@end
