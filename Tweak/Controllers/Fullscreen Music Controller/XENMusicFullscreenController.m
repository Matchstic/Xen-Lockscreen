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

#import "XENMusicFullscreenController.h"
#include "MediaRemote.h"
#import "UIImage+AverageColor.h"

@interface IS2Media : NSObject
+(void)registerForNowPlayingNotificationsWithIdentifier:(NSString*)identifier andCallback:(void (^)(void))callbackBlock;
+(void)unregisterForNotificationsWithIdentifier:(NSString*)identifier;
+(UIImage*)currentTrackArtwork;
+(BOOL)isPlaying;
@end

@interface XENMusicFullscreenController ()

@end

@implementation XENMusicFullscreenController

-(instancetype)init {
    self = [super init];
    
    if (self) {
        
        XENMusicFullscreenController * __weak weakself = self;
        
        //[objc_getClass("IS2Media") registerForNowPlayingNotificationsWithIdentifier:@"com.matchstic.xen.fullscreenmedia" andCallback:^{
        //    [weakself mediaUpdated];
        //}];
        
        MRMediaRemoteRegisterForNowPlayingNotifications(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0));
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        [center addObserverForName:(__bridge NSString *)kMRMediaRemoteNowPlayingInfoDidChangeNotification
                            object:nil
                             queue:[NSOperationQueue mainQueue]
                        usingBlock:^(NSNotification *notification) {
                            
                            // Get new media data!
                            [weakself mediaUpdated:NO];
                            
                        }];
        
        _hasPlayedSinceLocking = NO;
    }
    
    return self;
}

-(void)loadView {
    self.view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)];
    self.view.backgroundColor = [UIColor clearColor];
    
    // Next, prep artwork view.
    _artwork = [[XENBlurryArtworkView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)];
    _artwork.backgroundColor = [UIColor clearColor];
    
    // 3 == combined, 2 == fullscreen.
    _artwork.blurRadius = ([XENResources mediaArtworkStyle] == 3 ? 30.0 : 5.0);
    
    [self.view addSubview:_artwork];
    
    _darkener = [[UIView alloc] initWithFrame:_artwork.bounds];
    _darkener.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.2];
    _darkener.hidden = YES;
    
    [self.view addSubview:_darkener];
    
    if ([objc_getClass("IS2Media") isPlaying]) {
        [self mediaUpdated:YES]; // Update if currently playing on locking
    }
}

-(void)mediaUpdated {
    [self mediaUpdated:NO];
}

-(void)mediaUpdated:(BOOL)onLock {
    // Note that we may be coming in here off a background thread?
    MRMediaRemoteGetNowPlayingInfo(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(CFDictionaryRef information) {
        NSDictionary *data = (__bridge NSDictionary*)information;
        
        if (data) { // Seems to lead to crashes if data does not exist!
            
            BOOL isPlaying = [[data objectForKey:(__bridge NSString*)kMRMediaRemoteNowPlayingInfoPlaybackRate] boolValue];
            
            if (!_hasPlayedSinceLocking && isPlaying)
                _hasPlayedSinceLocking = YES;
            
            if (_hasPlayedSinceLocking) {
                NSData *imgdata = [data objectForKey:(__bridge NSString*)kMRMediaRemoteNowPlayingInfoArtworkData];
                UIImage *img = [UIImage imageWithData:imgdata];
                
                dispatch_async(dispatch_get_main_queue(), ^(void){
                    [UIView transitionWithView:_artwork
                                      duration:0.3
                                       options:UIViewAnimationOptionTransitionCrossDissolve
                                    animations:^{
                                        [_artwork setArtworkImage:img];
                                    } completion:NULL];
                    
                    _artwork.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
                    
                    if (img) {
                        _darkener.hidden = NO;
                    } else {
                        _darkener.hidden = YES;
                    }
                    
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"XENWallpaperChanged" object:nil];
                });
            }
        }
    });
}

-(BOOL)hasArtwork {
    return _artwork.artworkImage != nil && _artwork.artworkImage.size.width > 0;
}

-(UIColor*)averageArtworkColour {
    //UIGraphicsBeginImageContextWithOptions(_artwork.bounds.size, YES, 0);
    //[_artwork.layer renderInContext:UIGraphicsGetCurrentContext()];
    
    //UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    
    //UIGraphicsEndImageContext();
    
    return [_artwork.artworkImage averageColor];
}

-(void)rotateToOrient:(int)orient {
    self.view.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
    _artwork.frame = self.view.bounds;
    _darkener.frame = self.view.bounds;
}

-(void)prepareForDeconstruct {
    MRMediaRemoteUnregisterForNowPlayingNotifications();
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)dealloc {
    [_artwork removeFromSuperview];
    _artwork = nil;
    
    [_darkener removeFromSuperview];
    _darkener = nil;
    
    XENlog(@"XENMusicFullscreenController -- dealloc");
}

@end
