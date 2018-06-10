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

#import "XENAccelerometerHandler.h"

CGFloat normalise(CGFloat input);

@implementation XENAccelerometerHandler

CGFloat normalise(CGFloat input) {
    return input > 0.0 ? input : -input;
}

-(instancetype)initWithThreshold:(CGFloat)threshold {
    self = [super init];
    
    if (self) {
        _threshold = threshold;
        _manager = [[CMMotionManager alloc] init];
        _manager.accelerometerUpdateInterval = ACCEL_UPDATE_INTERVAL;
        _manager.deviceMotionUpdateInterval = ACCEL_UPDATE_INTERVAL;
    }
    
    return self;
}

-(void)startMonitoringWithCallback:(void (^)(void))callback {
    self.callback = callback;
    self.isUpdating = YES;
    
    // If using device motion data...
    if ([_manager isDeviceMotionAvailable]) {
        [self setActualThreshold:YES];
        
        // Use roll, pitch and yaw to work out the orientation of our device. We need to be close to normal hold to fire off correctly.
    
        [_manager startDeviceMotionUpdatesUsingReferenceFrame:CMAttitudeReferenceFrameXArbitraryZVertical toQueue:[NSOperationQueue mainQueue] withHandler:^(CMDeviceMotion *data, NSError *error) {
            
            //double yaw = data.attitude.yaw;
            double pitch = data.attitude.pitch;
            double roll = data.attitude.roll;
            
            // On normal settings:
            // We should fire when the pitch is in the range 0.5 - 1.0
            
            // Pitch: 1.5 denotes vertical, -1.5 denotes upside down vertical.
            // Roll: Greater than -1 if flipped, otherwise is between -1.5 and 1.5
            // _actualThreshold denotes the lower bound of pitch.
        
            BOOL rollValid = roll < 1.0 && roll > -1.0;
            BOOL pitchValid = pitch > _actualThreshold;
            
            if (rollValid && pitchValid) {
                self.callback();
            }
        }];
    } else {
        _startX = 0.0;
        _startY = 0.0;
        _startZ = 0.0;
        
        _began = YES;
        
         [self setActualThreshold:NO];
        
        [_manager startAccelerometerUpdatesToQueue:[NSOperationQueue mainQueue] withHandler:^(CMAccelerometerData *data, NSError *error) {
            // Normalise data...
            if (_began) {
                _startX = normalise(data.acceleration.x);
                _startY = normalise(data.acceleration.y);
                _startZ = normalise(data.acceleration.z);
                
                _began = NO;
            } else {
                CGFloat x = normalise(data.acceleration.x), y = normalise(data.acceleration.y), z = normalise(data.acceleration.z);
                
                x = normalise(x - _startX);
                y = normalise(y - _startY);
                z = normalise(z - _startZ);
        
                if (x > _actualThreshold || y > _actualThreshold || z > _actualThreshold) {
                    self.callback();
                }
            }
        }];
    }
}

-(void)setActualThreshold:(BOOL)isMotionAvailable {
    if (isMotionAvailable) {
        
        // Note: 0.75 == 45 degree angle held at.
        // From above, ~20-30 degrees looks normal.
        
        switch ((int)_threshold) {
        case 0:
            _actualThreshold = 0.2;
            break;
        case 1:
            _actualThreshold = 0.3;
            break;
        case 2:
            _actualThreshold = 0.4;
            break;
        case 3:
            _actualThreshold = 0.5;
            break;
        case 4:
            _actualThreshold = 0.6;
            break;
        default:
            _actualThreshold = 0.4;
            break;
        }
    } else {
        switch ((int)_threshold) {
        case 0:
            _actualThreshold = 0.1;
            break;
        case 1:
            _actualThreshold = 0.25;
            break;
        case 2:
            _actualThreshold = 0.35;
            break;
        case 3:
            _actualThreshold = 0.45;
            break;
        case 4:
            _actualThreshold = 0.6;
            break;
        default:
            _actualThreshold = 0.35;
            break;
        }
    }
}

-(void)pauseMonitoring {
    self.isUpdating = NO;
    if ([_manager isDeviceMotionAvailable])
        [_manager stopDeviceMotionUpdates];
    else
        [_manager stopAccelerometerUpdates];
}

-(void)dealloc {
    _manager = nil;
    self.callback = nil;
}

@end
