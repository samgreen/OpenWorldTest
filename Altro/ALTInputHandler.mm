//
//  ALTInputHandler.m
//  OpenWorldTest
//
//  Created by Mike Rotondo on 8/13/13.
//  Copyright (c) 2013 Taka Taka. All rights reserved.
//

#import "ALTInputHandler.h"
#import "ALTPointCloudMeshCreation.h"
#import "SKRPlayer.h"
#import <SceneKit/SceneKit.h>

@implementation ALTInputHandler
{
    NSMutableArray *_creations;
    ALTPointCloudMeshCreation *_currentCreation;
    BOOL _mouseButtonDown;
}
@synthesize scene = _scene;
@synthesize playerNode = _playerNode;

- (id)init
{
    self = [super init];
    if (self) {
        _creations = [NSMutableArray array];
    }
    return self;
}

- (void)mouseDown:(NSEvent *)theEvent
{
    _mouseButtonDown = YES;
    
    ALTPointCloudMeshCreation *newCreation = [[ALTPointCloudMeshCreation alloc] initWithParentNode:_scene.rootNode];
    [_creations addObject:newCreation];
    _currentCreation = newCreation;
}

- (void)mouseUp:(NSEvent *)theEvent
{
    _mouseButtonDown = NO;
}

- (void)gameLoopAtTime:(CVTimeStamp)time
{
    if (_mouseButtonDown)
    {
        GLKQuaternion orientation = GLKQuaternionMakeWithAngleAndAxis(_playerNode.rotation.w,
                                                                      _playerNode.rotation.x,
                                                                      _playerNode.rotation.y,
                                                                      _playerNode.rotation.z);
        GLKVector3 forwardVector = GLKVector3Make(0, 0, -1);
        GLKVector3 orientedForwardVector = GLKQuaternionRotateVector3(orientation, forwardVector);
        GLKVector3 scaledOrientedForwardVector = GLKVector3MultiplyScalar(orientedForwardVector, 5.0);
        
        GLKVector3 pointInFrontOfPlayer = GLKVector3Add(SCNVector3ToGLKVector3(_playerNode.position), scaledOrientedForwardVector);
        [_currentCreation addSphereAtPoint:pointInFrontOfPlayer radius:0.2 numPoints:10];
    }
}

@end
