#import "Game.h"
#import "CCMain.h"
#import "GameOver.h"
#import "GANTracker.h"
#import "SimpleAudioEngine.h"

@interface Game (Private)
- (void)initPlatforms;
- (void)initPlatform;
- (void)startGame;
- (void)resetPlatforms;
- (void)resetPlatform;
- (void)resetAlien;
- (void)resetBonus;
- (void)step:(ccTime)dt;
- (void)updateAlienPosition:(ccTime)dt;
- (void)checkForBonus;
- (void)checkForObjectCollisions;
- (void)checkForGameOver;
- (void)updateScreenFramePosition;
- (void)updateScore;
- (void)updateAlienFinalPosition;
- (void)jump;
- (void)showComboLabel;
- (void)showGameOver;

#define ALIEN_YPOS_OFFSET   0
#define PLATFORM_SCALE      0.65
#define FPS                 60
#define MIN_PLATFORM_STEP	50
#define MAX_PLATFORM_STEP	200
#define NUM_PLATFORMS		7
#define PLATFORM_TOP_PAD    20
#define MIN_BONUS_STEP		20
#define MAX_BONUS_STEP		40
#define MAX_HEIGHT          180

@end

@implementation Game

//Added by Kory for animation
@synthesize alien = _alien;

#pragma mark Initialize Game

+ (CCScene *)sceneWithMode:(NSString *)mode
{
    CCScene *scene = [CCScene node];
    Game *layer = [[Game alloc] initWithMode:mode];
    [scene addChild:layer];
    
    return scene;
}

- (id)initWithMode:(NSString*) mode
{
    //count a game played in google analytics
	NSError * error;
    [[GANTracker sharedTracker] trackPageview:@"/playgame" withError:&error];

	if(![super init]) return nil;
    
    //set up screen and game globals
    CGSize screenSize = [[UIScreen mainScreen] bounds].size;
    screenHeight = screenSize.width; //In landscape height is width vice versa
    screenWidth = screenSize.height;
    maxHorizontalMovement = (screenWidth/2)+20;
    minHorizontalMovement = (screenWidth/2)-20;
	gameSuspended = YES;
    gamePaused = NO;

	[self initPlatforms];
	//load images, labels, and menus
    CCSpriteBatchNode *batchNode = (CCSpriteBatchNode *)[self getChildByTag:kSpriteManager];
	CCSprite *bonus = [CCSprite spriteWithTexture:[batchNode texture] rect:CGRectMake(652,457,67,52)];
    [batchNode addChild:bonus z:4 tag:kBonusStartTag];
    bonus.scaleX = .5f;
    bonus.scaleY = .5f;

    bonus.visible = NO;
    
    CCLabelBMFont *scoreLabel = [CCLabelBMFont labelWithString:@"0" fntFile:@"spaceJump-hd.fnt"];
	[self addChild:scoreLabel z:5 tag:kScoreLabel];
	scoreLabel.position = ccp(100,300);
    
    CCLabelBMFont *comboTallyDisplay = [CCLabelBMFont labelWithString:@"" fntFile:@"spaceJump-hd.fnt"];
    [self addChild:comboTallyDisplay z:5 tag:kComboLabel];
    comboTallyDisplay.opacity = 0;
    comboTallyDisplay.position = ccpMidpoint(ccp(0,0), ccp(screenWidth,screenHeight/2));
    
    CCMenuItem *pauseMenuButton = [CCMenuItemImage itemFromNormalImage:@"buttonpause.png"
                                                         selectedImage:@"buttonpause.png"
                                                                target:self
                                                              selector:@selector(pauseGame)];
	pauseButton = [CCMenu menuWithItems: pauseMenuButton, nil];
	pauseButton.position = ccp(screenWidth-50,screenHeight-50);
	[self addChild:pauseButton z:5];
    //change variables based on game modes
    gameMode = mode;
    if ([gameMode isEqualToString:@"EasyMode"])
    {
        easyMode = YES;
        timedMode = NO;
        easyModePad = 5;
    }
    else if ([gameMode isEqualToString:@"TimedMode"])
    {
        easyModePad = 0;
        numOfSeconds = 0;
        numOfMinutes = 0;
        timedMode = YES;
        CCLabelBMFont *scoreLabel = [CCLabelBMFont labelWithString:@"0" fntFile:@"spaceJump-hd.fnt"];
        [self addChild:scoreLabel z:5 tag:kTimerLabel];
        scoreLabel.position = ccp(70,280);
        scoreLabel.scale = 0.7;
    }
    else
    {
        easyModePad = 0;
    }

    [self schedule:@selector(step:)];
	self.isTouchEnabled = YES;
	self.isAccelerometerEnabled = YES;
    [[UIAccelerometer sharedAccelerometer] setUpdateInterval:(1.0 / FPS)];
	
	[self startGame];
    [CDAudioManager sharedManager].mute = [self isMuted];
    [[SimpleAudioEngine sharedEngine] playBackgroundMusic:@"GameOn.mp3"];
	
	return self;
}

#pragma mark Initialize Objects

- (void)initPlatforms
{
    CCSpriteBatchNode *spriteSheet = [CCSpriteBatchNode batchNodeWithFile:@"objectplatforms.png"];
    [self addChild:spriteSheet z:4];
    
    //Cache the sprite frames and texture
    CCSpriteFrame *frame;
    frame = [CCSpriteFrame frameWithTexture:spriteSheet.texture rect:CGRectMake(0,0,148,46)];
    [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFrame:frame name:[NSString stringWithFormat:@"platform%d.png", 1]];
    frame = [CCSpriteFrame frameWithTexture:spriteSheet.texture rect:CGRectMake(180,0,69,46)];
    [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFrame:frame name:[NSString stringWithFormat:@"platform%d.png", 2]];
	currentPlatformTag = kPlatformsStartTag;
	while(currentPlatformTag < kPlatformsStartTag + NUM_PLATFORMS)
    {
		[self initPlatform];
		currentPlatformTag++;
	}
	[self resetPlatforms];
}

- (void)initPlatform
{
	CGRect rect = CGRectMake(0,0,148,46);
	CCSpriteBatchNode *platformNode = (CCSpriteBatchNode*)[self getChildByTag:kPlatformManager];
	CCSprite *platform = [CCSprite spriteWithTexture:[platformNode texture] rect:rect];
	[platformNode addChild:platform z:3 tag:currentPlatformTag];
}

- (void)startGame
{    
	score = 0;	
	[self resetPlatforms];
    [self resetAlien];
	[self resetBonus];
	
	[[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    if (timedMode)
    {
        [self schedule:@selector(readySetGoAnimations:) interval:1];
        performingStartAnimations = YES;
    }
    else
    {
        gameSuspended = NO;
    }
}

- (void)dealloc
{
    self.alien = nil;
    [super dealloc];
}

#pragma mark Reset Objects

- (void)resetPlatforms
{	
	currentPlatformY = -1;
	currentPlatformTag = kPlatformsStartTag;
	currentMaxPlatformStep = 100.0f;
	currentBonusPlatformIndex = 0;
	currentBonusType = 0;
	platformCount = 0;

	while(currentPlatformTag < kPlatformsStartTag + NUM_PLATFORMS)
    {
		[self resetPlatform];
		currentPlatformTag++;
	}
}

- (void)resetPlatform
{
	if(currentPlatformY < 0)
    {
		currentPlatformY = 30.0f;
	}
    else
    {
		currentPlatformY += random() % (int)(currentMaxPlatformStep - MIN_PLATFORM_STEP) + MIN_PLATFORM_STEP;
		if(currentMaxPlatformStep < MAX_PLATFORM_STEP)
        {
			currentMaxPlatformStep += 0.5f;
		}
	}
	
	CCSpriteBatchNode *platformNode = (CCSpriteBatchNode*)[self getChildByTag:kPlatformManager];
	CCSprite *platform = (CCSprite*)[platformNode getChildByTag:currentPlatformTag];
	platform.scaleX = PLATFORM_SCALE;
    platform.scaleY = PLATFORM_SCALE;
	
	float x;
	if(currentPlatformY == 30.0f)
    {
		x = screenWidth/2;
	} else
    {
        x = (arc4random() % 780) - 150;
	}
	
	platform.position = ccp(x,currentPlatformY);
	platformCount++;
	if(platformCount == currentBonusPlatformIndex)
    {
        CCSpriteBatchNode *batchNode = (CCSpriteBatchNode*)[self getChildByTag:kSpriteManager];
		CCSprite *bonus = (CCSprite*)[batchNode getChildByTag:kBonusStartTag];
		bonus.position = ccp(x,currentPlatformY+40);
		bonus.visible = YES;
	}
}

- (void)resetAlien
{
    //Create a sprite batch node
    CCSpriteBatchNode *spriteSheet = [CCSpriteBatchNode batchNodeWithFile:@"Jumps.png"];
    [self addChild:spriteSheet z:4];

    //Cache the sprite frames and texture
    CCSpriteFrame *frame;    
    frame = [CCSpriteFrame frameWithTexture:spriteSheet.texture rect:CGRectMake(20,40,64,90)];
    [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFrame:frame name:[NSString stringWithFormat:@"alien%d.png", 1]];
    frame = [CCSpriteFrame frameWithTexture:spriteSheet.texture rect:CGRectMake(109,36,64,98)];
    [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFrame:frame name:[NSString stringWithFormat:@"alien%d.png", 2]];
    frame = [CCSpriteFrame frameWithTexture:spriteSheet.texture rect:CGRectMake(555,18,64,144)];
    [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFrame:frame name:[NSString stringWithFormat:@"alien%d.png",3]];
    
    //Create the sprite and run the animation action
    alien_pos = ccp(screenWidth/2, screenHeight/2);
    
	alien_vel.x = 0;
	alien_vel.y = 0;
	alien_acc.x = 0;
	alien_acc.y = -450.0f;
    self.alien.position = alien_pos;
    self.alien = [CCSprite spriteWithSpriteFrameName:@"alien1.png"];
    self.alien.scale = 0.8f;
    [spriteSheet addChild: self.alien];
    
    justHitPlatform = NO;
    hitStarBounus = NO;
    kindOfJump = @"DefaultJump";
    [self updateAlienFinalPosition];
}

- (void)resetBonus
{	
	CCSpriteBatchNode *batchNode = (CCSpriteBatchNode*)[self getChildByTag:kSpriteManager];
	CCSprite *bonus = (CCSprite*)[batchNode getChildByTag:kBonusStartTag];
	bonus.visible = NO;
	currentBonusPlatformIndex += random() % (MAX_BONUS_STEP - MIN_BONUS_STEP) + MIN_BONUS_STEP;
}

#pragma mark Step Functions

- (void)step:(ccTime)dt
{
	[super step:dt];
	
	if(gameSuspended) return;
	[self updateAlienPosition:dt];
    [self checkForBonus];
    
	if(alien_vel.y < 0)
    {
        if (justHitPlatform && [kindOfJump isEqualToString:@"DefaultJump"])
        {
            comboTally = 0;
        }
        justHitPlatform = NO;
        [self checkForObjectCollisions];
        [self checkForGameOver];
	}
    else if(justHitPlatform)
    {
        [self jump];
    }
    if(alien_pos.y > MAX_HEIGHT)
    {
        [self updateScore];
        [self updateVerticalScreenFramePosition];
	}
    if(alien_pos.x > maxHorizontalMovement || alien_pos.x < minHorizontalMovement)
    {
        [self updateHorizontalScreenFramePosition];
    }
    [self updateAlienFinalPosition];
}

-(void) timerUpdate:(ccTime)delta
{
    if (score/10 >= 1000 || gamePaused)
    {
        return;
    }
    numOfSeconds += delta;
    if ((numOfSeconds-(numOfMinutes*60)) >= 60)
    {
        numOfMinutes++;
    }
    NSString *timerStr = [NSString stringWithFormat:@"%d:%.1f", numOfMinutes, numOfSeconds - (numOfMinutes * 60)];
    CCLabelBMFont *timerLabel = (CCLabelBMFont*)[self getChildByTag:kTimerLabel];
    [timerLabel setString:timerStr];
}

-(void) readySetGoAnimations:(ccTime)delta
{
    if (gamePaused)
    {
        return;
    }
    startGameAnimations++;
    CCLabelBMFont *comboTallyDisplay = (CCLabelBMFont*)[self getChildByTag:kComboLabel];
    id a1 = [CCFadeIn actionWithDuration:0.25f];
    id a2 = [CCFadeOut actionWithDuration:0.75f];
    id a3 = [CCSequence actions:a1,a2,nil];
    if (startGameAnimations == 3)
    {
        [comboTallyDisplay setString:@"GO!!!"];
        [comboTallyDisplay runAction:a3];
        alien_vel.y = 0;
        gameSuspended = NO;
        [self schedule:@selector(timerUpdate:) interval:0.1];
        [self unschedule:@selector(readySetGoAnimations)];
        performingStartAnimations = NO;
    }
    else if (startGameAnimations == 2)
    {
        [comboTallyDisplay setString:@"SET"];
        
        [comboTallyDisplay runAction:a3];
    }
    else if (startGameAnimations == 1)
    {
        [comboTallyDisplay setString:@"READY"];
        [comboTallyDisplay runAction:a3];
    }
    
}

#pragma mark UI Events

- (void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInView: [touch view]];
    CGRect mySurface = (CGRectMake(0, 0, 568, 320));
    if(CGRectContainsPoint(mySurface, location))
    {
        if(alien_vel.y < 0 || justHitPlatform)
        {
            CGSize alien_size = self.alien.contentSize;
            float max_x = 320-alien_size.width/2;
            float min_x = 0+alien_size.width/2;
            
            CCSpriteBatchNode *platformNode = (CCSpriteBatchNode*)[self getChildByTag:kPlatformManager];
            for(int t = kPlatformsStartTag; t < kPlatformsStartTag + NUM_PLATFORMS; t++)
            {
                CCSprite *platform = (CCSprite*)[platformNode getChildByTag:t];
                CGSize platform_size = platform.contentSize;
                CGPoint platform_pos = platform.position;
                max_x = platform_pos.x - platform_size.width/2 - 10;
                min_x = platform_pos.x + platform_size.width/2 + 10;
                float min_y = platform_pos.y + (platform_size.height+alien_size.height)/2 - PLATFORM_TOP_PAD;
                
                if(alien_pos.x > max_x &&
                   alien_pos.x < min_x &&
                   alien_pos.y > platform_pos.y &&
                   (alien_pos.y + ALIEN_YPOS_OFFSET) < (min_y + 8 + easyModePad))
                {
                    kindOfJump = @"PerfectJump";
                }
                else if(alien_pos.x > max_x &&
                        alien_pos.x < min_x &&
                        alien_pos.y > platform_pos.y &&
                        (alien_pos.y + ALIEN_YPOS_OFFSET) < (min_y +13+easyModePad))
                {
                    kindOfJump = @"ExcellentJump";
                }
                else if(alien_pos.x > max_x &&
                        alien_pos.x < min_x &&
                        alien_pos.y > platform_pos.y &&
                        (alien_pos.y + ALIEN_YPOS_OFFSET) < (min_y +18+easyModePad))
                {
                    kindOfJump = @"GoodJump";
                }
            }
        }
    }
}

- (void)accelerometer:(UIAccelerometer*)accelerometer didAccelerate:(UIAcceleration*)acceleration
{
	if(gameSuspended) return;
	float accel_filter = 0.1f;
	alien_vel.x = alien_vel.x * accel_filter + acceleration.y * (1.0f - accel_filter) * 1000.0f;
}

#pragma mark Perform Action

-(void)jump
{
    if (!justHitPlatform)
    {
        [[SimpleAudioEngine sharedEngine] playEffect:@"button-11.mp3"];
    }
    if ([kindOfJump isEqualToString:@"DefaultJump"] && !justHitPlatform)
    {
        alien_vel.y = 225.0f;
        justHitPlatform = YES;
    }
    else if ([kindOfJump isEqualToString:@"GoodJump"])
    {
        alien_vel.y = 300.0f;
        justHitPlatform = NO;
        comboTally = 0;
    }
    else if ([kindOfJump isEqualToString:@"ExcellentJump"])
    {
        alien_vel.y = 400.0f;
        justHitPlatform = NO;
        comboTally = 0;
    }
    else if ([kindOfJump isEqualToString:@"PerfectJump"])
    {
        alien_vel.y = 550.0f;
        justHitPlatform = NO;
        comboTally++;
        if (comboTally % 10 == 0)
        {
            alien_vel.y = 1800.0f;
            dissapearingPlatformTag = 0;
        }
        if(comboTally > maxCombo)
        {
            maxCombo = comboTally;
        }
        [self showComboLabel];
    }
    kindOfJump = @"DefaultJump";
}

- (void)showComboLabel
{
    NSString *stringLabel;
    if(comboTally == 1)
    {
        stringLabel = [NSString stringWithFormat:@"Perfect Jump!"];
    }
    else if(comboTally %10 == 0)
    {
        stringLabel = [NSString stringWithFormat:@"MEGA JUMP!!!"];
        [[SimpleAudioEngine sharedEngine] playEffect:@"star.m4a"];
    }
    else
    {
        stringLabel = [NSString stringWithFormat:@"Perfect Jump x %d", comboTally];
    }
    CCLabelBMFont *comboTallyDisplay = (CCLabelBMFont*)[self getChildByTag:kComboLabel];
    [comboTallyDisplay setString:stringLabel];
    id a1 = [CCFadeIn actionWithDuration:0.25f];
    id a2 = [CCFadeOut actionWithDuration:0.75f];
    id a3 = [CCSequence actions:a1,a2,nil];
    [comboTallyDisplay runAction:a3];
}

-(void)starBoost
{
    alien_vel.y = 1600.0f;
    hitStarBounus = YES;
    [[SimpleAudioEngine sharedEngine] playEffect:@"star.m4a"];
    NSString *scoreStr = [NSString stringWithFormat:@"%d",score];
    CCLabelBMFont *scoreLabel = (CCLabelBMFont*)[self getChildByTag:kScoreLabel];
    [scoreLabel setString:scoreStr];
    id a1 = [CCScaleTo actionWithDuration:0.2f scaleX:1.5f scaleY:0.8f];
    id a2 = [CCScaleTo actionWithDuration:0.2f scaleX:1.0f scaleY:1.0f];
    id a3 = [CCSequence actions:a1,a2,a1,a2,a1,a2,nil];
    [scoreLabel runAction:a3];
    id a4 = [CCScaleTo actionWithDuration:0.4f scaleX:0.7f scaleY:0.9f];
    id a5 = [CCScaleTo actionWithDuration:0.4f scaleX:0.8f scaleY:0.8f];
    id a6 = [CCSequence actions:a4,a5,a4,a5,a4,a5,nil];
    [self.alien runAction:a6];
    dissapearingPlatformTag = 0;
}

#pragma mark Check Collisions

- (void)checkForBonus
{
     CCSpriteBatchNode *batchNode = (CCSpriteBatchNode*)[self getChildByTag:kSpriteManager];
     CCSprite *bonus = (CCSprite*)[batchNode getChildByTag:kBonusStartTag+currentBonusType];
     if(bonus.visible)
     {
         CGPoint bonus_pos = bonus.position;
         float range = 20.0f;
         if(alien_pos.x > bonus_pos.x - range &&
         alien_pos.x < bonus_pos.x + range &&
         alien_pos.y > bonus_pos.y - range &&
         alien_pos.y < bonus_pos.y + range )
         {
             [self starBoost];
         }
     }
}

- (void)checkForObjectCollisions
{
    //load object sprite sheet - this actually be done in the init method
    CGSize alien_size = self.alien.contentSize;
    CCSpriteBatchNode *platformNode = (CCSpriteBatchNode*)[self getChildByTag:kPlatformManager];
    for(int t = kPlatformsStartTag; t < kPlatformsStartTag + NUM_PLATFORMS; t++)
    {
        CCSprite *platform = (CCSprite*)[platformNode getChildByTag:t];
        CGSize platform_size = platform.contentSize;
        CGPoint platform_pos = platform.position;
        float max_x = platform_pos.x - ((platform_size.width/2)*PLATFORM_SCALE);
        float min_x = platform_pos.x + ((platform_size.width/2)*PLATFORM_SCALE);
        float min_y = platform_pos.y + (platform_size.height+alien_size.height)/2 - PLATFORM_TOP_PAD;
        
        if(alien_pos.x > max_x &&
           alien_pos.x < min_x &&
           alien_pos.y > platform_pos.y &&
           (alien_pos.y + ALIEN_YPOS_OFFSET) < min_y)
        {
            [self jump];
            kindOfJump = @"DefaultJump";
            currentPlatformTag = t;
            [self updatePlatformSize];
        }
    }
}

- (void)checkForGameOver
{
    CGSize alien_size = self.alien.contentSize;
    if(alien_pos.y < -alien_size.height/2)
    {
        if (timedMode)
        {
            CCSpriteBatchNode *platformNode = (CCSpriteBatchNode*)[self getChildByTag:kPlatformManager];
            CCSprite *platform = (CCSprite*)[platformNode getChildByTag:currentPlatformTag];
            platform.scaleX = PLATFORM_SCALE;
            platform.scaleY = PLATFORM_SCALE;
            gameSuspended = YES;
            startGameAnimations = 0;
            alien_pos.x = screenWidth/2;
            alien_pos.y = screenHeight/2;
            platform.position = ccp(screenWidth/2,30);
            self.alien.position = alien_pos;
            dissapearingPlatformTag = 0;
            [self schedule:@selector(readySetGoAnimations:) interval:1];
            performingStartAnimations = YES;
        }
        else
        {
                [self showGameOver];
        }
    }
}

#pragma mark Update Object Positions

- (void)updateAlienPosition:(ccTime)dt
{
    //update x position
    alien_pos.x += alien_vel.x * dt;
    //update y position
    alien_vel.y += alien_acc.y * dt;
	alien_pos.y += alien_vel.y * dt;
}

- (void)updateVerticalScreenFramePosition
{
    //update the background position
    //calls moveup
    float delta = alien_pos.y - MAX_HEIGHT;
    alien_pos.y = MAX_HEIGHT;
    currentPlatformY -= delta;
    CCSpriteBatchNode *batchNode = (CCSpriteBatchNode*)[self getChildByTag:kSpriteManager];
    CCSpriteBatchNode *cloudsNode = (CCSpriteBatchNode*)[self getChildByTag:kCloudsManager];
    CCSpriteBatchNode *platformNode = (CCSpriteBatchNode*)[self getChildByTag:kPlatformManager];
    CCSprite *bonus = (CCSprite*)[batchNode getChildByTag:kBonusStartTag];
    
    for(int t = kCloudsStartTag; t < kCloudsStartTag + kNumClouds; t++)
    {
        CCSprite *cloud = (CCSprite*)[cloudsNode getChildByTag:t];
        CGPoint pos = cloud.position;
        pos.y -= delta * cloud.scaleY * 0.8f;
        if(pos.y < -cloud.contentSize.height/2)
        {
            currentCloudTag = t;
            [self resetCloud];
        } else
        {
            cloud.position = pos;
        }
    }
    for(int t = kPlatformsStartTag; t < kPlatformsStartTag + NUM_PLATFORMS; t++)
    {
        CCSprite *platform = (CCSprite*)[platformNode getChildByTag:t];
        CGPoint pos = platform.position;
        pos = ccp(pos.x,pos.y-delta);
        if(pos.y < -platform.contentSize.height/2)
        {
            currentPlatformTag = t;
            CCSpriteFrameCache* cache = [CCSpriteFrameCache sharedSpriteFrameCache];
            [platform setDisplayFrame:[cache spriteFrameByName:@"platform1.png"]];
            [self resetPlatform];
        }
        else
        {
            platform.position = pos;
        }
    }
    
     if(bonus.visible)
     {
        CGPoint pos = bonus.position;
        pos.y -= delta;
        if(pos.y < -bonus.contentSize.height/2 && !hitStarBounus)
        {
            [self resetBonus];
        } else
        {
            bonus.position = pos;
        }
     }
}

- (void)updateHorizontalScreenFramePosition
{
    //update the background position
    //calls moveleft, moveright
    float delta;
    if(alien_pos.x > maxHorizontalMovement)
    {
        delta = alien_pos.x - maxHorizontalMovement;
        alien_pos.x = maxHorizontalMovement;
    }
    else if(alien_pos.x < minHorizontalMovement)
    {
        delta = alien_pos.x - minHorizontalMovement;
        alien_pos.x = minHorizontalMovement;
    }

    CCSpriteBatchNode *batchNode = (CCSpriteBatchNode*)[self getChildByTag:kSpriteManager];
    CCSpriteBatchNode *cloudsNode = (CCSpriteBatchNode*)[self getChildByTag:kCloudsManager];
    CCSpriteBatchNode *platformNode = (CCSpriteBatchNode*)[self getChildByTag:kPlatformManager];
    CCSprite *bonus = (CCSprite*)[batchNode getChildByTag:kBonusStartTag];
     
    for(int t = kCloudsStartTag; t < kCloudsStartTag + kNumClouds; t++)
    {
        CCSprite *cloud = (CCSprite*)[cloudsNode getChildByTag:t];
        CGPoint pos = cloud.position;
        pos.x -= delta * cloud.scaleY * 0.8f;
        if(pos.x > 480+cloud.contentSize.width/2)
        {
            currentCloudTag = t;
            [self resetCloud];
         }
         else
         {
            cloud.position = pos;
         }
     }
    for(int t = kPlatformsStartTag; t < kPlatformsStartTag + NUM_PLATFORMS; t++)
    {
        CCSprite *platform = (CCSprite*)[platformNode getChildByTag:t];
        CGPoint pos = platform.position;
        pos = ccp(pos.x-delta,pos.y);
        if(pos.x < -150)
        {
            currentPlatformTag = t;
            [self updatePlatformPosition:@"left"];
        }
        else if(pos.x > 630)
        {
            currentPlatformTag = t;
            [self updatePlatformPosition:@"right"];
        }
        else
        {
            platform.position = pos;
        }
    }
    
    if(bonus.visible)
    {
        CGPoint pos = bonus.position;
        pos.x -= delta;
        if(pos.x < -150 || pos.x > 630)
        {
            [self resetBonus];
        }
        else
        {
            bonus.position = pos;
        }
    }
}

- (void)updatePlatformPosition:(NSString *)exitSide
{
    CCSpriteBatchNode *platformNode = (CCSpriteBatchNode*)[self getChildByTag:kPlatformManager];
    CCSprite *platform = (CCSprite*)[platformNode getChildByTag:currentPlatformTag];
    if ([exitSide isEqualToString:@"left"])
    {
        platform.position = ccp(620, platform.position.y);
    }
    else
    {
        platform.position = ccp(-140, platform.position.y);
    }
}

-(void)updatePlatformSize
{
    if ((currentPlatformTag == kPlatformsStartTag && !hasHitStartPlatform) || easyMode == YES)
    {
        return;
    }
    CCSpriteFrameCache* cache = [CCSpriteFrameCache sharedSpriteFrameCache];
    CCSpriteBatchNode *platformNode = (CCSpriteBatchNode*)[self getChildByTag:kPlatformManager];
	CCSprite *platform = (CCSprite*)[platformNode getChildByTag:currentPlatformTag];
    if (dissapearingPlatformTag == currentPlatformTag)
    {
        [platform setDisplayFrame:[cache spriteFrameByName:@"platform1.png"]];
        [self resetPlatform];
    }
    else
    {
        [platform setDisplayFrame:[cache spriteFrameByName:@"platform2.png"]];
        platform.scaleX = PLATFORM_SCALE;
        platform.scaleY = PLATFORM_SCALE;
        dissapearingPlatformTag = currentPlatformTag;
        if (currentPlatformTag != kPlatformsStartTag)
        {
            hasHitStartPlatform = YES;
        }
    }
}

#pragma mark Update Labels

- (void)updateScore
{
    float delta = (alien_pos.y - MAX_HEIGHT);
    score += delta;
    NSString *scoreStr = [NSString stringWithFormat:@"%d",score/10];
    CCLabelBMFont *scoreLabel = (CCLabelBMFont*)[self getChildByTag:kScoreLabel];
    [scoreLabel setString:scoreStr];
    if (score/10 >= 1000 && timedMode == YES)
    {
        [self unschedule:@selector(timerUpdate)];
        gameSuspended = YES;
        CCLabelBMFont *comboTallyDisplay = (CCLabelBMFont*)[self getChildByTag:kComboLabel];
        id a1 = [CCFadeIn actionWithDuration:2.0f];
        id a2 = [CCScaleTo actionWithDuration:1.5f scaleX:2.0f scaleY:1.5f];
        id a3 = [CCSequence actions:a1,a2,nil];
        [comboTallyDisplay setString:@"FINISHED!!!"];
        [comboTallyDisplay runAction:a3];
        [self showGameOver];
    }
}

-(void)updateAlienFinalPosition
{
    //Toggle the jump
    CCSpriteFrameCache* cache = [CCSpriteFrameCache sharedSpriteFrameCache];
    if (alien_vel.y < 20)
    {
        if (hitStarBounus == YES)
        {
            [self resetBonus];
        }
        hitStarBounus = NO;
        [self.alien setDisplayFrame:[cache spriteFrameByName:@"alien1.png"]];
    }
    else if (hitStarBounus && alien_vel.y > 150)
    {
        [self.alien setDisplayFrame:[cache spriteFrameByName:@"alien3.png"]];
    }
    else
    {
        [self.alien setDisplayFrame:[cache spriteFrameByName:@"alien2.png"]];
    }
    self.alien.rotation = alien_vel.x/40;
    self.alien.position = alien_pos;
}

#pragma mark Pause Menu

- (void)pauseGame
{
    if(gamePaused == NO)
    {
        gameSuspended = YES;
        gamePaused = YES;
        pauseButton.visible = NO;
        pauseScreen =[[CCSprite spriteWithFile:@"paused.png"] retain];
        CGSize screenSize = [[UIScreen mainScreen] bounds].size;
        [pauseScreen setContentSize:screenSize];
        pauseScreen.position= ccp(screenWidth*.5,screenWidth*.60);
        [self addChild:pauseScreen z:8];
        [self loadPauseMenu];
    }
}

-(void)loadPauseMenu
{
    pauseScreenMenu.visible = NO;
    CCMenuItem *playAgainButton = [CCMenuItemImage itemFromNormalImage:@"playAgainButton.png"
                                                         selectedImage:@"playAgainButton.png"
                                                                target:self
                                                              selector:@selector(playAgainAction:)];
    CCMenuItem *resumePlayButton = [CCMenuItemImage itemFromNormalImage:@"resumePlay.png"
                                                          selectedImage:@"resumePlay.png"
                                                                 target:self
                                                               selector:@selector(resumeGameAction:)];
    
    CCMenuItem *homeButton = [CCMenuItemImage itemFromNormalImage:@"buttonhome.png"
                                                    selectedImage:@"buttonhome.png"
                                                           target:self
                                                         selector:@selector(goHomeAction:)];
    CCMenuItem *muteButton;
    BOOL muted = [CDAudioManager sharedManager].mute;
    if(muted)
    {
        muteButton = [CCMenuItemImage itemFromNormalImage:@"buttonsound.png"
                                            selectedImage:@"buttonsound.png"
                                                   target:self
                                                 selector:@selector(toggleMute:)];
    } else
    {
        muteButton = [CCMenuItemImage itemFromNormalImage:@"buttonnosound.png"
                                            selectedImage:@"buttonnosound.png"
                                                   target:self
                                                 selector:@selector(toggleMute:)];
    }
	pauseScreenMenu = [CCMenu menuWithItems: resumePlayButton, playAgainButton, homeButton, muteButton, nil];
	[pauseScreenMenu alignItemsHorizontallyWithPadding:9];
	pauseScreenMenu.position = ccp(screenWidth*.5,screenWidth*.23);
	[self addChild:pauseScreenMenu z:10];
}

#pragma mark menu actions

- (void)playAgainAction:(id)sender
{
	CCTransitionScene *ts = [CCTransitionFade transitionWithDuration:0.5f scene:[Game sceneWithMode:gameMode] withColor:ccWHITE];
	[[CCDirector sharedDirector] replaceScene:ts];
}

- (void)resumeGameAction:(id)sender
{
	pauseScreen.visible = NO;
    pauseScreenMenu.visible = NO;
    pauseButton.visible = YES;
    gamePaused = NO;
    if (!performingStartAnimations)
    {
        gameSuspended = NO;
    }
}

- (void)goHomeAction:(id)sender
{
    [CDAudioManager sharedManager].mute = TRUE;
    [[UIApplication sharedApplication].keyWindow.rootViewController dismissModalViewControllerAnimated:YES];
    [[CCDirector sharedDirector] popScene];
    
}


- (void)toggleMute:(id)sender
{
    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
	BOOL isMuted = [standardUserDefaults boolForKey:@"isMuted"];
    [CDAudioManager sharedManager].mute = !isMuted;
    [[SimpleAudioEngine sharedEngine] playBackgroundMusic:@"GameOn.mp3"];
    [standardUserDefaults setBool:!isMuted forKey:@"isMuted"];
    [standardUserDefaults synchronize];
    [self loadPauseMenu];
}

-(BOOL)isMuted
{
    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
	if (standardUserDefaults)
    {
		return [standardUserDefaults boolForKey:@"isMuted"];
	} else
    {
        return NO;
    }
}

#pragma mark Game Over

- (void)showGameOver
{
	gameSuspended = YES;
    if (timedMode)
    {
        [[CCDirector sharedDirector] replaceScene:[CCTransitionFade transitionWithDuration:1
                                            scene:[GameOver gameOverSceneWithScore:0
                                                                          andCombo:maxCombo
                                                                    andCurrentMode:gameMode
                                                                        andMinutes:numOfMinutes
                                                                        andSeconds:numOfSeconds]
                                                                         withColor:ccWHITE]];
    }
    else
    {
        [[CCDirector sharedDirector] replaceScene:[CCTransitionFade transitionWithDuration:1
                                            scene:[GameOver gameOverSceneWithScore:score/10
                                                                          andCombo:maxCombo
                                                                    andCurrentMode:gameMode
                                                                        andMinutes:0
                                                                        andSeconds:0.0]
                                                                         withColor:ccWHITE]];
    }
}

@end
