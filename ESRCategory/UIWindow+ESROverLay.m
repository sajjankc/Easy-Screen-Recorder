//
//  UIWindow+ESROverLay.m
//  EasyScreenRecord
//
//  Created by Sajjan on 10/6/13.
//  Copyright (c) 2013 sajjankc. All rights reserved.
//

#import "UIWindow+ESROverLay.h"
#import "ESRViewVideoHandler.h"

@implementation UIWindow (ESROverLay)

- (UIView*) hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *hitView = [super hitTest:point withEvent:event];
    if (!CGPointEqualToPoint([ESRViewVideoHandler sharedViewVideoHandler].tapPoint, point)) {
        [ESRViewVideoHandler sharedViewVideoHandler].tapPoint = point;
        [ESRViewVideoHandler sharedViewVideoHandler].isTapped = YES;
    }
    return hitView;
}

@end
