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

#import "XENPocketStateDelegate.h"

@implementation XENPocketStateDelegate

-(instancetype)init {
    self = [super init];
    
    if (self) {
        _isDetectionEnabled = NO;
        _inPocketCallback = nil;
        _outPocketCallback = nil;
        _pocketStateManager = nil;
    }
    
    return self;
}

-(void)registerInPocketCallack:(XENPocketBlock)callback {
    _inPocketCallback = callback;
}

-(void)registerOutPocketCallack:(XENPocketBlock)callback {
    _outPocketCallback = callback;
}

-(void)enablePocketDetection {
    if (![XENPocketStateDelegate isPocketDetectionAvailable]) {
        return;
    }
    
    _pocketStateManager = [[objc_getClass("CMPocketStateManager") alloc] init];
    [_pocketStateManager setDelegate:self];
    
    [_pocketStateManager queryStateOntoQueue:dispatch_get_main_queue() andMonitorFor:60.0 withTimeout:60.0 andHandler:nil];
}

-(void)disablePocketDetection {
    XENlog(@"Disabling pocket detection");
    
    [_pocketStateManager setDelegate:nil];
    _pocketStateManager = nil;
}

+(BOOL)isPocketDetectionAvailable {
    return [objc_getClass("CMPocketStateManager") isPocketStateAvailable]; //[XENResources peekUsesCoreMotion];
}

-(void)dealloc {
    _isDetectionEnabled = NO;
    _inPocketCallback = nil;
    _outPocketCallback = nil;
    _pocketStateManager = nil;
}

#pragma mark Delegate

-(void)pocketStateManager:(CMPocketStateManager*)arg1 didUpdateState:(long long)arg2 {
    /*
     In delegate, states are:
     0 - "OutOfPocket"
     1 - "InPocket"
     2 - "FaceDown"
     3 - "FaceDownOnTable"
     */
    
    XENlog(@"Pocket state changed: %d, %@", arg2, [arg1 externalStateToString:(int)arg2]);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (arg2 == 0 && _outPocketCallback) {
            // Out of pocket.
            _outPocketCallback();
        } else if ((arg2 == 1 || arg2 == 3) && _inPocketCallback) { // When face down on table, or in pocket, screen is obscured.
            _inPocketCallback();
        }
    });
}

@end
