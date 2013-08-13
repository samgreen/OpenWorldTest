//
//  SKRInputHandler.h
//  OpenWorldTest
//
//  Created by Mike Rotondo on 8/13/13.
//  Copyright (c) 2013 Taka Taka. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SCNScene;
@class SKRPlayer;

@protocol SKRInputHandler <NSObject>

@property (nonatomic, strong) SCNScene *scene;
@property (nonatomic, strong) SKRPlayer *playerNode;

- (void)mouseDown:(NSEvent *)theEvent;
- (void)mouseUp:(NSEvent *)theEvent;
- (void)gameLoopAtTime:(CVTimeStamp)time;

@end
