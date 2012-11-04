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

- (id)initWithScore:(int)currentScore andCombo:(int)currentCombo
{
    //NSLog(@"Highscores::init");
	
	if(![super init]) return nil;
	
    CGRect screenBound = [[UIScreen mainScreen] bounds];
    CGSize screenSize = screenBound.size;
    CGFloat screenHeight = screenSize.width;
    CGFloat screenWidth = screenSize.height;
    
	int highScore = [self getHighScore];
    
    if (highScore < currentScore) {
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
    NSString *stringLabel;
    stringLabel = [NSString stringWithFormat:@"Score: %d", currentScore];
    CCLabelBMFont *currentScoreLabel = [CCLabelBMFont labelWithString:stringLabel fntFile:@"spaceJump-hd.fnt"];
    [self addChild:currentScoreLabel];
    currentScoreLabel.position = ccp(screenWidth*.5,screenHeight*.90);
    
    stringLabel = [NSString stringWithFormat:@"High Score: %d", highScore];
    CCLabelBMFont *highScoreLabel = [CCLabelBMFont labelWithString:stringLabel fntFile:@"spaceJump-hd.fnt"];
    [self addChild:highScoreLabel];
    highScoreLabel.position = ccp(screenWidth*.5,screenHeight*.75);
    
    stringLabel = [NSString stringWithFormat:@"Combo: %d", currentCombo];
    CCLabelBMFont *currentComboLabel = [CCLabelBMFont labelWithString:stringLabel fntFile:@"spaceJump-hd.fnt"];
    [self addChild:currentComboLabel];
    currentComboLabel.position = ccp(screenWidth*.5,screenHeight*.60);
    
    stringLabel = [NSString stringWithFormat:@"Max Combo: %d", bestCombo];
    CCLabelBMFont *maxComboLabel = [CCLabelBMFont labelWithString:stringLabel fntFile:@"spaceJump-hd.fnt"];
    [self addChild:maxComboLabel];
    maxComboLabel.position = ccp(screenWidth*.5,screenHeight*.45);


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
