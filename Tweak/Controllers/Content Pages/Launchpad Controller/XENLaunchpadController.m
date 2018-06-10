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



// SBDashBoardSlidingAppViewController

#import "XENLaunchpadController.h"
#import "KTCenterFlowLayout.h"
#import "XENLaunchpadCollectionCell.h"

@interface XENLaunchpadController ()

@end

@implementation XENLaunchpadController

-(instancetype)init {
    self = [super init];
    
    if (self) {
        self.dataSource = [XENLaunchpadDataSource sharedInstance];
    }
    
    return self;
}

-(void)loadView {
    if ([XENResources launchpadUseQuickDial]) {
        self.headerController = [[XENLaunchpadHeaderViewController alloc] init];
        [self.headerController loadView];
    }
    
    self.collectionViewController = [[UICollectionViewController alloc] initWithCollectionViewLayout:[self layoutForLaunchpadController]];
    self.collectionViewController.collectionView.delegate = self;
    self.collectionViewController.collectionView.dataSource = self;
    
    [self.collectionViewController.collectionView registerClass:[XENLaunchpadCollectionCell class] forCellWithReuseIdentifier:@"launchpadCell"];
    self.collectionViewController.collectionView.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
    self.collectionViewController.collectionView.backgroundColor = [UIColor clearColor];
    self.collectionViewController.collectionView.opaque = NO;
    self.collectionViewController.collectionView.showsVerticalScrollIndicator = NO;
    self.collectionViewController.collectionView.bounces = YES;
    self.collectionViewController.collectionView.clipsToBounds = NO;
    
    // This was in viewDidLoad
    [self.collectionViewController.collectionView registerClass:[UICollectionReusableView class]
                                     forSupplementaryViewOfKind: UICollectionElementKindSectionHeader
                                            withReuseIdentifier:@"headerView"];
    [self.collectionViewController.collectionView registerClass:[UICollectionReusableView class]
                                     forSupplementaryViewOfKind: UICollectionElementKindSectionFooter
                                            withReuseIdentifier:@"footerView"];
    
    self.view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)];
    self.view.tag = 12345;
    self.view.backgroundColor = [UIColor clearColor];
    
    [self.view addSubview:self.collectionViewController.collectionView];
}

-(UICollectionViewFlowLayout*)layoutForLaunchpadController {
    KTCenterFlowLayout *notifLayout = [[KTCenterFlowLayout alloc] init];
    notifLayout.scrollDirection = UICollectionViewScrollDirectionVertical;
    
    if (![XENResources launchpadIconsOnly]) {
        notifLayout.itemSize = CGSizeMake(SCREEN_MIN_LENGTH*0.40, SCREEN_MAX_LENGTH*0.40 + ((IS_IPAD ? 72 : 60)*[XENResources launchpadIconSize])/2);
        notifLayout.minimumInteritemSpacing = SCREEN_MIN_LENGTH*0.10;
        notifLayout.minimumLineSpacing = notifLayout.minimumInteritemSpacing/2;
        
        [notifLayout setSectionInset:UIEdgeInsetsMake(30.0, 7.0, 10.0, 7.0)];
    } else {
        notifLayout.itemSize = CGSizeMake((IS_IPAD ? 72 : 60)*[XENResources launchpadIconSize], (IS_IPAD ? 72 : 60)*[XENResources launchpadIconSize]);
        notifLayout.minimumInteritemSpacing = SCREEN_MIN_LENGTH*0.10;
        notifLayout.minimumLineSpacing = notifLayout.minimumInteritemSpacing/2;
        
        [notifLayout setSectionInset:UIEdgeInsetsMake(30.0, SCREEN_WIDTH*0.05, 10.0, SCREEN_WIDTH*0.05)];
    }
    
    return notifLayout;
}

#pragma mark UICollectionView delegates

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [[self.dataSource availableBundleIdentifiers] count];
}

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    XENLaunchpadCollectionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"launchpadCell" forIndexPath:indexPath];
    NSString *bundleIdentifier = [self.dataSource availableBundleIdentifiers][indexPath.row];
    
    // Setup with correct icon and snapshot.
    if (![XENResources launchpadIconsOnly]) {
        [cell setupWithSnapshotView:[self.dataSource snapshotImageForBundleIdentifier:bundleIdentifier] andIconView:[self.dataSource iconImageForBundleIdentifier:bundleIdentifier]];
    } else {
        [cell setupWithIconView:[self.dataSource iconImageForBundleIdentifier:bundleIdentifier]];
    }
    
    return cell;
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    XENlog(@"cell %ld was selected", (long)indexPath.row);
    NSString *bundleIdentifier = [self.dataSource availableBundleIdentifiers][indexPath.row];
    
    [self.dataSource requestAnimationToBundleIdentifier:bundleIdentifier];
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    UICollectionReusableView *reusableview = nil;
    
    if (kind == UICollectionElementKindSectionHeader) {
        UICollectionReusableView *headerview = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"headerView" forIndexPath:indexPath];
        
        if ([XENResources launchpadUseQuickDial])
            [headerview addSubview:self.headerController.view];
        
        reusableview = headerview;
    }
    
    if (kind == UICollectionElementKindSectionFooter) {
        UICollectionReusableView *footerview = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:@"footerView" forIndexPath:indexPath];
        
        reusableview = footerview;
    }
    
    return reusableview;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    
    if ([XENResources launchpadUseQuickDial]) {
        CGSize headerSize = CGSizeMake(SCREEN_WIDTH, [self.headerController viewHeight]+30);
        return headerSize;
    } else {
        return CGSizeMake(SCREEN_WIDTH, 1);
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section {
    CGSize headerSize = CGSizeMake(SCREEN_WIDTH, 1);
    return headerSize;
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [XENResources resetLockscreenDimTimer];
}

#pragma mark Inherited things

-(void)rotateToOrientation:(int)orient {
    self.headerController.view.frame = CGRectMake(0, 30, SCREEN_WIDTH, [self.headerController viewHeight]);
    
    KTCenterFlowLayout *notifLayout = (KTCenterFlowLayout*)self.collectionViewController.collectionView.collectionViewLayout;
    
    if (![XENResources launchpadIconsOnly]) {
        notifLayout.itemSize = CGSizeMake(SCREEN_MIN_LENGTH*0.40, SCREEN_MAX_LENGTH*0.40 + ((IS_IPAD ? 72 : 60)*[XENResources launchpadIconSize])/2);
        notifLayout.minimumInteritemSpacing = SCREEN_MIN_LENGTH*0.10;
        notifLayout.minimumLineSpacing = notifLayout.minimumInteritemSpacing/2;
    } else {
        notifLayout.itemSize = CGSizeMake((IS_IPAD ? 72 : 60)*[XENResources launchpadIconSize], (IS_IPAD ? 72 : 60)*[XENResources launchpadIconSize]);
        notifLayout.minimumInteritemSpacing = SCREEN_MIN_LENGTH*0.10;
        notifLayout.minimumLineSpacing = notifLayout.minimumInteritemSpacing/2;
        
        [notifLayout setSectionInset:UIEdgeInsetsMake(30.0, SCREEN_WIDTH*0.05, 10.0, SCREEN_WIDTH*0.05)];
    }
    
    [notifLayout invalidateLayout];
}

-(void)resetForScreenOff {
    
}

-(BOOL)wantsBlurredBackground {
    return [XENResources launchpadUseQuickDial];
}

-(NSString*)name {
    return [XENResources localisedStringForKey:@"Launchpad" value:@"Launchpad"];
}

-(NSString*)uniqueIdentifier {
    return @"com.matchstic.launchpad";
}

-(XENDeviceSupport)supportedDevices {
    return kSupportsAll;
}

-(void)resetViewForUnlock {
    // Clear any pre-existing snapshot data.
    [self.dataSource resetSnapshotCache];
    
    [super resetViewForUnlock];
}

-(void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
    // If we're not locked, can we kill everything?
    if (![XENResources isCurrentlyLocked]) {
        XENlog(@"Killing Launchpad due to memory pressure. Will rebuild on next lock.");
        
        self.dataSource = nil;
        
        [self.collectionViewController.view removeFromSuperview];
        self.collectionViewController = nil;
    }
}

-(void)dealloc {
    self.dataSource = nil;
    
    [self.collectionViewController.view removeFromSuperview];
    self.collectionViewController = nil;
}

@end
