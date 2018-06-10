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

#import "XENBaseViewController.h"
#import <objc/runtime.h>

@interface XENBaseViewController ()

@end

@implementation XENBaseViewController

#pragma mark Xen view information

+ (BOOL)supportsCurrentiOSVersion { return YES; }

-(NSString*)name { return @"BASE_VIEW"; }
-(NSString*)uniqueIdentifier { return @"com.matchstic.base_view"; }
-(XENDeviceSupport)supportedDevices { return kSupportsAll; }
-(void)rotateToOrientation:(int)orient {}
-(void)resetForScreenOff {}
-(BOOL)wantsBlurredBackground { return NO; }
-(BOOL)alwaysWantsLightStatusBar {
    if ([self wantsBlurredBackground]) {
        return YES;
    }
    
    return NO;
}
-(void)movingToControllerWithPercent:(CGFloat)percent { }
-(void)willMoveToControllerAfterScrollingEnds {}

-(void)configureViewForLock {
    self._allowGeometryChange = YES;
    
    if (!self.isViewLoaded) {
        [self loadView];
    }
    
    // Subclasses do whatever else they need to before displaying to the user.
    
    self._debugIsReset = NO;
}

-(void)resetViewForUnlock {
    // Subclasses are not expected to call super to this.
    
    if (self.isViewLoaded) {
        for (UIView *view in self.view.subviews) {
            [view removeFromSuperview];
        }
        
        [self.view removeFromSuperview];
        self.view = nil;
    }
    
    self._debugIsReset = YES;
}

-(void)resetViewForSettingsChange:(NSDictionary*)oldSettings :(NSDictionary*)newSettings {
    // Again, not expected to call super.
    [self resetViewForUnlock];
}

-(void)notifyPreemptiveRemoval {}
-(void)notifyPreemptiveAddition {}
-(void)notifyUnlockWillBegin {}

-(void)resetViewForSetupDone {
    [self resetViewForUnlock];
}

#pragma mark Boring memory shit

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(NSString*)description {
    return [NSString stringWithFormat:@"<%@ name: %@, uniqueId: %@, supportedDevices: %lu, isReset: %d, isViewLoaded: %d>", [self class], [self name], [self uniqueIdentifier], (unsigned long)[self supportedDevices], self._debugIsReset, self.isViewLoaded];
}

@end
