//
//  SKRHydra.h
//  OpenWorldTest
//
//  Created by Luke Iannini on 5/22/13.
//  Copyright (c) 2013 Taka Taka. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SceneKit/SceneKit.h>

@protocol SKRHydraDelegate <NSObject>
@optional
- (void)leftButton1Pressed:(BOOL)pressed;
- (void)leftButton2Pressed:(BOOL)pressed;
- (void)leftButton3Pressed:(BOOL)pressed;
- (void)leftButton4Pressed:(BOOL)pressed;
- (void)leftBumperPressed:(BOOL)pressed;
- (void)leftJoystickPressed:(BOOL)pressed;
- (void)leftStartPressed:(BOOL)pressed;
- (void)leftTriggerPressed:(BOOL)pressed;

- (void)rightButton1Pressed:(BOOL)pressed;
- (void)rightButton2Pressed:(BOOL)pressed;
- (void)rightButton3Pressed:(BOOL)pressed;
- (void)rightButton4Pressed:(BOOL)pressed;
- (void)rightBumperPressed:(BOOL)pressed;
- (void)rightJoystickPressed:(BOOL)pressed;
- (void)rightStartPressed:(BOOL)pressed;
- (void)rightTriggerPressed:(BOOL)pressed;

@end

typedef struct _SKRHydraController {
    SCNVector4 rotation;
    SCNVector3 position;
    CGPoint joystick;
} SKRHydraController;

typedef struct _SKRHydraControllerPair {
    SKRHydraController left;
    SKRHydraController right;
} SKRHydraControllerPair;


@interface SKRHydra : NSObject

- (SKRHydraControllerPair)poll;

@property (nonatomic, weak) id delegate;

@end
