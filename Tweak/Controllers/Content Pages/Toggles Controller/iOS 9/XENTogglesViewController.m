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

#import "XENTogglesViewController.h"
#import "XENLegibilityLabel.h"
#import "XENCCStatsController.h"

@interface XENTogglesViewController () {
    UIView *_container;
    SBCCSettingsSectionController *_toggles;
    SBCCBrightnessSectionController *_brightness;
    XENCCStatsController *_statistics;
    SBCCAirStuffSectionController *_airstuff;
    SBCCQuickLaunchSectionController *_shortcuts;
    MPUMediaControlsVolumeView *_volume;
    UIVisualEffectView *brightnessEffect;
}

@end

@interface SBControlCenterContentView : UIView
+ (float)defaultBreadthForOrientation:(int)orientation;
- (id)initWithFrame:(CGRect)frame;
- (float)contentHeightForOrientation:(int)orientation;
@end

@implementation XENTogglesViewController

-(void)loadView {
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)];
    self.view = view;
    self.view.backgroundColor = [UIColor clearColor];
    self.view.tag = 12345;
    
    _container = [[UIView alloc] initWithFrame:CGRectZero];
    
    [self.view addSubview:_container];
    
    // Load up CC elements: Toggles, brightness, stats, airdrop/play, shortcuts
    CGFloat originY = 0;
    CGFloat containerHeight = self.view.frame.size.height * 0.9;
    
    [XENResources setTogglesConfiguring:YES];
    
    _toggles = [[objc_getClass("SBCCSettingsSectionController") alloc] init];
    [self addChildViewController:_toggles];
    [_toggles controlCenterWillPresent];
    [_container addSubview:_toggles.view];
    
    // If using CCSettings , we need to have the toggles full-screen width.
    CGRect togglesRect = CGRectMake(self.view.frame.size.width * 0.075, originY, self.view.frame.size.width * 0.85,  containerHeight * 0.15);
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:@"/Library/MobileSubstrate/DynamicLibraries/CCSettings.dylib"])
        togglesRect = CGRectMake(0, originY, self.view.frame.size.width,  containerHeight * 0.15);
    
    _toggles.view.frame = togglesRect;
    
    originY += _toggles.view.frame.size.height;
    
    // We'll add the brightness slider to a pretty vibrant effect.
    
    _brightness = [[objc_getClass("SBCCBrightnessSectionController") alloc] init];
    //_brightness.view.frame =
    UIVibrancyEffect *vibrancy = [UIVibrancyEffect effectForBlurEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]];
    if ([XENResources togglesTintWithWallpaper]) {
        brightnessEffect = [[UIVisualEffectView alloc] initWithEffect:vibrancy];
        if (![XENResources blurredBackground])
            brightnessEffect.alpha = 0.95;
    } else
        brightnessEffect = (UIVisualEffectView*)[[UIView alloc] initWithFrame:CGRectZero];
    brightnessEffect.frame = CGRectMake(self.view.frame.size.width * 0.075, originY, self.view.frame.size.width * 0.85, 100);
    _brightness.view.frame = CGRectMake(0, 0, self.view.frame.size.width * 0.85, 50);
    _brightness.view.backgroundColor = [UIColor clearColor];
    _brightness.view.tintColor = [UIColor whiteColor];
    
    [[_brightness xen_slider] setAdjusting:YES];
    [[_brightness xen_slider] setTag:1337];
    [[_brightness xen_slider] _xen_setTrackImagesForCurrentTheme];
    
    [self addChildViewController:_brightness];
    [_brightness controlCenterWillPresent];
    [_brightness viewWillAppear:NO];
    if ([XENResources togglesTintWithWallpaper])
        [brightnessEffect.contentView addSubview:_brightness.view];
    else
        [brightnessEffect addSubview:_brightness.view];
    [_container addSubview:brightnessEffect];
    
    if ([XENResources togglesGlyphTintForState:0 isCircle:YES]) {
        brightnessEffect.tintColor = [XENResources togglesGlyphTintForState:0 isCircle:YES];
    }
    
    originY += _brightness.view.frame.size.height;
    
    // Do volume too!
    _volume = [(MPUMediaControlsVolumeView*)[objc_getClass("MPUMediaControlsVolumeView") alloc] initWithStyle:1];
    _volume.frame = CGRectMake(0, 50, brightnessEffect.frame.size.width, 50);
    [_volume.slider setAdjusting:YES];
    [_volume.slider setTag:1337];
    if ([XENResources togglesTintWithWallpaper])
        [brightnessEffect.contentView addSubview:_volume];
    else
        [brightnessEffect addSubview:_volume];
    
    originY += _volume.frame.size.height;
    
    _statistics = [[XENCCStatsController alloc] init];
    _statistics.view.frame = CGRectMake(self.view.frame.size.width * 0.075, originY, self.view.frame.size.width * 0.85, containerHeight * 0.3);
    _statistics.view.userInteractionEnabled = NO;
    [_statistics viewDidLayoutSubviews];
    [_container addSubview:_statistics.view];
    
    originY += _statistics.view.frame.size.height;
    
    _airstuff = [[objc_getClass("SBCCAirStuffSectionController") alloc] init];
    [self addChildViewController:_airstuff];
    [_airstuff controlCenterWillPresent];
    [_container addSubview:_airstuff.view];
    _airstuff.view.frame = CGRectMake(self.view.frame.size.width * 0.075, originY, self.view.frame.size.width * 0.85, 55);
    _airstuff.view.layer.cornerRadius = 12.5;
    _airstuff.view.clipsToBounds = YES;
    
    originY += _airstuff.view.frame.size.height;
    
    _shortcuts = [[objc_getClass("SBCCQuickLaunchSectionController") alloc] init];
    [self addChildViewController:_shortcuts];
    [_shortcuts controlCenterWillPresent];
    [_container addSubview:_shortcuts.view];
    _shortcuts.view.frame = CGRectMake(self.view.frame.size.width * 0.075, originY, self.view.frame.size.width * 0.85, containerHeight * 0.25);
    
    originY += _shortcuts.view.frame.size.height;
    
    [XENResources setTogglesConfiguring:NO];
    
    _container.frame = CGRectMake(0, (self.view.frame.size.height - originY)/2, self.view.frame.size.width, originY);
}

#pragma mark Inherited things

-(void)rotateToOrientation:(int)orient {
    CGFloat originY = 0;
    CGFloat containerHeight = self.view.frame.size.height * 0.9;
    
    // If using CCSettings , we need to have the toggles full-screen width.
    CGRect togglesRect = CGRectMake(self.view.frame.size.width * 0.075, originY, self.view.frame.size.width * 0.85,  containerHeight * 0.15);
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:@"/Library/MobileSubstrate/DynamicLibraries/CCSettings.dylib"])
        togglesRect = CGRectMake(0, originY, self.view.frame.size.width,  containerHeight * 0.15);
    
    _toggles.view.frame = togglesRect;
    originY += _toggles.view.frame.size.height;
    
    brightnessEffect.frame = CGRectMake(self.view.frame.size.width * 0.075, originY, self.view.frame.size.width * 0.85, 100);
    _brightness.view.frame = CGRectMake(0, 0, self.view.frame.size.width * 0.85, 50);
    originY += _brightness.view.frame.size.height;
    
    _volume.frame = CGRectMake(0, 50, brightnessEffect.frame.size.width, 50);
    
    originY += _volume.frame.size.height;
    
    _statistics.view.frame = CGRectMake(self.view.frame.size.width * 0.075, originY, self.view.frame.size.width * 0.85, containerHeight * 0.3);
    originY += _statistics.view.frame.size.height;
    
    _airstuff.view.frame = CGRectMake(self.view.frame.size.width * 0.075, originY, self.view.frame.size.width * 0.85, 55);
    originY += _airstuff.view.frame.size.height;
    
    _shortcuts.view.frame = CGRectMake(self.view.frame.size.width * 0.075, originY, self.view.frame.size.width * 0.85, containerHeight * 0.25);
    originY += _shortcuts.view.frame.size.height;
    
    _container.frame = CGRectMake(0, (self.view.frame.size.height - originY)/2, self.view.frame.size.width, originY);
}

-(void)resetForScreenOff {
    // TODO: Hide the popover from the airstuff controller.
}

-(BOOL)wantsBlurredBackground {
    return YES;
}

-(NSString*)name {
    return [XENResources localisedStringForKey:@"Toggles" value:@"Toggles"];
}

-(NSString*)uniqueIdentifier {
    return @"com.matchstic.toggles.iphone";
    //return @"com.matchstic.toggles.ipad";
}

+(BOOL)supportsCurrentiOSVersion {
    return [UIDevice currentDevice].systemVersion.floatValue < 10.0;
}

-(XENDeviceSupport)supportedDevices {
    return kSupportsIphone;
}

-(void)resetViewForUnlock {
    XENlog(@"Resetting Toggles for unlock.");
    
    [_statistics prepareForRemoval];
    
    [_toggles.view removeFromSuperview];
    [_toggles removeFromParentViewController];
    _toggles = nil;
    
    [_brightness.view removeFromSuperview];
    [_brightness removeFromParentViewController];
    _brightness = nil;
    
    [_statistics.view removeFromSuperview];
    [_statistics removeFromParentViewController];
    _statistics = nil;
    
    [_airstuff.view removeFromSuperview];
    [_airstuff removeFromParentViewController];
    _airstuff = nil;
    
    [_shortcuts.view removeFromSuperview];
    [_shortcuts removeFromParentViewController];
    _shortcuts = nil;
    
    [_volume removeFromSuperview];
    _volume = nil;
    
    [super resetViewForUnlock];
}

-(void)dealloc {
    [_statistics prepareForRemoval];
    
    [_toggles.view removeFromSuperview];
    [_toggles removeFromParentViewController];
    _toggles = nil;
    
    [_brightness.view removeFromSuperview];
    [_brightness removeFromParentViewController];
    _brightness = nil;
    
    [_statistics.view removeFromSuperview];
    [_statistics removeFromParentViewController];
    _statistics = nil;
    
    [_airstuff.view removeFromSuperview];
    [_airstuff removeFromParentViewController];
    _airstuff = nil;
    
    [_shortcuts.view removeFromSuperview];
    [_shortcuts removeFromParentViewController];
    _shortcuts = nil;
    
    [_volume removeFromSuperview];
    _volume = nil;
    
    if (self.isViewLoaded)
    for (UIView *view in self.view.subviews) {
        [view removeFromSuperview];
    }
    
    XENlog(@"Deallocated toggles view!");
}

@end
