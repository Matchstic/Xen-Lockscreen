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

#import "XENAdditionalController.h"
#import "XENPResources.h"
#include <sys/sysctl.h>
#import <objc/runtime.h>

#define cellIdentifier @"XENAdditionalCell"

@interface XENPAdditionalController ()

@end

@implementation XENPAdditionalController

-(id)specifiers {
    if (_specifiers == nil) {
        NSMutableArray *testingSpecs = [self loadSpecifiersFromPlistName:@"Additional" target:self];
        
        // Finished messing with specifiers
        _specifiers = testingSpecs;
        _specifiers = [self localizedSpecifiersForSpecifiers:_specifiers];
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

-(BOOL)deviceSupportsPeek {
    // Get hardware verison.
    size_t buflen = 0x80;
    char buf[buflen];
    
    sysctlbyname("hw.machine", buf, &buflen, NULL, 0);
    
    NSString *machineType = [NSString stringWithUTF8String:(buf ? buf : "")];
    
    if ([machineType rangeOfString:@"iPhone"].location != NSNotFound) {
        return YES;
    } else {
        return NO;
    }
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
    
    NSString *imageName = @"";
    NSString *title = @"TITLE";
    NSString *subtitle = @"SUBTITLE";
    
    BOOL interimPeekEnabled = [UIDevice currentDevice].systemVersion.floatValue < 10.0;
    BOOL interimThemesEnabled = [UIDevice currentDevice].systemVersion.floatValue < 10.0;
    
    switch (arg2.section) {
        case 0:
            // Peek
            imageName = @"Peek";
            title = [XENPResources localisedStringForKey:@"PEEK" value:@"Peek"];
            if ([self deviceSupportsPeek]) {
                subtitle = [XENPResources localisedStringForKey:@"PEEK_SUBTITLE" value:@"Glance at the time and notifications by raising your phone"];
            } else {
                subtitle = [XENPResources localisedStringForKey:@"PEEK_DISABLED_SUBTITLE" value:@"This is only available on devices that provide a proximity sensor"];
                cell.userInteractionEnabled = cell.textLabel.enabled = cell.detailTextLabel.enabled = NO;
                cell.imageView.alpha = 0.5;
            }
            
            cell.userInteractionEnabled = cell.textLabel.enabled = cell.detailTextLabel.enabled = interimPeekEnabled;
            
            break;
        case 1:
            // Theming
            imageName = @"Themes";
            title = [XENPResources localisedStringForKey:@"THEMING" value:@"Theming"];
            subtitle = [XENPResources localisedStringForKey:@"THEMING_SUBTITLE" value:@"Customise the overall look and feel of Xen"];
            
            cell.userInteractionEnabled = cell.textLabel.enabled = cell.detailTextLabel.enabled = interimThemesEnabled;
            
            break;
        case 2:
            // Welcome
            imageName = @"Welcome";
            title = [XENPResources localisedStringForKey:@"MORNING_SUMMARY" value:@"Morning Summary"];
            subtitle = [XENPResources localisedStringForKey:@"MORNING_SUMMARY_SUBTITLE" value:@"Displays useful information about the upcoming day after waking up"];
            break;
            
        default:
            break;
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
    
    UIViewController *controller = nil;
    
    BOOL interimPeekEnabled = [UIDevice currentDevice].systemVersion.floatValue < 10.0;
    BOOL interimThemesEnabled = [UIDevice currentDevice].systemVersion.floatValue < 10.0;
    
    switch (indexPath.section) {
        case 0: {
            // Peek
            if (interimPeekEnabled)
                controller = [[objc_getClass("XENPPeekController") alloc] init];
            break;
        } case 1:
            // Themes
            if (interimThemesEnabled)
                controller = [[objc_getClass("XENPThemeController") alloc] init];
            break;
        case 2:
            controller = [[objc_getClass("XENPWelcomeController") alloc] init];
            break;
            
        default:
            break;
    }
    
    if (controller) {
        [self pushController:controller animate:YES];
        
        UIBarButtonItem *newBackButton = [[UIBarButtonItem alloc] initWithTitle:[XENPResources localisedStringForKey:@"Back" value:@"Back"] style:UIBarButtonItemStylePlain target:nil action:nil];
        [[self navigationItem] setBackBarButtonItem:newBackButton];
    }
}

- (CGFloat)tableView:(id)arg1 heightForRowAtIndexPath:(id)arg2 {
    return 70;
}

@end
