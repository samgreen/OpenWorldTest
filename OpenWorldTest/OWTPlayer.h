//
//  PlayerNode.h
//  SceneKraft
//
//  Created by Tom Irving on 09/09/2012.
//  Copyright (c) 2012 Tom Irving. All rights reserved.
//

#import <SceneKit/SceneKit.h>
#import "OWTEntity.h"

@interface OWTPlayer : OWTEntity {
}

@property (nonatomic, retain) SCNNode *leftEye;
@property (nonatomic, retain) SCNNode *rightEye;

+ (OWTPlayer *)node;

@end