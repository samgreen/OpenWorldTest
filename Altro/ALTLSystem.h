//
//  SKRLSystem.h
//  OpenWorldTest
//
//  Created by Mike Rotondo on 6/7/13.
//  Copyright (c) 2013 Taka Taka. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ALTLSystem : NSObject

- (id)initWithVariables:(NSArray *)variables constants:(NSArray *)constants rules:(NSDictionary *)rules;
- (NSString *)process:(NSString *)string numGenerations:(int)numGenerations;

@end
