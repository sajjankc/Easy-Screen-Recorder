//
//  UIWindow+ESROverLay.h
//  EasyScreenRecord
//
//  Created by Sajjan on 10/6/13.
//  Copyright (c) 2013 sajjankc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIWindow (ESROverLay) 

- (UIView*) hitTest:(CGPoint)point withEvent:(UIEvent *)event;

@end
