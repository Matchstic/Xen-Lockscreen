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

#import "XENPWelcomePickerCell.h"
#import "XENPResources.h"

@implementation XENPWelcomePickerCell

- (instancetype)initWithStyle:(int)style reuseIdentifier:(NSString *)reuseIdentifier specifier:(PSSpecifier *)specifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier specifier:specifier];
    
    if (self) {
        // Setup...
        _picker = [[UIDatePicker alloc] initWithFrame:CGRectZero];
        _picker.datePickerMode = UIDatePickerModeTime;
        _picker.minuteInterval = 15;
        
        // Set default value.
        NSDate *defaultValue = [XENPResources getPreferenceKey:@"welcomeWakeupTime"];
        if (!defaultValue) {
            // Create default value for 6am.
            NSDateComponents *components = [[NSDateComponents alloc] init];
            [components setDay:1];
            [components setMonth:1];
            [components setYear:2016];
            [components setHour:6];
            [components setMinute:0];
            defaultValue = [[NSCalendar currentCalendar] dateFromComponents:components];
        }
        
        [_picker setDate:defaultValue animated:NO];
        
        [_picker addTarget:self action:@selector(dateChanged:) forControlEvents:UIControlEventValueChanged];
        
        [self.contentView addSubview:_picker];
        
        _titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _titleLabel.text = [XENPResources localisedStringForKey:@"Typical Wake Up Time" value:@"Typical Wake Up Time"];
        _titleLabel.textColor = [UIColor blackColor];
        _titleLabel.font = [UIFont systemFontOfSize:15];
        _titleLabel.textAlignment = NSTextAlignmentLeft;
        
        [self.contentView addSubview:_titleLabel];
        
        _seperatorView = [[UIView alloc] initWithFrame:CGRectZero];
        _seperatorView.backgroundColor = [UIColor groupTableViewBackgroundColor];
        
        [self.contentView addSubview:_seperatorView];
    }
    
    return self;
}

- (CGFloat)preferredHeightForWidth:(CGFloat)width {
    // Return a custom cell height.
    return 260.f;
}

-(void)dateChanged:(id)sender {
    [XENPResources setPreferenceKey:@"welcomeWakeupTime" withValue:_picker.date];
}

-(void)layoutSubviews {
    [super layoutSubviews];
    
    // Layout...
    _titleLabel.frame = CGRectMake(15, 0, self.contentView.frame.size.width, 44);
    _seperatorView.frame = CGRectMake(0, 44, self.contentView.frame.size.width, 1);
    _picker.frame = CGRectMake(0, 45, self.contentView.frame.size.width, _picker.frame.size.height);
}

@end
