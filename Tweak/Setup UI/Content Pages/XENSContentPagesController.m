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

#import "XENSContentPagesController.h"
#import "XENSPeekController.h"
#import "XENSWelcomeController.h"
#import "XENSetupWindow.h"

@interface XENSContentPagesController ()

@end

@implementation XENSContentPagesController

-(NSString*)headerTitle {
    return [XENResources localisedStringForKey:@"Content Pages" value:@"Content Pages"];
}

-(NSString*)cellReuseIdentifier {
    return [super cellReuseIdentifier];
}

-(NSInteger)rowsToDisplay {
    return 1;
}

-(UIImage*)footerImage {
    UIImage *img = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"/Library/Application Support/Xen/Setup/ContentPages%@", [XENResources imageSuffix]]];
    
    return [img imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
}
-(NSString*)footerTitle {
    return [XENResources localisedStringForKey:@"What are Content Pages?" value:@"What are Content Pages?"];
}

-(NSString*)footerBody {
    return [XENResources localisedStringForKey:@"Xen Lockscreen allows for multiple pages on the lockscreen, which each display different content." value:@"Xen Lockscreen allows for multiple pages on the lockscreen, which each display different content."];
}

-(NSString*)titleForCellAtIndex:(NSInteger)index {
    return [XENResources localisedStringForKey:@"Customise Pages" value:@"Customise Pages"];
}

-(void)userDidSelectCellAtIndex:(NSInteger)index {
    [self launchEditPanel];
}

-(UIViewController*)controllerToSegueForIndex:(NSInteger)index {
    if ([XENResources deviceSupportsPeek]) {
        return [[XENSPeekController alloc] initWithStyle:UITableViewStyleGrouped];
    } else {
        return [[XENSWelcomeController alloc] initWithStyle:UITableViewStyleGrouped];
    }
}

-(BOOL)shouldSegueToNewControllerAfterSelectingCell {
    return NO;
}

-(BOOL)shouldCheckmarkAfterSelectingCell {
    return NO;
}

-(BOOL)shouldDisplayNextButton {
    return YES;
}

-(void)viewDidLoad {
    [super viewDidLoad];
    
    [[self navigationItem].rightBarButtonItem setEnabled:YES];
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [super tableView:tableView
                       cellForRowAtIndexPath:indexPath];
    
    cell.textLabel.textColor = [[UIApplication sharedApplication].keyWindow tintColor];
    cell.textLabel.tintColor = [[UIApplication sharedApplication].keyWindow tintColor];
    cell.tintColor = [[UIApplication sharedApplication].keyWindow tintColor];
    
    cell.accessoryType = UITableViewCellAccessoryDetailButton;
    
    return cell;
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.textLabel.textColor = [[UIApplication sharedApplication].keyWindow tintColor];
}

-(void)launchEditPanel {
    //[XENResources setLoadingInAsEditMode:YES];
    [XENResources setIsLoadedEditFromSetup:YES];
    [XENResources setIsPageEditInSetup:YES];
    
    self.pageController = [[XENPageArrangementController alloc] init];
    self.pageController.delegate = nil;
    
    UIWindow *contentEditWindow = [XENResources contentEditWindow];
    contentEditWindow.frame = CGRectMake(0, SCREEN_MAX_LENGTH, SCREEN_MIN_LENGTH, SCREEN_MAX_LENGTH);
    [contentEditWindow addSubview:self.pageController.view];
    contentEditWindow.windowLevel = 1085;
    
    [contentEditWindow makeKeyAndVisible];
    
    [XENResources moveUpDownWallpaperWindowForSetup:NO];
    
    UIWindow *wallpaperWindow = [XENResources wallpapeWindow];
    wallpaperWindow.frame = CGRectMake(0, SCREEN_MAX_LENGTH, SCREEN_MIN_LENGTH, SCREEN_MAX_LENGTH);
    
    [UIView animateWithDuration:0.25 animations:^{
        contentEditWindow.frame = CGRectMake(0, 0, SCREEN_MIN_LENGTH, SCREEN_MAX_LENGTH);
        wallpaperWindow.frame = CGRectMake(0, 0, SCREEN_MIN_LENGTH, SCREEN_MAX_LENGTH);
    }];
}

-(void)viewWillDisappear:(BOOL)animated {
    [self.pageController.view removeFromSuperview];
    self.pageController = nil;
    
    [XENResources setIsPageEditInSetup:NO];
    
    [super viewWillDisappear:animated];
}

-(void)dealloc {
    [self.pageController.view removeFromSuperview];
    self.pageController = nil;
}

@end
