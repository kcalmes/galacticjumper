//
//  PauseGame.m
//  SpaceJump
//
//  Created by Brady Hunt on 11/15/12.
//  Copyright (c) 2012 Matthew McArthur. All rights reserved.
//

#import "PauseGame.h"
#import "CCMain.h"
#import "Game.h"
#import "SimpleAudioEngine.h"

@interface PauseGame ()

@property (nonatomic, strong) Game *game;

@end

@implementation PauseGame

@synthesize game = _game;

NSString* gameMode;

+ (CCScene *)pauseSceneWithScore:(int)currentScore andCombo:(int)lastCombo andCurrentMode:(NSString *)currentMode andGame:(Game *)game
{
    CCScene *scene = [CCScene node];
    
    PauseGame *layer = [[[PauseGame alloc] initWithScore:currentScore andCombo:lastCombo andCurrentMode:currentMode andGame:game] autorelease];
    [scene addChild:layer];
    
    return scene;
}

- (id)initWithScore:(int)currentScore andCombo:(int)currentCombo andCurrentMode:(NSString *)currentMode andGame:(Game *)game
{
    //NSLog(@"Highscores::init");
	
	if(![super init]) return nil;
    
    self.game = game;
	
    CGRect screenBound = [[UIScreen mainScreen] bounds];
    CGSize screenSize = screenBound.size;
    CGFloat screenHeight = screenSize.width;
    CGFloat screenWidth = screenSize.height;

    NSString *stringLabel;
    stringLabel = [NSString stringWithFormat:@"Current Score: %d", currentScore];
    CCLabelBMFont *currentScoreLabel = [CCLabelBMFont labelWithString:stringLabel fntFile:@"spaceJump-hd.fnt"];
    [self addChild:currentScoreLabel];
    currentScoreLabel.position = ccp(screenWidth*.5,screenHeight*.75);
    
    stringLabel = [NSString stringWithFormat:@"Current Combo: %d", currentCombo];
    CCLabelBMFont *highScoreLabel = [CCLabelBMFont labelWithString:stringLabel fntFile:@"spaceJump-hd.fnt"];
    [self addChild:highScoreLabel];
    highScoreLabel.position = ccp(screenWidth*.5,screenHeight*.50);
    
    //display the high scrore
    //NSLog(@"current score: %d -> high score: %d", currentScore, highScore);
    
    [self loadMenu];
		
	return self;
}

- (void)dealloc {
    //	NSLog(@"Highscores::dealloc");
	[super dealloc];
}

- (void)playAgainAction:(id)sender
{
    //	NSLog(@"playAgainAction");
    
	CCTransitionScene *ts = [CCTransitionFade transitionWithDuration:0.5f scene:[Game sceneWithMode:gameMode] withColor:ccWHITE];
	[[CCDirector sharedDirector] replaceScene:ts];
}

- (void)exitGameAction:(id)sender
{
	//NSLog(@"exitGameAction");
    [CDAudioManager sharedManager].mute = TRUE;
    [[UIApplication sharedApplication].keyWindow.rootViewController dismissModalViewControllerAnimated:YES];
    [[CCDirector sharedDirector] popScene];
}

- (void)resumeGameAction:(id)sender
{
	CCTransitionScene *ts = [CCTransitionCrossFade transitionWithDuration:0.5f scene:[Game sceneWithGame:self.game]];
	[[CCDirector sharedDirector] replaceScene:ts];
}

- (void)toggleMute:(id)sender
{
    [CDAudioManager sharedManager].mute = ![CDAudioManager sharedManager].mute;
    
    [self loadMenu];
}

-(void)loadMenu{
    CGRect screenBound = [[UIScreen mainScreen] bounds];
    CGSize screenSize = screenBound.size;
    CGFloat screenHeight = screenSize.width;
    CGFloat screenWidth = screenSize.height;
    
    CCMenuItem *playAgainButton = [CCMenuItemImage itemFromNormalImage:@"playAgainButton.png" selectedImage:@"playAgainButton.png" target:self selector:@selector(playAgainAction:)];
	CCMenuItem *exitGameButton = [CCMenuItemImage itemFromNormalImage:@"buttonhome.png" selectedImage:@"buttonhome.png" target:self selector:@selector(exitGameAction:)];
    CCMenuItem *resumePlayButton = [CCMenuItemImage itemFromNormalImage:@"resumePlay.png" selectedImage:@"resumePlay.png" target:self selector:@selector(resumeGameAction:)];
    CCMenuItem *muteButton;
    BOOL muted = [CDAudioManager sharedManager].mute;
    if(muted){
        muteButton = [CCMenuItemImage itemFromNormalImage:@"buttonsound.png" selectedImage:@"buttonsound.png" target:self selector:@selector(toggleMute:)];
    } else {
        muteButton = [CCMenuItemImage itemFromNormalImage:@"buttonnosound.png" selectedImage:@"buttonnosound.png" target:self selector:@selector(toggleMute:)];
    }
	
	CCMenu *menu = [CCMenu menuWithItems: resumePlayButton, playAgainButton, exitGameButton, muteButton, nil];
    
	[menu alignItemsHorizontallyWithPadding:9];
    
	menu.position = ccp(screenWidth*.5,screenHeight*.20);
	
	[self addChild:menu];
}


@end
