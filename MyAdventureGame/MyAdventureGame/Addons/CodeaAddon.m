//
//  CodeaAddon.m
//  MyProject
//
//  Created by Simeon on 13/10/2014.
//  Copyright (c) 2014 MyCompany. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CodeaAddon.h"

@implementation CodeaAddon

- (void) codea:(StandaloneCodeaViewController*)controller didCreateLuaState:(struct lua_State*)L
{
    NSAssert(NO, @"Missing implementation for '%@' in CodeaAddon subclass", NSStringFromSelector(_cmd));
}

- (void) codea:(StandaloneCodeaViewController*)controller willCloseLuaState:(struct lua_State*)L
{
    _codeaController = nil;
}

- (void) codeaDidRegisterAddon:(StandaloneCodeaViewController *)controller
{
    _codeaController = controller;
}

@end