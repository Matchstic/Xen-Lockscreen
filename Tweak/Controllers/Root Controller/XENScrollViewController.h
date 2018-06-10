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

#import "XENPageArrangementController.h"
#import "XENMusicFullscreenController.h"
#import "XENHomeViewController.h"
#import "XENPageArrangementGesture.h"

@interface XENScrollViewController : UIViewController <UIScrollViewDelegate, XENPageArrangementControllerDelegate, XENHomeDelegate> {
    CGFloat _pageArrangementTransitionOffset;
    _UIBackdropView *wallpaperBlurView;
    UIView *_blurDarkener;
    CGFloat _lastKnownScrollPosition;
    UIView *_slideLeft;
    UIView *_slideRight;
    BOOL _adjustingSlides;
    BOOL _ignoreBlurNeeded;
    BOOL _fromDrag;
    BOOL _initialised;
    int _currentPage;
    
    BOOL _isRotating;
}

@property (nonatomic, weak) UIScrollView *lockscreenScrollView;
@property (nonatomic, weak) XENHomeViewController *homeViewController;
@property (nonatomic, strong) XENPageArrangementController *pageArrangementController;
@property (nonatomic, strong) XENMusicFullscreenController *musicFullscreenController;
@property (nonatomic, strong) NSArray *enabledIdentifiers;

-(void)configureWithScrollView:(UIScrollView*)scrollView;
-(void)configureControllersForLock;
-(void)adjustFramesForControllerAddingToScrollView:(BOOL)add;
-(void)postLockScreenInit;
-(void)handleReconfigureFromSetup;
-(void)finaliseEverythingForPostSetup;
-(void)addViewFromOriginalLockscreen:(UIView*)view;
-(void)rotateToOrientation:(int)orient;
-(void)setUIMaskedForRotation:(BOOL)arg1;
-(void)screenDidTurnOff;
-(void)prepareForScreenUndim;
-(BOOL)onHomePage;
-(void)moveToHomeController:(BOOL)animated;
-(void)passcodeCancelButtonWasTapped;
-(BOOL)isDraggingSlideUpArrow;

-(void)adjustSidersForSlideBegin;
-(void)adjustSidersForSlideEndedFinalOffset:(CGFloat)offset;
-(void)adjustSidersForUnlockPercent:(CGFloat)percent;

//-(void)didSortLockPages;

-(void)invalidateNotificationFrame;

-(void)makeDamnSureThatHomeIsInMiddleBeforeScreenOn;

-(void)notifyUnlockWillBegin;

-(XENBaseViewController*)controllerAtOffset:(CGFloat)offset;

-(void)invalidateControllersForLockPages;

@end
