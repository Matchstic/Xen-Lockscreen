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

#import <UIKit/UIKit.h>
#import "CoreDragon.h"
#import "AYVibrantButton.h"
#import "XENTintedView.h"

#define SCROLL_AREA 20
#define BOTTOM_SIZE SCREEN_HEIGHT - (SCREEN_HEIGHT*0.6) - 50

@protocol XENPageArrangementControllerDelegate <NSObject>
//-(void)relayoutControllerViewsForFailedTransition;
//-(void)setupForTransitioningToControllerAtOffset:(int)offset;
//-(void)relayoutControllerViewsForReturningTransition;
//-(void)closeContentPanel;
@end

@interface XENPageArrangementController : UIViewController <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, DragonDelegate, DragonDropDelegate> {
    int _scrollViewOffsetForToTransition;
    CGFloat _percentageToArrangement;
    UIView *_currentViewForTransitionAnimation;
    NSMutableArray *_enabledControllerIdentifiers;
    NSMutableArray *_disabledControllerIdentifiers;
    CGRect _toRectOnTransition;
    CGFloat _toTransformOnTransition;
    int _currentDragIndex;
    int _currentCollectionView;
    int _startDragIndex;
    int _startCollectionView;
    NSIndexPath *_emptyCellLocation;
    NSString *_currentDragIdentifier;
}

@property (nonatomic, strong) UICollectionViewController *mainCollectionController;
@property (nonatomic, strong) UICollectionViewController *bottomCollectionController;
@property (nonatomic, weak) id<XENPageArrangementControllerDelegate> delegate;
@property (nonatomic, strong) _UIBackdropView *backdropView;
@property (nonatomic, strong) UILabel *noAvailablePages;
@property (nonatomic, strong) AYVibrantButton *cancelButton;
@property (nonatomic, strong) AYVibrantButton *acceptButton;
@property (nonatomic, strong) UIVisualEffectView *vibrancyEffectView;
@property (nonatomic, strong) XENTintedView *breakingLine;
@property (nonatomic, strong) UILabel *helpLabel;

//-(void)beginTransitionToArrangementWithScrollViewOffset:(int)offset;
//-(void)updateTransitionToArrangementWithPercent:(CGFloat)percent;
//-(void)endTransitionToArrangementWithVelocity:(CGFloat)velocity;
//-(void)cancelTransitionToArrangementWithCompletion:(void(^)(void))completion;

-(void)invalidateForLockPages;
-(int)getDragIndexForLocationInView:(UIView*)view point:(CGPoint)point;

@end
