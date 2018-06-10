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

#import "XENPGroupedNotificationsController.h"
#import "XENPResources.h"

@interface XENPGroupedNotificationsController ()

@end

static XENPGroupedNotificationsController __weak *_shared;

@implementation XENPGroupedNotificationsController

-(instancetype)init {
    self = [super init];
    
    if (self) {
        CFNotificationCenterRef r = CFNotificationCenterGetDarwinNotifyCenter();
        CFNotificationCenterAddObserver(r, NULL, XENPGroupedSettingsChanged, CFSTR("com.matchstic.xen/settingschanged"), NULL, 0);
        
        _shared = self;
    }
    
    return self;
}

-(void)dealloc {
    _shared = nil;
}

-(id)specifiers {
    if (_specifiers == nil) {
        NSMutableArray *testingSpecs = [self loadSpecifiersFromPlistName:@"Grouping" target:self];
        
        _specifiers = testingSpecs;
        _specifiers = [self localizedSpecifiersForSpecifiers:_specifiers];
        
        id value = [XENPResources getPreferenceKey:@"useGroupedNotifications"];
        BOOL actual = (value ? [value boolValue] : YES);
        
        PSSpecifier *spec = [_specifiers objectAtIndex:3];
        
        [spec setProperty:[NSNumber numberWithBool:actual] forKey:@"enabled"];
    }
    
    return _specifiers;
}

-(void)configureAutoOpenSpecifier {
    id value = [XENPResources getPreferenceKey:@"useGroupedNotifications"];
    BOOL actual = (value ? [value boolValue] : YES);
    
    PSSpecifier *spec = [self specifierAtIndex:3];
    
    [spec setProperty:[NSNumber numberWithBool:actual] forKey:@"enabled"];
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

static void XENPGroupedSettingsChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    // Settings changed; reload specifiers.
    if (_shared) {
        [_shared configureAutoOpenSpecifier];
        [_shared reloadSpecifierAtIndex:3 animated:YES];
    }
}

@end
