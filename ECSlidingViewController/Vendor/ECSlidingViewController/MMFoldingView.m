//
//  MMFoldingView.m
//  ECSlidingViewController
//
//  Created by Michael Manesh on 5/15/12.
//  Copyright (c) 2012 Booz Allen Hamilton. All rights reserved.
//

#import "MMFoldingView.h"
#import "UIImage+ImageWithUIView.h"

#define OVERLAY_TAG 42

// redirects delegate calls for the left half / right half layers,
// since a UIView's delegate methods are reserved for its layer
@interface MMSublayerDelegate : NSObject
@property (nonatomic, weak) MMFoldingView *foldingView;
@end

@implementation MMSublayerDelegate
@synthesize foldingView;
- (id<CAAction>)actionForLayer:(CALayer *)layer forKey:(NSString *)event {
    return [foldingView actionForLayer:layer forKey:event];
}
@end


// controls the folding view
@interface MMFoldingView ()

@property (nonatomic, retain) CALayer *leftHalfLayer;
@property (nonatomic, retain) CALayer *rightHalfLayer;
@property (nonatomic, retain) MMSublayerDelegate *sublayerDelegate;

@property float fullWidth;
@property (readonly) float halfWidth;
@property float animationDuration;
@property BOOL isAnimating;

@end

@implementation MMFoldingView

@synthesize leftHalfLayer;
@synthesize rightHalfLayer;
@synthesize fullWidth;
@synthesize animationDuration;
@synthesize isAnimating;
@synthesize sublayerDelegate;

- (float) halfWidth {
    return fullWidth/2;
}

- (id)initWithView:(UIView *)view {
    if (self = [super init]) {
        // take a snapshot of the underleft view controller, copy it into two image views,
        // one for the left half and one for the right
        UIImage *underLeftImage = [UIImage imageWithUIView:view];
        
        // setup the left & right half layers
        self.leftHalfLayer = [CALayer layer];
        self.rightHalfLayer = [CALayer layer];
        [self.leftHalfLayer setContents:(id)[underLeftImage CGImage]];
        [self.rightHalfLayer setContents:(id)[underLeftImage CGImage]];
        
        // create a UIView to hold both halves
        self.frame = view.frame;
        self.backgroundColor = [UIColor blackColor];
        
        // save the width
        self.fullWidth = view.frame.size.width;
        
        // add perspective to all sublayers
        CATransform3D sublayerTransform = CATransform3DIdentity;
        sublayerTransform.m34 = -1./500;
        self.layer.sublayerTransform = sublayerTransform;
        
        // we add one layer for the left half and one for the right
        self.leftHalfLayer.anchorPoint = CGPointMake(0, .5);
        [self.layer addSublayer:self.leftHalfLayer];
        
        self.rightHalfLayer.anchorPoint = CGPointMake(1, .5);
        [self.layer addSublayer:self.rightHalfLayer];
        
        // size and position the image layers
        CGRect halfFrame = view.frame;
        halfFrame.size.width = self.halfWidth;
        self.leftHalfLayer.frame = halfFrame;
        self.rightHalfLayer.frame = halfFrame;
        self.leftHalfLayer.masksToBounds = YES;
        self.rightHalfLayer.masksToBounds = YES;
        self.leftHalfLayer.contentsGravity = kCAGravityLeft;
        self.rightHalfLayer.contentsGravity = kCAGravityRight;

        // setup the delegates and a delegate redirector
        self.sublayerDelegate = [[MMSublayerDelegate alloc] init];
        self.sublayerDelegate.foldingView = self;
        self.leftHalfLayer.delegate = sublayerDelegate;
        self.rightHalfLayer.delegate = sublayerDelegate;
        
        /*
        CGRect frame = self.leftHalfImageView.frame;
        frame.size.width /= 2;
        self.leftHalfImageView.frame = frame;
        self.rightHalfImageView.frame = frame;
        
        self.leftHalfImageView.contentMode = UIViewContentModeLeft;
        self.leftHalfImageView.clipsToBounds = YES;
        self.rightHalfImageView.contentMode = UIViewContentModeRight;
        self.rightHalfImageView.clipsToBounds = YES;
         
         */
        
        // TODO: add insets for beauty (anti-aliased edges)
        
        // add overlays whose opacity we will adjust depending on the angle
        //CGRect viewFrame = CGRectMake(0, 0, self.leftHalfLayer.frame.size.width, self.leftHalfLayer.frame.size.height);
        
        /*
        UIView *overlayView = [[UIView alloc] initWithFrame:viewFrame];
        overlayView.tag = OVERLAY_TAG;
        overlayView.backgroundColor = [UIColor blackColor];
        [self.leftHalfLayer addSubview:overlayView];
        
        overlayView = [[UIView alloc] initWithFrame:viewFrame];
        overlayView.tag = OVERLAY_TAG;
        overlayView.backgroundColor = [UIColor blackColor];
        [self.rightHalfImageView addSubview:overlayView];
         
         */
        
        // set the delegates for all layers to self so we can control the animations


    }
    return self;
}


- (void)layoutSubviews {
    float maxHalfWidth = self.halfWidth;
    float currentWidth = self.bounds.size.width;
    float halfCurrentWidth = currentWidth / 2;
    
    CGFloat opposite = halfCurrentWidth;  
    CGFloat hypoteneuse = maxHalfWidth;
    CGFloat theta = acosf(opposite/hypoteneuse);
    CGFloat leftAngle = theta;
    CGFloat rightAngle = -theta;
    
    CATransform3D leftTransform = CATransform3DIdentity;
    
    // increase the width of the right side to the nearest full pixel to ensure no gap ever appears between the two sides
    CATransform3D rightTransform = CATransform3DMakeScale((halfCurrentWidth+0.5)/halfCurrentWidth, 1, 1);
    //CATransform3D rightTransform = CATransform3DIdentity;
    
    self.leftHalfLayer.transform = CATransform3DRotate(leftTransform, leftAngle, 0.0, 1.0, 0.0);
    self.rightHalfLayer.transform = CATransform3DRotate(rightTransform, rightAngle, 0.0, 1.0, 0.0);
    
    CGRect rightFrame = self.rightHalfLayer.frame;
    //rightFrame.size.width += 1;
    //self.rightHalfImageView.layer.frame = rightFrame;
    NSLog(@"frame %f, %f", rightFrame.size.width, rightFrame.origin.x);
    
    // make sure the layers are positioned to the edges of the folding view
    self.leftHalfLayer.position = CGPointMake(0, self.frame.size.height/2);
    self.rightHalfLayer.position = CGPointMake(currentWidth, self.frame.size.height/2);
    
    // set the alpha for the overlays   
    /*
    float ratio = 1 - opposite / hypoteneuse; // range: 0-1
    [[self.leftHalfImageView viewWithTag:OVERLAY_TAG] setAlpha:ratio*0.8];
    [[self.rightHalfImageView viewWithTag:OVERLAY_TAG] setAlpha:ratio*0.5];
     */
}


- (void)enableBoundsAnimationWithDuration:(float)time {
  self.isAnimating = YES;
  self.animationDuration = time;
}

- (void)disableBoundsAnimation {
  self.isAnimating = NO;
}

- (id<CAAction>)actionForLayer:(CALayer *)layer forKey:(NSString *)event {
    NSLog(@"event is %@", event);
    
    if (isAnimating) {
        CABasicAnimation *animation = [CABasicAnimation animation];
        animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        animation.duration = animationDuration;
        animation.delegate = self;
        return animation;
    }
    
    return (id)[NSNull null];
}

@end
