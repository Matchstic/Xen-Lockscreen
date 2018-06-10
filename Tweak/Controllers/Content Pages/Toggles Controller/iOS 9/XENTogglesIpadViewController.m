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

#import "XENTogglesIpadViewController.h"
#import "XENLegibilityLabel.h"
#import "XENCCStatsController.h"

@interface IS2Media : NSObject
+(void)registerForNowPlayingNotificationsWithIdentifier:(NSString*)identifier andCallback:(void (^)(void))callbackBlock;
+(void)unregisterForNotificationsWithIdentifier:(NSString*)identifier;
+(UIImage*)currentTrackArtwork;
@end

@interface XENTogglesIpadViewController () {
    UIView *_container;
    SBCCSettingsSectionController *_toggles;
    SBCCBrightnessSectionController *_brightness;
    XENCCStatsController *_statistics;
    SBCCAirStuffSectionController *_airstuff;
    SBCCQuickLaunchSectionController *_shortcuts;
    MPUMediaControlsVolumeView *_volume;
    UIVisualEffectView *brightnessEffect;
    UIImageView *_artworkView;
    MPUSystemMediaControlsViewController *_controlsViewController;
    
    UIVisualEffectView *_mediaControlsBackground;
    UIView *_mediaBlockout;
}

@end

@implementation XENTogglesIpadViewController

-(void)loadView {
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)];
    self.view = view;
    self.view.backgroundColor = [UIColor clearColor];
    self.view.tag = 12345;
    
    _container = [[UIView alloc] initWithFrame:CGRectZero];
    
    [self.view addSubview:_container];
    
    // Load up CC elements: Toggles, brightness, stats, airdrop/play, shortcuts
    CGFloat originY = [[UIApplication sharedApplication] statusBarFrame].size.height;
    CGFloat containerHeight = self.view.frame.size.height * 0.9;
    
    // TOP
    [XENResources setTogglesConfiguring:YES];
    
    _toggles = [[objc_getClass("SBCCSettingsSectionController") alloc] init];
    [self addChildViewController:_toggles];
    [_toggles controlCenterWillPresent];
    [_container addSubview:_toggles.view];
    _toggles.view.frame = CGRectMake(self.view.frame.size.width * 0.075, originY, self.view.frame.size.width*0.85, containerHeight * 0.15);
    
    originY += _toggles.view.frame.size.height;
    
    // LEFT COLUMN
    
    // We'll add the brightness slider to a pretty vibrant effect.
    
    _brightness = [[objc_getClass("SBCCBrightnessSectionController") alloc] init];
    //_brightness.view.frame =
    UIVibrancyEffect *vibrancy = [UIVibrancyEffect effectForBlurEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]];
    if ([XENResources togglesTintWithWallpaper]) {
        brightnessEffect = [[UIVisualEffectView alloc] initWithEffect:vibrancy];
        if (![XENResources blurredBackground]) {
            brightnessEffect.alpha = 0.95;
        }
    } else
        brightnessEffect = (UIVisualEffectView*)[[UIView alloc] initWithFrame:CGRectZero];
    brightnessEffect.frame = CGRectMake(self.view.frame.size.width * 0.075, originY, self.view.frame.size.width * 0.85, 50);
    _brightness.view.frame = CGRectMake(10, 0, brightnessEffect.frame.size.width/2 - 20, 50);
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
    
    // Do volume too!
    _volume = [(MPUMediaControlsVolumeView*)[objc_getClass("MPUMediaControlsVolumeView") alloc] initWithStyle:1];
    _volume.frame = CGRectMake(brightnessEffect.frame.size.width/2 + 10, 0, brightnessEffect.frame.size.width/2 - 20, 50);
    [_volume.slider setAdjusting:YES];
    [_volume.slider setTag:1337];
    if ([XENResources togglesTintWithWallpaper])
        [brightnessEffect.contentView addSubview:_volume];
    else
        [brightnessEffect addSubview:_volume];
    
    originY += _brightness.view.frame.size.height + 20;
    
    CGFloat originYLeft = originY;
    
    // Padding due to artwork view
    CGFloat statsHeight = 100;
    CGFloat statsMargin = 60 + (orient3 == 1 || orient3 == 2 ? 10 : 5);
    originYLeft += statsMargin;
    
    _statistics = [[XENCCStatsController alloc] init];
    _statistics.view.frame = CGRectMake(self.view.frame.size.width * 0.075, originYLeft, self.view.frame.size.width * 0.35, statsHeight);
    _statistics.view.userInteractionEnabled = NO;
    [_statistics viewDidLayoutSubviews];
    [_container addSubview:_statistics.view];
    
    originYLeft += _statistics.view.frame.size.height;
    originYLeft += statsMargin/2;
    
    _airstuff = [[objc_getClass("SBCCAirStuffSectionController") alloc] init];
    [self addChildViewController:_airstuff];
    [_airstuff controlCenterWillPresent];
    [_container addSubview:_airstuff.view];
    _airstuff.view.frame = CGRectMake(self.view.frame.size.width * 0.075, originYLeft, self.view.frame.size.width * 0.35, 55);
    _airstuff.view.layer.cornerRadius = 12.5;
    _airstuff.view.clipsToBounds = YES;
    
    originYLeft += _airstuff.view.frame.size.height;
    
    // RIGHT COLUMN
    
    CGFloat originYRight = originY + (orient3 == 1 || orient3 == 2 ? 20 : 10);
    
    if ([objc_getClass("IS2Media") isPlaying]) {
        _artworkView = [[UIImageView alloc] initWithImage:[objc_getClass("IS2Media") currentTrackArtwork]];
    } else {
        _artworkView = [[UIImageView alloc] initWithImage:[XENResources themedImageWithName:@"ArtworkPlaceholder"]];
    }
    _artworkView.frame = CGRectMake(self.view.frame.size.width*0.5 + 10 + (_volume.frame.size.width/2 - 135), originYRight, 270, 270);
    _artworkView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.5];
    
    [_container addSubview:_artworkView];
    
    originYRight += _artworkView.frame.size.height + 20 + (orient3 == 1 || orient3 == 2 ? 20 : 10);;
    
    // Controls.
    if ([XENResources blurredBackground]) {
        UIVisualEffect *effect = [UIVibrancyEffect effectForBlurEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]];
        _mediaControlsBackground = [[UIVisualEffectView alloc] initWithEffect:effect];
        
        //_mediaBlockout = [[UIView alloc] initWithFrame:CGRectZero];
        //_mediaBlockout.backgroundColor = [UIColor whiteColor];
        
        //[_mediaControlsBackground.contentView addSubview:_mediaBlockout];
    } else {
        _mediaControlsBackground = (UIVisualEffectView*)[[UIView alloc] initWithFrame:CGRectZero];
        _mediaControlsBackground.backgroundColor = [UIColor colorWithWhite:0.35 alpha:1.0];
    }
    
    _mediaControlsBackground.frame = CGRectMake(self.view.frame.size.width*0.075, originYRight, self.view.frame.size.width * 0.85, 127);
    _mediaBlockout.frame = _mediaControlsBackground.bounds;
    _mediaControlsBackground.layer.masksToBounds = YES;
    _mediaControlsBackground.layer.cornerRadius = 12.5;
    
    [_container addSubview:_mediaControlsBackground];
    
    _controlsViewController = [(MPUSystemMediaControlsViewController*)[objc_getClass("MPUSystemMediaControlsViewController") alloc] initWithStyle:2];
    [self addChildViewController:_controlsViewController];
    _controlsViewController.view.autoresizingMask = 0;
    //_controlsViewController.view.frame = CGRectMake(self.view.frame.size.width*0.5 + 10, originYRight, _volume.frame.size.width, 127);
    //_controlsViewController.view.frame = CGRectMake(0, originYRight, self.view.frame.size.width * 0.85, 127);
    _controlsViewController.view.frame = _mediaControlsBackground.bounds;
    _controlsViewController.view.tag = 1337;
    
    [_controlsViewController viewWillAppear:NO];
    
    if (![XENResources blurredBackground]) {
        [_mediaControlsBackground addSubview:_controlsViewController.view];
    } else {
        [_mediaControlsBackground.contentView addSubview:_controlsViewController.view];
    }
    
    MPUSystemMediaControlsView *mediaControls = [_controlsViewController _xen_mediaView];
    //mediaControls.frame = CGRectMake(0, 0, _volume.frame.size.width, 127);
    mediaControls.frame = _controlsViewController.view.bounds;
    mediaControls.volumeView.hidden = YES;
    [mediaControls.volumeView removeFromSuperview];
    
    originYRight += _controlsViewController.view.frame.size.height;
    
    originY = (originYLeft > originYRight ? originYLeft : originYRight);
    
    // BOTTOM
    
    _shortcuts = [[objc_getClass("SBCCQuickLaunchSectionController") alloc] init];
    _shortcuts.view.tag = 1337;
    [self addChildViewController:_shortcuts];
    [_shortcuts controlCenterWillPresent];
    [_container addSubview:_shortcuts.view];
    [_shortcuts viewDidLoad];
    CGFloat shortcutsHeight = containerHeight * (orient3 == 1 || orient3 == 2 ? 0.25 : 0.15);
    _shortcuts.view.frame = CGRectMake(self.view.frame.size.width * 0.075, originY, self.view.frame.size.width * 0.85, shortcutsHeight);
    
    originY += _shortcuts.view.frame.size.height;
    
    _container.frame = CGRectMake(0, (self.view.frame.size.height - originY)/2, self.view.frame.size.width, originY);
    
    [XENResources setTogglesConfiguring:NO];
    
    // Setup for IS2Media
    [objc_getClass("IS2Media") registerForNowPlayingNotificationsWithIdentifier:@"com.matchstic.xen" andCallback:^{
        _artworkView.image = [objc_getClass("IS2Media") currentTrackArtwork];
        
        if (!_artworkView.image) {
            _artworkView.image = [XENResources themedImageWithName:@"ArtworkPlaceholder"];
        }
    }];
}

#pragma mark Inherited things

-(void)rotateToOrientation:(int)orient {
    CGFloat originY = [[UIApplication sharedApplication] statusBarFrame].size.height;
    CGFloat containerHeight = self.view.frame.size.height * 0.9;
    
    _toggles.view.frame = CGRectMake(self.view.frame.size.width * 0.075, originY, self.view.frame.size.width*0.85, containerHeight * 0.15);
    originY += _toggles.view.frame.size.height;
    
    brightnessEffect.frame = CGRectMake(self.view.frame.size.width * 0.075, originY, self.view.frame.size.width * 0.85, 50);
    _brightness.view.frame = CGRectMake(10, 0, brightnessEffect.frame.size.width/2 - 20, 50);
    _volume.frame = CGRectMake(brightnessEffect.frame.size.width/2 + 10, 0, brightnessEffect.frame.size.width/2 - 20, 50);
    originY += _brightness.view.frame.size.height + 20;
    
    CGFloat originYLeft = originY;
    
    // Paddig due to artwork view
    CGFloat statsHeight = 100;
    CGFloat statsMargin = 60 + (orient3 == 1 || orient3 == 2 ? 10 : 5);
    originYLeft += statsMargin;
    
    _statistics.view.frame = CGRectMake(self.view.frame.size.width * 0.075, originYLeft, self.view.frame.size.width * 0.35, statsHeight);
    originYLeft += _statistics.view.frame.size.height;
    originYLeft += statsMargin/2;
    
    _airstuff.view.frame = CGRectMake(self.view.frame.size.width * 0.075, originYLeft, self.view.frame.size.width * 0.35, 55);
    originYLeft += _airstuff.view.frame.size.height;
    
    // RIGHT
    CGFloat originYRight = originY + (orient3 == 1 || orient3 == 2 ? 20 : 10);
    
    _artworkView.frame = CGRectMake(self.view.frame.size.width*0.5 + 10 + (_volume.frame.size.width/2 - 135), originYRight, 270, 270);
    originYRight += _artworkView.frame.size.height + 20 + (orient3 == 1 || orient3 == 2 ? 20 : 10);;
    
    //_controlsViewController.view.frame = CGRectMake(self.view.frame.size.width*0.5 + 10, originYRight, _volume.frame.size.width, 127);
    _mediaControlsBackground.frame = CGRectMake(self.view.frame.size.width*0.075, originYRight, self.view.frame.size.width * 0.85, 127);
    _mediaBlockout.frame = _mediaControlsBackground.bounds;
    _controlsViewController.view.frame = _mediaControlsBackground.bounds;
    //_controlsViewController.view.frame = CGRectMake(self.view.frame.size.width*0.075, originYRight, self.view.frame.size.width * 0.85, 127);
    MPUSystemMediaControlsView *mediaControls = [_controlsViewController _xen_mediaView];
    //mediaControls.frame = CGRectMake(0, 0, _volume.frame.size.width, 127);
    mediaControls.frame = _controlsViewController.view.bounds;
    originYRight += _controlsViewController.view.frame.size.height;
    
    originY = (originYLeft > originYRight ? originYLeft : originYRight);
    
    CGFloat shortcutsHeight = containerHeight * (orient3 == 1 || orient3 == 2 ? 0.25 : 0.15);
    _shortcuts.view.frame = CGRectMake(self.view.frame.size.width * 0.075, originY, self.view.frame.size.width * 0.85, shortcutsHeight);
    
    originY += _shortcuts.view.frame.size.height;
    
    _container.frame = CGRectMake(0, (self.view.frame.size.height - originY)/2, self.view.frame.size.width, originY);
}

-(void)resetForScreenOff {
    
}

-(BOOL)wantsBlurredBackground {
    return YES;
}

+(BOOL)supportsCurrentiOSVersion {
    return [UIDevice currentDevice].systemVersion.floatValue < 10.0;
}

-(NSString*)name {
    return [XENResources localisedStringForKey:@"Toggles" value:@"Toggles"];
}

-(NSString*)uniqueIdentifier {
    return @"com.matchstic.toggles.ipad";
    //return @"com.matchstic.toggles.iphone";
}

-(XENDeviceSupport)supportedDevices {
    return kSupportsIpad;
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
    
    [_controlsViewController.view removeFromSuperview];
    [_controlsViewController removeFromParentViewController];
    _controlsViewController = nil;
    
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
    
    [_controlsViewController.view removeFromSuperview];
    [_controlsViewController removeFromParentViewController];
    _controlsViewController = nil;
    
    if (self.isViewLoaded)
    for (UIView *view in self.view.subviews) {
        [view removeFromSuperview];
    }
    
    [objc_getClass("IS2Media") unregisterForNotificationsWithIdentifier:@"com.matchstic.xen"];
}

@end
