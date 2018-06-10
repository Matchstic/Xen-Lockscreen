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

#import "XENPLaunchpadController.h"
#import "XENPResources.h"
#import "XENLaunchpadCollectionCell.h"

@interface XENPLaunchpadController ()

@end

static XENPLaunchpadController *instance;

@implementation XENPLaunchpadController

+(instancetype)sharedInstance {
    if (!instance) {
        NSLog(@"NSTANCE NOT EXIST");
    }
    return instance;
}

-(instancetype)init {
    self = [super init];
    
    if (self) {
        instance = self;
    }
    
    return self;
}

-(id)specifiers {
    if (_specifiers == nil) {
        NSMutableArray *testingSpecs = [self loadSpecifiersFromPlistName:@"Launchpad" target:self];
        
        // Add Quick Dialler if available.
        BOOL deviceSupportsQuickDialler = YES;
        NSString *deviceType = [UIDevice currentDevice].model;
        
        // Only iPhone can define favourite contacts.
        if (![deviceType isEqualToString:@"iPhone"]){
            deviceSupportsQuickDialler = NO;
        }
        
        if (deviceSupportsQuickDialler) {
            PSSpecifier *group = [PSSpecifier groupSpecifierWithName:@""];
            NSString *str = @"Quick Dialler allows access to contacts marked as Favourite in the Phone app.";
            [group setProperty:[XENPResources localisedStringForKey:str value:str] forKey:@"footerText"];
            
            // Create QD spec.
            PSSpecifier *spec = [PSSpecifier preferenceSpecifierNamed:[XENPResources localisedStringForKey:@"Use Quick Dialler" value:@"Use Quick Dialler"] target:self set:@selector(setPreferenceValue:specifier:) get:@selector(readPreferenceValue:) detail:nil cell:PSSwitchCell edit:nil];
            [spec setProperty:@"launchpadUseQuickDial" forKey:@"key"];
            [spec setProperty:[NSNumber numberWithBool:YES] forKey:@"enabled"];
            [spec setProperty:@"com.matchstic.xen" forKey:@"defaults"];
            [spec setProperty:@"com.matchstic.xen/settingschanged" forKey:@"PostNotification"];
            [spec setProperty:[NSNumber numberWithBool:YES] forKey:@"default"];
            
            // We temporarily will disable QD on iOS 10.
            if ([UIDevice currentDevice].systemVersion.floatValue >= 10) {
                [spec setProperty:[NSNumber numberWithBool:NO] forKey:@"enabled"];
            }
            
            [testingSpecs insertObject:spec atIndex:0];
            [testingSpecs insertObject:group atIndex:0];
        }
        
        _specifiers = testingSpecs;
        _specifiers = [self localizedSpecifiersForSpecifiers:_specifiers];
        
        [self updateSpecifiersForiOS10InterimEnabledness];
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

-(void)updateSpecifiersForiOS10InterimEnabledness {
    if ([UIDevice currentDevice].systemVersion.floatValue < 10.0) {
        return;
    }
    
    // In fact, all that does work is the dim adjustment and debug logging.
    for (PSSpecifier *spec in _specifiers) {
        if ([spec.properties[@"key"] isEqualToString:@"launchpadRequiresPasscode"]) {
            if (spec.cellType != PSGroupCell) {
                [spec setProperty:[NSNumber numberWithBool:NO] forKey:@"enabled"];
                [self reloadSpecifier:spec animated:NO];
            }
            
        }
    }
}

-(CGFloat)tableView:(UITableView*)view heightForRowAtIndexPath:(NSIndexPath*)indexPath {
    UITableViewCell *cell = [self tableView:view cellForRowAtIndexPath:indexPath];
    
    if ([cell respondsToSelector:@selector(refreshCollectionView)]) {
        return [(XENLaunchpadCollectionCell*)cell preferredHeightForWidth:cell.frame.size.width];
    } else {
        return [super tableView:view heightForRowAtIndexPath:indexPath];
    }
}

-(void)setPreferenceValue:(id)value specifier:(PSSpecifier*)specifier {
    [XENPResources setPreferenceKey:specifier.properties[@"key"] withValue:value];
    
    // Also fire off the custom cell notification.
    CFStringRef toPost = (__bridge CFStringRef)specifier.properties[@"PostNotification"];
    if (toPost) CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), toPost, NULL, NULL, YES);
}

@end
