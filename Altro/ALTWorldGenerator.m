//
//  ALTWorldGenerator.m
//  OpenWorldTest
//
//  Created by Mike Rotondo on 6/1/13.
//  Copyright (c) 2013 Taka Taka. All rights reserved.
//

#import "ALTWorldGenerator.h"
#import "SKRMath.h"
#import "ALTHeightField.h"
#import <GLKit/GLKMath.h>
#import <SceneKit/SceneKit.h>

@implementation ALTWorldGenerator
{
    SCNNode *_worldNode;
    ALTHeightField *_heightField;
}

- (SCNVector3)initialPlayerPosition
{
    return SCNVector3Make(0, 0, 0);
}

- (SCNVector4)initialPlayerRotation
{
    GLKQuaternion q = GLKQuaternionMakeWithAngleAndAxis(0, 1, 0, 0);
    return SKRVector4FromQuaternion(q);
}

- (SCNNode *)worldNodeForPlayerPosition:(SCNVector3)newPlayerPosition rotation:(SCNVector4)newPlayerRotation
{
    return _worldNode;
}

- (float)terrainHeightAt:(GLKVector3)location
{
    return [_heightField heightAt:location] - 20;
}

- (BOOL)playerShouldHaveLight
{
    return NO;
}

static void generateHeightmap(int rows, int columns, float *heights)
{
    for (int i = 0; i < 200; i++)
    {
        GLKVector2 normalizedPoint = GLKVector2Make((arc4random() / (float)0x100000000), (arc4random() / (float)0x100000000));
        float magnitude = 5.0 * (arc4random() / (float)0x100000000);
        float width = 0.05 + 0.05 * (arc4random() / (float)0x100000000);
        for (int z = 0; z < rows; z++)
        {
            for (int x = 0; x < columns; x++)
            {
                float distance = GLKVector2Distance(normalizedPoint, GLKVector2Make((float)x / columns, (float)z / rows));
                float incrementalHeight = cosf(MIN((1.0 / width) * distance, M_PI_2)) * magnitude;
                
                float currentHeight = heights[x + z * columns];
                heights[x + z * columns] = currentHeight + incrementalHeight;
            }
        }
    }
}

- (id)init
{
    self = [super init];
    if (self) {
        _worldNode = [SCNNode node];
        
        SCNLight *sunlight = [SCNLight light];
        sunlight.type = SCNLightTypeDirectional;
        SCNNode *sunlightNode = [SCNNode node];
        sunlightNode.light = sunlight;
        GLKQuaternion sunlightOrientation = GLKQuaternionMakeWithAngleAndAxis(-M_PI_4, 1, 0, 0);
        sunlightNode.rotation = SKRVector4FromQuaternion(sunlightOrientation);
        [_worldNode addChildNode:sunlightNode];
        
        CAKeyframeAnimation *sunlightAnimation = [CAKeyframeAnimation animationWithKeyPath:@"rotation"];
        sunlightAnimation.values = [NSArray arrayWithObjects:
                                    [NSValue valueWithSCNVector4:SKRVector4FromQuaternion(GLKQuaternionMakeWithAngleAndAxis(-M_PI_4, 1, 0, 0))],
                                    [NSValue valueWithSCNVector4:SKRVector4FromQuaternion(GLKQuaternionMakeWithAngleAndAxis(-3 * M_PI_4, 1, 0, 0))],
                                    nil];
        sunlightAnimation.duration = 30.0f;
        sunlightAnimation.repeatCount = HUGE_VALF;
        sunlightAnimation.autoreverses = YES;
        [sunlightNode addAnimation:sunlightAnimation forKey:@"rotation"];
        
        SCNGeometry *sphereGeometry = [SCNSphere sphereWithRadius:0.3];
        SCNMaterial *sphereMaterial = [SCNMaterial material];
        sphereMaterial.diffuse.contents = [NSColor orangeColor];
        sphereGeometry.materials = @[sphereMaterial];
        SCNNode *sphereNode = [SCNNode nodeWithGeometry:sphereGeometry];
        sphereNode.position = SCNVector3Make(0, 0, -1);
        [_worldNode addChildNode:sphereNode];
        
        int rows = 200;
        int columns = 200;
        float *heights = (float *)malloc(rows * columns * sizeof(float));
        generateHeightmap(rows, columns, heights); // ALTHeightField takes ownership of heights pointer, so we don't free it here
        _heightField = [[ALTHeightField alloc] initWithRows:rows columns:columns heights:heights xspace:1.0 zspace:1.0];
        
        SCNMaterial *heightFieldMaterial = [SCNMaterial material];
        heightFieldMaterial.diffuse.contents = [NSColor colorWithCalibratedRed:87.0/255 green:126.0/255 blue:42.0/255 alpha:1.000];
        heightFieldMaterial.lightingModelName = SCNLightingModelBlinn;
        _heightField.geometry.firstMaterial = heightFieldMaterial;

        SCNNode *heightFieldNode = [SCNNode nodeWithGeometry:_heightField.geometry];
        heightFieldNode.position = SCNVector3Make(0, -20, 0);
        [_worldNode addChildNode:heightFieldNode];
    }
    return self;
}

@end
