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

#import "XENFirstBootController.h"

@interface XENFirstBootController ()

@end

@implementation XENFirstBootController

-(void)loadView {
    self.view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)];
    self.view.tag = 12345;
    self.view.backgroundColor = [UIColor clearColor];
    
    if (_textLabel) {
        [_textLabel removeFromSuperview];
        _textLabel = nil;
    }
    
    _textLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH*0.8, 100)];
    _textLabel.textAlignment = NSTextAlignmentCenter;
    _textLabel.textColor = [UIColor colorWithWhite:1.0 alpha:0.65];
    _textLabel.font = [UIFont systemFontOfSize:20];
    _textLabel.text = [self textWithDisplayedName];
    _textLabel.numberOfLines = 0;
    _textLabel.lineBreakMode = NSLineBreakByWordWrapping;
    
    [self.view addSubview:_textLabel];
    
    if (_vibrancyUnderlayView) {
        [_vibrancyUnderlayView removeFromSuperview];
        _vibrancyUnderlayView = nil;
    }
    
    _vibrancyUnderlayView = [[UIVisualEffectView alloc] initWithEffect:[UIVibrancyEffect effectForBlurEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]]];
    
    [self.view addSubview:_vibrancyUnderlayView];
    
    if (_padlockImageView) {
        [_padlockImageView removeFromSuperview];
        _padlockImageView = nil;
    }
    
    _padlockImageView = [[UIImageView alloc] initWithImage:[[XENResources themedImageWithName:@"Padlock"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
    _padlockImageView.backgroundColor = [UIColor clearColor];
    
    [_vibrancyUnderlayView.contentView addSubview:_padlockImageView];
    
    [self relayoutSubviews];
}

-(NSString*)textWithDisplayedName {
    return [NSString stringWithFormat:[XENResources localisedStringForKey:@"Unlock your device to view \"%@\"" value:@"Unlock your device to view \"%@\""], _displayedName];
}

-(void)setActualIdentifier:(NSString*)actual andDisplayedName:(NSString*)name {
    _actualIdentifier = nil;
    _displayedName = nil;
    
    _actualIdentifier = actual;
    _displayedName = name;
}

#pragma mark Inherited

-(BOOL)wantsBlurredBackground {
    return YES;
}

-(NSString*)uniqueIdentifier {
    return _actualIdentifier;
}

-(NSString*)name {
    return _displayedName;
}

-(XENDeviceSupport)supportedDevices {
    return kSupportsAll;
}

-(void)relayoutSubviews {
    self.view.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
    _textLabel.frame = CGRectMake(SCREEN_WIDTH*0.1, (SCREEN_HEIGHT/2)-150, SCREEN_WIDTH*0.8, 100);
    
    _vibrancyUnderlayView.frame = _padlockImageView.bounds;
    _vibrancyUnderlayView.center = CGPointMake(SCREEN_WIDTH/2, SCREEN_HEIGHT/2 + _padlockImageView.bounds.size.height/2);
}

-(void)rotateToOrientation:(int)orient {
    [self relayoutSubviews];
}

-(void)dealloc {
    [_textLabel removeFromSuperview];
    _textLabel = nil;
    
    [_padlockImageView removeFromSuperview];
    _padlockImageView = nil;
    
    [_vibrancyUnderlayView removeFromSuperview];
    _vibrancyUnderlayView = nil;
}

@end
