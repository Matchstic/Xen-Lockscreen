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

#import "XENLegibilityLabel.h"

@implementation XENLegibilityLabel

-(instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    
    if (self) {
        // We need to register for changes from CustomCover
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleCustomCoverChanged:)
                                                     name:@"CustomCoverLockScreenColourUpdateNotification"
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleCustomCoverReset:)
                                                     name:@"CustomCoverLockScreenColourResetNotification"
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(updateLegibilityIfNecessary)
                                                     name:@"XENLegibibilityDidChange"
                                                   object:nil];
    }
    
    return self;
}

-(void)handleCustomCoverChanged:(NSNotification*)sender {
    NSDictionary *dict = [sender userInfo];
    self.textColor = dict[@"SecondaryColour"];
}

-(void)handleCustomCoverReset:(NSNotification*)sender {
    self.textColor = [XENResources effectiveLegibilityColor];
}

-(void)updateLegibilityIfNecessary {
    self.textColor = [XENResources effectiveLegibilityColor];
}

-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
