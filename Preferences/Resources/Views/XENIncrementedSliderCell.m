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

#import "XENIncrementedSliderCell.h"
#import "XENPResources.h"

@implementation XENPIncrementedSliderCell

- (id)initWithStyle:(int)arg1 reuseIdentifier:(id)arg2 specifier:(id)arg3 {
    self = [super initWithStyle:arg1 reuseIdentifier:arg2 specifier:arg3];
    if (self) {
        UIDiscreteSlider *replacementSlider = [[UIDiscreteSlider alloc] initWithFrame:self.control.frame];
        [replacementSlider addTarget:self action:@selector(saveSliderValue) forControlEvents:UIControlEventTouchUpInside];
        replacementSlider.increment = 0.1;
        [self setControl:replacementSlider];
    }
    return self;
}
- (void)layoutSubviews {
    [super layoutSubviews];
    
    NSNumber *value = [self numberForSpecifier:[self specifier]];
    UIDiscreteSlider *slider = (UIDiscreteSlider *) self.control;
    slider.value = [value floatValue];
}

- (void)saveSliderValue {
    UIDiscreteSlider *slider = (UIDiscreteSlider *) self.control;
    NSNumber *value = @(slider.value);
    [self setNumber:value forKey:[[self specifier] propertyForKey:@"key"]];
}

-(NSNumber*)numberForSpecifier:(PSSpecifier*)specifier {
    id data = [XENPResources getPreferenceKey:[specifier propertyForKey:@"key"]];
    
    return (data ? data : [specifier propertyForKey:@"default"]);
}

-(void)setNumber:(NSNumber*)number forKey:(NSString*)key {
    [XENPResources setPreferenceKey:key withValue:number];
}

@end
