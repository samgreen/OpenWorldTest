//
//  OWTWorldGenerator.m
//  OpenWorldTest
//
//  Created by Mike Rotondo on 6/1/13.
//  Copyright (c) 2013 Taka Taka. All rights reserved.
//

#import "OWTWorldGenerator.h"
#import "OWTLevelGenerator.h"
#import "OWTChunk.h"
#import <GLKit/GLKMath.h>
#import "SKRMath.h"

typedef enum _SKRBlockType
{
	SKRBlockTypeWater,
	SKRBlockTypeDirt,
	SKRBlockTypeGrass,
	SKRBlockTypeTree
} SKRBlockType;

@implementation OWTWorldGenerator
{
	NSMutableDictionary *chunkCache;
    NSMutableArray *blocks;
	OWTLevelGenerator *gen;
    
    SCNNode *worldNode;
    
    SCNGeometry *dirtGeometry;
    SCNGeometry *grassGeometry;
    SCNGeometry *waterGeometry;
    SCNGeometry *treeGeometry;
}

- (SCNVector3)initialPlayerPosition
{
    return SCNVector3Make(MAP_BOUNDS/2, MAP_BOUNDS/2, 5);
}

- (SCNVector4)initialPlayerRotation
{
    GLKQuaternion q = GLKQuaternionMakeWithAngleAndAxis(0, 1, 0, 0);
    return SKRVector4FromQuaternion(q);
}

- (SCNNode *)worldNodeForPlayerPosition:(SCNVector3)newPlayerPosition rotation:(SCNVector4)newPlayerRotation
{
    CGPoint playerChunk = CGPointMake(round(newPlayerPosition.x/CHUNK_SIZE), round(newPlayerPosition.y/CHUNK_SIZE));
    
    if (playerChunk.x > 2)
        playerChunk.x -= 2;
    if (playerChunk.y > 2)
        playerChunk.y -= 2;
    
    for (int j = 0; j < 4; j++)
    {
        for (int i = 0; i < 4; i++)
        {
            CGPoint newChunk;
            newChunk.x = playerChunk.x+i;
            newChunk.y = playerChunk.y+j;
            
            [self generateChunk:newChunk];
        }
    }
    
    /* Now unload chunks away from the player */
    
    for (OWTChunk *chunk in worldNode.childNodes)
    {
        if (![chunk isKindOfClass:[OWTChunk class]])
            continue;
        
        double chunkDistance = sqrt(pow((playerChunk.x-chunk.chunkX),2)+pow((playerChunk.y-chunk.chunkY),2));
        
        if (chunkDistance > 4)
        {
            [chunk performSelector:@selector(removeFromParentNode) withObject:nil afterDelay:0.0];
        }
    }
    
    return worldNode;
}

- (id)init
{
    self = [super init];
    if (self) {
        blocks = @[].mutableCopy;
        chunkCache = @{}.mutableCopy;

        worldNode = [SCNNode node];
        
        gen = [[OWTLevelGenerator alloc] init];
        [gen gen:12];

        [self premakeMaterials];
    }
    return self;
}

-(void)premakeMaterials
{
	/* Blocks */
	
	/*
     We share the same scene for the different blocks, but copy the geometry
     for each kind. Each geometry has its own texture it shares with blocks
     of same type.
	 */
	
	NSString *cubePath = [[NSBundle mainBundle] pathForResource:@"cube" ofType:@"dae"];
	SCNScene *cubeScene = [SCNScene sceneWithURL:[NSURL fileURLWithPath:cubePath] options:nil error:nil];
	
	SCNNode *cubeNode = [cubeScene.rootNode childNodeWithName:@"cube" recursively:NO];
	
	dirtGeometry = cubeNode.geometry.copy;
	dirtGeometry.materials = @[[self generateMaterialForBlockType:SKRBlockTypeDirt]];
	
	grassGeometry = cubeNode.geometry.copy;
	grassGeometry.materials = @[[self generateMaterialForBlockType:SKRBlockTypeGrass]];
	
	waterGeometry = cubeNode.geometry.copy;
	waterGeometry.materials = @[[self generateMaterialForBlockType:SKRBlockTypeWater]];
	
	/* Trees */
	
	NSString *treePath = [[NSBundle mainBundle] pathForResource:@"tree" ofType:@"dae"];
	SCNScene *treeScene = [SCNScene sceneWithURL:[NSURL fileURLWithPath:treePath] options:nil error:nil];
	
	SCNNode *treeNode = [treeScene.rootNode childNodeWithName:@"tree" recursively:NO];
	
	treeGeometry = treeNode.geometry;
	treeGeometry.materials = @[[self generateMaterialForBlockType:SKRBlockTypeTree]];
	
}

-(SCNMaterial *)generateMaterialForBlockType:(SKRBlockType)type
{
	SCNMaterial *material = [SCNMaterial material];
    
	switch (type) {
		case SKRBlockTypeGrass:
			material.diffuse.contents = [NSImage imageNamed:@"grass.png"];
			break;
		case SKRBlockTypeWater:
		{
			material.diffuse.contents = [NSImage imageNamed:@"water.png"];
			material.transparency = 0.9;
			break;
		}
		case SKRBlockTypeDirt:
			material.diffuse.contents = [NSImage imageNamed:@"dirt.png"];
			break;
		case SKRBlockTypeTree:
		{
			material.diffuse.contents = [NSColor colorWithCalibratedRed:0.001 green:0.352 blue:0.001 alpha:1.000];
			break;
		}
		default:
			break;
	}
	
	material.diffuse.wrapS = SCNRepeat;
	material.diffuse.wrapT = SCNRepeat;
	material.diffuse.magnificationFilter = SCNNearestFiltering;
	material.doubleSided = NO;
	
	material.diffuse.contentsTransform = CATransform3DMakeScale(4, 4, 4);
	
	return material;
}

#pragma mark - Map Generation

-(void)generateChunk:(CGPoint)chunkCoord
{
	OWTChunk *chunk = [chunkCache objectForKey:NSStringFromPoint(chunkCoord)];
	
	if (!chunk)
	{
		chunk = [[OWTChunk alloc] init];
		chunk.chunkX = chunkCoord.x;
		chunk.chunkY = chunkCoord.y;
		chunk.name = [NSString stringWithFormat:@"chunk:%@", NSStringFromPoint(chunkCoord)];
		
		dispatch_async(dispatch_get_global_queue(0, 0), ^{
			
			CGPoint position = chunkCoord;
			
			position.x *= CHUNK_SIZE;
			position.y *= CHUNK_SIZE;
			
			for (int y = position.y; y < position.y+CHUNK_SIZE; y++)
			{
				for (int x = position.x; x < position.x+CHUNK_SIZE; x++)
				{
					int maxZ = [gen valueForX:x Y:y]/GAME_DEPTH;
					
					for (int z = 0; z <= maxZ; z++)
					{
						SKRBlockType blockType = SKRBlockTypeGrass;
						
						if (z == 0 && z == maxZ)
							blockType = SKRBlockTypeWater;
						
						else if (z < 2 && z == maxZ)
							blockType = SKRBlockTypeDirt;
						
						if (z > 3 && z == maxZ)
							blockType = SKRBlockTypeTree;
                        
						if (z >= 0 && z == maxZ)
							[self addBlockAtLocation:SCNVector3Make(x, y, z) inNode:chunk withType:blockType];
					}
				}
			}
		});
		
		[chunkCache setObject:chunk forKey:NSStringFromPoint(chunkCoord)];
	}
	
	if (!chunk.parentNode)
	{
		/* Animate the chunk into position */
		
		SCNVector3 cp = chunk.position;
		chunk.opacity = 0;
		cp.z = -4;
		chunk.position = cp;
		cp.z = 0;
		[worldNode addChildNode:chunk];
		
		[SCNTransaction begin];
		[SCNTransaction setAnimationDuration:0.5];
		chunk.opacity = 1;
		chunk.position = cp;
		[SCNTransaction commit];
	}
}

-(void)addBlockAtLocation:(SCNVector3)location inNode:(SCNNode *)node withType:(SKRBlockType)type
{
	SCNGeometry *geometry = nil;
	
	switch (type) {
		case SKRBlockTypeGrass:
		{
			geometry = grassGeometry;
			break;
		}
		case SKRBlockTypeWater:
		{
			geometry = waterGeometry;
			break;
		}
		case SKRBlockTypeDirt:
		{
			geometry = dirtGeometry;
			break;
		}
		case SKRBlockTypeTree:
		{
			geometry = treeGeometry;
			break;
		}
			
		default:
			break;
	}
	
	dispatch_async(dispatch_get_main_queue(), ^{
		
		SCNNode *boxNode = [SCNNode nodeWithGeometry:geometry];
		boxNode.position = SCNVector3Make(location.x, location.y, location.z);
		[node addChildNode:boxNode];
		[blocks addObject:boxNode];
	});
}

@end
