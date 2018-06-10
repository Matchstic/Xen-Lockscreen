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

#import "XENDashBoardArrangementController.h"
#import "XENBaseViewController.h"
#import "XENDashBoardPageViewController.h"
#import "XENPageArrangementCell.h"
#import <MobileCoreServices/MobileCoreServices.h>

@interface XENDashBoardArrangementController ()
@property (nonatomic, strong) DragonControllerModified *controller;
@end

@interface SBLockScreenManager (Blah)
- (id)_newLockScreenController;
@end

@implementation XENDashBoardArrangementController

-(instancetype)init {
    self = [super init];
    
    if (self) {
        // Setup known subclasses of SBDashBoardPageViewController
        NSMutableArray *newArray = [NSMutableArray array];
        
        SBDashBoardMainPageViewController *mainVc = [[objc_getClass("SBDashBoardMainPageViewController") alloc] init];
        [newArray addObject:mainVc];
        
        SBDashBoardTodayPageViewController *todayVc = [[objc_getClass("SBDashBoardTodayPageViewController") alloc] init];
        [newArray addObject:todayVc];
        
        // We don't want the camera to show!
        
        for (XENBaseViewController *contr in [XENResources availableViewControllers]) {
            XENDashBoardPageViewController *pageCont = [[objc_getClass("XENDashBoardPageViewController") alloc] init];
            pageCont.xenController = contr;
            
            [newArray addObject:pageCont];
        }
        
        _knownDashBoardControllers = newArray;
        
        // Re-do the identifiers!
        [self configureIdentifiers];
    }
    
    return self;
}

-(void)configureIdentifiers {
    _enabledControllerIdentifiers = [[XENResources _enabledIdentifiersForPageArrangement:YES] mutableCopy];
    
    // Sanity checks.
    [_enabledControllerIdentifiers removeObject:@"com.matchstic.passcode"];
    [_enabledControllerIdentifiers removeObject:@"com.apple.camera"];
    
    _disabledControllerIdentifiers = [NSMutableArray array];
    
    for (SBDashBoardPageViewController *controller in _knownDashBoardControllers) {
        if (![_enabledControllerIdentifiers containsObject:[controller _xen_identifier]] && ![[controller _xen_identifier] isEqualToString:@"com.matchstic.passcode"]) {
            
            XENDeviceSupport deviceType = (IS_IPAD ? kSupportsIpad : kSupportsIphone);
            
            if ([controller respondsToSelector:@selector(xenController)]) {
                XENBaseViewController *cont = [(XENDashBoardPageViewController*)controller xenController];
                if ([cont supportedDevices] == deviceType || [cont supportedDevices] == kSupportsAll)
                    [_disabledControllerIdentifiers addObject:[controller _xen_identifier]];
            } else {
                [_disabledControllerIdentifiers addObject:[controller _xen_identifier]];
            }
        }
    }
    
    // Sanity checks.
    [_disabledControllerIdentifiers removeObject:@"com.apple.camera"];
}

-(id)controllerWithIdentifier:(NSString*)identifier {
    for (SBDashBoardPageViewController *controller in _knownDashBoardControllers) {
        if ([[controller _xen_identifier] isEqualToString:identifier])
            return controller;
    }
    
    return nil;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    XENPageArrangementCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"collectionCell" forIndexPath:indexPath];
    NSString *identifier = @"";
    
    if ([collectionView isEqual:self.mainCollectionController.collectionView])
        identifier = _enabledControllerIdentifiers[indexPath.row];
    else
        identifier = _disabledControllerIdentifiers[indexPath.row];
    
    // Setup with correct icon and snapshot.
    if (![identifier isEqualToString:_currentDragIdentifier]) {
        SBDashBoardPageViewController *controller = [self controllerWithIdentifier:identifier];
        if (controller) {
            [self addChildViewController:controller];
            [cell setupWithDashBoardController:controller];
        } else {
            [cell setupWithUnableToLoad];
        }
        cell.controllerIdentifier = identifier;
        cell.backgroundColor = [UIColor clearColor];
    } else {
        cell.controllerIdentifier = nil;
    }
    
    XENlog(@"Setup cell with identifier %@", identifier);
    
    [self.controller registerDragSource:cell delegate:self];
    
    return cell;
}

-(void)collectionView:(UICollectionView *)collectionView willDisplayCell:(XENPageArrangementCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    
    NSString *identifier = @"";
    
    if ([collectionView isEqual:self.mainCollectionController.collectionView])
        identifier = _enabledControllerIdentifiers[indexPath.row];
    else
        identifier = _disabledControllerIdentifiers[indexPath.row];
    
    SBDashBoardPageViewController *controller = [self controllerWithIdentifier:identifier];
    
    CGAffineTransform transform = controller.view.transform;
    CGRect frame = controller.view.frame;
    controller.view.transform = CGAffineTransformIdentity;
    
    @try {
        [controller viewDidLoad];
    } @catch (NSException *e) {
        XENlog(@"CAUGHT!\n%@", e);
    }
    
    [controller viewWillAppear:YES];
    [controller viewDidAppear:YES];
    controller.view.transform = transform;
    controller.view.frame = CGRectMake(frame.origin.x, frame.origin.y, controller.view.frame.size.width, controller.view.frame.size.height);
    controller.view.hidden = NO;
    controller.view.userInteractionEnabled = NO;
}

- (void)beginDragOperation:(id<DragonInfo>)drag fromView:(UIView *)draggable {
    XENlog(@"BEGINNING DRAG OP, %@", draggable);
    
    // By default, the item being dragged is represented by a screenshot of the draggable view.
    // Optionally, you can set 'title', 'subtitle' and 'draggingIcon' on the dragging info
    // to give it a pretty icon.
    NSString *text = [(XENPageArrangementCell*)draggable controllerIdentifier];
    
    if ([XENResources useSlideToUnlockMode] && [text isEqualToString:@"com.apple.main"]) {
        return;
    }
    
    // Required: Provide the data to be dragged by adding it to the dragging info's pasteboard:
    [drag.pasteboard setValue:text forPasteboardType:(NSString*)kUTTypePlainText];
    
    // Work out start index etc.
    if ([_enabledControllerIdentifiers containsObject:text]) {
        _startCollectionView = 0;
        _startDragIndex = (int)[_enabledControllerIdentifiers indexOfObject:text];
    } else {
        _startCollectionView = 1;
        _startDragIndex = (int)[_disabledControllerIdentifiers indexOfObject:text];
    }
    
    _currentDragIdentifier = text;
    _currentCollectionView = _startCollectionView;
    _emptyCellLocation = [NSIndexPath indexPathForItem:_startDragIndex inSection:0];
}

-(BOOL)dropTarget:(UIView * __nonnull)droppable canAcceptDrag:(id<DragonInfo> __nonnull)drag {
    if ([_currentDragIdentifier isEqualToString:@"com.apple.main"] && _currentCollectionView == 1) {
        return NO;
    } else {
        return YES;
    }
}

- (BOOL)dropTarget:(UIView *)droppable shouldAcceptDrag:(id<DragonInfo>)drag {
    // Make sure we check for the home controller
    
    if ([_currentDragIdentifier isEqualToString:@"com.apple.main"] && _currentCollectionView == 1) {
        return NO;
    } else {
        return YES;
    }
}

-(void)dropTarget:(UIView * __nonnull)droppable acceptDrag:(id<DragonInfo> __nonnull)drag atPoint:(CGPoint)p withProxyView:(UIView * __nonnull)proxy {
    // Will be going to a new place!
    // Already know new index for the new collection view, or location, so literally just get that cell, and drop
    // our view on it. Lovely.
    
    XENlog(@"DROPPING VIEW!");
    
    UICollectionView *collectionView = (_currentCollectionView == 0 ? self.mainCollectionController.collectionView : self.bottomCollectionController.collectionView);
    for (XENPageArrangementCell *check in collectionView.visibleCells) {
        if (!check.controllerIdentifier || [check.controllerIdentifier isEqualToString:_currentDragIdentifier]) {
            [check setupWithDashBoardController:[self controllerWithIdentifier:_currentDragIdentifier]];
            check.controllerIdentifier = _currentDragIdentifier;
            break;
        }
    }
    
    _currentDragIdentifier = nil;
}

-(void)dropTarget:(UIView * __nonnull)droppable updateHighlight:(UIView * __nonnull)highlightContainer forDrag:(id<DragonInfo> __nonnull)drag atPoint:(CGPoint)p {
    int previousCollectionView = _currentCollectionView;
    int previousDragIndex = _currentDragIndex;
    CGPoint inMainScreen = [droppable convertPoint:p toView:self.view];
    
    XENlog(@"UPDATE HIGHLIGHT");
    
    if ([[self dropTargetAtPoint:inMainScreen] isEqual:self.mainCollectionController.collectionView]) {
        _currentCollectionView = 0;
    } else {
        _currentCollectionView = 1;
    }
    
    BOOL checkHome = [_currentDragIdentifier isEqualToString:@"com.apple.main"];
    if (checkHome) {
        _currentDragIndex = [self getDragIndexForLocationInView:self.mainCollectionController.collectionView point:[self.view convertPoint:inMainScreen toView:self.mainCollectionController.collectionView]];
    } else {
        _currentDragIndex = [self getDragIndexForLocationInView:[self dropTargetAtPoint:inMainScreen] point:p];
    }
    
    UICollectionView *collect = (UICollectionView*)droppable;
    
    // Move around cells.
    // Current point is converted already to the point space of the drop target. Sweet!
    // First, figure if the point is on the edges of the screen.
    if (inMainScreen.x < SCROLL_AREA) {
        // Slide towards index 0 if possible.
        CGFloat offset = collect.contentOffset.x - 30;
        if (offset < 0) offset = 0;
        
        [UIView animateWithDuration:0.05 animations:^{
            [collect setContentOffset:CGPointMake(offset, collect.contentOffset.y)];
        }];
    } else if (inMainScreen.x > SCREEN_WIDTH-SCROLL_AREA) {
        // Slide towards index n
        CGFloat offset = collect.contentOffset.x + 30;
        //UIEdgeInsets insets = [self collectionView:collect layout:collect.collectionViewLayout insetForSectionAtIndex:0];
        
        if (offset > collect.contentSize.width - SCREEN_WIDTH) offset = collect.contentSize.width - SCREEN_WIDTH;
        
        [UIView animateWithDuration:0.05 animations:^{
            [collect setContentOffset:CGPointMake(offset, collect.contentOffset.y)];
        }];
    }
    
    // Next, move empty cell around if possible.
    if ((_currentCollectionView == previousCollectionView || checkHome) && _currentDragIndex != previousDragIndex) {
        // Still in same collection view. Sweet!
        NSMutableArray *values = (_currentCollectionView == 0 ? _enabledControllerIdentifiers : _disabledControllerIdentifiers);
        [collect performBatchUpdates:^{
            //if (!(_currentCollectionView == 1 && [_currentDragIdentifier isEqualToString:@"com.matchstic.home"])) {
            if (values.count > 1) {
                [values removeObject:_currentDragIdentifier];
                [values insertObject:_currentDragIdentifier atIndex:_currentDragIndex];
                
                [collect moveItemAtIndexPath:_emptyCellLocation toIndexPath:[NSIndexPath indexPathForItem:_currentDragIndex inSection:0]];
            }
            //}
        } completion:^(BOOL finished) {
            
        }];
        
        if (checkHome) {
            _currentCollectionView = _startCollectionView;
        }
    } else if (_currentCollectionView != previousCollectionView && ![_currentDragIdentifier isEqualToString:@"com.apple.main"]){
        XENlog(@"MOVING TO NEW COLLECTION VIEW! %d %d", previousCollectionView, _currentCollectionView);
        // Hold on. Home controller isn't allowed to move. Check for that.
        
        // Move to new collectionview
        NSMutableArray *currentvalues = (_currentCollectionView == 0 ? _enabledControllerIdentifiers : _disabledControllerIdentifiers);
        NSMutableArray *oldvalues = (previousCollectionView == 0 ? _enabledControllerIdentifiers : _disabledControllerIdentifiers);
        [collect performBatchUpdates:^{
            [currentvalues insertObject:_currentDragIdentifier atIndex:_currentDragIndex];
            
            [collect insertItemsAtIndexPaths:[NSArray arrayWithObjects:[NSIndexPath indexPathForItem:_currentDragIndex inSection:0], nil]];
        } completion:^(BOOL finished) {
            
        }];
        
        UICollectionView *old = (previousCollectionView == 0 ? self.mainCollectionController.collectionView : self.bottomCollectionController.collectionView);
        
        [old performBatchUpdates:^{
            [oldvalues removeObject:_currentDragIdentifier];
            [old deleteItemsAtIndexPaths:[NSArray arrayWithObjects:[NSIndexPath indexPathForItem:previousDragIndex inSection:0], nil]];
        } completion:^(BOOL finished) {
            if (finished) {
                // Center the remaining views if appropriate.
            }
        }];
        
        // Adjust alpha of "No pages available" if needed.
        [UIView animateWithDuration:0.25 animations:^{
            self.noAvailablePages.alpha = (_disabledControllerIdentifiers.count == 0 ? 1.0 : 0.0);
        }];
    }
    
    _emptyCellLocation = [NSIndexPath indexPathForItem:_currentDragIndex inSection:0];
}

@end
