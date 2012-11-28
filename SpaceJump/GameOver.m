#import "GameOver.h"
#import "CCMain.h"
#import "Game.h"
#import "GameOver.h"
#import "SimpleAudioEngine.h"

@interface GameOver (Private)
- (void)playAgainAction:(id)sender;
- (void)exitGameAction:(id)sender;
@end

@implementation GameOver
NSString* gameMode;
float seconds;
int minutes;


+ (CCScene *)gameOverSceneWithScore:(int)lastScore andCombo:(int)lastCombo andCurrentMode:(NSString *)currentMode andMinutes:(int)minutes andSeconds:(float) seconds
{
    CCScene *game = [CCScene node];
    
    GameOver *layer = [[[GameOver alloc] initWithScore:lastScore andCombo:lastCombo andCurrentMode:currentMode andMinutes:minutes andSeconds:seconds] autorelease];
    [game addChild:layer];
    
    return game;
}

- (id)initWithScore:(int)currentScore andCombo:(int)currentCombo andCurrentMode:(NSString *)currentMode andMinutes:(int)minutes andSeconds:(float) seconds
{
    //NSLog(@"Highscores::init");
	
	if(![super init]) return nil;
	
    CGRect screenBound = [[UIScreen mainScreen] bounds];
    CGSize screenSize = screenBound.size;
    CGFloat screenHeight = screenSize.width;
    CGFloat screenWidth = screenSize.height;
    
	
    gameMode = currentMode;
    int highScore;
    int bestMinutes;
    float bestSeconds;
    NSString* scoreLabel;
    NSString* bestScoreLabel;
    NSString* comboLabel;
    
    if ([gameMode isEqualToString:@"TimedMode"])
    {
        bestMinutes = [self getBestTimeMinutes];
        bestSeconds = [self getBestTimeSeconds];
        if (bestSeconds > seconds)
        {
            [self saveBestTimeMinutes:minutes];
            [self saveBestTimeSeconds:seconds];
            bestMinutes = minutes;
            bestSeconds = seconds;
        }
        scoreLabel = [NSString stringWithFormat:@"Time %d:%.1f", minutes, seconds - (minutes * 60)];
        bestScoreLabel = [NSString stringWithFormat:@"Best Time %d:%.1f", bestMinutes, bestSeconds - (bestMinutes * 60)];
        CCLabelBMFont *currentScoreLabel = [CCLabelBMFont labelWithString:scoreLabel fntFile:@"spaceJump-hd.fnt"];
        [self addChild:currentScoreLabel];
        currentScoreLabel.position = ccp(screenWidth*.5,screenHeight*.70);
        
        CCLabelBMFont *highScoreLabel = [CCLabelBMFont labelWithString:bestScoreLabel fntFile:@"spaceJump-hd.fnt"];
        [self addChild:highScoreLabel];
        highScoreLabel.position = ccp(screenWidth*.5,screenHeight*.50);
        
        CCLabelBMFont *gameModeLabel = [CCLabelBMFont labelWithString:@"Timed Mode" fntFile:@"spaceJump-hd.fnt"];
        [self addChild:gameModeLabel];
        gameModeLabel.position = ccp(screenWidth*.5,screenHeight*.90);
    }
    else
    {
        highScore = [self getHighScore];
        if (highScore < currentScore)
        {
            [self saveHighScore:currentScore];
            highScore = currentScore;
            //announce NEW HIGH SCORE!!
        }
        int bestCombo = [self getBestCombo];
        
        if (bestCombo < currentCombo) {
            [self saveBestCombo:currentCombo];
            bestCombo = currentCombo;
            //announce NEW BEST COMBO!!
        }
        NSString*  gameModeStr;
        if ([gameMode isEqualToString:@"EasyMode"])
        {
            gameModeStr = @"Easy Mode";
        }
        else
        {
            gameModeStr = @"Hard Mode";
        }
        
        CCLabelBMFont *gameModeLabel = [CCLabelBMFont labelWithString:gameModeStr fntFile:@"spaceJump-hd.fnt"];
        [self addChild:gameModeLabel];
        gameModeLabel.position = ccp(screenWidth*.5,screenHeight*.92);
        
        scoreLabel = [NSString stringWithFormat:@"Score: %d", currentScore];
        bestScoreLabel = [NSString stringWithFormat:@"High Score: %d", highScore];
        CCLabelBMFont *currentScoreLabel = [CCLabelBMFont labelWithString:scoreLabel fntFile:@"spaceJump-hd.fnt"];
        [self addChild:currentScoreLabel];
        currentScoreLabel.position = ccp(screenWidth*.5,screenHeight*.77);
        
        CCLabelBMFont *highScoreLabel = [CCLabelBMFont labelWithString:bestScoreLabel fntFile:@"spaceJump-hd.fnt"];
        [self addChild:highScoreLabel];
        highScoreLabel.position = ccp(screenWidth*.5,screenHeight*.64);
        
        
        comboLabel = [NSString stringWithFormat:@"Combo: %d", currentCombo];
        CCLabelBMFont *currentComboLabel = [CCLabelBMFont labelWithString:comboLabel fntFile:@"spaceJump-hd.fnt"];
        [self addChild:currentComboLabel];
        currentComboLabel.position = ccp(screenWidth*.5,screenHeight*.51);
        
        comboLabel = [NSString stringWithFormat:@"Max Combo: %d", bestCombo];
        CCLabelBMFont *maxComboLabel = [CCLabelBMFont labelWithString:comboLabel fntFile:@"spaceJump-hd.fnt"];
        [self addChild:maxComboLabel];
        maxComboLabel.position = ccp(screenWidth*.5,screenHeight*.38);
        
        currentScoreLabel.scale = .75f;
        highScoreLabel.scale = .75f;
        maxComboLabel.scale = .75f;
        currentComboLabel.scale = .75f;
        gameModeLabel.scale = .9f;
    }
    
    //display the high scrore
    //NSLog(@"current score: %d -> high score: %d", currentScore, highScore);

	CCMenuItem *playAgainButton = [CCMenuItemImage itemFromNormalImage:@"playAgainButton.png" selectedImage:@"playAgainButton.png" target:self selector:@selector(playAgainAction:)];
	CCMenuItem *exitGameButton = [CCMenuItemImage itemFromNormalImage:@"buttonhome.png" selectedImage:@"exitGameButton" target:self selector:@selector(exitGameAction:)];
	
	CCMenu *menu = [CCMenu menuWithItems: playAgainButton, exitGameButton, nil];

	[menu alignItemsHorizontallyWithPadding:9];

	menu.position = ccp(screenWidth*.5,screenHeight*.20);
	
	[self addChild:menu];
	
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

-(void)saveHighScore:(int)highscore
{
    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
	if (standardUserDefaults) {
        if ([gameMode isEqualToString:@"EasyMode"])
        {
            [standardUserDefaults setObject:[NSNumber numberWithInt:highscore] forKey:@"highscore_easy"];
        }
        else
        {
            [standardUserDefaults setObject:[NSNumber numberWithInt:highscore] forKey:@"highscore_hard"];
        }
		[standardUserDefaults synchronize];
	}
}

-(int)getHighScore
{
    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
	int val = 0;
	if (standardUserDefaults)
    {
        if ([gameMode isEqualToString:@"EasyMode"])
        {
		val = [[standardUserDefaults objectForKey:@"highscore_easy"] integerValue];
        }
        else
        {
            val = [[standardUserDefaults objectForKey:@"highscore_hard"] integerValue];
        }
    }
	return val;
}
    
-(float)getBestTimeSeconds
{
    
    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
	float val = 0.0;
	if (standardUserDefaults)
    {
        val = [[standardUserDefaults objectForKey:@"highscore_seconds"] floatValue];
    }
    return val;
}

-(int)getBestTimeMinutes
{
    
    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
	int val = 0;
	if (standardUserDefaults)
    {
        val = [[standardUserDefaults objectForKey:@"highscore_minutes"] floatValue];
    }
    return val;
}


-(void)saveBestTimeSeconds:(float)seconds
{
    
    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
	if (standardUserDefaults)
    {
        [standardUserDefaults setObject:[NSNumber numberWithFloat:seconds] forKey:@"highscore_seconds"];
    }
}

-(void)saveBestTimeMinutes:(int)minutes
{
    
    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
	if (standardUserDefaults)
    {
        [standardUserDefaults setObject:[NSNumber numberWithInt:minutes] forKey:@"highscore_minutes"];
    }
}

-(void)saveBestCombo:(int)combo{
    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
	if (standardUserDefaults)
    {
        if ([gameMode isEqualToString:@"EasyMode"])
        {
            [standardUserDefaults setObject:[NSNumber numberWithInt:combo] forKey:@"combo_easy"];
        }
        else
        {
            [standardUserDefaults setObject:[NSNumber numberWithInt:combo] forKey:@"combo_hard"];
        }
		[standardUserDefaults synchronize];
	}
}
-(int)getBestCombo{
    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
	int val = 0;
	if (standardUserDefaults)
    {
        if ([gameMode isEqualToString:@"EasyMode"])
        {
            val = [[standardUserDefaults objectForKey:@"combo_easy"] integerValue];
        }
        else
        {
            val = [[standardUserDefaults objectForKey:@"combo_hard"] integerValue];
        }
    }
	
	return val;
}
@end
