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

#import "XENPCameraController.h"
#import "XENPResources.h"

@interface XENPCameraController ()

@end

@implementation XENPCameraController

-(id)specifiers {
    if (_specifiers == nil) {
        NSMutableArray *testingSpecs = [self loadSpecifiersFromPlistName:@"Camera" target:self];
        
        _specifiers = testingSpecs;
        _specifiers = [self localizedSpecifiersForSpecifiers:_specifiers];
        
        [self updateLocationCellIfNeeded];
    }
    
    return _specifiers;
}

-(void)updateLocationCellIfNeeded {
    id val = [XENPResources getPreferenceKey:@"slideToUnlockModeDirection"];
    int defaultVal = [UIDevice currentDevice].systemVersion.floatValue < 10.0 ? 0 : 3;
    int value = val ? [val intValue] : defaultVal;
    
    PSSpecifier *location = nil;
    
    for (PSSpecifier *spec in _specifiers) {
        if ([spec.properties[@"key"] isEqualToString:@"iOS10CameraPosition"]) {
            location = spec;
            break;
        }
    }
    
    if (value == 1 || value == 3)
        [location setProperty:[NSNumber numberWithBool:YES] forKey:@"enabled"];
    else {
        [location setProperty:[NSNumber numberWithBool:NO] forKey:@"enabled"];
        
        PSSpecifier *segmentHeader = nil;
        
        for (PSSpecifier *spec in _specifiers) {
            if ([[spec.properties allKeys] containsObject:@"segmentHeader"]) {
                segmentHeader = spec;
                break;
            }
        }
        
        NSString *str = @"When using the left or right unlock direction, the Camera page can only be placed at the opposite end to where unlocking occurs.";
        str = [XENPResources localisedStringForKey:str value:str];
        
        [segmentHeader setProperty:str forKey:@"footerText"];
        
        [self reloadSpecifier:segmentHeader animated:YES];
    }
    
    [self reloadSpecifier:location animated:YES];
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

-(void)setPreferenceValue:(id)value specifier:(PSSpecifier*)specifier {
    [XENPResources setPreferenceKey:specifier.properties[@"key"] withValue:value];
    
    // Also fire off the custom cell notification.
    CFStringRef toPost = (__bridge CFStringRef)specifier.properties[@"PostNotification"];
    if (toPost) CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), toPost, NULL, NULL, YES);
}

@end
