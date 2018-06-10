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

#import "XENSetupMultipleSwitchView.h"

@implementation XENSetupMultipleSwitchView

-(instancetype)initWithItems:(NSArray *)items andSpecifierKey:(NSString *)key {
    self = [super initWithFrame:CGRectZero];
    
    if (self) {
        _key = key;
        
        // Initialise cells
        int count = 0;
        for (NSDictionary *dict in items) {
            XENSetupMultipleSwitchCell *cell = [[XENSetupMultipleSwitchCell alloc]
                                            initWithImage:[UIImage imageWithContentsOfFile:dict[@"imagePath"]]
                                            label:[XENResources localisedStringForKey:dict[@"label"] value:dict[@"label"]]
                                            node:count
                                            andDelegate:self];
            [self addSubview:cell];
            
            count++;
        }
    }
    
    return self;
}

-(void)layoutSubviews {
    [super layoutSubviews];
    
    // Layout cells.
    int cellCount = (int)[self.subviews count];
    
    for (XENSetupMultipleSwitchCell *cell in self.subviews) {
        CGFloat xOrigin;
        CGFloat width = self.frame.size.height * 0.5;
        
        if (width * cellCount > self.frame.size.width) {
            width = self.frame.size.width/cellCount;
        }
        
        if (cellCount % 2 != 0) {
            // There'll be a cell sitting in the middle.
            if (cell.node + 1 <= floorf((float)cellCount/2.0)) {
                // We're on the left.
                XENlog(@"Cell %d on left", cell.node);
                xOrigin = self.frame.size.width/2 - width/2 + ((cell.node - floorf((float)cellCount/2.0)) * width);
            } else if (cell.node + 1 > ceilf((float)cellCount/2.0)) {
                XENlog(@"Cell %d on right", cell.node);
                // We're on the right
                xOrigin = self.frame.size.width/2 + width/2 + ((cell.node - ceilf((float)cellCount/2.0)) * width);
            } else {
                // We're in the middle
                XENlog(@"Cell %d on middle", cell.node);
                xOrigin = self.frame.size.width/2 - width/2;
            }
        } else {
            // No cell in middle
            xOrigin = self.frame.size.width/2 + ((cell.node - cellCount/2) * width);
        }
        
        cell.frame = CGRectMake(xOrigin, 0, width, self.frame.size.height);
    }
}

#pragma mark Delegate

-(void)didSelectNode:(int)node {
    for (XENSetupMultipleSwitchCell *cell in self.subviews) {
        [cell setEnabled:cell.node == node];
    }
    
    [XENResources setPreferenceKey:_key withValue:[NSNumber numberWithInt:node] andPost:YES];
}

-(void)dealloc {
    for (UIView *view in self.subviews) {
        [view removeFromSuperview];
    }
}

@end
