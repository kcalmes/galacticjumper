#import "GameOver.h"
#import "CCMain.h"
#import "Game.h"
#import "GameOver.h"

@interface GameOver (Private)
- (void)playAgainAction:(id)sender;
- (void)exitGameAction:(id)sender;
@end


@implementation GameOver

+ (CCScene *)gameOverSceneWithScore:(int)lastScore
{
    CCScene *game = [CCScene node];
    
    GameOver *layer = [[[GameOver alloc] initWithScore:lastScore] autorelease];
    [game addChild:layer];
    
    return game;
}

- (id)initWithScore:(int)lastScore {
    NSLog(@"Highscores::init");
	
	if(![super init]) return nil;

//	NSLog(@"lastScore = %d",lastScore);
	
	int highScore = [self getHighScore];
    int currentScore = lastScore;
    
    if (highScore < currentScore) {
        [self saveHighScore:currentScore];
        highScore = currentScore;
        //announce NEW HIGH SCORE!!
    }
    //Display the current score
    //display the high scrore
    
    NSLog(@"current score: %d -> high score: %d", currentScore, highScore);

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
	[highscores release];
	[super dealloc];
}

- (void)playAgainAction:(id)sender
{
//	NSLog(@"button1Callback");

	CCTransitionScene *ts = [CCTransitionFade transitionWithDuration:0.5f scene:[Game scene] withColor:ccWHITE];
	[[CCDirector sharedDirector] replaceScene:ts];
}

- (void)exitGameAction:(id)sender
{
	//NSLog(@"button2Callback");
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

@end
