//
//  SPDraggingProxyView.h
//  DragNDropFeature
//
//  Created by Nevyn Bengtsson on 2012-12-14.
//  Copyright (c) 2012 Spotify. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol DragonProxyView <NSObject>
- (void)animateOut:(dispatch_block_t)completion forSuccess:(BOOL)wasSuccessful;
@end

@interface DragonProxyView : UIView <DragonProxyView>
- (instancetype)initWithIcon:(UIImage*)icon title:(NSString*)title subtitle:(NSString*)subtitle;
@end

@interface DragonNotProxyView : UIView <DragonProxyView>
- (instancetype)initWithView:(UIView*)view;
- (void)handleAutoResizingAtPoint:(CGPoint)p;
@property (nonatomic, weak) UIView *workedOnView;
@end

@interface DragonScreenshotProxyView : UIImageView <DragonProxyView>
- (instancetype)initWithScreenshot:(UIImage *)screenshot;
@end
