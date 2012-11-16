//
//  PauseGame.h
//  SpaceJump
//
//  Created by Brady Hunt on 11/15/12.
//  Copyright (c) 2012 Matthew McArthur. All rights reserved.
//

#import "cocos2d.h"
#import "CCMain.h"
#import "Game.h"

@interface PauseGame : Main <UITextFieldDelegate>
+ (CCScene *)pauseSceneWithScore:(int)currentScore andCombo:(int)currentCombo andCurrentMode:(NSString*)currentMode andGame:(Game *)game;
- (id)initWithScore:(int)currentScore andCombo:(int)currentCombo andCurrentMode:(NSString*) currentMode andGame:(Game *)game;
@end

