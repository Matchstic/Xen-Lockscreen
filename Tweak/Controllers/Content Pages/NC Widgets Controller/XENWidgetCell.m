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

#import "XENWidgetCell.h"

@interface _UIBackdropView (Thing)
- (void)_setBlursBackground:(BOOL)arg1;
@end

@implementation XENWidgetCell

// TODO: Sort out removal of views by accident. Seems the table view tries to reuse us, when really we're still
// displaying a cell. Odd, eh?!

-(void)prepareForReuse {
    _titleLabel.text = @"";
    _iconView.image = nil;
    
    [_widgetController.view removeFromSuperview];
    _rowInfo = nil;
    
    [super prepareForReuse];
}

-(void)readyWidgetForReuse {
    _titleLabel.text = @"";
    _iconView.image = nil;
    
    XENlog(@"READY WIDGET FOR REUSE: %@", [_widgetController widgetIdentifier]);
    [_widgetController.view removeFromSuperview];
    _rowInfo = nil;
}

-(void)prepareForReloadOfUI {
    // Break blur effect.
    [_blurView _setBlursBackground:NO];
}

-(void)finishedReloadingUI {
    // Re-apply blur effect.
    [_blurView _setBlursBackground:YES];
}

-(void)initialiseViewsIfNeeded {
    if (_viewsInitialised) {
        return;
    }
    
    if (!_blurView) {
        _UIBackdropViewSettings *settings = [objc_getClass("_UIBackdropViewSettings") settingsForPrivateStyle:([XENResources widgetsAlternateColoursMode] ? 2060 : 1)];
        _blurView = [[objc_getClass("_UIBackdropView") alloc] initWithFrame:CGRectZero autosizesToFitSuperview:NO settings:settings];
        _blurView.layer.cornerRadius = 12.5;
        _blurView.layer.masksToBounds = YES;
        
        [self.contentView addSubview:_blurView];
    }
    
    if (!_titleBackingView) {
        _titleBackingView = [[UIView alloc] initWithFrame:CGRectZero];
        
        if (![XENResources widgetsAlternateColoursMode]) {
            _titleBackingView.backgroundColor = [UIColor darkGrayColor];
            _titleBackingView.alpha = 0.75;
        } else {
            _titleBackingView.backgroundColor = [UIColor whiteColor];
            _titleBackingView.alpha = 0.25;
        }
        
        [_blurView.contentView addSubview:_titleBackingView];
    }
    
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _titleLabel.font = [UIFont systemFontOfSize:15];
        _titleLabel.textAlignment = NSTextAlignmentLeft;
        _titleLabel.textColor = ([XENResources widgetsAlternateColoursMode] ? [UIColor colorWithWhite:0.0 alpha:0.65] : [UIColor whiteColor]);
        _titleLabel.text = @"";
        _titleLabel.numberOfLines = 1;
        
        [self.contentView addSubview:_titleLabel];
    }
    
    if (!_iconView) {
        _iconView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
        _iconView.image = nil;
        
        [self.contentView addSubview:_iconView];
    }
    
    _viewsInitialised = YES;
}

-(void)setupWithRowInfo:(SBWidgetRowInfo*)rowInfo andDelegate:(id<SBWidgetViewControllerDelegate, XENWidgetCellDelegate>)delegate {
    if ([_widgetController.view.superview isEqual:self.contentView]) {
        [_widgetController.view removeFromSuperview];
    }
    
    self.identifier = [rowInfo identifier];
    self.delegate = delegate;
    self.widgetController = rowInfo.widget;
    _rowInfo = rowInfo;
    
    // Configure views etc.
    [self initialiseViewsIfNeeded];
    
    _titleLabel.text = [_rowInfo displayName];
    _iconView.image = [_rowInfo icon];
    
    // And add the new widget view to our UI.
    [self.contentView addSubview:_widgetController.view];
    
    self.backgroundColor = [UIColor clearColor];
    self.contentView.backgroundColor = [UIColor clearColor];
    
    self.contentView.layer.masksToBounds = YES;
}

-(void)layoutSubviews {
    // Setup frames etc.
    [super layoutSubviews];
    
    CGFloat width = self.contentView.frame.size.width - 15;
    CGFloat height = self.contentView.frame.size.height - 10;
    CGFloat xInset = 7.5;
    CGFloat yInset = 5;
    
    if (IS_IPAD) {
        CGFloat sizing = (orient3 == 1 || orient3 == 2 ? SCREEN_WIDTH*0.1 : SCREEN_WIDTH*0.175);
        
        width -= sizing*2;
        xInset += sizing;
    }
    
    _blurView.frame = CGRectMake(xInset, yInset, width, height);
    _falseAnimationView.frame = CGRectMake(xInset, yInset, width, height);
    
    // Now for title, and icon.
    _iconView.frame = CGRectMake(xInset + 10, yInset + 10, 20, 20);
    _titleLabel.frame = CGRectMake(xInset + 40, yInset, width - xInset - 5, 40);
    _titleBackingView.frame = CGRectMake(0, 0, _blurView.contentView.frame.size.width, 40);
    
    // And finally, the widget itself.
    _widgetController.view.frame = CGRectMake(xInset, yInset+40, width, _rowInfo.preferredViewHeight);
    
    self.contentView.layer.cornerRadius = 12.5;
    self.contentView.layer.masksToBounds = YES;
}

#pragma mark Selection handling.

-(void)setSelected:(BOOL)selected animated:(BOOL)animated {}

-(void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {}

// Handle taps outside of the widget.
-(UIView*)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    if (point.y < 5 || point.y > _blurView.frame.size.height + 5 || point.x < _blurView.frame.origin.x || point.x > _blurView.frame.size.width + 7.5) {
        return nil;
    }
    
    return [super hitTest:point withEvent:event];
}

-(void)dealloc {
    [_widgetController.view removeFromSuperview];
    [_widgetController removeFromParentViewController];
    _widgetController = nil;
    
    _rowInfo = nil;
    
    [_blurView removeFromSuperview];
    _blurView = nil;
    
    [_iconView removeFromSuperview];
    _iconView = nil;
    
    [_titleLabel removeFromSuperview];
    _titleLabel = nil;
    
    [_titleBackingView removeFromSuperview];
    _titleBackingView = nil;
}

@end
