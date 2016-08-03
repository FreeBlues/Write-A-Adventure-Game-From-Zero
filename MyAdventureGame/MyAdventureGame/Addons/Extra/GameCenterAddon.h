//
//  GameCenterAddon.h
//
//  Basic GameCenter integration Codea Addon
//   supports leaderboards, achievements
//
//  Created by Simeon on 12/10/2014.
//  Copyright (c) 2014 Two Lives Left. All rights reserved.
//

/*
 
 This addon implements the following Lua API:
 -------------------------------------------
 
 -- Check if GameCenter is enabled
 if gamecenter.enabled() then
 
     -- Submit to default leaderboard
     gamecenter.submitScore( 1234 )
 
     -- Submit to specific leaderboard
     gamecenter.submitScore( 1234, “LeaderboardID” )
 
 end
 
 -- Show default GameCenter leaderboard (pauses Codea)
 gamecenter.showLeaderboards()
 
 -- Show specific GameCenter leaderboard (pauses Codea)
 gamecenter.showLeaderboards(“LeaderboardID”)
 
 -- Show achievements (pauses Codea)
 gamecenter.showAchievements()
 
 -- Submit an achievement with a percent complete amount (0.0 - 100.0)
 gamecenter.submitAchievement( “AchievementID”, percent )
 
 -- Submit a score for a specific leaderboard
 gamecenter.submitScore( 1234, “LeaderboardID” )
 
 */

#import <Foundation/Foundation.h>

#import "CodeaAddon.h"

@interface GameCenterAddon : CodeaAddon

+ (instancetype) sharedInstance;

@property (nonatomic, assign) BOOL gameCenterEnabled;
@property (nonatomic, strong) NSString *defaultLeaderboard;

@end
