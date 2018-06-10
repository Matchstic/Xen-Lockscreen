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
#import "XENBaseViewController.h"
#import "XENPageArrangementCell.h"
#import <MobileCoreServices/MobileCoreServices.h>

@interface XENPageArrangementController ()
@property (nonatomic, strong) DragonControllerModified *controller;
@end

@implementation XENPageArrangementController

-(instancetype)init {
    self = [super init];
    
    if (self) {
        [XENResources reloadSettings];
        
        [self configureIdentifiers];
    }
    
    return self;
}

-(void)configureIdentifiers {
    _enabledControllerIdentifiers = [[XENResources _enabledIdentifiersForPageArrangement:YES] mutableCopy];
    
    [_enabledControllerIdentifiers removeObject:@"com.matchstic.passcode"];
    
    _disabledControllerIdentifiers = [NSMutableArray array];
    
    for (XENBaseViewController *controller in [XENResources availableViewControllers]) {
        if (![_enabledControllerIdentifiers containsObject:[controller uniqueIdentifier]] && ![[controller uniqueIdentifier] isEqualToString:@"com.matchstic.passcode"]) {
            
            XENDeviceSupport deviceType = (IS_IPAD ? kSupportsIpad : kSupportsIphone);
            BOOL supportsCurrent = [[controller class] supportsCurrentiOSVersion];
            
            if (([controller supportedDevices] == deviceType || [controller supportedDevices] == kSupportsAll) && supportsCurrent)
                [_disabledControllerIdentifiers addObject:[controller uniqueIdentifier]];
        }
    }
}

-(void)invalidateForLockPages {
    [self configureIdentifiers];
    
    // Reload controllers.
    [self.mainCollectionController.collectionView reloadData];
    [self.bottomCollectionController.collectionView reloadData];
}

-(void)loadView {
    self.view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)];
    self.view.backgroundColor = [UIColor clearColor];
    
    // Get wallpaper, put as root view.
    
    self.controller = [[DragonControllerModified alloc] init];
    
    [self.controller enableLongPressDraggingInWindow:(UIWindow*)self.view];
    
    self.mainCollectionController = [[UICollectionViewController alloc] initWithCollectionViewLayout:[self layoutForCollectionViewController]];
    self.mainCollectionController.collectionView.delegate = self;
    self.mainCollectionController.collectionView.dataSource = self;
    
    [self.mainCollectionController.collectionView registerClass:[XENPageArrangementCell class] forCellWithReuseIdentifier:@"collectionCell"];
    self.mainCollectionController.collectionView.frame = CGRectMake(0, 20, SCREEN_WIDTH, (SCREEN_HEIGHT*0.6) - 20);
    self.mainCollectionController.collectionView.backgroundColor = [UIColor clearColor];
    self.mainCollectionController.collectionView.opaque = NO;
    self.mainCollectionController.collectionView.showsVerticalScrollIndicator = NO;
    self.mainCollectionController.collectionView.showsHorizontalScrollIndicator = NO;
    self.mainCollectionController.collectionView.alwaysBounceHorizontal = YES;
    self.mainCollectionController.collectionView.alwaysBounceVertical = NO;
    self.mainCollectionController.collectionView.clipsToBounds = YES;
    self.mainCollectionController.collectionView.canCancelContentTouches = NO;
    self.mainCollectionController.collectionView.tag = 1;

    [self.view addSubview:self.mainCollectionController.collectionView];
    
    [self.controller registerDropTarget:self.mainCollectionController.collectionView delegate:self];
    
    self.bottomCollectionController = [[UICollectionViewController alloc] initWithCollectionViewLayout:[self layoutForCollectionViewController]];
    self.bottomCollectionController.collectionView.delegate = self;
    self.bottomCollectionController.collectionView.dataSource = self;
    
    [self.bottomCollectionController.collectionView registerClass:[XENPageArrangementCell class] forCellWithReuseIdentifier:@"collectionCell"];
    self.bottomCollectionController.collectionView.frame = CGRectMake(0, SCREEN_HEIGHT*0.6, SCREEN_WIDTH, BOTTOM_SIZE);
    self.bottomCollectionController.collectionView.backgroundColor = [UIColor clearColor];
    self.bottomCollectionController.collectionView.opaque = NO;
    self.bottomCollectionController.collectionView.showsVerticalScrollIndicator = NO;
    self.bottomCollectionController.collectionView.showsHorizontalScrollIndicator = NO;
    self.bottomCollectionController.collectionView.alwaysBounceHorizontal = YES;
    self.bottomCollectionController.collectionView.alwaysBounceVertical = NO;
    self.bottomCollectionController.collectionView.clipsToBounds = YES;
    self.bottomCollectionController.collectionView.canCancelContentTouches = NO;
    self.bottomCollectionController.collectionView.tag = 0;
    
    [self.view addSubview:self.bottomCollectionController.collectionView];
    
    [self.controller registerDropTarget:self.bottomCollectionController.collectionView delegate:self];
    
    // We'll also need the "bar" view underneath the bottom section.
    _UIBackdropViewSettings *settings = [objc_getClass("_UIBackdropViewSettings") settingsForPrivateStyle:([XENResources shouldUseDarkColouration] ? 1 : 0)];
    self.backdropView = [[objc_getClass("_UIBackdropView") alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT) autosizesToFitSuperview:NO settings:settings];
    self.backdropView.userInteractionEnabled = YES;
    
    [self.view insertSubview:self.backdropView atIndex:0];
    
    // And also a label if there are no pages to show
    UIVibrancyEffect *vibrancyEffect = [UIVibrancyEffect effectForBlurEffect:[UIBlurEffect effectWithStyle:([XENResources shouldUseDarkColouration] ? UIBlurEffectStyleDark : UIBlurEffectStyleLight)]];
    self.vibrancyEffectView = [[UIVisualEffectView alloc] initWithEffect:vibrancyEffect];
    [self.vibrancyEffectView setFrame:self.backdropView.bounds];
    
    [self.backdropView addSubview:self.vibrancyEffectView];
    
    // Label for vibrant text
    self.noAvailablePages = [[UILabel alloc] initWithFrame:CGRectMake(0, SCREEN_HEIGHT*0.6, self.backdropView.frame.size.width, BOTTOM_SIZE)];
    [self.noAvailablePages setText:[XENResources localisedStringForKey:@"No Pages Available" value:@"No Pages Available"]];
    [self.noAvailablePages setFont:[UIFont systemFontOfSize:25.0f]];
    self.noAvailablePages.textAlignment = NSTextAlignmentCenter;
    
    [self.vibrancyEffectView.contentView addSubview:self.noAvailablePages];
    
    // Buttons to close window.
    self.cancelButton = [[AYVibrantButton alloc] initWithFrame:CGRectMake(-1, self.vibrancyEffectView.contentView.frame.size.height - 50, SCREEN_WIDTH/2 + 1.5, 52) style:AYVibrantButtonStyleTranslucent];
    self.cancelButton.vibrancyEffect = vibrancyEffect;
    self.cancelButton.cornerRadius = 0.0;
    self.cancelButton.text = [XENResources localisedStringForKey:@"Cancel" value:@"Cancel"];
    [self.cancelButton addTarget:self action:@selector(cancelEditingContentPanel:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.vibrancyEffectView.contentView addSubview:self.cancelButton];
    
    self.acceptButton = [[AYVibrantButton alloc] initWithFrame:CGRectMake(SCREEN_WIDTH/2 - 0.5, self.vibrancyEffectView.contentView.frame.size.height - 50, SCREEN_WIDTH/2 + 1.5, 52) style:AYVibrantButtonStyleTranslucent];
    self.acceptButton.vibrancyEffect = vibrancyEffect;
    self.acceptButton.cornerRadius = 0.0;
    self.acceptButton.text = [XENResources localisedStringForKey:@"Accept" value:@"Accept"];
    [self.acceptButton addTarget:self action:@selector(acceptEditingContentPanel:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.vibrancyEffectView.contentView addSubview:self.acceptButton];
    
    self.helpLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 5, SCREEN_WIDTH, 20)];
    self.helpLabel.text = [XENResources localisedStringForKey:@"Drag and drop to arrange" value:@"Drag and drop to arrange"];
    self.helpLabel.textAlignment = NSTextAlignmentCenter;
    self.helpLabel.textColor = ([XENResources shouldUseDarkColouration] ? [UIColor colorWithWhite:0.2 alpha:1.0] : [UIColor colorWithWhite:1.0 alpha:1.0]);
    self.helpLabel.font = [UIFont systemFontOfSize:14];
    
    [self.vibrancyEffectView.contentView addSubview:self.helpLabel];
    
    if (_disabledControllerIdentifiers.count > 0) {
        self.noAvailablePages.alpha = 0.0;
    }
}

-(UICollectionViewFlowLayout*)layoutForCollectionViewController {
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    layout.minimumInteritemSpacing = 10;
    
    return layout;
}

#pragma mark UICollectionView data source and delegate

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    int count = 0;
    if ([collectionView isEqual:self.mainCollectionController.collectionView])
        count = (int)[_enabledControllerIdentifiers count];
    else
        count = (int)[_disabledControllerIdentifiers count];
    
    return count;
}

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
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
        XENBaseViewController *controller = [XENResources controllerWithIdentifier:identifier];
        [cell setupWithXENController:controller];
        cell.controllerIdentifier = identifier;
        cell.backgroundColor = [UIColor clearColor];
    
        XENlog(@"Setup cell with identifier %@", identifier);
    } else {
        cell.controllerIdentifier = nil;
    }
    
    [self.controller registerDragSource:cell delegate:self];
    
    return cell;
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    XENlog(@"cell %ld was selected", (long)indexPath.row);
    return; // No launching allowed for overlay thing.
    
    if ([collectionView isEqual:self.mainCollectionController.collectionView]) {
        // Alright, we can launch this one back to LS. No need to worry about data source, that's handled
        // by the draggable methods.
        //[self.delegate setupForTransitioningToControllerAtOffset:(int)indexPath.row];
        NSString *identifier = [_enabledControllerIdentifiers objectAtIndex:(int)indexPath.row];
        
        XENPageArrangementCell *cell;
        
        for (XENPageArrangementCell *cl in self.mainCollectionController.collectionView.visibleCells) {
            if ([cl.controllerIdentifier isEqualToString:identifier]) {
                cell = cl;
                break;
            }
        }
        
        _toRectOnTransition = [self.mainCollectionController.collectionView.superview convertRect:cell.controllerView.frame fromView:cell.controllerView.superview];
        cell.controllerView.frame = _toRectOnTransition;
        [self.mainCollectionController.collectionView.superview addSubview:cell.controllerView];
        
        // Scroll view is now readied, just animate up the view, and then we *should* be fine
        [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            cell.controllerView.transform = CGAffineTransformMakeScale(1.0, 1.0);
            cell.controllerView.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
            cell.controllerView.layer.borderColor = [UIColor clearColor].CGColor;
            cell.controllerView.layer.borderWidth = 0;
            cell.controllerView.layer.cornerRadius = 0;
            self.mainCollectionController.collectionView.alpha = 0.0;
            
            self.bottomCollectionController.collectionView.frame = CGRectMake(0, SCREEN_HEIGHT, self.bottomCollectionController.collectionView.frame.size.width, self.bottomCollectionController.collectionView.frame.size.height);
            self.backdropView.frame = self.bottomCollectionController.collectionView.frame;
        } completion:^(BOOL finished) {
            cell.controllerView.userInteractionEnabled = YES;
            //[self.delegate relayoutControllerViewsForReturningTransition];
        }];
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    if ([collectionView isEqual:self.mainCollectionController.collectionView])
        return CGSizeMake(SCREEN_WIDTH*TOP_CELL_MULTIPLIER, SCREEN_HEIGHT*TOP_CELL_MULTIPLIER + 30);
    else
        return CGSizeMake(SCREEN_WIDTH*BOTTOM_CELL_MULTIPLIER, SCREEN_HEIGHT*BOTTOM_CELL_MULTIPLIER + 30);

    return CGSizeZero;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    CGFloat cellSize;
    int count = 0;
    CGFloat spacing = 5;
    if ([collectionView isEqual:self.mainCollectionController.collectionView]) {
        cellSize = SCREEN_WIDTH*TOP_CELL_MULTIPLIER;
        count = (int)_enabledControllerIdentifiers.count;
    } else {
        cellSize = SCREEN_WIDTH*BOTTOM_CELL_MULTIPLIER;
        count = (int)_disabledControllerIdentifiers.count;
    }
    
    // Quite simply, work out the total size of the elements, and if less than screen width, inset appropriately. Otherwise,
    // make it center the 0-index and the nth-index
    CGFloat fullSize = (count * cellSize) + (count-1 * spacing);
    if (fullSize < SCREEN_WIDTH) {
        // Center as appropriate.
        CGFloat inset = SCREEN_WIDTH/2 - fullSize/2;
        return UIEdgeInsetsMake(0, inset, 0, inset);
    } else {
        // Alright. Just give an arbitrary amount for easiness.
        return UIEdgeInsetsMake(0, SCREEN_WIDTH*0.1, 0, SCREEN_WIDTH*0.1);
    }
}

#pragma mark Draggable delegate

- (void)beginDragOperation:(id<DragonInfo>)drag fromView:(UIView *)draggable {
    XENlog(@"BEGINNING DRAG OP, %@", draggable);
    
    // By default, the item being dragged is represented by a screenshot of the draggable view.
    // Optionally, you can set 'title', 'subtitle' and 'draggingIcon' on the dragging info
    // to give it a pretty icon.
    NSString *text = [(XENPageArrangementCell*)draggable controllerIdentifier];
    
    if ([XENResources useSlideToUnlockMode] && [text isEqualToString:@"com.matchstic.home"]) {
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

-(void)beganDragOperation:(id<DragonInfo> __nonnull)drag fromView:(UIView * __nonnull)draggable {
    
}

-(BOOL)dropTarget:(UIView * __nonnull)droppable canAcceptDrag:(id<DragonInfo> __nonnull)drag {
    if ([_currentDragIdentifier isEqualToString:@"com.matchstic.home"] && _currentCollectionView == 1) {
        return NO;
    } else {
        return YES;
    }
    
    //return YES;
}

// Ensure that we only receive drops for plain text
- (BOOL)dropTarget:(UIView *)droppable shouldAcceptDrag:(id<DragonInfo>)drag {
    // TODO: MAke sure we check for the home controller
    
    /*if (_startCollectionView == _currentCollectionView && _startDragIndex == _currentDragIndex) {
        // Returning to the same place, same as a cancel.
        return NO;
    }*/
    
    if ([_currentDragIdentifier isEqualToString:@"com.matchstic.home"] && _currentCollectionView == 1) {
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
            [check setupWithXENController:[XENResources controllerWithIdentifier:_currentDragIdentifier]];
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
    
    if ([[self dropTargetAtPoint:inMainScreen] isEqual:self.mainCollectionController.collectionView]) {
        _currentCollectionView = 0;
    } else {
        _currentCollectionView = 1;
    }
    
    BOOL checkHome = [_currentDragIdentifier isEqualToString:@"com.matchstic.home"];
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
    } else if (_currentCollectionView != previousCollectionView && ![_currentDragIdentifier isEqualToString:@"com.matchstic.home"]){
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

-(int)getDragIndexForLocationInView:(UIView*)view point:(CGPoint)point {
    //CGPoint convertedPoint = [hitView convertPoint:convertedPoint fromView:self.view];
    
    int val = (int)[(UICollectionView*)view indexPathForItemAtPoint:point].row;
    
    // Now, check if the point found falls *outside* the inset of the collection view.
    
    UIEdgeInsets insets = [self collectionView:(UICollectionView*)view layout:[(UICollectionView*)view collectionViewLayout] insetForSectionAtIndex:0];
    if (point.x < insets.left) {
        val = 0;
    } else if (point.x > [(UICollectionView*)view contentSize].width - insets.right) {
        val = ([view isEqual:self.mainCollectionController.collectionView] ? (int)_enabledControllerIdentifiers.count - 1 : (int)_disabledControllerIdentifiers.count - 1);
        if (val < 0) val = 0;
    }
    
    XENlog(@"Giving %d for point %@", val, NSStringFromCGPoint(point));
    
    if (!view) {
        return 0;
    }
    
    return val;
}

-(UIView*)dropTargetAtPoint:(CGPoint)p {
    // Check bounds for point, and return as necessary.
    
    if (p.y < self.bottomCollectionController.collectionView.frame.origin.y) {
        return self.mainCollectionController.collectionView;
    } else {
        return self.bottomCollectionController.collectionView;
    }
}

-(CGPoint)positionForDragConclusion:(id<DragonInfo>)info {
    // Work out where the cell requested is right now.
    
    UICollectionView *collectionView = (_currentCollectionView == 0 ? self.mainCollectionController.collectionView : self.bottomCollectionController.collectionView);
    
    for (XENPageArrangementCell *check in collectionView.visibleCells) {
        if (!check.controllerIdentifier || [check.controllerIdentifier isEqualToString:_currentDragIdentifier]) {
            // We have the correct cell now.
            // Get co-ordinates in screen space.
            XENlog(@"CHECKMATE! %@", NSStringFromCGRect(check.frame));
            CGFloat x = check.frame.origin.x - collectionView.contentOffset.x;
            CGFloat y = check.frame.origin.y + collectionView.frame.origin.y;
            
            XENlog(@"CHECKMATE2! %@", NSStringFromCGPoint(CGPointMake(x, y)));
            return CGPointMake(x, y);
        }
    }
    
    return CGPointZero;
}

-(int)currentController {
    return _currentCollectionView;
}

-(void)cancelEditingContentPanel:(id)sender {
    [self closeContentPanel];
}

-(void)acceptEditingContentPanel:(id)sender {
    // End up saving changes to disk or whatever.
    [XENResources saveNewControllerIdentifiersLayout:_enabledControllerIdentifiers];
    [self closeContentPanel];
}

-(void)closeContentPanel {
    int orientation = [UIApplication sharedApplication].statusBarOrientation;
    [XENResources setCurrentOrientation:orientation];
    
    [UIView animateWithDuration:0.25 animations:^{
        [XENResources contentEditWindow].frame = CGRectMake(0, SCREEN_HEIGHT, SCREEN_WIDTH, SCREEN_HEIGHT);
        [XENResources wallpapeWindow].frame = CGRectMake(0, SCREEN_HEIGHT, SCREEN_WIDTH, SCREEN_HEIGHT);
    } completion:^(BOOL finished) {
        if (finished) {
            [XENResources hideContentEditWindow];
            if ([XENResources isLoadedEditFromSetup]) {
                [XENResources moveUpDownWallpaperWindowForSetup:YES];
            } else {
                [XENResources moveUpDownWallpaperWindow:YES];
            }
            [XENResources wallpapeWindow].frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
        }
    }];
    //[self.delegate closeContentPanel];
}

#pragma Inherited shit

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)rotateToOrientation:(int)orient {
    self.mainCollectionController.collectionView.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT*0.6);
    self.bottomCollectionController.collectionView.frame = CGRectMake(0, SCREEN_HEIGHT*0.6, SCREEN_WIDTH, BOTTOM_SIZE);
    self.backdropView.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
    self.vibrancyEffectView.frame = self.backdropView.bounds;
    self.breakingLine.frame = CGRectMake(0, SCREEN_HEIGHT*0.6, SCREEN_WIDTH, 1);
    self.noAvailablePages.frame = CGRectMake(0, SCREEN_HEIGHT*0.6, self.backdropView.frame.size.width, BOTTOM_SIZE);
}

-(void)dealloc {
    self.controller = nil;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
