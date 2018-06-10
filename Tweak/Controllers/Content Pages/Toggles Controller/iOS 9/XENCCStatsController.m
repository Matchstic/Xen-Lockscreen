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

//  Utilises InfoStats2 for data access.

#import "XENCCStatsController.h"
#import "XENCCStatsView.h"
#import <objc/runtime.h>

@interface XENCCStatsController () {
    UIVisualEffectView *_effects;
}

@end

@interface IS2System : NSObject
+(int)ramFree;
+(double)cpuUsage;
+(double)freeDiskSpaceInFormat:(int)format;
+(double)networkSpeedUp;
+(double)networkSpeedDown;
@end

typedef enum : NSUInteger {
    kCPU,
    kRAM,
    kStorage,
    kUpload,
    kDownload
} XENCCStatsType;

@implementation XENCCStatsController

-(void)loadView {
    self.view = [[UIView alloc] initWithFrame:CGRectZero];
    self.view.backgroundColor = [UIColor clearColor];
    
    UIVibrancyEffect *vibrancy = [UIVibrancyEffect effectForBlurEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]];
    if ([XENResources togglesTintWithWallpaper]) {
        _effects = [[UIVisualEffectView alloc] initWithEffect:vibrancy];
        if (![XENResources blurredBackground]) {
            _effects.alpha = 0.95;
        }
    } else
        _effects = (UIVisualEffectView*)[[UIView alloc] initWithFrame:CGRectZero];
    
    [self.view addSubview:_effects];
    
    // Options: CPU usage, RAM free, Storage free, upload speed, download speed
    NSArray *enabledPanels = [XENResources enabledStatisticsPanels];
    if (enabledPanels.count == 0) {
        // None enabled! Notify user of this.
        _noStatsEnabled = [[UILabel alloc] initWithFrame:CGRectZero];
        _noStatsEnabled.backgroundColor = [UIColor clearColor];
        _noStatsEnabled.alpha = 0.75;
        _noStatsEnabled.font = [UIFont systemFontOfSize:15 weight:UIFontWeightLight];
        _noStatsEnabled.textColor = [UIColor whiteColor];
        _noStatsEnabled.text = [XENResources localisedStringForKey:@"No Statistics Enabled" value:@"No Statistics Enabled"];
        _noStatsEnabled.textAlignment = NSTextAlignmentCenter;
        
        if ([XENResources togglesTintWithWallpaper])
            [_effects.contentView addSubview:_noStatsEnabled];
        else
            [_effects addSubview:_noStatsEnabled];
    } else {
        for (NSString *variant in enabledPanels) {
            XENCCStatsView *view;
            
            // First, grab the correct image.
            UIImage *img = [XENResources themedImageWithName:[NSString stringWithFormat:@"Toggles/%@", variant]];
            //if ([XENResources togglesTintWithWallpaper])
            //    img = [img imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            NSString *string = [self currentStringForVariant:[self variantStringToInt:variant]];
            
            view = [[XENCCStatsView alloc] initWithVariant:[self variantStringToInt:variant] customImage:img andDefaultString:string];
            
            if ([XENResources togglesTintWithWallpaper])
                [_effects.contentView addSubview:view];
            else
                [_effects addSubview:view];
        }
        
        _updateTimer = [NSTimer scheduledTimerWithTimeInterval:10.0 target:self selector:@selector(updateTimerFired:) userInfo:nil repeats:YES];
    }
}

-(XENCCStatsType)variantStringToInt:(NSString*)string {
    if ([string isEqualToString:@"kCPU"]) {
        return kCPU;
    } else if ([string isEqualToString:@"kRAM"]) {
        return kRAM;
    } else if ([string isEqualToString:@"kStorage"]) {
        return kStorage;
    } else if ([string isEqualToString:@"kUpload"]) {
        return kUpload;
    } else if ([string isEqualToString:@"kDownload"]) {
        return kDownload;
    } else {
        return -1;
    }
}

-(NSString*)currentStringForVariant:(XENCCStatsType)variant {
    NSString *output = @"";
    
    switch (variant) {
        case kCPU:
            output = [NSString stringWithFormat:@"%.1f%%", [objc_getClass("IS2System") cpuUsage]];
            break;
        case kRAM:
            output = [NSString stringWithFormat:@"%d MB", [objc_getClass("IS2System") ramFree]];
            break;
        case kStorage:
            output = [NSString stringWithFormat:@"%d GB", (int)[objc_getClass("IS2System") freeDiskSpaceInFormat:3]];
            break;
        case kUpload:
            output = [NSString stringWithFormat:@"%.1f kb/s", [objc_getClass("IS2System") networkSpeedUp]];
            break;
        case kDownload:
            output = [NSString stringWithFormat:@"%.1f kb/s", [objc_getClass("IS2System") networkSpeedDown]];
            break;
        default:
            break;
    }
    
    return output;
}

-(void)updateTimerFired:(id)sender {
    int count = (int)[XENResources enabledStatisticsPanels].count;
    
    for (int i = 0; i < count; i++) {
        XENCCStatsView *view;
        @try {
        if ([XENResources togglesTintWithWallpaper])
            view = (XENCCStatsView*)[_effects.contentView.subviews objectAtIndex:i];
        else
            view = (XENCCStatsView*)[_effects.subviews objectAtIndex:i];
        [view updateLabel:[self currentStringForVariant:view.variant]];
        } @catch(NSException *e) {
            [_updateTimer invalidate];
            break;
        }
    }
}

-(void)viewDidLayoutSubviews {
    _effects.frame = self.view.bounds;
    
    int count = (int)[XENResources enabledStatisticsPanels].count;
    
    if (count > 0) {
        CGFloat width = self.view.frame.size.width/count;
        
        // Layout the panels
        for (int i = 0; i < count; i++) {
            UIView *view;
            if ([XENResources togglesTintWithWallpaper])
                view = [_effects.contentView.subviews objectAtIndex:i];
            else
                view = [_effects.subviews objectAtIndex:i];
            view.frame = CGRectMake(width*i, 0, width, self.view.frame.size.height);
        }
    } else {
        _noStatsEnabled.frame = self.view.bounds;
    }
}

-(void)prepareForRemoval {
    [_updateTimer invalidate];
}

-(void)dealloc {
    for (UIView *view in self.view.subviews) {
        [view removeFromSuperview];
    }
    
    [_updateTimer invalidate];
}

@end
