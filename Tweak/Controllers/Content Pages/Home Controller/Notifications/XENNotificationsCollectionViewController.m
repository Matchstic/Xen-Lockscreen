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

#import "XENNotificationsCollectionViewController.h"

@interface XENNotificationsCollectionViewController ()

@end

@implementation XENNotificationsCollectionViewController

-(instancetype)initWithCollectionViewLayout:(UICollectionViewLayout *)layout {
    self = [super initWithCollectionViewLayout:layout];
    
    if (self) {
        // Setup things for collection view controller
        [self.collectionView registerClass:[XENNotificationsCollectionViewCell class] forCellWithReuseIdentifier:@"notificationCell"];
        self.collectionView.frame = CGRectMake(SCREEN_WIDTH/2 - (NOTIFICATION_CELL_WIDTH*[XENResources notificationCellsPerRow])/2 - [XENResources notificationCellsPerRow], [self rawYOrigin], NOTIFICATION_CELL_WIDTH*[XENResources notificationCellsPerRow] + (2*[XENResources notificationCellsPerRow]), [self rawNotificationsHeight]);
        self.collectionView.backgroundColor = [UIColor clearColor];
        self.collectionView.opaque = NO;
        self.collectionView.showsVerticalScrollIndicator = NO;
        self.collectionView.bounces = YES;
        self.collectionView.clipsToBounds = NO;
        self.collectionView.tag = 1337123;
        
        [XENResources registerControllerForFadeOnHomeArrowUp:self];
    }
    
    return self;
}

#pragma mark UICollectionView delegate

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [[XENResources allNotificationBundleIdentifiers] count];
}

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    XENNotificationsCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"notificationCell" forIndexPath:indexPath];
    
    [cell setupWithBundleIdentifier:[XENResources allNotificationBundleIdentifiers][indexPath.row]];
    [cell setNotificationCount:[XENResources countOfNotificationsForBundleIdentifier:[XENResources allNotificationBundleIdentifiers][indexPath.row]]];
    
    int row = (((CGFloat)indexPath.row + 1.0) / [XENResources notificationCellsPerRow]);
    row -= row;
    row = ceilf(row);
    
    if (row < 0)
        row = 0;
    
    int column = (int)indexPath.row - (row * [XENResources notificationCellsPerRow]) + 1;
    
    XENlog(@"We're getting a new cell yo. Column is %d", column);
    
    [cell setCellColumn:column];
    
    return cell;
}

float iconCellNum;
float iconCellRow;
-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSString *bundleIdentifier = [XENResources allNotificationBundleIdentifiers][indexPath.row];
    
    XENlog(@"cell %ld was selected, with bundle id %@", (long)indexPath.row, bundleIdentifier);
    
    //notify_post("com.matchstic.convergance/notificationExpanded");
    
    XENNotificationsCollectionViewCell *cell;
    
    for (XENNotificationsCollectionViewCell *cell2 in self.collectionView.visibleCells) {
        if ([cell2.bundleId isEqualToString:bundleIdentifier]) {
            cell = cell2;
            break;
        }
    }
    
    [cell setNewNotificationGlow:NO];
    
    [XENResources setCurrentlyShownNotificationAppIdentifier:bundleIdentifier];
    [XENResources reloadNotificationListView];
    
    XENlog(@"cell.bundleID == %@", cell.bundleId);
    
    // nab icon + calculate rect
    [self.icon removeFromSuperview];
    self.icon = nil;
    
    self.icon = [XENResources iconImageViewForBundleIdentifier:cell.bundleId];
    
    CGRect rect = [self.collectionView.superview convertRect:cell.icon.frame fromView:cell.icon.superview];
    self.icon.frame = rect;
    self.icon.alpha = 0.0;

    [self.collectionView.superview addSubview:self.icon];
    
    [UIView animateWithDuration:0.0f animations:^{
        self.icon.alpha = 1.0;
    }];
    
    // assume it's placed correctly, then move the bugger.
    CGRect newframe = self.icon.frame;
    if (IS_IPAD) {
        newframe.size = CGSizeMake(50, 50);
    } else {
        newframe.size = CGSizeMake(45, 45);
    }
    
    newframe.origin.x = (SCREEN_WIDTH/2)-(newframe.size.width/2);
    newframe.origin.y = [self rawYOrigin] - newframe.size.height + (IS_IPAD ? 5 : 10); // Always have the small overlap
    
    [XENResources notificationListView].transform = CGAffineTransformMakeScale(0.5, 0.5);
    [XENResources notificationListView].alpha = 0.0;
    [XENResources notificationListView].hidden = NO;
    
    cell.icon.hidden = YES;
    
    [UIView animateWithDuration:0.3 animations:^{
        self.icon.frame = newframe;
        self.icon.alpha = 1.0;
        if (IS_IPAD)
            self.icon.transform = CGAffineTransformMakeScale(1.2, 1.2);
        self.collectionView.alpha = 0.0;
        self.collectionView.transform = CGAffineTransformMakeScale(0.5, 0.5);
        
        // We need to move up the clock, set the alpha + transform for notifications table,
        [XENResources notificationListView].alpha = 1.0;
        [XENResources notificationListView].transform = CGAffineTransformMakeScale(1.0, 1.0);
    } completion:^(BOOL finished) {
        if (finished) {
            // insert button underneath image, then add to button's subview
            self.fullscrenNotifButton = [UIButton buttonWithType:UIButtonTypeCustom]; // CVReactiveButton
            [self.fullscrenNotifButton addTarget:self
                                      action:@selector(removeFullscreenNotification:)
                            forControlEvents:UIControlEventTouchUpInside];
            self.fullscrenNotifButton.frame = self.icon.frame;
            self.fullscrenNotifButton.backgroundColor = [UIColor clearColor];
        
            [self.collectionView.superview insertSubview:self.fullscrenNotifButton aboveSubview:self.collectionView];
        
            CGRect rect = self.icon.frame;
            UIView *sv = self.icon.superview;
            self.icon.alpha = 0.0f;
            rect = [self.fullscrenNotifButton convertRect:rect fromView:sv];
            self.icon.frame = rect;
            [self.fullscrenNotifButton addSubview:self.icon];
            [UIView animateWithDuration:0.0f animations:^{
                self.icon.alpha = 1.0;
            }];
        
            self.collectionView.transform = CGAffineTransformMakeScale(1.0, 1.0);
        
            // Disable user interaction on HTML wallpaper
        
            [XENResources resetLockscreenDimTimer];
        }
    }];
}

-(CGFloat)rawYOrigin {
    // XXX: When rotating the device, this value only updates AFTER the rotation has begun. Right now,
    // it seems that the old value is pulled, resulting in some bizarre UI weirdness.
    
    // MSHookIvar<UIView*>(self, "_containerView");
    
    CGFloat raw = [objc_getClass("SBFLockScreenMetrics") notificationListInsets].top;
    CGFloat raw2 = [[[XENResources notificationListView].subviews firstObject] frame].origin.y;
    CGFloat final = 0;
    
    if (raw != raw2 && CGRectEqualToRect([[[XENResources notificationListView].subviews firstObject] frame], CGRectZero)) {
        // WTF, that's not right.
        // Go off the first raw value.
        final = raw;
    } else if (raw != raw2) {
        // Concede to the frame of the view.
        final = raw2;
    } else {
        final = raw;
    }
    
    if (final < 65) {
        final = 65;
        
        if ([XENResources useGroupedNotifications]) {
            CGRect newFrame = [[[XENResources notificationListView].subviews firstObject] frame];
            newFrame.origin.y = 65;
        
            [[[XENResources notificationListView].subviews firstObject] setFrame:newFrame];
        }
    }
    
    return final;
    
    //return [XENResources notificationListView].frame.origin.y;
}

-(CGFloat)rawNotificationsHeight {
    return [[[XENResources notificationListView].subviews firstObject] frame].size.height;
    
    //return [XENResources notificationListView].frame.size.height;
}

-(void)removeFullscreenNotification:(id)sender {
    //notify_post("com.matchstic.convergance/notificationClosed");
    XENlog(@"Current app identifier is %@", [XENResources currentlyShownNotificationAppIdentifier]);
    
    // return icon to ls + remove button
    CGRect rect = self.icon.frame;
    UIView *sv = self.icon.superview;
    self.icon.alpha = 0.0f;
    rect = [self.collectionView.superview convertRect:rect fromView:sv];
    self.icon.frame = rect;
    [self.collectionView.superview addSubview:self.icon];
    
    [UIView animateWithDuration:0.0f animations:^{
        self.icon.alpha = 1.0;
    }];
    
    [self.fullscrenNotifButton removeFromSuperview];
    self.fullscrenNotifButton = nil;
    
    // get new index of cell
    
    XENNotificationsCollectionViewCell *cell = nil;
    for (XENNotificationsCollectionViewCell *cl in self.collectionView.visibleCells) {
        if ([cl.bundleId isEqualToString:[XENResources currentlyShownNotificationAppIdentifier]]) {
            cell = cl;
            break;
        }
    }
    
    self.collectionView.transform = CGAffineTransformMakeScale(1.0, 1.0);
    
    CGRect rectA = CGRectMake(0, 0, NOTIFICATION_ICON_SIZE, NOTIFICATION_ICON_SIZE);
    rectA = [self.collectionView.superview convertRect:rectA fromView:cell.icon.superview];
    
    self.collectionView.transform = CGAffineTransformMakeScale(0.5, 0.5);
    
    cell.icon.hidden = YES;
    
    [UIView animateWithDuration:0.3 animations:^{
        if (IS_IPAD)
            self.icon.transform = CGAffineTransformMakeScale(1.0, 1.0);
        if (cell)
            self.icon.frame = rectA;
        self.collectionView.alpha = 1.0;
        self.collectionView.transform = CGAffineTransformMakeScale(1.0, 1.0);
        // fade out table here
        [XENResources notificationListView].alpha = 0.0;
        [XENResources notificationListView].transform = CGAffineTransformMakeScale(0.5, 0.5);
        if (cell == nil)
            self.icon.alpha = 0.0;
        else
            self.icon.alpha = 1.0;
    } completion:^(BOOL finished) {
        if (finished) {
            [XENResources setCurrentlyShownNotificationAppIdentifier:@""];
        
            // Enable HTML user interaction
            //ls.bgHtml.userInteractionEnabled = YES;
            [XENResources notificationListView].transform = CGAffineTransformMakeScale(1.0, 1.0);
            [XENResources notificationListView].alpha = 0.0;
            [XENResources notificationListView].hidden = YES;
        
            [self removeNotificationAssetsIfNecessary];
        
            // get cell image back
            self.icon.hidden = YES;
            [self.icon removeFromSuperview];
            self.icon = nil;
        
            cell.icon.hidden = NO;
        }
    }];
    
    [XENResources resetLockscreenDimTimer];
}

-(void)relayoutForChangeInDataSource:(BOOL)isAddingItem andIndex:(int)index2 {
    self.collectionView.frame = CGRectMake(SCREEN_WIDTH/2 - (NOTIFICATION_CELL_WIDTH*[XENResources notificationCellsPerRow])/2 - [XENResources notificationCellsPerRow], [self rawYOrigin], NOTIFICATION_CELL_WIDTH*[XENResources notificationCellsPerRow] + (2*[XENResources notificationCellsPerRow]), [self rawNotificationsHeight]);
}

-(void)updateCount:(int)count forCellWithBundleIdentifier:(NSString*)bundleIdentifier {
    XENNotificationsCollectionViewCell *cell = nil;
    for (XENNotificationsCollectionViewCell *cl in self.collectionView.visibleCells) {
        if ([cl.bundleId isEqualToString:bundleIdentifier]) {
            cell = cl;
            break;
        }
    }
    
    [cell setNotificationCount:count];
}

-(void)autoOpenIfNecessary:(NSString*)bundleIdentifier {
    if ([XENResources currentlyShownNotificationAppIdentifier] == nil ||
        [[XENResources currentlyShownNotificationAppIdentifier] isEqualToString:@""]) {
        int index = (int)[[XENResources allNotificationBundleIdentifiers] indexOfObject:bundleIdentifier];
        [XENResources setCurrentlyShownNotificationAppIdentifier:[bundleIdentifier copy]];
        NSIndexPath *path = [NSIndexPath indexPathForRow:index inSection:0];
        [self collectionView:self.collectionView didSelectItemAtIndexPath:path];
    }
}

-(void)invalidateRawYOrigin {
    [self rotateToOrient:0];
}

-(void)rotateToOrient:(int)orientation {
    CGRect newframe = self.fullscrenNotifButton.frame;
    
    if (IS_IPAD) {
        newframe.size = CGSizeMake(50, 50);
    } else {
        newframe.size = CGSizeMake(45, 45);
    }
    
    newframe.origin.x = (SCREEN_WIDTH/2)-(newframe.size.width/2);
    newframe.origin.y = [self rawYOrigin] - newframe.size.height + (IS_IPAD ? 5 : 10); // Always have the small overlap
    
    self.fullscrenNotifButton.frame = newframe;
    
    // Handle this frame's frame
    CGFloat transform = self.collectionView.transform.a;
    self.collectionView.transform = CGAffineTransformMakeScale(1.0, 1.0);
    self.collectionView.frame = CGRectMake(SCREEN_WIDTH/2 - (NOTIFICATION_CELL_WIDTH*[XENResources notificationCellsPerRow])/2 - [XENResources notificationCellsPerRow], [self rawYOrigin], NOTIFICATION_CELL_WIDTH*[XENResources notificationCellsPerRow] + (2*[XENResources notificationCellsPerRow]), [self rawNotificationsHeight]);
    self.collectionView.transform = CGAffineTransformMakeScale(transform, transform);
}

-(void)setAlpha:(CGFloat)alpha {
    self.collectionView.alpha = alpha;
    self.fullscrenNotifButton.alpha = alpha;
}

-(void)resetForScreenOff {
    //[self removeFullscreenNotification:nil];
}

#pragma mark Deallocation

-(void)removeNotificationAssetsIfNecessary {
    if (self.icon) {
        [self.icon removeFromSuperview];
        self.icon = nil;
    }
    
    if (self.fullscrenNotifButton) {
        [self.fullscrenNotifButton removeFromSuperview];
        self.fullscrenNotifButton = nil;
    }
}

-(void)dealloc {
    [self removeNotificationAssetsIfNecessary];
    
    for (UIView *view in self.collectionView.subviews)
        [view removeFromSuperview];
    
    XENlog(@"XENNotificationCollectionViewListController -- dealloc");
}

@end
