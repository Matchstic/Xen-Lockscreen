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

#import "XENPResources.h"
#include <notify.h>

static NSBundle *strings;

@implementation XENPResources

+(NSString*)localisedStringForKey:(NSString*)key value:(NSString*)val {
    if (!strings) {
        strings = [NSBundle bundleWithPath:@"/Library/PreferenceBundles/XenPrefs.bundle"];
    }
    return [strings localizedStringForKey:key value:val table:nil];
}

+(NSString*)imageSuffix {
    NSString *suffix = @"";
    switch ((int)[UIScreen mainScreen].scale) {
        case 2:
            suffix = @"@2x";
            break;
        case 3:
            suffix = @"@3x";
            break;
            
        default:
            break;
    }
    
    return [NSString stringWithFormat:@"%@.png", suffix];
}

+(void)setPreferenceKey:(NSString*)key withValue:(id)value {
    if (!key || !value) {
        NSLog(@"Not setting value, as one of the arguments is null");
    }
    
    CFPreferencesAppSynchronize(CFSTR("com.matchstic.xen"));
    NSMutableDictionary *settings = [(__bridge NSDictionary *)CFPreferencesCopyMultiple(CFPreferencesCopyKeyList(CFSTR("com.matchstic.xen"), kCFPreferencesCurrentUser, kCFPreferencesAnyHost), CFSTR("com.matchstic.xen"), kCFPreferencesCurrentUser, kCFPreferencesAnyHost) mutableCopy];
    
    [settings setObject:value forKey:key];
    
    // Write to CFPreferences
    CFPreferencesSetValue ((__bridge CFStringRef)key, (__bridge CFPropertyListRef)value, CFSTR("com.matchstic.xen"), kCFPreferencesCurrentUser, kCFPreferencesCurrentHost);
    
    [settings writeToFile:@"/var/mobile/Library/Preferences/com.matchstic.xen.plist" atomically:YES];
    
    // Notify that we've changed!
    CFStringRef toPost = (__bridge CFStringRef)@"com.matchstic.xen/settingschanged";
    if (toPost) CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), toPost, NULL, NULL, YES);
}

+(id)getPreferenceKey:(NSString*)key {
    CFPreferencesAppSynchronize(CFSTR("com.matchstic.xen"));
    
    NSDictionary *settings = (__bridge NSDictionary *)CFPreferencesCopyMultiple(CFPreferencesCopyKeyList(CFSTR("com.matchstic.xen"), kCFPreferencesCurrentUser, kCFPreferencesAnyHost), CFSTR("com.matchstic.xen"), kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
    return [settings objectForKey:key];
}

@end
