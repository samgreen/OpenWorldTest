//
//  SKRMath.h
//  OpenWorldTest
//
//  Created by Luke Iannini on 5/26/13.
//  Copyright (c) 2013 Taka Taka. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SceneKit/SceneKit.h>
#import <GLKit/GLKit.h>

extern SCNVector4 SKRVector4FromQuaternion(float x, float y, float z, float w);
extern NSString *NSStringFromSCNVector3(SCNVector3 vector);
extern NSString *NSStringFromSCNVector4(SCNVector4 vector);