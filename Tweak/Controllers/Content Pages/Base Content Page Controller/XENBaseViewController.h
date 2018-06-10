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

//  DO NOT INSTIANTATE THIS CLASS DIRECTLY

#import <UIKit/UIKit.h>

typedef enum : NSUInteger {
    kSupportsIphone,
    kSupportsIpad,
    kSupportsAll,
} XENDeviceSupport;

@interface XENBaseViewController : UIViewController

@property (nonatomic, readwrite) BOOL _debugIsReset;
@property (nonatomic, readwrite) BOOL _allowGeometryChange;

+(BOOL)supportsCurrentiOSVersion;

-(void)rotateToOrientation:(int)orient;
-(void)resetForScreenOff;
-(NSString*)name;
-(NSString*)uniqueIdentifier;
-(XENDeviceSupport)supportedDevices;
-(BOOL)wantsBlurredBackground;
-(BOOL)alwaysWantsLightStatusBar;
-(void)movingToControllerWithPercent:(CGFloat)percent;
-(void)willMoveToControllerAfterScrollingEnds;

// View management
-(void)configureViewForLock;
-(void)resetViewForUnlock;
-(void)resetViewForSetupDone;
-(void)resetViewForSettingsChange:(NSDictionary*)oldSettings :(NSDictionary*)newSettings;
-(void)notifyUnlockWillBegin;
-(void)notifyPreemptiveRemoval;
-(void)notifyPreemptiveAddition;

@end
