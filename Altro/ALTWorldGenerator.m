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
    SCNNode *_sunlightNode;
    ALTHeightField *_heightField;
    NSMutableArray *_trees;
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

static SCNNode *generateSunlightNode()
{
    SCNLight *sunlight = [SCNLight light];
    sunlight.type = SCNLightTypeDirectional;
    SCNNode *sunlightNode = [SCNNode node];
    sunlightNode.light = sunlight;
    sunlightNode.rotation = SKRVector4FromQuaternion(GLKQuaternionMakeWithAngleAndAxis(-M_PI_4, 1, 0, 0));
    
    return sunlightNode;
}

static ALTHeightField *generateHeightfield()
{
    int rows = 200;
    int columns = 200;
    float *heights = (float *)malloc(rows * columns * sizeof(float));
    generateHeightmap(rows, columns, heights); // ALTHeightField takes ownership of heights pointer, so we don't free it here
    return [[ALTHeightField alloc] initWithRows:rows columns:columns heights:heights xspace:1.0 zspace:1.0];
}

static SCNNode *generateTerrainNode(ALTHeightField *heightField)
{    
    SCNMaterial *terrainMaterial = [SCNMaterial material];
    terrainMaterial.diffuse.contents = [NSColor colorWithCalibratedRed:87.0/255 green:126.0/255 blue:42.0/255 alpha:1.000];
    terrainMaterial.lightingModelName = SCNLightingModelBlinn;
    heightField.geometry.firstMaterial = terrainMaterial;
    
    SCNNode *terrainNode = [SCNNode nodeWithGeometry:heightField.geometry];
    terrainNode.position = SCNVector3Make(0, -20, 0);
    return terrainNode;
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

//static NSMutableArray *generateTrees(ALTHeightField *heightField)
//{
//    
//}

- (void)updateAfterFirstAddedToParentNode
{
    // This has to be after the node has been added to a parent node, which is dumb & I've reported it in bug ID 14096429
    CAKeyframeAnimation *sunlightAnimation = [CAKeyframeAnimation animationWithKeyPath:@"rotation"];
    sunlightAnimation.values = [NSArray arrayWithObjects:
                                [NSValue valueWithSCNVector4:SKRVector4FromQuaternion(GLKQuaternionMakeWithAngleAndAxis(-M_PI_4, 1, 0, 0))],
                                [NSValue valueWithSCNVector4:SKRVector4FromQuaternion(GLKQuaternionMakeWithAngleAndAxis(-3 * M_PI_4, 1, 0, 0))],
                                nil];
    sunlightAnimation.duration = 30.0f;
    sunlightAnimation.repeatCount = HUGE_VALF;
    sunlightAnimation.autoreverses = YES;
    [_sunlightNode addAnimation:sunlightAnimation forKey:@"rotation"];
}

- (id)init
{
    self = [super init];
    if (self) {
        _worldNode = [SCNNode node];
        
        _sunlightNode = generateSunlightNode();
        [_worldNode addChildNode:_sunlightNode];

        _heightField = generateHeightfield();
        [_worldNode addChildNode:generateTerrainNode(_heightField)];
    }
    return self;
}

@end
