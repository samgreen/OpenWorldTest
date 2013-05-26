//
//  SKRHydra.m
//  OpenWorldTest
//
//  Created by Luke Iannini on 5/22/13.
//  Copyright (c) 2013 Taka Taka. All rights reserved.
//

#import "SKRHydra.h"

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
        
        sixenseSetActiveBase(0);
        sixenseAllControllerData acd;
        sixenseGetAllNewestData( &acd );
        sixenseUtils::getTheControllerManager()->update( &acd );
        
        static NSTimer *tempTimer;
        tempTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(update) userInfo:nil repeats:YES];
    }
    return self;
}

- (void)update {
    
    sixenseSetActiveBase(0);
	sixenseAllControllerData acd;
	sixenseGetAllNewestData( &acd );
	sixenseUtils::getTheControllerManager()->update( &acd );
    
    // Draw the two 3d objects representing the controllers
    int base, cont, i, j;
    float rot_mat[4][4];
    
    int left_index = sixenseUtils::getTheControllerManager()->getIndex( sixenseUtils::ControllerManager::P1L );
    int right_index = sixenseUtils::getTheControllerManager()->getIndex( sixenseUtils::ControllerManager::P1R );
    
    // Go through each of the connected systems
    for( base=0; base<sixenseGetMaxBases(); base++ ) {
        sixenseSetActiveBase(base);
        
        // Get the latest controller data
        sixenseGetAllNewestData( &acd );
        
        // For each possible controller
        for( cont=0; cont<sixenseGetMaxControllers(); cont++ ) {
            
            // See if it's enabled
            if( sixenseIsControllerEnabled( cont ) ) {
					if( cont == left_index ) { // if this is the left controller
                        NSLog(@"Left controller");
					}
                
					if( cont == right_index ) { // if this is the right controller
                        NSLog(@"Right controller");
					}
                
                // draw one hand darker than the other one
//					if( cont == 0 ) {
//						glColor3d(colors[base][0]+flash_multiplier, colors[base][1]+flash_multiplier, colors[base][2]+flash_multiplier );
//					} else {
//						glColor3d(0.6f*colors[base][0]+flash_multiplier, 0.6f*colors[base][1]+flash_multiplier, 0.6f*colors[base][2]+flash_multiplier );
//					}
                
                for( i=0; i<3; i++ )
                    for( j=0; j<3; j++ )
                        rot_mat[i][j] = acd.controllers[cont].rot_mat[i][j];
                
                rot_mat[0][3] = 0.0f;
                rot_mat[1][3] = 0.0f;
                rot_mat[2][3] = 0.0f;
                rot_mat[3][0] = acd.controllers[cont].pos[0]/500.0f;
                rot_mat[3][1] = acd.controllers[cont].pos[1]/500.0f;
                rot_mat[3][2] = acd.controllers[cont].pos[2]/500.0f;
                rot_mat[3][3] = 1.0f;
                
            }
        }
    }
}


- (void)dealloc
{
    sixenseExit();
}

@end
