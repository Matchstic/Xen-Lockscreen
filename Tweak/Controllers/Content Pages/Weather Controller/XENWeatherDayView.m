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

#import "XENWeatherDayView.h"
#import "XENWeatherLayerFactory.h"
#import "IS2Weather.h"

@implementation XENWeatherDayView

-(id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    
    if (self) {
        
    }
    
    return self;
}

-(void)_configureIfNeeded {
    if (!_weekday) {
        _weekday = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 5, 15)];
        _weekday.font = [UIFont systemFontOfSize:15];
        _weekday.text = @"";
        _weekday.textAlignment = NSTextAlignmentLeft;
        _weekday.textColor = [UIColor whiteColor];
        
        [self addSubview:_weekday];
    }
    
    if (!_condition) {
        _condition = [[UIImageView alloc] initWithImage:nil];
        
        [self addSubview:_condition];
    }
        
    if (!_high) {
        _high = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 2, 15)];
        _high.font = [UIFont systemFontOfSize:15];
        _high.text = @"-";
        _high.textAlignment = NSTextAlignmentRight;
        _high.textColor = [UIColor whiteColor];
        
        [self addSubview:_high];
    }
    
    if (!_low) {
        _low = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 2, 15)];
        _low.font = [UIFont systemFontOfSize:15];
        _low.text = @"-";
        _low.textAlignment = NSTextAlignmentRight;
        _low.textColor = [UIColor colorWithWhite:1.0 alpha:0.5];
        
        [self addSubview:_low];
    }
}

-(void)reuseWithWeekday:(NSString*)weekday condition:(int)condition high:(NSString*)high andLow:(NSString*)low {
    [self _configureIfNeeded];
    
    CGRect rect = [XENResources boundedRectForFont:[UIFont systemFontOfSize:15] andText:weekday width:SCREEN_WIDTH*0.8];
    _weekday.frame = CGRectMake(20, 0, rect.size.width+5, self.bounds.size.height);
    _weekday.text = weekday;
    
    _condition.image = [[XENWeatherLayerFactory sharedInstance] iconForCondition:condition wantsLargerIcons:NO];
    [_condition sizeToFit];
    _condition.center = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);
    
    // CAREFUL! On iOS 10, a forecast's temperature is a WFTemperature.
    NSString *hightext;
    NSString *lowtext;
    
    if ([high isKindOfClass:objc_getClass("WFTemperature")]) {
        BOOL isCelsius = [objc_getClass("IS2Weather") isCelsius];
        
        WFTemperature *hightemp = (WFTemperature*)high;
        WFTemperature *lowtemp = (WFTemperature*)low;
        
        hightext = [NSString stringWithFormat:@"%d", (int)(isCelsius ? hightemp.celsius : hightemp.fahrenheit)];
        lowtext = [NSString stringWithFormat:@"%d", (int)(isCelsius ? lowtemp.celsius : lowtemp.fahrenheit)];
    } else {
        hightext = high;
        lowtext = low;
        
        // Convert high/low if needed...
        if (![objc_getClass("IS2Weather") isCelsius]) {
            hightext = [NSString stringWithFormat:@"%d", [self toFarenheit:high.intValue]];
            lowtext = [NSString stringWithFormat:@"%d", [self toFarenheit:low.intValue]];
        }
    }
    
    rect = [XENResources boundedRectForFont:[UIFont systemFontOfSize:15] andText:hightext width:SCREEN_WIDTH*0.8];
    _high.frame = CGRectMake(0, 0, rect.size.width+2, rect.size.height);
    _high.frame = CGRectMake(self.bounds.size.width-50-_high.bounds.size.width, 0, _high.bounds.size.width, self.bounds.size.height);
    _high.text = hightext;
    
    rect = [XENResources boundedRectForFont:[UIFont systemFontOfSize:15] andText:lowtext width:SCREEN_WIDTH*0.8];
    _low.frame = CGRectMake(0, 0, rect.size.width+2, rect.size.height);
    _low.frame = CGRectMake(self.bounds.size.width-20-_low.bounds.size.width, 0, _low.bounds.size.width, self.bounds.size.height);
    _low.text = lowtext;
}

-(int)toFarenheit:(int)input {
    return ((input*9)/5) + 32;
}

-(void)layoutSubviews {
    [super layoutSubviews];
    
    // Layout subviews...
    _weekday.frame = CGRectMake(20, 0, _weekday.frame.size.width, self.bounds.size.height);
    _condition.center = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);
    _low.frame = CGRectMake(self.bounds.size.width-20-_low.bounds.size.width, 0, _low.bounds.size.width, self.bounds.size.height);
    _high.frame = CGRectMake(self.bounds.size.width-50-_high.bounds.size.width, 0, _high.bounds.size.width, self.bounds.size.height);
    
    self.backgroundColor = [UIColor clearColor];
}

-(void)dealloc {
    [_weekday removeFromSuperview];
    _weekday = nil;
    
    [_condition removeFromSuperview];
    _condition = nil;
    
    [_high removeFromSuperview];
    _high = nil;
    
    [_low removeFromSuperview];
    _low = nil;
}

@end
