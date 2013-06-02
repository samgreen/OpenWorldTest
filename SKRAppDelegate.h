//
//  SKRAppDelegate.h
//  OpenWorldTest
//
//  Created by Mike Rotondo on 6/1/13.
//  Copyright (c) 2013 Taka Taka. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SceneKit/SceneKit.h>
#import <OpenGL/gl.h>
#import "SKRWorldGenerator.h"

@class SKRView;

@interface SKRAppDelegate : NSObject <NSApplicationDelegate, SCNSceneRendererDelegate>

- (id)initWithWindow:(NSWindow *)window skrView:(SKRView *)view worldGenerator:(NSObject<SKRWorldGenerator>*)worldGenerator;

@end
