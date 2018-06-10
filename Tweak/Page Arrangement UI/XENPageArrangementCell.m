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

#import "XENPageArrangementCell.h"
#import "XENBaseViewController.h"
#import "XENDashBoardPageViewController.h"

@implementation XENPageArrangementCell

-(void)setupWithXENController:(XENBaseViewController*)controller {
    if (!self.controllerLabel) {
        self.controllerLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.controllerLabel.textAlignment = NSTextAlignmentCenter;
        self.controllerLabel.textColor = ![XENResources shouldUseDarkColouration] ? [UIColor colorWithWhite:0.1 alpha:1.0] : [UIColor whiteColor];
        self.controllerLabel.font = [UIFont systemFontOfSize:14];
        
        [self.contentView addSubview:self.controllerLabel];
    }
    
    if (self.controllerView.superview == self.contentView) {
        [self.controllerView removeFromSuperview];
        self.controllerView = nil;
    }
    
    self.controllerLabel.text = [controller name];
    self.controllerLabel.alpha = 1.0;
    self.controllerView = controller.view;
    self.controllerView.clipsToBounds = YES;
    self.controllerView.userInteractionEnabled = NO;
    
    if (controller._debugIsReset) {
        [controller configureViewForLock];
    }
    
    [self.contentView addSubview:self.controllerView];
    
    if (![self.controllerView viewWithTag:1999]) {
        CGFloat alpha = 0.25;
        if ([XENResources useSlideToUnlockMode] && [[controller uniqueIdentifier] isEqualToString:@"com.matchstic.home"]) {
            alpha = 0.5;
        }

        UIView *backer = [[UIView alloc] initWithFrame:controller.view.bounds];
        backer.backgroundColor = [UIColor colorWithWhite:[XENResources shouldUseDarkColouration] ? 1.0 : 0.0 alpha:alpha];
        backer.tag = 1999;
        
        [controller.view insertSubview:backer atIndex:0];
    }
    
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

-(void)setupWithDashBoardController:(SBDashBoardPageViewController*)controller {
    if (!self.controllerLabel) {
        self.controllerLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.controllerLabel.textAlignment = NSTextAlignmentCenter;
        self.controllerLabel.textColor = ![XENResources shouldUseDarkColouration] ? [UIColor colorWithWhite:0.1 alpha:1.0] : [UIColor whiteColor];
        self.controllerLabel.font = [UIFont systemFontOfSize:14];
        
        [self.contentView addSubview:self.controllerLabel];
    }
    
    XENlog(@"SETTING UP WITH %@", controller);
    
    if (self.controllerView.superview == self.contentView) {
        [self.controllerView removeFromSuperview];
        self.controllerView = nil;
    }
    
    self.controllerLabel.text = [controller _xen_name];
    self.controllerLabel.alpha = 1.0;
    
    self.controllerView = controller.view;
    self.controllerView.hidden = NO;
    self.controllerView.tag = 12345;
    
    self.controllerView.clipsToBounds = YES;
    self.controllerView.userInteractionEnabled = NO;
    self.contentView.userInteractionEnabled = NO;
    
    if ([controller respondsToSelector:@selector(xenController)]) {
        XENBaseViewController *cont = [(XENDashBoardPageViewController*)controller xenController];
    
        if (cont._debugIsReset) {
            [cont configureViewForLock];
        }
    }
    
    [self.contentView addSubview:self.controllerView];
    
    if (![self.controllerView viewWithTag:1999]) {
        CGFloat alpha = 0.25;
        if ([XENResources useSlideToUnlockMode] && [[controller _xen_identifier] isEqualToString:@"com.apple.main"]) {
            alpha = 0.5;
        }
        
        UIView *backer = [[UIView alloc] initWithFrame:controller.view.bounds];
        backer.backgroundColor = [UIColor colorWithWhite:[XENResources shouldUseDarkColouration] ? 1.0 : 0.0 alpha:alpha];
        backer.tag = 1999;
        
        [controller.view insertSubview:backer atIndex:0];
    }
    
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

-(void)setupWithUnableToLoad {
    if (!self.controllerLabel) {
        self.controllerLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.controllerLabel.textAlignment = NSTextAlignmentCenter;
        self.controllerLabel.textColor = ![XENResources shouldUseDarkColouration] ? [UIColor colorWithWhite:0.1 alpha:1.0] : [UIColor whiteColor];
        self.controllerLabel.font = [UIFont systemFontOfSize:14];
        
        [self.contentView addSubview:self.controllerLabel];
    }
    
    if (self.controllerView.superview == self.contentView) {
        [self.controllerView removeFromSuperview];
        self.controllerView = nil;
    }
    
    self.controllerLabel.text = [XENResources localisedStringForKey:@"Error" value:@"Error"];
    self.controllerLabel.alpha = 1.0;
    
    self.controllerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)];
    self.controllerView.hidden = NO;
    self.controllerView.tag = 12345;
    
    UILabel *label = [[UILabel alloc] initWithFrame:self.controllerView.bounds];
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = [UIColor whiteColor];
    label.text = [XENResources localisedStringForKey:@"Cannot load page" value:@"Cannot load page"];
    label.font = [UIFont systemFontOfSize:16];
    label.numberOfLines = 0;
    
    [self.controllerView addSubview:label];
    
    self.controllerView.clipsToBounds = YES;
    self.controllerView.userInteractionEnabled = NO;
    self.contentView.userInteractionEnabled = NO;
    
    [self.contentView addSubview:self.controllerView];
    
    if (![self.controllerView viewWithTag:1999]) {        
        UIView *backer = [[UIView alloc] initWithFrame:self.controllerView.bounds];
        backer.backgroundColor = [UIColor colorWithWhite:[XENResources shouldUseDarkColouration] ? 1.0 : 0.0 alpha:0.25];
        backer.tag = 1999;
        
        [self.controllerView insertSubview:backer atIndex:0];
    }
    
    [self setNeedsLayout];
    [self layoutIfNeeded];

}

-(void)layoutSubviews {
    self.contentView.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
    
    self.controllerLabel.frame = CGRectMake(0, self.contentView.frame.size.height - 30, self.contentView.frame.size.width, 30);
    
    // Calculate the transform necessary to apply to our controller view.
    if ([self.controllerView.superview isEqual:self.contentView]) {
        self.controllerView.transform = CGAffineTransformIdentity;
        self.controllerView.bounds = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
        CGFloat transform = self.frame.size.width / SCREEN_WIDTH;
        
        self.controllerView.transform = CGAffineTransformMakeScale(transform, transform);
        self.controllerView.frame = CGRectMake(0, 0, self.controllerView.frame.size.width, self.controllerView.frame.size.height);
    
        self.controllerView.layer.cornerRadius = 12.5;
        
        self.controllerView.userInteractionEnabled = NO;
        self.contentView.userInteractionEnabled = NO;
        self.controllerView.clipsToBounds = YES;
        self.controllerView.hidden = NO;
    }
}

-(void)setFrame:(CGRect)frame {
    XENlog(@"Setting frame on cell with %@ to %@", self.controllerLabel.text, NSStringFromCGRect(frame));
    [super setFrame:frame];
}

-(void)setAlpha:(CGFloat)alpha {
    [super setAlpha:alpha];
    
    self.controllerLabel.alpha = alpha;
}

-(void)prepareForReuse {
    [super prepareForReuse];
    
    self.controllerLabel.text = @"";
    if (self.controllerView.superview == self.contentView) {
        [self.controllerView removeFromSuperview];
        self.controllerView = nil;
    }
}

-(void)relayoutController {
    [self.contentView addSubview:self.controllerView];
    [self setNeedsLayout];
}

-(NSString*)description {
    return [NSString stringWithFormat:@"<%@, controller identifier is %@>", [self class], self.controllerIdentifier];
}

@end
