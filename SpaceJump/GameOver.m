#import "GameOver.h"
#import "CCMain.h"
#import "Game.h"
#import "GameOver.h"

@interface GameOver (Private)
- (void)playAgainAction:(id)sender;
- (void)exitGameAction:(id)sender;
@end


@implementation GameOver

+ (CCScene *)gameOverSceneWithScore:(int)lastScore andCombo:(int)lastCombo
{
    CCScene *game = [CCScene node];
    
    GameOver *layer = [[[GameOver alloc] initWithScore:lastScore andCombo:lastCombo] autorelease];
    [game addChild:layer];
    
    return game;
}

- (id)initWithScore:(int)currentScore andCombo:(int)lastCombo
{
    NSLog(@"Highscores::init");
	
	if(![super init]) return nil;
	
	int highScore = [self getHighScore];
    
    if (highScore < currentScore) {
        [self saveHighScore:currentScore];
        highScore = currentScore;
        //announce NEW HIGH SCORE!!
    }
    NSString *stringLabel = [NSString stringWithFormat:@"Score: %d!", currentScore];
    CCLabelBMFont *lastScoreLabel = [CCLabelBMFont labelWithString:stringLabel fntFile:@"spaceJump-hd.fnt"];
    //[self addChild:comboTallyDisplay];
    //comboTallyDisplay.opacity = 0;
    lastScoreLabel.position = ccpMidpoint(ccp(0,0), ccp(480,320));
    //id a1 = [CCFadeIn actionWithDuration:0.25f];
    //id a2 = [CCFadeOut actionWithDuration:0.75f];
    //id a3 = [CCSequence actions:a1,a2,nil];
    //[comboTallyDisplay runAction:a3];

    //display the high scrore
    NSLog(@"current score: %d -> high score: %d", currentScore, highScore);
    
    
    int bestCombo = [self getHighScore];
    int currentCombo = lastCombo;
    
    if (bestCombo < currentCombo) {
        [self saveBestCombo:currentCombo];
        bestCombo = currentCombo;
        //announce NEW BEST COMBO!!
    }
    //Display the current score
    //display the high scrore
    
    

	CCMenuItem *button1 = [CCMenuItemImage itemFromNormalImage:@"playAgainButton.png" selectedImage:@"playAgainButton.png" target:self selector:@selector(playAgainAction:)];
	CCMenuItem *button2 = [CCMenuItemImage itemFromNormalImage:@"exitGameButton.png" selectedImage:@"exitGameButton" target:self selector:@selector(exitGameAction:)];
	
	CCMenu *menu = [CCMenu menuWithItems: button1, button2, nil];

	[menu alignItemsVerticallyWithPadding:9];
    CGRect screenBound = [[UIScreen mainScreen] bounds];
    CGSize screenSize = screenBound.size;
    CGFloat screenHeight = screenSize.width;
    CGFloat screenWidth = screenSize.height;
	menu.position = ccp(screenWidth/2,screenHeight/2);
	
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

	CCTransitionScene *ts = [CCTransitionFade transitionWithDuration:0.5f scene:[Game scene] withColor:ccWHITE];
	[[CCDirector sharedDirector] replaceScene:ts];
}

- (void)exitGameAction:(id)sender
{
	//NSLog(@"exitGameAction");
    [[UIApplication sharedApplication].keyWindow.rootViewController dismissModalViewControllerAnimated:YES];
    [[CCDirector sharedDirector] popScene];
}

-(void)saveHighScore:(int)highscore{
    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
	if (standardUserDefaults) {
		[standardUserDefaults setObject:[NSNumber numberWithInt:highscore] forKey:@"highscore"];
		[standardUserDefaults synchronize];
	}
}
-(int)getHighScore{
    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
	int val = 0;
	if (standardUserDefaults)
		val = [[standardUserDefaults objectForKey:@"highscore"] integerValue];
	
	return val;
}
-(void)saveBestCombo:(int)combo{
    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
	if (standardUserDefaults) {
		[standardUserDefaults setObject:[NSNumber numberWithInt:combo] forKey:@"combo"];
		[standardUserDefaults synchronize];
	}
}
-(int)getBestCombo{
    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
	int val = 0;
	if (standardUserDefaults)
		val = [[standardUserDefaults objectForKey:@"combo"] integerValue];
	
	return val;
}
@end
