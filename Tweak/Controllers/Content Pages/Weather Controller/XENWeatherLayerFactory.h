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

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIKit.h>

#warning Private filesystem access used here.

@interface WFTemperature : NSObject
@property (nonatomic) double celsius;
@property (nonatomic) double fahrenheit;
@property (nonatomic) double kelvin;
@end

@interface XENWeatherLayerFactory : NSObject

@property(strong, nonatomic) NSBundle *weatherFrameworkBundle;

+(instancetype)sharedInstance;

-(id)layerForCondition:(int)arg1 isDay:(_Bool)arg2;
-(CALayer*)colourBackingLayerForCondition:(int)condition isDay:(BOOL)isDay;

-(NSString*)nameForCondition:(int)condition;
-(UIImage*)iconForCondition:(int)condition wantsLargerIcons:(BOOL)larger;
-(NSString*)weatherStringForString:(NSString*)input;
//-(UIView*)viewForCondition:(int)condition isDay:(BOOL)isDay;

@end
