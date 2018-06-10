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

#import "XENPPeekController.h"
#import "XENPResources.h"

@interface XENPPeekController ()

@end

@implementation XENPPeekController

-(id)specifiers {
    if (_specifiers == nil) {
        NSMutableArray *testingSpecs = [self loadSpecifiersFromPlistName:@"Peek" target:self];
        
        _specifiers = testingSpecs;
        _specifiers = [self localizedSpecifiersForSpecifiers:_specifiers];
        
        [self updateEnabledForQuickGlance];
    }
    
    return _specifiers;
}

-(void)updateEnabledForQuickGlance {    
    id val = [XENPResources getPreferenceKey:@"peekShowDarkUI"];
    BOOL output = val ? [val boolValue] : YES;
    
    // Cells are 8 and 9, section 4
    
    PSSpecifier *statusBar = [_specifiers objectAtIndex:8];
    [statusBar setProperty:[NSNumber numberWithBool: output] forKey:@"enabled"];
    
    PSSpecifier *notifications = [_specifiers objectAtIndex:9];
    [notifications setProperty:[NSNumber numberWithBool: output] forKey:@"enabled"];
    
    [self reloadSpecifier:statusBar animated:YES];
    [self reloadSpecifier:notifications animated:YES];
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
    
    if ([specifier.properties[@"key"] isEqualToString:@"peekShowDarkUI"]) {
        [self updateEnabledForQuickGlance];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"com.matchstic.xen/previewPeekUpdate" object:nil];
    
    // Also fire off the custom cell notification.
    CFStringRef toPost = (__bridge CFStringRef)specifier.properties[@"PostNotification"];
    if (toPost) CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), toPost, NULL, NULL, YES);
}

@end
