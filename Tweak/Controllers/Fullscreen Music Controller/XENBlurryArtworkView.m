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

#import "XENBlurryArtworkView.h"

@implementation XENBlurryArtworkView

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _imageView = [[UIImageView alloc] initWithFrame:frame];
        _imageView.contentMode = UIViewContentModeScaleAspectFill;
        _imageView.clipsToBounds = YES;
        _imageView.opaque = YES;
        [self addSubview:_imageView];
        
        blurQueue = dispatch_queue_create("com.matchstic.xen.fullscreenmedia", NULL);
    }
    
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGRect bounds = self.bounds;
    
    CGFloat width = MAX(bounds.size.width, bounds.size.height);
    
    CGRect imageViewFrame = bounds;
    imageViewFrame.size.width = width;
    imageViewFrame.size.height = width;
    imageViewFrame.origin.x = floor((bounds.size.width - imageViewFrame.size.width) / 2.0);
    imageViewFrame.origin.y = floor((bounds.size.height - imageViewFrame.size.height) / 2.0);
    _imageView.frame = imageViewFrame;
}

// This is updated when the display state changes?!
- (void)setArtworkImage:(UIImage *)artworkImage {
    if (_artworkImage == artworkImage)
        return;
    
    _artworkImage = artworkImage;
    
    if (_artworkImage != nil) {
        if (![artworkImage isKindOfClass:[UIImage class]]) {
            _artworkImage = nil;
        }
    }
    
    if (_artworkImage && [[_artworkImage class] isSubclassOfClass:[UIImage class]]) {
        // Setup new blurred image using StackBlur.
        // Do it on a background thread for those on older devces.
        dispatch_async(blurQueue, ^{
            UIImage *blurredImage = nil;
            
            @try {
                blurredImage = [_artworkImage XEN_stackBlur:self.blurRadius];
            } @catch (NSException *e) {
                // Well, bugger.
                blurredImage = nil;
            }
            
            dispatch_async(dispatch_get_main_queue(), ^(void){
                [_imageView setImage:blurredImage];
                
                [self setNeedsLayout];
                [self setNeedsDisplay];
                [_imageView setNeedsDisplay];
            });
        });
    } else {
        // if not an image, well, we can't really handle that.
        [_imageView setImage:nil];
    
        [self setNeedsLayout];
        [self setNeedsDisplay];
        [_imageView setNeedsDisplay];
    }
}

- (UIImage *)artworkImage {
    return _artworkImage;
}

-(void)dealloc {
    [_imageView removeFromSuperview];
    _imageView = nil;
    
    _artworkImage = nil;
}

@end
