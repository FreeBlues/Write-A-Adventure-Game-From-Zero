//
//  GameCenterAddon.m
//
//  Basic GameCenter integration Codea Addon
//   supports leaderboards, achievements
//
//  Created by Simeon on 12/10/2014.
//  Copyright (c) 2014 Two Lives Left. All rights reserved.
//

#import "GameCenterAddon.h"

#import <GameKit/GameKit.h>

#import "StandaloneCodeaViewController.h"

#import "lua.h"
#import "lauxlib.h"

#define GAMECENTER_LIB_NAME "gamecenter"

#pragma mark - Lua Functions

static int gamecenter_enabled(struct lua_State* L);

static int gamecenter_showLeaderboards(struct lua_State* L);
static int gamecenter_showAchievements(struct lua_State* L);

static int gamecenter_submitScore(struct lua_State* L);
static int gamecenter_submitAchievement(struct lua_State* L);

#pragma mark - Lua Function Mappings

static const luaL_Reg gamecenterLibs[] =
{
    {"enabled", gamecenter_enabled},
    {"showLeaderboards", gamecenter_showLeaderboards},
    {"showAchievements", gamecenter_showAchievements},
    {"submitScore",      gamecenter_submitScore},
    {"submitAchievement",gamecenter_submitAchievement},
    {NULL, NULL}
};

static int luaopen_gamecenter(lua_State *L)
{
    //Register Game Center functions with Lua
    lua_newtable(L);
    luaL_setfuncs(L, gamecenterLibs, 0);
    
    return 1;
}

#pragma mark - Game Center Addon

@interface GameCenterAddon ()<GKGameCenterControllerDelegate>

@end

@implementation GameCenterAddon

#pragma mark - Singleton

+ (instancetype) sharedInstance
{
    static id _sharedObject = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedObject = [[self alloc] init];
    });
    return _sharedObject;
}

#pragma mark - Game Center Helper Methods

- (void) authenticateLocalPlayerWithCodeaController:(StandaloneCodeaViewController *)codeaController
{
    __weak __typeof(&*self)weakSelf = self;
    
    //Create the authentication handler which captures the Codea View Controller
    GKLocalPlayer *player = [GKLocalPlayer localPlayer];
    
    player.authenticateHandler = ^(UIViewController *viewController, NSError *error) {
        
        if( viewController != nil )
        {
            //Game Center wants us to present something
            
            //Pause the Codea game
            codeaController.paused = YES;
            
            //Present the controller
            [codeaController presentViewController:viewController animated:YES completion:nil];
        }
        else
        {
            //The player signed in, or game center was disabled
            
            //Resume Codea game
            codeaController.paused = NO;
            
            //Game center is enabled if the player authenticated
            weakSelf.gameCenterEnabled = [GKLocalPlayer localPlayer].authenticated;
            
            if( weakSelf.gameCenterEnabled )
            {
                //Get the default leaderboard
                [[GKLocalPlayer localPlayer] loadDefaultLeaderboardIdentifierWithCompletionHandler:^(NSString *leaderboardIdentifier, NSError *error) {
                    
                    weakSelf.defaultLeaderboard = leaderboardIdentifier;
                }];
            }
        }
        
    };
}

- (void) showGameCenterWithConfigurationBlock:(void(^)(GKGameCenterViewController *gvc))config
{
    GKGameCenterViewController *gcController = [[GKGameCenterViewController alloc] init];
    
    //Pause Codea Runtime
    StandaloneCodeaViewController *currentCodea = self.codeaController;
    currentCodea.paused = YES;
    
    if( config )
    {
        config(gcController);
    }
    
    //Present game center leaderboards
    gcController.gameCenterDelegate = self;
    [currentCodea presentViewController:gcController animated:YES completion:nil];
}

- (void) submitScore:(NSInteger)score leaderboard:(NSString *)leaderboard
{
    GKScore *localScore = [[GKScore alloc] initWithLeaderboardIdentifier:leaderboard];
    
    localScore.value = score;
    localScore.leaderboardIdentifier = leaderboard ?: self.defaultLeaderboard;
    
    [GKScore reportScores:@[localScore] withCompletionHandler:^(NSError *error) {
        //Do nothing yet
    }];
}

- (void) submitAchievement:(NSString *)achievement percent:(double)percent
{
    GKAchievement *localAchievement = [[GKAchievement alloc] initWithIdentifier:achievement];
    
    localAchievement.percentComplete = percent;
    
    [GKAchievement reportAchievements:@[localAchievement] withCompletionHandler:^(NSError *error) {
        //Do nothing yet
    }];
}

- (void) showLeaderboardWithID:(NSString *)leaderboardID
{
    __weak __typeof(&*self)weakSelf = self;
    
    leaderboardID = leaderboardID ?: self.defaultLeaderboard;
    
    [self showGameCenterWithConfigurationBlock:^(GKGameCenterViewController *gvc) {
        gvc.viewState = GKGameCenterViewControllerStateLeaderboards;
        gvc.leaderboardIdentifier = leaderboardID;
    }];
}

- (void) showAchievements
{
    [self showGameCenterWithConfigurationBlock:^(GKGameCenterViewController *gvc) {
        gvc.viewState = GKGameCenterViewControllerStateAchievements;
    }];
}

#pragma mark - Codea Addon Protocol Implementation

- (void) codea:(StandaloneCodeaViewController*)codeaController didCreateLuaState:(struct lua_State*)L
{
    //Authenticate the local player, pausing the runtime if necessary
    [self authenticateLocalPlayerWithCodeaController:codeaController];
    
    CODEA_ADDON_REGISTER(GAMECENTER_LIB_NAME, luaopen_gamecenter);
}

#pragma mark - Game Center View Controller Delegate

- (void) gameCenterViewControllerDidFinish:(GKGameCenterViewController *)gameCenterViewController
{
    [gameCenterViewController.presentingViewController dismissViewControllerAnimated:YES completion:^{
        
        //Unpause Codea Runtime
        self.codeaController.paused = NO;
        
    }];
}

#pragma mark - Lua Function Implementations

static int gamecenter_enabled(struct lua_State* L)
{
    lua_pushboolean(L, [GameCenterAddon sharedInstance].gameCenterEnabled);
    
    return 1;
}

static int gamecenter_showLeaderboards(struct lua_State* L)
{
    NSString *leaderboardID = nil;
    
    int n = lua_gettop(L);
    
    //Get the leaderboard ID
    if( n > 0 )
    {
        leaderboardID = @(luaL_checkstring(L, 1));
    }
    
    //All Lua functions call outside of main thread
    // we need to handle any UI on main thread
    dispatch_async(dispatch_get_main_queue(), ^{
        
        //If leaderboard is nil, default leaderboard will be used
        [[GameCenterAddon sharedInstance] showLeaderboardWithID:leaderboardID];
        
    });
    
    return 0;
}

static int gamecenter_showAchievements(struct lua_State* L)
{
    //All Lua functions call outside of main thread
    // we need to handle any UI on main thread
    dispatch_async(dispatch_get_main_queue(), ^{
        
        //If leaderboard is nil, default leaderboard will be used
        [[GameCenterAddon sharedInstance] showAchievements];
        
    });
    
    return 0;
}

static int gamecenter_submitScore(struct lua_State* L)
{
    int n = lua_gettop(L);
    
    lua_Number score = 0;
    NSString *leaderboardID = nil;
    
    if( n > 0 )
    {
        score = luaL_checknumber(L, 1);
    }
    
    if( n > 1 )
    {
        //Custom leaderboard specified
        leaderboardID = @(luaL_checkstring(L, 2));
    }
    
    [[GameCenterAddon sharedInstance] submitScore:score leaderboard:leaderboardID];
    
    return 0;
}

static int gamecenter_submitAchievement(struct lua_State* L)
{
    int n = lua_gettop(L);
    
    if( n >= 2 )
    {
        NSString *achievementID = @(luaL_checkstring(L, 1));
        lua_Number percent = luaL_checknumber(L, 2);
        
        [[GameCenterAddon sharedInstance] submitAchievement:achievementID percent:percent];
    }
    
    return 0;
}

@end
