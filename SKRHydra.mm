//
//  SKRHydra.m
//  OpenWorldTest
//
//  Created by Luke Iannini on 5/22/13.
//  Copyright (c) 2013 Taka Taka. All rights reserved.
//

#import "SKRHydra.h"
#import "SKRMath.h"

#import <objc/message.h>

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
{
    sixenseUtils::ButtonStates leftButtonStates;
    sixenseUtils::ButtonStates rightButtonStates;
}

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
    
    int base, controllerIndex;
    
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
        for( controllerIndex=0; controllerIndex<sixenseGetMaxControllers(); controllerIndex++ ) {
            sixenseControllerData controller = acd.controllers[controllerIndex];
            // See if it's enabled
            if( sixenseIsControllerEnabled( controllerIndex ) ) {
                
                SCNVector4 orientation = SKRVector4FromQuaternion(controller.rot_quat[0],
                                                                  controller.rot_quat[1],
                                                                  controller.rot_quat[2],
                                                                  controller.rot_quat[3]);
                
                SCNVector3 position = SCNVector3Make(controller.pos[0]/500.0f,
                                                     controller.pos[1]/500.0f,
                                                     controller.pos[2]/500.0f);
                SKRHydraController hydraController;
                hydraController.orientation = orientation;
                hydraController.position = position;
                hydraController.joystick = CGPointMake(controller.joystick_x,
                                                       controller.joystick_y);
                
                if( controllerIndex == leftIndex ) {
                    leftButtonStates.update(&controller);
                    [self handleLeftSideButtonStates:leftButtonStates];
                    pair.left = hydraController;
                } else if ( controllerIndex == rightIndex ) {
                    rightButtonStates.update(&controller);
                    [self handleRightSideButtonStates:rightButtonStates];
                    pair.right = hydraController;
                }
            }
        }
    }
    return pair;
}

- (void)handleButtonDelegationForStates:(sixenseUtils::ButtonStates)buttonStates
                                   side:(SKRSide)side {
    if (side == SKRLeft) {
        
    } else if (side == SKRRight) {
        
    }
}

- (void)callSelector:(SEL)selector ifImplementedWithBool:(BOOL)value {
    if ([self.delegate respondsToSelector:selector]) {
        objc_msgSend(self.delegate, selector, value);
    }
}

- (void)handleLeftSideButtonStates:(sixenseUtils::ButtonStates)buttonStates {
    if (buttonStates.buttonJustPressed(SIXENSE_BUTTON_BUMPER)) {
        [self callSelector:@selector(leftBumperPressed:) ifImplementedWithBool:YES];
    } else if (buttonStates.buttonJustReleased(SIXENSE_BUTTON_BUMPER)) {
        [self callSelector:@selector(leftBumperPressed:) ifImplementedWithBool:NO];
    }
    
    if (buttonStates.buttonJustPressed(SIXENSE_BUTTON_JOYSTICK)) {
        [self callSelector:@selector(leftJoystickPressed:) ifImplementedWithBool:YES];
    } else if (buttonStates.buttonJustReleased(SIXENSE_BUTTON_JOYSTICK)) {
        [self callSelector:@selector(leftJoystickPressed:) ifImplementedWithBool:NO];
    }
    
    if (buttonStates.buttonJustPressed(SIXENSE_BUTTON_1)) {
        [self callSelector:@selector(leftButton1Pressed:) ifImplementedWithBool:YES];
    } else if (buttonStates.buttonJustReleased(SIXENSE_BUTTON_1)) {
        [self callSelector:@selector(leftButton1Pressed:) ifImplementedWithBool:NO];
    }
    
    if (buttonStates.buttonJustPressed(SIXENSE_BUTTON_2)) {
        [self callSelector:@selector(leftButton2Pressed:) ifImplementedWithBool:YES];
    } else if (buttonStates.buttonJustReleased(SIXENSE_BUTTON_2)) {
        [self callSelector:@selector(leftButton2Pressed:) ifImplementedWithBool:NO];
    }
    
    if (buttonStates.buttonJustPressed(SIXENSE_BUTTON_3)) {
        [self callSelector:@selector(leftButton3Pressed:) ifImplementedWithBool:YES];
    } else if (buttonStates.buttonJustReleased(SIXENSE_BUTTON_3)) {
        [self callSelector:@selector(leftButton3Pressed:) ifImplementedWithBool:NO];
    }
    
    if (buttonStates.buttonJustPressed(SIXENSE_BUTTON_4)) {
        [self callSelector:@selector(leftButton4Pressed:) ifImplementedWithBool:YES];
    } else if (buttonStates.buttonJustReleased(SIXENSE_BUTTON_4)) {
        [self callSelector:@selector(leftButton4Pressed:) ifImplementedWithBool:NO];
    }
    
    if (buttonStates.buttonJustPressed(SIXENSE_BUTTON_START)) {
        [self callSelector:@selector(leftStartPressed:) ifImplementedWithBool:YES];
    } else if (buttonStates.buttonJustReleased(SIXENSE_BUTTON_START)) {
        [self callSelector:@selector(leftStartPressed:) ifImplementedWithBool:NO];
    }
    
    if (buttonStates.triggerJustPressed()) {
        [self callSelector:@selector(leftTriggerPressed:) ifImplementedWithBool:YES];
    } else if (buttonStates.triggerJustReleased()) {
        [self callSelector:@selector(leftTriggerPressed:) ifImplementedWithBool:NO];
    }
}

- (void)handleRightSideButtonStates:(sixenseUtils::ButtonStates)buttonStates {
    if (buttonStates.buttonJustPressed(SIXENSE_BUTTON_BUMPER)) {
        [self callSelector:@selector(rightBumperPressed:) ifImplementedWithBool:YES];
    } else if (buttonStates.buttonJustReleased(SIXENSE_BUTTON_BUMPER)) {
        [self callSelector:@selector(rightBumperPressed:) ifImplementedWithBool:NO];
    }
    
    if (buttonStates.buttonJustPressed(SIXENSE_BUTTON_JOYSTICK)) {
        [self callSelector:@selector(rightJoystickPressed:) ifImplementedWithBool:YES];
    } else if (buttonStates.buttonJustReleased(SIXENSE_BUTTON_JOYSTICK)) {
        [self callSelector:@selector(rightJoystickPressed:) ifImplementedWithBool:NO];
    }
    
    if (buttonStates.buttonJustPressed(SIXENSE_BUTTON_1)) {
        [self callSelector:@selector(rightButton1Pressed:) ifImplementedWithBool:YES];
    } else if (buttonStates.buttonJustReleased(SIXENSE_BUTTON_1)) {
        [self callSelector:@selector(rightButton1Pressed:) ifImplementedWithBool:NO];
    }
    
    if (buttonStates.buttonJustPressed(SIXENSE_BUTTON_2)) {
        [self callSelector:@selector(rightButton2Pressed:) ifImplementedWithBool:YES];
    } else if (buttonStates.buttonJustReleased(SIXENSE_BUTTON_2)) {
        [self callSelector:@selector(rightButton2Pressed:) ifImplementedWithBool:NO];
    }
    
    if (buttonStates.buttonJustPressed(SIXENSE_BUTTON_3)) {
        [self callSelector:@selector(rightButton3Pressed:) ifImplementedWithBool:YES];
    } else if (buttonStates.buttonJustReleased(SIXENSE_BUTTON_3)) {
        [self callSelector:@selector(rightButton3Pressed:) ifImplementedWithBool:NO];
    }
    
    if (buttonStates.buttonJustPressed(SIXENSE_BUTTON_4)) {
        [self callSelector:@selector(rightButton4Pressed:) ifImplementedWithBool:YES];
    } else if (buttonStates.buttonJustReleased(SIXENSE_BUTTON_4)) {
        [self callSelector:@selector(rightButton4Pressed:) ifImplementedWithBool:NO];
    }
    
    if (buttonStates.buttonJustPressed(SIXENSE_BUTTON_START)) {
        [self callSelector:@selector(rightStartPressed:) ifImplementedWithBool:YES];
    } else if (buttonStates.buttonJustReleased(SIXENSE_BUTTON_START)) {
        [self callSelector:@selector(rightStartPressed:) ifImplementedWithBool:NO];
    }
    
    if (buttonStates.triggerJustPressed()) {
        [self callSelector:@selector(rightTriggerPressed:) ifImplementedWithBool:YES];
    } else if (buttonStates.triggerJustReleased()) {
        [self callSelector:@selector(rightTriggerPressed:) ifImplementedWithBool:NO];
    }
}


- (void)dealloc
{
    sixenseExit();
}

@end
