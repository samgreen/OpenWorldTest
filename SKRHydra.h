//
//  SKRHydra.h
//  OpenWorldTest
//
//  Created by Luke Iannini on 5/22/13.
//  Copyright (c) 2013 Taka Taka. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SceneKit/SceneKit.h>

typedef struct _SKRHydraController {
    SCNVector4 orientation;
    SCNVector3 position;
} SKRHydraController;

typedef struct _SKRHydraControllerPair {
    SKRHydraController left;
    SKRHydraController right;
} SKRHydraControllerPair;


@interface SKRHydra : NSObject

- (SKRHydraControllerPair)poll;

@end
