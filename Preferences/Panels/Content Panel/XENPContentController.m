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

#import "XENPContentController.h"
#import "XENPResources.h"
#import <objc/runtime.h>

#define cellIdentifier @"XENContentCell"

@interface XENPContentController ()

@end

@implementation XENPContentController

-(instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if (self) {
        // Setup data source to also load from filesystem where appropriate
        NSMutableArray *dataSourceMutable = [NSMutableArray array];
        
        /*
         * Launchpad
         * Toggles
         * Weather
         * Widgets
         * News
         * Stocks
         * Calendar
         */
        
        BOOL interimTogglesEnabled = [UIDevice currentDevice].systemVersion.floatValue < 10.0;
        BOOL interimNCWidgetsEnabled = [UIDevice currentDevice].systemVersion.floatValue < 10.0;
        
        [dataSourceMutable addObject:@{@"name": @"Launchpad", @"image": @"Launchpad", @"subtitle": @"Quick access to apps directly from the lockscreen", @"controller": @"XENPLaunchpadController", @"enabled": [NSNumber numberWithBool:YES]}];
        [dataSourceMutable addObject:@{@"name": @"Toggles", @"image": @"Toggles", @"subtitle": @"Change device settings, and access Control Centre shortcuts", @"controller": @"XENPTogglesController", @"enabled": [NSNumber numberWithBool:interimTogglesEnabled]}];
        [dataSourceMutable addObject:@{@"name": @"Calendar", @"image": @"Calendar", @"subtitle": @"Glance at the events scheduled for today, and throughout the week", @"controller": @"XENPCalendarController", @"enabled": [NSNumber numberWithBool:YES]}];
        [dataSourceMutable addObject:@{@"name": @"Weather", @"image": @"Weather", @"subtitle": @"View the current forecast, and a preview of the coming week", @"controller": @"XENPWeatherController", @"enabled": [NSNumber numberWithBool:YES]}];
        [dataSourceMutable addObject:@{@"name": @"NC Widgets", @"image": @"NCWidgets", @"subtitle": @"View widgets directly on the lockscreen" , @"controller": @"XENPWidgetsController", @"enabled": [NSNumber numberWithBool:interimNCWidgetsEnabled]}];
        
        if ([UIDevice currentDevice].systemVersion.floatValue >= 10.0) {
            [dataSourceMutable addObject:@{@"name": @"iOS 10 Camera", @"image": @"Camera", @"subtitle": @"Access the stock Camera page by swiping" , @"controller": @"XENPCameraController", @"enabled": [NSNumber numberWithBool:YES]}];
        }
        
        [dataSourceMutable addObject:@{@"name": @"Media", @"image": @"Media", @"subtitle": @"Control and view details of currently playing media", @"controller": @"XENPMusicController", @"enabled": [NSNumber numberWithBool:NO]}];
        
        _dataSource = [dataSourceMutable copy];
    }
    
    return self;
}

-(id)specifiers {
    if (_specifiers == nil) {
        NSMutableArray *testingSpecs = [self loadSpecifiersFromPlistName:@"Content" target:self];
        
        // Add iOS 10+ specific pages.
        if ([UIDevice currentDevice].systemVersion.floatValue >= 10.0) {
            PSSpecifier *group = [PSSpecifier groupSpecifierWithName:@""];
            
            [testingSpecs addObject:group];
            
            // Camera.
            PSSpecifier *cameraSpec = [PSSpecifier preferenceSpecifierNamed:[XENPResources localisedStringForKey:@"Camera" value:@"Camera"] target:self set:nil get:nil detail:nil cell:PSLinkCell edit:nil];
            
            [testingSpecs addObject:cameraSpec];
        }
        
        _specifiers = testingSpecs;
    }
    
    return _specifiers;
}

-(void)viewWillAppear:(BOOL)view {
    if ([self respondsToSelector:@selector(navigationItem)]) {
        [[self navigationItem] setTitle:[XENPResources localisedStringForKey:@"Content Pages" value:@"Content Pages"]];
    }
    
    // Add share button.
    self.navigationItem.rightBarButtonItems = @[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(openEditPanel:)]];
    
    [super viewWillAppear:view];
}

- (id)tableView:(UITableView*)arg1 cellForRowAtIndexPath:(NSIndexPath*)arg2 {
    UITableViewCell *cell = [arg1 dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    cell.contentView.alpha = 1.0;
    cell.userInteractionEnabled = cell.textLabel.enabled = cell.detailTextLabel.enabled = YES;
    cell.imageView.alpha = 1.0;
    
    NSDictionary *dict = [_dataSource objectAtIndex:arg2.section];
    
    NSString *imageName = dict[@"image"];
    NSString *title = [XENPResources localisedStringForKey:dict[@"name"] value:dict[@"name"]];
    NSString *subtitle = [XENPResources localisedStringForKey:dict[@"subtitle"] value:dict[@"subtitle"]];
    
    BOOL enabled = dict[@"enabled"] ? [dict[@"enabled"] boolValue] : YES;
    
    if (!enabled) {
        cell.userInteractionEnabled = cell.textLabel.enabled = cell.detailTextLabel.enabled = NO;
        cell.imageView.alpha = 0.5;
    }
    
    UIImage *cellImage = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"/Library/PreferenceBundles/XenPrefs.bundle/CellIcons/%@%@", imageName, [XENPResources imageSuffix]]];
    cell.imageView.image = cellImage;
    
    cell.textLabel.text = title;
    cell.detailTextLabel.text = subtitle;
    cell.detailTextLabel.numberOfLines = 2;
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSDictionary *dict = [_dataSource objectAtIndex:indexPath.section];
    NSString *className = dict[@"controller"];
    const char *class = [className cStringUsingEncoding:NSUTF8StringEncoding];
    
    NSLog(@"Loading up class: %s", class);
    
    UIViewController *controller = [[objc_getClass(class) alloc] init];
    
    if (controller) {
        [self pushController:controller animate:YES];
    }
}

- (CGFloat)tableView:(id)arg1 heightForRowAtIndexPath:(id)arg2 {
    return 70;
}

-(void)openEditPanel:(id)sender {
    // open Edit pane.
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.matchstic.xen/showcontentedit"), NULL, NULL, YES);
}

-(void)closeContentPanel {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

@end
