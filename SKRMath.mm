//
//  SKRMath.m
//  OpenWorldTest
//
//  Created by Luke Iannini on 5/26/13.
//  Copyright (c) 2013 Taka Taka. All rights reserved.
//

#import "SKRMath.h"
#import <GLKit/GLKit.h>

SCNVector4 SKRVector4FromQuaternionValues(float x, float y, float z, float w) {
    GLKQuaternion rotation = GLKQuaternionMake(x, y, z, w);
    GLKVector3 axis = GLKQuaternionAxis(rotation);
    float angle = GLKQuaternionAngle(rotation);
    
    return SCNVector4Make(axis.x, axis.y, axis.z, angle);
}

SCNVector4 SKRVector4FromQuaternion(GLKQuaternion q)
{
    return SKRVector4FromQuaternionValues(q.x, q.y, q.z, q.w);
}

NSString *NSStringFromSCNVector3(SCNVector3 vector) {
    return [NSString stringWithFormat:@"(%f, %f, %f)", vector.x, vector.y, vector.z];
}

NSString *NSStringFromSCNVector4(SCNVector4 vector) {
    return [NSString stringWithFormat:@"(%f, %f, %f, %f)", vector.x, vector.y, vector.z, vector.w];
}