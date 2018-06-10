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

#import "XENReactiveButton.h"

@implementation XENReactiveButton

-(void)setHighlighted:(BOOL)highlighted {
    if (highlighted)
        [UIView animateWithDuration:0.01 animations:^{
            self.transform = CGAffineTransformMakeScale(0.85, 0.85);
            self.alpha = 0.8;
        }];
    else
        [UIView animateWithDuration:0.075 animations:^{
            self.transform = CGAffineTransformMakeScale(1.0, 1.0);
            self.alpha = 1.0;
        }];
    
    [super setHighlighted:highlighted];
}

@end
