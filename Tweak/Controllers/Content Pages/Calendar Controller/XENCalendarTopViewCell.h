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

#import <UIKit/UIKit.h>

#define CELL_WIDTH (IS_IPAD ? 100 : 40)
#define CELL_HEIGHT (IS_IPAD ? 45 : 60)

@protocol XENCalTopCell <NSObject>
-(void)didTapCellWithTag:(NSInteger)tag;
@end

// Background red view is handled by the delegate. We just handle text colours.
@interface XENCalendarTopViewCell : UIView {
    UIButton *_button;
    UILabel *_numberLabel;
    UILabel *_dayLabel;
}

@property (nonatomic, weak) id<XENCalTopCell> delegate;
@property (nonatomic, strong) NSDate *date;

-(void)setupWithDate:(NSDate*)date;

@end
