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

#import "XENLaunchpadCollectionCell.h"
#import "XENLaunchpadColViewCell.h"
#import "XENPLaunchpadController.h"
#import "XENPResources.h"

#define is_IPAD (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
#define interiemSpacing 10

@implementation XENLaunchpadCollectionCell

// Needed to stop a crash when we don't correctly inherit methods...
+(int)cellStyle {
    return UITableViewCellStyleDefault;
}

- (instancetype)initWithStyle:(int)style reuseIdentifier:(NSString *)reuseIdentifier specifier:(PSSpecifier *)specifier {
	self = [super initWithStyle:style reuseIdentifier:reuseIdentifier specifier:specifier];
    
    if (self) {
        // Build up our UICollectionViewController.
        [self loadDataSource];
        
        // Create controller.
        DraggableCollectionViewFlowLayout *layout = [[DraggableCollectionViewFlowLayout alloc] init];
        layout.scrollDirection = UICollectionViewScrollDirectionVertical;
        layout.minimumLineSpacing = 15;
        layout.minimumInteritemSpacing = interiemSpacing;
        
        self.collectionView = [[UICollectionViewController alloc] initWithCollectionViewLayout:layout];
        self.collectionView.collectionView.backgroundColor = [UIColor clearColor];
        self.collectionView.collectionView.showsVerticalScrollIndicator = NO;
        self.collectionView.collectionView.bounces = YES;
        self.collectionView.collectionView.delegate = self;
        self.collectionView.collectionView.dataSource = self;
        self.collectionView.collectionView.clipsToBounds = NO;
        self.collectionView.view.clipsToBounds = NO;
        self.collectionView.collectionView.draggable = YES;
        
        [self.collectionView.collectionView registerClass:[XENLaunchpadColViewCell class] forCellWithReuseIdentifier:@"lcell"];
        [self.contentView addSubview:self.collectionView.collectionView];
        
        [self.collectionView.collectionView reloadData];
    }
    return self;
}

- (id)initWithSpecifier:(PSSpecifier *)specifier {
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell" specifier:specifier];
    return self;
}

-(void)loadDataSource {
    self.collectionDataSource = [[XENPResources getPreferenceKey:@"launchpadIdentifiers"] mutableCopy];
    if (!self.collectionDataSource)
        self.collectionDataSource = [@[@"com.apple.MobileSMS", @"com.apple.Preferences", @"com.apple.calculator", @"com.apple.camera", @"com.apple.Maps"] mutableCopy];
    
    [self.collectionDataSource addObject:@"<blank>"];
}

-(void)refreshCollectionView {
    // Reload data source.
    [self loadDataSource];
    
    // Refresh collection view.
    [self.collectionView.collectionView reloadData];
    
    [[XENPLaunchpadController sharedInstance] reloadSpecifiers];
}

-(void)layoutSubviews {
    [super layoutSubviews];
    
    self.collectionView.collectionView.frame = CGRectMake(self.frame.size.width * 0.05, 0, self.frame.size.width * 0.9, self.frame.size.height);
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self.collectionDataSource count]; // We need to have a cell explicitly for adding a new cell.
}

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    // If it's the last cell, that one can't be edited, and will always be the one to be tapped.
    XENLaunchpadColViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"lcell" forIndexPath:indexPath];
    
    NSString *identifier = self.collectionDataSource[indexPath.row];
    
    [cell initialiseForIdentifier:identifier];
    cell.delegate = self;
    
    return cell;
}

- (CGFloat)preferredHeightForWidth:(CGFloat)arg1 {
    [self loadDataSource];
    
    arg1 *= 0.9;
    
	// Return a custom cell height.
    CGFloat cellsPerLine = floorf((arg1 / (65 + interiemSpacing)));
    float lines = ceilf(self.collectionDataSource.count / cellsPerLine);
    
    return (65 * lines) + (15 * (lines - 1)) + 7;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(65, 65);
}

- (void)collectionView:(UICollectionView *)collectionView moveItemAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
    NSString *identifier = [self.collectionDataSource objectAtIndex:fromIndexPath.row];
    
    if (toIndexPath.row < fromIndexPath.row) {
        [self.collectionDataSource insertObject:identifier atIndex:toIndexPath.row];
        [self.collectionDataSource removeObjectAtIndex:fromIndexPath.row+1];
    } else {
        [self.collectionDataSource insertObject:identifier atIndex:toIndexPath.row+1];
        [self.collectionDataSource removeObjectAtIndex:fromIndexPath.row];
    }
    
    NSLog(@"self.collectiondataSource == %@", self.collectionDataSource);
    
    // Save out the changes.
    NSMutableArray *mutable = [self.collectionDataSource mutableCopy];
    [mutable removeObject:@"<blank>"];
    
    [XENPResources setPreferenceKey:@"launchpadIdentifiers" withValue:mutable];
}

- (BOOL)collectionView:(UICollectionView *)collectionView canMoveItemAtIndexPath:(NSIndexPath *)indexPath {
    XENLaunchpadColViewCell *cell = (XENLaunchpadColViewCell*)[self collectionView:collectionView cellForItemAtIndexPath:indexPath];
    
    if ([cell.identifer isEqualToString:@"<blank>"])
        return NO;
    else
        return YES;
}

- (BOOL)collectionView:(UICollectionView *)collectionView canMoveItemAtIndexPath:(NSIndexPath *)indexPath toIndexPath:(NSIndexPath *)toIndexPath {
    XENLaunchpadColViewCell *cell = (XENLaunchpadColViewCell*)[self collectionView:collectionView cellForItemAtIndexPath:toIndexPath];
    
    if ([cell.identifer isEqualToString:@"<blank>"])
        return NO;
    else
        return YES;
}

@end
