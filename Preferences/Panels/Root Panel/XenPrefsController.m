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

#import "XenPrefsController.h"
#import <Preferences/PSSpecifier.h>
#include <time.h>
#include <stdio.h>
#import "XENPResources.h"
#import "XENPHeaderView.h"
#import <objc/runtime.h>

#define cellIdentifier @"XENRootCell"

@implementation XenPrefsController

-(id)specifiers {
    if (_specifiers == nil) {
        NSLog(@"Loading specifiers...");
        NSMutableArray *testingSpecs = [self loadSpecifiersFromPlistName:@"Root" target:self];
        
        // Finished messing with specifiers
        _specifiers = testingSpecs;
        _specifiers = [self localizedSpecifiersForSpecifiers:_specifiers];
        
        NSLog(@"Loaded.");
    }
    
    return _specifiers;
}

-(NSArray *)localizedSpecifiersForSpecifiers:(NSArray *)s {
    int i;
    for (i=0; i<[s count]; i++) {
        if ([[s objectAtIndex: i] name]) {
            [[s objectAtIndex: i] setName:[[self bundle] localizedStringForKey:[[s objectAtIndex: i] name] value:[[s objectAtIndex: i] name] table:nil]];
        }
        if ([[s objectAtIndex: i] titleDictionary]) {
            NSMutableDictionary *newTitles = [[NSMutableDictionary alloc] init];
            for(NSString *key in [[s objectAtIndex: i] titleDictionary]) {
                [newTitles setObject: [[self bundle] localizedStringForKey:[[[s objectAtIndex: i] titleDictionary] objectForKey:key] value:[[[s objectAtIndex: i] titleDictionary] objectForKey:key] table:nil] forKey: key];
            }
            [[s objectAtIndex: i] setTitleDictionary: newTitles];
        }
    }
    
    return s;
}

- (id)tableView:(UITableView*)arg1 cellForRowAtIndexPath:(NSIndexPath*)arg2 {
    NSLog(@"Asking for cell %ld,%ld", (long)arg2.row, (long)arg2.section);
    
    //UITableViewCell *cell = [super tableView:arg1 cellForRowAtIndexPath:arg2];
    UITableViewCell *cell = [arg1 dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    cell.contentView.alpha = 1.0;
    
    NSString *imageName = @"";
    NSString *title = @"TITLE";
    NSString *subtitle = @"SUBTITLE";
    
    switch (arg2.section) {
        case 0:
            // Home page
            cell.contentView.alpha = 0.9;
            imageName = @"Home";
            title = [XENPResources localisedStringForKey:@"HOME_PAGE" value:@"Home Page"];
            subtitle = [XENPResources localisedStringForKey:@"HOME_PAGE_SUBTITLE" value:@"Adjust default components"];
            break;
        case 1:
            // Content page
            imageName = @"Content";
            title = [XENPResources localisedStringForKey:@"CONTENT_PAGES" value:@"Content Pages"];
            subtitle = [XENPResources localisedStringForKey:@"CONTENT_PAGES_SUBTITLE" value:@"Extend lockscreen functionality"];
            break;
        case 2:
            // Advanced
            imageName = @"Additional";
            title = [XENPResources localisedStringForKey:@"ADDITIONAL_FEATURES" value:@"Additional Features"];
            subtitle = [XENPResources localisedStringForKey:@"ADDITIONAL_FEATURES_SUBTITLE" value:@"Supplement Apple's offerings"];
            break;
        case 3:
            // Advanced
            imageName = @"Advanced";
            title = [XENPResources localisedStringForKey:@"ADVANCED" value:@"Advanced"];
            subtitle = [XENPResources localisedStringForKey:@"ADVANCED_SUBTITLE" value:@"Fine-tune your experience"];
            break;
        case 4:
            // Support/credits
            imageName = @"Support";
            title = [XENPResources localisedStringForKey:@"SUPPORT" value:@"Support"];
            subtitle = [XENPResources localisedStringForKey:@"SUPPORT_SUBTITLE" value:@"Contact the developer"];
            break;
            
        default:
            break;
    }
    
    UIImage *cellImage = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"/Library/PreferenceBundles/XenPrefs.bundle/CellIcons/%@%@", imageName, [XENPResources imageSuffix]]];
    cell.imageView.image = cellImage;
    
    cell.textLabel.text = title;
    cell.detailTextLabel.text = subtitle;
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    UIViewController *controller = nil;
    
    switch (indexPath.section) {
        case 0: {
            // Home page
            controller = [[objc_getClass("XENPHomeController") alloc] init];
            break;
        } case 1:
            // Content page
            controller = [[objc_getClass("XENPContentController") alloc] init];
            break;
        case 2:
            // Additional
            controller = [[objc_getClass("XENPAdditionalController") alloc] init];
            break;
        case 3:
            // Advanced
            controller = [[objc_getClass("XENPAdvancedController") alloc] init];
            break;
        case 4:
            // Support/credits
            controller = [[objc_getClass("XENPSupportController") alloc] init];
            break;
            
        default:
            break;
    }
    
    if (controller) {
        [self pushController:controller animate:YES];
        
        UIBarButtonItem *newBackButton = [[UIBarButtonItem alloc] initWithTitle:@"Back"
                                         style:UIBarButtonItemStylePlain
                                        target:nil
                                        action:nil];
        [[self navigationItem] setBackBarButtonItem:newBackButton];
    }
}

- (CGFloat)tableView:(id)arg1 heightForRowAtIndexPath:(id)arg2 {
    return 70;
}

-(void)viewWillAppear:(BOOL)view {
    if (!self.table.tableHeaderView) {
        // Add header view.
        XENPHeaderView *view = [[XENPHeaderView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 200)];
        [self.table setTableHeaderView:view];
        
        [self.table insertSubview:view atIndex:0];
    }
    
    if ([self respondsToSelector:@selector(navigationItem)]) {
        [[self navigationItem] setTitle:@""];
    }
    
    // Add share button.
    self.navigationItem.rightBarButtonItems = @[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(shareTweak:)]];
    
    [super viewWillAppear:view];
}

-(void)shareTweak:(UIBarButtonItem*)item {
    NSString *message = @"I'm using Xen Lockscreen to supercharge my lockscreen! Check it out on Cydia:";
    NSURL *url = [NSURL URLWithString:@"http://cydia.saurik.com/package/com.matchstic.xen/"];
    
    UIActivityViewController *viewController = [[UIActivityViewController alloc] initWithActivityItems:@[message, url] applicationActivities:nil];
    viewController.popoverPresentationController.barButtonItem = item;
    [self.parentController presentViewController:viewController animated:YES completion:nil];
}

@end
