//
//  CodeaAddon.h
//
//  This is a protocol for adding native extensions to
//   exported Codea projects. You must deal with Lua directly to
//   register your functions and globals.
//
//  Please note that all of these callbacks happen off the main
//   thread. If you want to touch UIKit please ensure that you
//   dispatch_async to the main thread.
//
//  Created by Simeon on 5/04/13.
//  Copyright (c) 2014 Two Lives Left. All rights reserved.
//

#import "StandaloneCodeaViewController.h"

#define CODEA_ADDON_REGISTER(name, func) \
            luaL_requiref(L, (name), (func), 1); \
            lua_pop(L, 1);

@class CodeaViewController;

struct lua_State;

@protocol CodeaAddon <NSObject>

//For registering your custom functions and libraries
- (void) codea:(StandaloneCodeaViewController*)controller didCreateLuaState:(struct lua_State*)L;

@optional

//For clean up (if necessary)
- (void) codea:(StandaloneCodeaViewController*)controller willCloseLuaState:(struct lua_State*)L;

//Handling changes to the viewer state (if necessary)
- (void) codea:(StandaloneCodeaViewController*)controller didPause:(BOOL)pause;
- (void) codea:(StandaloneCodeaViewController*)controller didChangeViewMode:(CodeaViewMode)mode;

//The reset button is pressed, this will cause:
//  willCloseLuaState and didCreateLuaState to be called again in sequence
- (void) codeaWillReset:(StandaloneCodeaViewController*)controller;

//Called each frame update
- (void) codeaWillDrawFrame:(StandaloneCodeaViewController*)controller withDelta:(CGFloat)deltaTime;

//Called when the addon is registered
- (void) codeaDidRegisterAddon:(StandaloneCodeaViewController*)controller;

@end

//Basic Codea Addon Implementation
// Subclass this for your own addons
@interface CodeaAddon : NSObject<CodeaAddon>

@property (nonatomic, weak, readonly) StandaloneCodeaViewController *codeaController;

@end
