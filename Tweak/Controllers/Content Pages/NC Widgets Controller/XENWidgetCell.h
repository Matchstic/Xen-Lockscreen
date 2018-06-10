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

#import <UIKit/UIKit.h>

@protocol XENWidgetCellDelegate <NSObject>
-(UIBlurEffect*)widgetBlurEffect;
@end

@interface XENWidgetCell : UITableViewCell {
    _UIBackdropView *_blurView;
    UIImageView *_iconView;
    UILabel *_titleLabel;
    UIView *_titleBackingView;
    UIView *_falseAnimationView;
    BOOL _viewsInitialised;
    
    // Shite for widget controller.
    SBWidgetRowInfo *_rowInfo;
}

@property (nonatomic, strong) NSString *identifier;
@property (nonatomic, weak) id<SBWidgetViewControllerDelegate, XENWidgetCellDelegate> delegate;
@property (nonatomic, weak) SBWidgetViewController *widgetController;

-(void)setupWithRowInfo:(SBWidgetRowInfo*)rowInfo andDelegate:(id<SBWidgetViewControllerDelegate, XENWidgetCellDelegate>)delegate;
-(void)readyWidgetForReuse;

-(void)prepareForReloadOfUI;
-(void)finishedReloadingUI;

@end
