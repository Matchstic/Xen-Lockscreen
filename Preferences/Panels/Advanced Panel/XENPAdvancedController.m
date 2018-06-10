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

#import "XENPAdvancedController.h"
#import "XENPResources.h"

@interface XENPAdvancedController ()

@end

@implementation XENPAdvancedController

-(id)specifiers {
    if (_specifiers == nil) {
        NSMutableArray *testingSpecs = [self loadSpecifiersFromPlistName:@"Advanced" target:self];
        
        // Iterate over the specifiers. If marked as not working on this version of iOS, remove from specs.
        for (PSSpecifier *spec in [testingSpecs copy]) {
            NSNumber *minVer = [spec.properties objectForKey:@"minVer"];
            NSNumber *maxVer = [spec.properties objectForKey:@"maxVer"];
            
            if (!minVer) {
                // This pref doesn't specify a min.
                continue;
            }
            
            if ([UIDevice currentDevice].systemVersion.floatValue < minVer.floatValue) {
                [testingSpecs removeObject:spec];
            }
            
            if (maxVer) {
                // Only check max if present.
                if ([UIDevice currentDevice].systemVersion.floatValue > maxVer.floatValue) {
                    [testingSpecs removeObject:spec];
                }
            }
        }
        
        _specifiers = testingSpecs;
        _specifiers = [self localizedSpecifiersForSpecifiers:_specifiers];
        
        [self updateBlurPasscodeCellIfNeeded];
        [self updateSpecifiersForiOS10InterimEnabledness];
    }
    
    return _specifiers;
}

-(void)updateBlurPasscodeCellIfNeeded {
    id val = [XENPResources getPreferenceKey:@"useBlurredBackground"];
    BOOL value = val ? [val boolValue] : YES;
    
    PSSpecifier *passcodeBlur = nil;
    
    for (PSSpecifier *spec in _specifiers) {
        if ([spec.properties[@"key"] isEqualToString:@"useBlurredPasscodeBackground"]) {
            passcodeBlur = spec;
            break;
        }
    }
        
    [passcodeBlur setProperty:[NSNumber numberWithBool:value] forKey:@"enabled"];
    [self reloadSpecifier:passcodeBlur animated:YES];
}

-(void)updateSpecifiersForiOS10InterimEnabledness {
    // As of 3/1/17, the following do not function at all:
    // Some visibility items.
    // Background blur.
    
    if ([UIDevice currentDevice].systemVersion.floatValue < 10.0) {
        return;
    }
    
    // In fact, all that does work is the dim adjustment and debug logging.
    for (PSSpecifier *spec in _specifiers) {
        if (![spec.properties[@"key"] isEqualToString:@"lockScreenIdleTime"] &&
            ![spec.properties[@"key"] isEqualToString:@"debugLogging"] &&
            ![spec.properties[@"key"] isEqualToString:@"hideSlideIndicators"] &&
            ![spec.properties[@"key"] isEqualToString:@"hideClock"] &&
            ![spec.properties[@"key"] isEqualToString:@"hidePageControlDots"]) {
            
            if (spec.cellType != PSGroupCell) {
                [spec setProperty:[NSNumber numberWithBool:NO] forKey:@"enabled"];
                [self reloadSpecifier:spec animated:NO];
            }
            
        }
    }
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
    
    if ([specifier.properties[@"key"] isEqualToString:@"useBlurredBackground"]) {
        [self updateBlurPasscodeCellIfNeeded];
    }
    
    // Also fire off the custom cell notification.
    CFStringRef toPost = (__bridge CFStringRef)specifier.properties[@"PostNotification"];
    if (toPost) CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), toPost, NULL, NULL, YES);
}

@end
