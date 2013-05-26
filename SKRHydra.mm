//
//  SKRHydra.m
//  OpenWorldTest
//
//  Created by Luke Iannini on 5/22/13.
//  Copyright (c) 2013 Taka Taka. All rights reserved.
//

#import "SKRHydra.h"
#import "SKRMath.h"

#include <sixense.h>
#include <sixense_math.hpp>
#include <sixense_utils/derivatives.hpp>
#include <sixense_utils/button_states.hpp>
#include <sixense_utils/event_triggers.hpp>
#include <sixense_utils/controller_manager/controller_manager.hpp>

static bool controller_manager_screen_visible = true;
std::string controller_manager_text_string;
void controller_manager_setup_callback( sixenseUtils::ControllerManager::setup_step step ) {
    
    NSLog(@"SETUP CALLBACK");
	if( sixenseUtils::getTheControllerManager()->isMenuVisible() ) {
		// Turn on the flag that tells the graphics system to draw the instruction screen instead of the controller information. The game
		// should be paused at this time.
		controller_manager_screen_visible = true;
        
		// Ask the controller manager what the next instruction string should be.
		controller_manager_text_string = sixenseUtils::getTheControllerManager()->getStepString();
        NSLog(@"NEW STEP STRING: %s", controller_manager_text_string.c_str());
		// We could also load the supplied controllermanager textures using the filename: sixenseUtils::getTheControllerManager()->getTextureFileName();
	} else {
		// We're done with the setup, so hide the instruction screen.
		controller_manager_screen_visible = false;
        
	}
}

@implementation SKRHydra

+ (void)load {
    // This fails when called at the same time as oculus init, so I moved it here.
    sixenseInit();
}

- (id)init
{
    self = [super init];
    if (self) {        
        // Init the controller manager. This makes sure the controllers are present, assigned to left and right hands, and that
        // the hemisphere calibration is complete.
        sixenseUtils::getTheControllerManager()->setGameType( sixenseUtils::ControllerManager::ONE_PLAYER_TWO_CONTROLLER );
        sixenseUtils::getTheControllerManager()->registerSetupCallback( controller_manager_setup_callback );
    }
    return self;
}

- (SKRHydraControllerPair)poll {
    
    sixenseSetActiveBase(0);
	sixenseAllControllerData acd;
	sixenseGetAllNewestData( &acd );
	sixenseUtils::getTheControllerManager()->update( &acd );
    
    int base, controller;
    
    int leftIndex  = sixenseUtils::getTheControllerManager()->getIndex( sixenseUtils::ControllerManager::P1L );
    int rightIndex = sixenseUtils::getTheControllerManager()->getIndex( sixenseUtils::ControllerManager::P1R );
    
    // We currently only return one pair of controllers, even if there are multiple base stations.
    SKRHydraControllerPair pair;
    
    // Go through each of the connected systems
    for( base=0; base<sixenseGetMaxBases(); base++ ) {
        sixenseSetActiveBase(base);
        
        // Get the latest controller data
        sixenseGetAllNewestData( &acd );
        
        // For each possible controller
        for( controller=0; controller<sixenseGetMaxControllers(); controller++ ) {
            
            // See if it's enabled
            if( sixenseIsControllerEnabled( controller ) ) {
                
                SCNVector4 orientation = SKRVector4FromQuaternion(acd.controllers[controller].rot_quat[0],
                                                                  acd.controllers[controller].rot_quat[1],
                                                                  acd.controllers[controller].rot_quat[2],
                                                                  acd.controllers[controller].rot_quat[3]);
                
                SCNVector3 position = SCNVector3Make(acd.controllers[controller].pos[0]/500.0f,
                                                     acd.controllers[controller].pos[1]/500.0f,
                                                     acd.controllers[controller].pos[2]/500.0f);
                SKRHydraController hydraController;
                hydraController.orientation = orientation;
                hydraController.position = position;
                
                if( controller == leftIndex ) {
                    pair.left = hydraController;
                } else if ( controller == rightIndex ) {
                    pair.right = hydraController;
                }
            }
        }
    }
    return pair;
}


- (void)dealloc
{
    sixenseExit();
}

@end
