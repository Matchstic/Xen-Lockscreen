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

//  A shim for LockPages, which allows the user to re-arrange views from LockPages, along with correctly rendering them.

#import "XENLockPagesController.h"

@interface XENLockPagesController ()

@end

@implementation XENLockPagesController

-(void)loadView {
    self.view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)];
    self.view.tag = 12345;
    self.view.backgroundColor = [UIColor clearColor];
    
    [self.view addSubview:[_page view]];
}

-(void)setPage:(id<LPPage>)page {
    _page = page;
}

-(BOOL)shouldDisplay {
    return YES;
}

-(long long)priority {
    return [_page priority];
}

-(id)LPPage {
    return _page;
}

#pragma mark Inherited shit

+(BOOL)supportsCurrentiOSVersion {
    // LockPages on iOS 10 is handled totally differently.
    return [UIDevice currentDevice].systemVersion.floatValue < 10;
}

-(BOOL)wantsBlurredBackground {
    if ([_page respondsToSelector:@selector(backgroundAlpha)]) {
        return ([_page backgroundAlpha] > 0.0);
    }
    
    return NO;
}

-(void)movingToControllerWithPercent:(CGFloat)percent {
    if (percent == 0.0) {
        _presented = NO;
        [_page pageDidDismiss];
    } else if (percent == 1.0) {
        _presented = YES;
        [_page pageDidPresent];
    }
    
    // TODO: Handle 'will' do things
}

-(NSString*)uniqueIdentifier {
    return [NSString stringWithFormat:@"lockpages.%@", NSStringFromClass([[(LPPage*)_page page] class])];
}

-(NSString*)name {
    // Use known names first.
    NSString *identifier = [self uniqueIdentifier];
    
    if ([identifier isEqualToString:@"lockpages.FCForecastViewController"]) {
        return @"Forecast";
    }
    
    return NSStringFromClass([[(LPPage*)_page page] class]);
}

-(XENDeviceSupport)supportedDevices {
    return kSupportsAll;
}

-(void)notifyPreemptiveAddition {
    XENlog(@"*** LOCKPAGES :: PRE-EMPTIVE ADDITION");
}

-(void)relayoutSubview {
    UIView *view = [_page view];
    [self.view addSubview:view];
    
    view.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
}

-(void)rotateToOrientation:(int)orient {
    [self relayoutSubview];
}

-(void)dealloc {
    // Only the LockPages controllers are killed on an unlock.
    [[_page view] removeFromSuperview];
    _page = nil;
}

@end
