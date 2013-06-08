//
//  SKRLSystem.m
//  OpenWorldTest
//
//  Created by Mike Rotondo on 6/7/13.
//  Copyright (c) 2013 Taka Taka. All rights reserved.
//

#import "SKRLSystem.h"

@implementation SKRLSystem
{
    NSSet *_variables;
    NSSet *_constants;
    NSDictionary *_rules;
}

- (id)initWithVariables:(NSArray *)variables constants:(NSArray *)constants rules:(NSDictionary *)rules
{
    self = [super init];
    if (self) {
        _variables = [NSSet setWithArray:variables];
        _constants = [NSSet setWithArray:constants];
        _rules = rules;
    }
    return self;
}

- (NSString *)process:(NSString *)string numGenerations:(int)numGenerations;
{
    if (numGenerations <= 0)
    {
        return string;
    }
    NSMutableString *newString = [NSMutableString string];
    for (int i = 0; i < string.length; i++)
    {
        [newString appendString:[self processCharacter:[string substringWithRange:NSMakeRange(i, 1)]]];
    }
    NSLog(@"Got a new string; %@", newString);
    return [self process:newString numGenerations:numGenerations - 1];
}

- (NSString *)processCharacter:(NSString *)character
{
    if ([_constants containsObject:character])
    {
        return character;
    }
    else if ([_variables containsObject:character])
    {
        NSString *ruleOutput = [_rules objectForKey:character];
        return ruleOutput;
    }
    NSAssert(NO, @"L-System tried to process a character %@ which is neither a constant or a variable", character);
    return nil;
}

@end
