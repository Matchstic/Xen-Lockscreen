#import "DragonController.h"
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>
#import "DragonDropHighlightView.h"
#import "DragonContainerWindow.h"
#import "DragonProxyView.h"

@class SPDropTarget, SPDragSource;

#define DNDLog(...) NSLog(__VA_ARGS__)
//#define DNDLog(...)

static NSString *const kDragMetadataKey = @"eu.thirdcog.dragndrop.meta";

static const void *kLongPressGrecKey = &kLongPressGrecKey;
static const void *kDragSourceKey = &kDragSourceKey;
static const void *kDropTargetKey = &kDropTargetKey;

@interface SPDraggingState : NSObject <DragonInfo>
// Initial, transferrable state
@property(nonatomic,strong) UIImage *screenshot;
@property(nonatomic,copy) NSString *title;
@property(nonatomic,copy) NSString *subtitle;
@property(nonatomic,strong) UIImage *draggingIcon;
@property(nonatomic,strong) UIPasteboard *pasteboard;
@property(nonatomic,assign) CGPoint initialPositionInScreenSpace;
@property(nonatomic,assign) NSString *operationIdentifier;

// During-drag state
@property(nonatomic,strong) NSArray *originalPasteboardContents;
@property(nonatomic,strong) UIView *dragView; // the thing that was long-pressed
@property(nonatomic,strong) UIView<DragonProxyView> *proxyView; // thing under finger
@property(nonatomic,strong) NSArray *activeDropTargets;
@property(nonatomic,strong) NSTimer *springloadingTimer;
@property(nonatomic,strong) NSTimer *conclusionTimeoutTimer;
@property(nonatomic,weak) SPDropTarget *hoveringTarget;
@end

@interface SPDragSource : NSObject
@property(nonatomic,weak) UIView *view;
@property(nonatomic,weak) id<DragonDelegate> delegate;
@end

@interface SPDropTarget : NSObject
@property(nonatomic,weak) UIView *view;
@property(nonatomic,weak) id<DragonDropDelegate> delegate;
@property(nonatomic,strong) DragonDropHighlightView *highlight;
- (BOOL)canSpringload:(id<DragonInfo>)drag;
- (BOOL)canDrop:(id<DragonInfo>)drag;
@end

@interface DragonControllerModified () <UIGestureRecognizerDelegate>
{
    NSMutableSet *_dropTargets;
    NSTimer *_highlightTimer;
}
@property(nonatomic,strong) SPDraggingState *state;
@property(nonatomic,weak) UIView *draggingContainer;
@property(nonatomic,weak) UIView *workingView;
@property (nonatomic, weak) id<DragonDelegate> delegate;
@end

@implementation DragonControllerModified

- (id)init {
    if (!(self = [super init]))
        return nil;
	
    _dropTargets = [NSMutableSet new];
	
    return self;
}

- (void)dealloc {

}

#pragma mark - Gestures

- (void)enableLongPressDraggingInWindow:(UIView*)window {
	UILongPressGestureRecognizer *longPressGrec = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(dragGesture:)];
	longPressGrec.delegate = self;
    longPressGrec.minimumPressDuration = 0.2;
	[window addGestureRecognizer:longPressGrec];
	objc_setAssociatedObject(window, kLongPressGrecKey, longPressGrec, OBJC_ASSOCIATION_RETAIN);
    
    self.workingView = window;
    self.draggingContainer = window;
}

- (void)disableLongPressDraggingInWindow:(UIWindow*)window
{
	UILongPressGestureRecognizer *longPressGrec = objc_getAssociatedObject(window, kLongPressGrecKey);
	if(!longPressGrec)
		return;
	
	[window removeGestureRecognizer:longPressGrec];
	objc_setAssociatedObject(window, kLongPressGrecKey, nil, OBJC_ASSOCIATION_RETAIN);
}

- (BOOL)draggingOperationIsInProgress
{
	return _state != nil;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return self.draggingOperationIsInProgress;
}

- (void)dragGesture:(UIGestureRecognizer*)grec
{
    if(grec.state == UIGestureRecognizerStateBegan) {
        SPDragSource *initiator = [self sourceUnderLocation:[grec locationInView:grec.view]];
        [self startDraggingWithInitiator:initiator event:grec];
    } else if(grec.state == UIGestureRecognizerStateChanged) {
        [self continueDraggingFromGesture:[grec locationInView:_draggingContainer]];
    } else if(grec.state == UIGestureRecognizerStateEnded) {
        [self concludeDraggingFromGesture];
    } else if(grec.state == UIGestureRecognizerStateCancelled) {
        [self cancelDragging];
    }
}

#pragma mark - Registration

- (void)registerDragSource:(UIView *)draggable delegate:(id<DragonDelegate>)delegate
{
	SPDragSource *source = [SPDragSource new];
	source.view = draggable;
	source.delegate = delegate;
    objc_setAssociatedObject(draggable, kDragSourceKey, source, OBJC_ASSOCIATION_RETAIN);
}

- (void)unregisterDragSource:(UIView *)draggable
{
    SPDragSource *source = objc_getAssociatedObject(draggable, kDragSourceKey);
	if(source) {
		objc_setAssociatedObject(draggable, kDragSourceKey, NULL, OBJC_ASSOCIATION_RETAIN);
	}
}

- (void)registerDropTarget:(UIView *)droppable delegate:(id<DragonDropDelegate>)delegate
{
    [self unregisterDropTarget:droppable];
    
    SPDropTarget *target = [SPDropTarget new];
    target.view = droppable;
    target.delegate = delegate;
    [_dropTargets addObject:target];
    objc_setAssociatedObject(droppable, kDropTargetKey, target, OBJC_ASSOCIATION_ASSIGN);
    
    
    if(_state) {
		if([target.delegate dropTarget:target.view canAcceptDrag:_state]) {
            _state.activeDropTargets = [_state.activeDropTargets arrayByAddingObject:target];
        }
    }
}

- (void)unregisterDropTarget:(id)droppable
{
    for(SPDropTarget *target in [_dropTargets allObjects]) {
        if(target.view == droppable || target.delegate == droppable) {
            [_dropTargets removeObject:target];
            [target.highlight removeFromSuperview];
            objc_setAssociatedObject(target.view, kDropTargetKey, nil, OBJC_ASSOCIATION_ASSIGN);
            break;
        }
    }
}

static UIImage *screenshotForView(UIView *view)
{
    CGSize sz = view.frame.size;
    UIGraphicsBeginImageContextWithOptions(sz, NO, view.traitCollection.displayScale);

	if(![view drawViewHierarchyInRect:(CGRect){.size=sz} afterScreenUpdates:NO])
		[view.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *screenShot = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return screenShot;
}

static NSDictionary *serializedImage(UIImage *image)
{
	return @{
		@"scale": @(image.scale),
		@"pngData": UIImagePNGRepresentation(image),
	};
}

static UIImage *unserializedImage(NSDictionary *rep)
{
	if(!rep || !rep[@"pngData"] || !rep[@"scale"])
		return nil;
	return [UIImage imageWithData:rep[@"pngData"] scale:[rep[@"scale"] floatValue]];
}

#pragma mark Application frame and coordinate system util

- (CGPoint)convertLocalPointToScreenSpace:(CGPoint)localPoint
{
    //return localPoint;
	return [self.draggingContainer convertPoint:localPoint toCoordinateSpace:[UIScreen mainScreen].fixedCoordinateSpace];
}

- (CGPoint)convertScreenPointToLocalSpace:(CGPoint)remotePoint
{
    //return remotePoint;
	return [self.draggingContainer convertPoint:remotePoint fromCoordinateSpace:[UIScreen mainScreen].fixedCoordinateSpace];
}

#pragma mark Start dragging

- (void)startDraggingWithInitiator:(SPDragSource*)source event:(UIGestureRecognizer*)grec
{
	if(_state != nil) {
		[self _cleanUpDragging];
	}
	
    id<DragonDelegate> delegate = source.delegate;
    self.delegate = delegate;

    SPDraggingState *state = [SPDraggingState new];
    state.dragView = source.view;
	state.operationIdentifier = [[NSUUID UUID] UUIDString];
	
	// Setup pasteboard contents
	state.pasteboard = [UIPasteboard generalPasteboard];
	state.originalPasteboardContents = state.pasteboard.items;
	state.pasteboard.items = @[];
	[delegate beginDragOperation:state fromView:state.dragView];
	if(state.pasteboard.items.count == 0) {
		NSLog(@"%@: Cancelling drag operation because no item was put on pasteboard", [self class]);
		state.pasteboard.items = state.originalPasteboardContents;
		return;
	}
	
    // Dragging displayables
	if(!state.draggingIcon)
		state.screenshot = screenshotForView(state.dragView);
	
	// Create image metadata that we want to put on auxiliary pasteboard
	NSMutableDictionary *meta = [@{
		@"uuid": state.operationIdentifier,
	} mutableCopy];
	if(state.draggingIcon) meta[@"draggingIcon"] = serializedImage(state.draggingIcon);
	if(state.screenshot) meta[@"screenshot"] = serializedImage(state.screenshot);
	NSData *metadata = [NSKeyedArchiver archivedDataWithRootObject:[meta copy]];
	
	// Now attach it to the new pasteboard items. can't find API to do so, so mess with the items array...
	NSMutableArray *items = [[state.pasteboard items] mutableCopy];
	NSMutableDictionary *firstItem = [[items firstObject] mutableCopy];
	firstItem[kDragMetadataKey] = metadata;
	items[0] = firstItem;
	state.pasteboard.items = items;
	
	// Figure out anchor point and locations
	CGPoint hitInView = [grec locationInView:state.dragView];
	CGPoint anchorPoint = CGPointMake(
		hitInView.x/state.dragView.frame.size.width,
		hitInView.y/state.dragView.frame.size.height
	);
	
	CGPoint initialLocation = [grec locationInView:_draggingContainer];
	CGPoint initialScreenLocation = [self convertLocalPointToScreenSpace:initialLocation];
	state.initialPositionInScreenSpace = initialScreenLocation;
	
	// Setup UI
	[self startDraggingWithState:state anchorPoint:anchorPoint initialPosition:initialLocation andSource:source];
}

- (void)startDraggingWithState:(SPDraggingState*)state anchorPoint:(CGPoint)anchorPoint initialPosition:(CGPoint)position andSource:(SPDragSource*)source {
	self.state = state;
    
    state.proxyView = [[DragonNotProxyView alloc] initWithView:state.dragView];
	
    state.proxyView.alpha = 1;
    [UIView animateWithDuration:0.2 animations:^{
        state.dragView.alpha = 0;
    }];
    
    [_draggingContainer addSubview:state.proxyView];
    
    if(!state.draggingIcon) { // it's just a screenshot, position it correctly
        state.proxyView.layer.anchorPoint = anchorPoint;
    }
    
    state.proxyView.layer.position = position;
    
    _state.activeDropTargets = [_dropTargets.allObjects filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^(SPDropTarget *target, NSDictionary *bindings) {
		return [target.delegate dropTarget:target.view canAcceptDrag:state];
	}]];
    
    [source.delegate beganDragOperation:state fromView:state.dragView];
    
    [(DragonNotProxyView*)_state.proxyView handleAutoResizingAtPoint:CGPointZero];
	
    [UIView animateWithDuration:0.2 animations:^{
        _state.proxyView.transform = CGAffineTransformMakeScale(1.15, 1.15);
    }];
    
    _highlightTimer = [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(updateHighlightStuff:) userInfo:nil repeats:YES];
}

#pragma mark Continue dragging

- (void)continueDraggingFromGesture:(CGPoint)position {
	[self _continueDragging:position];
}

- (void)_continueDragging:(CGPoint)position {
    _state.proxyView.layer.position = position;
    
    // Re-transform view as needed.
    [(DragonNotProxyView*)_state.proxyView handleAutoResizingAtPoint:position];
    
    SPDropTarget *previousTarget = _state.hoveringTarget;
    _state.hoveringTarget = [self targetUnderFinger];
    if(_state.hoveringTarget != previousTarget) {
    
        previousTarget.highlight.hovering = NO;
        _state.hoveringTarget.highlight.hovering = YES;
    }
}

-(void)updateHighlightStuff:(id)sender {
    if([_state.hoveringTarget.delegate respondsToSelector:@selector(dropTarget:updateHighlight:forDrag:atPoint:)]) {
        CGPoint locationInWindow = _state.proxyView.layer.position;
        CGPoint p = [_state.hoveringTarget.view convertPoint:locationInWindow fromView:_state.proxyView.superview];
        
        [_state.hoveringTarget.delegate dropTarget:_state.hoveringTarget.view updateHighlight:_state.hoveringTarget.highlight forDrag:_state atPoint:p];
    }
}

#pragma mark Conclude dragging

// Finger has been lifted, conclude the dragging operation!
- (void)concludeDraggingFromGesture {
	[self _concludeDragging];
}

// This will either end up calling 'cancelDragging' or 'cleanUpDragging'
- (void)_concludeDragging {
	DNDLog(@"Concluding dragging!");
    
    [_highlightTimer invalidate];
    _highlightTimer = nil;
	
    SPDropTarget *targetThatWasHit = [self targetUnderFinger];
    
    if (![_state.activeDropTargets containsObject:targetThatWasHit] || ![targetThatWasHit canDrop:_state]) {
        [self cancelDragging];
        return;
    }
    
    CGPoint locationInWindow = _state.proxyView.layer.position;
    CGPoint p = [targetThatWasHit.view convertPoint:locationInWindow fromView:_state.proxyView.superview];
    UIView *xenView = [_state.proxyView viewWithTag:12345];
    
    [UIView animateWithDuration:.2 animations:^{
        _state.proxyView.transform = CGAffineTransformMakeScale(1.0, 1.0);
        
        CGPoint origin = [self.delegate positionForDragConclusion:_state];
        if ([self.delegate currentController] == 1) {
            // Only do if going to bottom
            origin.x -= (_state.proxyView.bounds.size.width - xenView.frame.size.width)/2;
            origin.y -= (_state.proxyView.bounds.size.height - xenView.frame.size.height)/2;
        }
        
        _state.proxyView.frame = CGRectMake(origin.x, origin.y, _state.proxyView.frame.size.width, _state.proxyView.frame.size.height);
        [(DragonNotProxyView*)_state.proxyView handleAutoResizingAtPoint:CGPointZero];
    } completion:^(BOOL finished) {
         _state.dragView.alpha = 1;
         _state.proxyView.alpha = 0;
        [targetThatWasHit.delegate dropTarget:targetThatWasHit.view acceptDrag:_state atPoint:p withProxyView:_state.proxyView];
        [self _cleanUpDragging];
    }];
}

#pragma mark Cancel dragging

// Animate indicating that the drag failed, across all apps.
- (void)cancelDragging {
	[self _cancelDragging];
}

- (void)_cancelDragging {
    DNDLog(@"Cancelling dragging");
    [_highlightTimer invalidate];
    _highlightTimer = nil;
    
	[_state.conclusionTimeoutTimer invalidate];

	[_state.proxyView animateOut:nil forSuccess:NO];
    [UIView animateWithDuration:.4 animations:^{
        _state.proxyView.transform = CGAffineTransformMakeScale(1.0, 1.0);
        _state.proxyView.layer.position = [self.delegate positionForDragConclusion:_state];
        _state.dragView.alpha = 1;
    } completion:^(BOOL finished) {
        [_state.dragView addSubview:_state.proxyView.subviews.firstObject];
        [self _cleanUpDragging];
    }];
}

#pragma mark Clean up dragging

// Okay, this app (or another app that handled the touch lifting) has finished handling
// the drag operation. We can now clean up.
- (void)cleanUpDraggingc{
	DNDLog(@"Asking everybody to clean up dragging");

	[self _cleanUpDragging];
}

// Tear down and reset all dragging related state
- (void)_cleanUpDragging {
	DNDLog(@"Performing cleanup");
	[_state.conclusionTimeoutTimer invalidate];
	_state.conclusionTimeoutTimer = nil;
	
    [_state.springloadingTimer invalidate];
    [_state.proxyView removeFromSuperview];
    //[self stopHighlightingDropTargets];
	
	if(self.state.originalPasteboardContents)
		self.state.pasteboard.items = self.state.originalPasteboardContents;
	
    self.state = nil;
}

#pragma mark - Etc

- (SPDragSource*)sourceUnderLocation:(CGPoint)locationInWindow {
    UIView *view = [self.workingView hitTest:locationInWindow withEvent:nil];
    SPDragSource *source = nil;
    do {
        source = objc_getAssociatedObject(view, kDragSourceKey);
        if (source)
            break;
        view = [view superview];
    } while(view);

    return source;
}

- (SPDropTarget*)targetUnderFinger {
    UIView *view = [self.delegate dropTargetAtPoint:_state.proxyView.layer.position];
    
    return objc_getAssociatedObject(view, kDropTargetKey);
}

- (CGRect)localFrameInScreenSpace {
	return [self.draggingContainer convertRect:self.draggingContainer.bounds toCoordinateSpace:[UIScreen mainScreen].fixedCoordinateSpace];
}

- (BOOL)_draggingStartedWithinMyApp {
    return YES;
}

- (BOOL)_draggingIsWithinMyApp {
    return YES;
}

@end

@implementation SPDraggingState
@end

@implementation SPDragSource
@end

@implementation SPDropTarget
- (BOOL)canSpringload:(id<DragonInfo>)drag {
    return NO;
    
    BOOL supportsSpringloading = [self.delegate respondsToSelector:@selector(dropTarget:springload:atPoint:)];
    BOOL supportsShould = [self.delegate respondsToSelector:@selector(dropTarget:shouldSpringload:)];
    BOOL shouldStartSpringloading = supportsSpringloading && (!supportsShould || [self.delegate dropTarget:self.view shouldSpringload:drag]);
    return shouldStartSpringloading;
}
- (BOOL)canDrop:(id<DragonInfo>)drag {
    return [self.delegate dropTarget:self.view shouldAcceptDrag:drag];
}
@end
