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

#import "XENPageArrangementGesture.h"

@implementation XENPageArrangementGesture

- (void)touchesBegan:(NSSet*)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    if (self.numberOfTouches != self.maximumNumberOfTouches) {
        XENlog(@"Cancelling...");
        self.state = UIGestureRecognizerStateFailed;
    }
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesMoved:touches withEvent:event];
    if (self.numberOfTouches != self.maximumNumberOfTouches) {
        XENlog(@"Ending early...");
        self.state = UIGestureRecognizerStateEnded;
    }
}

- (BOOL)canBePreventedByGestureRecognizer:(UIGestureRecognizer *)preventingGestureRecognizer {
    XENlog(@"Checking if page gesture can be prevented");
    
    if ([[preventingGestureRecognizer class] isEqual:[UITapGestureRecognizer class]]) {
        return YES;
    }
    
    return NO;
}

- (BOOL)canPreventGestureRecognizer:(UIGestureRecognizer *)preventedGestureRecognizer {
    XENlog(@"Checking if page gesture can prevent other gestures");
    return YES;
}

- (BOOL)shouldBeRequiredToFailByGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    XENlog(@"Checking if page gesture needs to fail before others can work");
    return YES;
}

@end
