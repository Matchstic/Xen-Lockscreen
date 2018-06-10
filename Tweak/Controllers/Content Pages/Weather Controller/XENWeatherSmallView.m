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

#import "XENWeatherSmallView.h"
#import "XENWeatherLayerFactory.h"
#import "IS2Weather.h"
#include <math.h>

int RoundNum(int num);

@interface IS2System : NSObject
+ (BOOL)isDeviceIn24Time;
@end

@implementation XENWeatherSmallView

-(void)_configureIfNeeded {
    if (!_hourLabel) {
        _hourLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 8, self.bounds.size.width, 14.5)];
        _hourLabel.font = [UIFont systemFontOfSize:13];
        _hourLabel.text = @"";
        _hourLabel.textAlignment = NSTextAlignmentCenter;
        _hourLabel.textColor = [UIColor whiteColor];
        
        [self addSubview:_hourLabel];
    }
        
    // Chance of rain shenanigans.
    if (!_precipitationLabel) {
        _precipitationLabel = [[UILabel alloc] initWithFrame:CGRectMake(1, 23.5, self.bounds.size.width, 13.5)];
        _precipitationLabel.font = [UIFont systemFontOfSize:10];
        _precipitationLabel.text = @"";
        _precipitationLabel.textAlignment = NSTextAlignmentCenter;
        _precipitationLabel.textColor = [UIColor colorWithRed:0.13 green:0.78 blue:0.99 alpha:1.0];
        
        [self addSubview:_precipitationLabel];
    }
    
    if (!_icon) {
        _icon = [[UIImageView alloc] initWithImage:nil];
        _icon.center = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);
        
        [self addSubview:_icon];
    }
    
    if (!_temperatureLabel) {
        _temperatureLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 71, self.frame.size.width, 17)];
        _temperatureLabel.font = [UIFont systemFontOfSize:13];
        _temperatureLabel.textColor = [UIColor whiteColor];
        _temperatureLabel.textAlignment = NSTextAlignmentCenter;
        
        [self addSubview:_temperatureLabel];
    }
}

-(void)prepareForReuse {
    _conditionCode = 0;
    _temperature = nil;
}

-(void)reuseWithConditionCode:(int)condition temperature:(NSString*)temperature rain:(CGFloat)chanceOfRain isDay:(BOOL)isDay andHour:(NSString*)hourIndex isNow:(BOOL)isNow {
    [self _configureIfNeeded];
    
    _conditionCode = condition;
    
    // CAREFUL! On iOS 10, a forecast's temperature is a WFTemperature.
    if ([temperature isKindOfClass:objc_getClass("WFTemperature")]) {
        BOOL isCelsius = [objc_getClass("IS2Weather") isCelsius];
        
        WFTemperature *temp = (WFTemperature*)temperature;
        _temperature = [NSString stringWithFormat:@"%d", (int)(isCelsius ? temp.celsius : temp.fahrenheit)];
    } else {
        _temperature = temperature;
        if (![objc_getClass("IS2Weather") isCelsius] && !isNow) {
            _temperature = [NSString stringWithFormat:@"%d", [self toFarenheit:_temperature.intValue]];
        }
    }
    
    _chanceOfRain = chanceOfRain;
    _hour = hourIndex;
    
    // Work out hour text.
    NSString *subString;
    
    if ([_hour rangeOfString: @":"].location != NSNotFound)
        subString = [_hour substringWithRange: NSMakeRange(0, [_hour rangeOfString: @":"].location)];
    else
        subString = _hour;
    
    // Also, we need to handle 12/24hr time
    if (![objc_getClass("IS2System") isDeviceIn24Time] && [_hour rangeOfString: @":"].location != NSNotFound) {
        NSString *testString = subString;
        if ([subString hasPrefix:@"0"]) {
            // Remove prefix
            testString = [subString substringFromIndex:1];
        }
        
        int value = testString.intValue;
        
        NSString *ampm = @"";
        
        if (value > 12) {
            value -= 12;
            
            // Set to PM
            ampm = [XENResources sharedDateFormatter].PMSymbol;
        } else {
            // Set ampm to AM
            ampm = [XENResources sharedDateFormatter].AMSymbol;
        }
        
        if (value == 0) {
            // Handle midnight
            value = 12;
            ampm = [XENResources sharedDateFormatter].AMSymbol;
        } else if (value == 12) {
            // Handle midday
            ampm = [XENResources sharedDateFormatter].PMSymbol;
        }
        
        subString = [NSString stringWithFormat:@"%d%@", value, ampm];
    }
    
    _hourLabel.text = subString;
    
    // Chance of rain shenanigans.
    _precipitationLabel.text = (chanceOfRain >= 30 ? [NSString stringWithFormat:@"%d%%", RoundNum((int)_chanceOfRain)] : @"");
    
    UIImage *img = [[XENWeatherLayerFactory sharedInstance] iconForCondition:_conditionCode wantsLargerIcons:YES];
    _icon.image = img;
        
    [_icon sizeToFit];
    _icon.center = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);
    
    NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithString:@""];
    
    NSDictionary * attributes = [NSDictionary dictionaryWithObject:[UIFont systemFontOfSize:13 weight:UIFontWeightUltraLight] forKey:NSFontAttributeName];
    NSAttributedString *subString1 = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@", _temperature] attributes:attributes];
    [str appendAttributedString:subString1];
    
    NSMutableDictionary * attributes2 = [NSMutableDictionary dictionaryWithObject:[UIFont systemFontOfSize:13 weight:UIFontWeightLight] forKey:NSFontAttributeName];
    //[attributes2 setObject:[NSNumber numberWithDouble:0] forKey:NSBaselineOffsetAttributeName];
    NSAttributedString * subString2 = [[NSAttributedString alloc] initWithString:[[XENWeatherLayerFactory sharedInstance] weatherStringForString:@"DEGREE"] attributes:attributes2];
    [str appendAttributedString:subString2];
    
    _temperatureLabel.attributedText = str;
    _temperatureLabel.frame = CGRectMake(0, 71, self.frame.size.width, 17);
}

-(int)toFarenheit:(int)input {
    return ((input*9)/5) + 32;
}

-(void)setForNow {
    _hourLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
    _temperatureLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
}

-(void)dealloc {
    _temperature = nil;
    _chanceOfRain = 0;
    _hour = nil;
    
    [_hourLabel removeFromSuperview];
    _hourLabel = nil;
    
    [_temperatureLabel removeFromSuperview];
    _temperatureLabel = nil;
    
    [_precipitationLabel removeFromSuperview];
    _precipitationLabel = nil;
    
    [_icon removeFromSuperview];
    _icon = nil;
}

int RoundNum(int num) {
    int rem = num % 10;
    return rem >= 5 ? (num - rem + 10) : (num - rem);
}

@end
