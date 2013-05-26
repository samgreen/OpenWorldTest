//
//  SKRMath.m
//  OpenWorldTest
//
//  Created by Luke Iannini on 5/26/13.
//  Copyright (c) 2013 Taka Taka. All rights reserved.
//

#import "SKRMath.h"
#import <GLKit/GLKit.h>

SCNVector4 SKRVector4FromQuaternion(float x, float y, float z, float w) {
    GLKQuaternion orientation = GLKQuaternionMake(x, y, z, w);
    GLKVector3 axis = GLKQuaternionAxis(orientation);
    float angle = GLKQuaternionAngle(orientation);
    
    return SCNVector4Make(axis.x, axis.y, axis.z, angle);
}

NSString *NSStringFromSCNVector3(SCNVector3 vector) {
    return [NSString stringWithFormat:@"(%f, %f, %f)", vector.x, vector.y, vector.z];
}

NSString *NSStringFromSCNVector4(SCNVector4 vector) {
    return [NSString stringWithFormat:@"(%f, %f, %f, %f)", vector.x, vector.y, vector.z, vector.w];
}