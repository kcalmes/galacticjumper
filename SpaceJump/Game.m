#import "Game.h"
#import "CCMain.h"
#import "GameOver.h"
#import "GANTracker.h"

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
- (void)oldJump;
- (void)showGameOver;

#define ALIEN_YPOS_OFFSET 0
#define PLATFORM_SCALE 0.65

@end

@implementation Game

//Added by Kory for animation
@synthesize alien = _alien;

#pragma mark InitializeGame

+ (CCScene *)scene
{
    CCScene *game = [CCScene node];
    
    Game *layer = [Game node];
    [game addChild:layer];
    
    return game;
}

- (id)init {
    //NSLog(@"Game::init");
    //count a game played in google analytics
	NSError * error;
    if (![[GANTracker sharedTracker] trackPageview:@"/playgame"
                                         withError:&error])
    {
        NSLog(@"there was an error");
    } else {
        NSLog(@"there was not an error");
    }
	if(![super init]) return nil;
    
    CGSize screenSize = [[UIScreen mainScreen] bounds].size;
    screenHeight = screenSize.width; //In landscape height is width vice versa
    screenWidth = screenSize.height;
	
	gameSuspended = YES;

	CCSpriteBatchNode *batchNode = (CCSpriteBatchNode *)[self getChildByTag:kSpriteManager];

	[self initPlatforms];
	
	CCSprite *bonus = [CCSprite spriteWithTexture:[batchNode texture] rect:CGRectMake(652,457,67,52)];
    [batchNode addChild:bonus z:4 tag:kBonusStartTag];
    bonus.scaleX = .5f;
    bonus.scaleY = .5f;

    bonus.visible = NO;
    
    //This position for the score label makes it so that 1000000 is the highest possible score before the label goes off screen
    CCLabelBMFont *scoreLabel = [CCLabelBMFont labelWithString:@"0" fntFile:@"spaceJump-hd.fnt"];
	[self addChild:scoreLabel z:5 tag:kScoreLabel];
	scoreLabel.position = ccp(80,300);

	[self schedule:@selector(step:)];
	
	self.isTouchEnabled = YES;
	self.isAccelerometerEnabled = YES;

	[[UIAccelerometer sharedAccelerometer] setUpdateInterval:(1.0 / kFPS)];
	
	[self startGame];
	
	return self;
}

#pragma mark InitializeObjects

- (void)initPlatforms
{
    //	NSLog(@"initPlatforms");
    CCSpriteBatchNode *spriteSheet = [CCSpriteBatchNode batchNodeWithFile:@"objectplatforms.png"];
    [self addChild:spriteSheet z:4];
    
    //Cache the sprite frames and texture
    CCSpriteFrame *frame;
    frame = [CCSpriteFrame frameWithTexture:spriteSheet.texture rect:CGRectMake(0,0,148,46)];
    [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFrame:frame name:[NSString stringWithFormat:@"platform%d.png", 1]];
    frame = [CCSpriteFrame frameWithTexture:spriteSheet.texture rect:CGRectMake(180,0,69,46)];
    [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFrame:frame name:[NSString stringWithFormat:@"platform%d.png", 2]];
	
	currentPlatformTag = kPlatformsStartTag;
	while(currentPlatformTag < kPlatformsStartTag + kNumPlatforms)
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

- (void)startGame {
    //	NSLog(@"startGame");
    
	score = 0;
	
	//[self resetClouds];
	[self resetPlatforms];
    [self resetAlien];
	[self resetBonus];
	
	[[UIApplication sharedApplication] setIdleTimerDisabled:YES];
	gameSuspended = NO;
}

- (void)dealloc
{
//	NSLog(@"Game::dealloc");
    self.alien = nil;
    //self.jumpAction = nil;
    [super dealloc];
}

#pragma mark ResetObjects

- (void)resetPlatforms
{
//	NSLog(@"resetPlatforms");
	
	currentPlatformY = -1;
	currentPlatformTag = kPlatformsStartTag;
	currentMaxPlatformStep = 100.0f;
	currentBonusPlatformIndex = 0;
	currentBonusType = 0;
	platformCount = 0;

	while(currentPlatformTag < kPlatformsStartTag + kNumPlatforms)
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
	} else
    {
		currentPlatformY += random() % (int)(currentMaxPlatformStep - kMinPlatformStep) + kMinPlatformStep;
        NSLog(@"max step = %f, currentY = %f",currentMaxPlatformStep, currentPlatformY);
		if(currentMaxPlatformStep < kMaxPlatformStep)
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
		x = 220.0f;
	} else
    {
        x = (arc4random() % 680) - 100;
	}
	
	platform.position = ccp(x,currentPlatformY);
	platformCount++;
    //	NSLog(@"platformCount = %d",platformCount);
    CCSpriteBatchNode *batchNode = (CCSpriteBatchNode*)[self getChildByTag:kSpriteManager];
	
	if(platformCount == currentBonusPlatformIndex)
    {
        //		NSLog(@"platformCount == currentBonusPlatformIndex");
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

    //Gather the list of frames
    NSMutableArray *jumpAnimFrames = [NSMutableArray array];
    for(int i = 1; i <= 2; ++i) {
        [jumpAnimFrames addObject:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:[NSString stringWithFormat:@"alien%d.png", i]]];
    }
    
    
    //Create the sprite and run the animation action
    CGSize winSize = [CCDirector sharedDirector].winSize;
    self.alien = [CCSprite spriteWithSpriteFrameName:@"alien2.png"];
    self.alien.position = ccp(winSize.width/2, winSize.height/2);
    self.alien.scale = 0.6f;
    
    alien_pos.x = 220;
	alien_pos.y = 160;
	self.alien.position = alien_pos;

	alien_vel.x = 0;
	alien_vel.y = 0;
	
	alien_acc.x = 0;
	alien_acc.y = -450.0f;
    
    self.alien = [CCSprite spriteWithSpriteFrameName:@"alien1.png"];
    //self.alien.scale = 0.25f;
    self.alien.scale = 0.8f;

    [spriteSheet addChild: self.alien];
    
    justHitPlatform = NO;
    hitStarBouns = NO;
    kindOfJump = @"DefaultJump";
    
}

- (void)resetBonus {
//	NSLog(@"resetBonus");
	
	CCSpriteBatchNode *batchNode = (CCSpriteBatchNode*)[self getChildByTag:kSpriteManager];
	CCSprite *bonus = (CCSprite*)[batchNode getChildByTag:kBonusStartTag];
	bonus.visible = NO;
	currentBonusPlatformIndex += random() % (kMaxBonusStep - kMinBonusStep) + kMinBonusStep;
}

#pragma mark StepFunction

- (void)step:(ccTime)dt {
	//NSLog(@"Game::step");

	[super step:dt];
	
	if(gameSuspended) return;
    
	[self updateAlienPosition:dt];
    [self checkForBonus];
    
	if(alien_vel.y < 0)
    {
        if (justHitPlatform && [kindOfJump isEqualToString:@"DefaultJump"]) {
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
    if(alien_pos.y > 180)
    {
        [self updateScore];
        [self updateVerticalScreenFramePosition];
	}
    if(alien_pos.x > 260 || alien_pos.x < 220)
    {
        [self updateHorizontalScreenFramePosition];
    }
    [self updateAlienFinalPosition];
}

#pragma mark TouchEvents

- (void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    //NSLog(@"Screen Touched");
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInView: [touch view]];
    
    CGRect mySurface = (CGRectMake(0, 0, 480, 320));
    if(CGRectContainsPoint(mySurface, location))
    {
        if(alien_vel.y < 0 || justHitPlatform)
        {
            
            CGSize alien_size = self.alien.contentSize;
            float max_x = 320-alien_size.width/2;
            float min_x = 0+alien_size.width/2;
            
            CCSpriteBatchNode *platformNode = (CCSpriteBatchNode*)[self getChildByTag:kPlatformManager];
            for(int t = kPlatformsStartTag; t < kPlatformsStartTag + kNumPlatforms; t++)
            {
                CCSprite *platform = (CCSprite*)[platformNode getChildByTag:t];
                
                CGSize platform_size = platform.contentSize;
                CGPoint platform_pos = platform.position;
                
                max_x = platform_pos.x - platform_size.width/2 - 10;
                min_x = platform_pos.x + platform_size.width/2 + 10;
                float min_y = platform_pos.y + (platform_size.height+alien_size.height)/2 - kPlatformTopPadding;
                
                if(alien_pos.x > max_x &&
                   alien_pos.x < min_x &&
                   alien_pos.y > platform_pos.y &&
                   (alien_pos.y + ALIEN_YPOS_OFFSET) < min_y + 8)
                {
                    kindOfJump = @"PerfectJump";
                }
                else if(alien_pos.x > max_x &&
                        alien_pos.x < min_x &&
                        alien_pos.y > platform_pos.y &&
                        (alien_pos.y + ALIEN_YPOS_OFFSET) < min_y +13)
                {
                    kindOfJump = @"ExcellentJump";
                }
                else if(alien_pos.x > max_x &&
                        alien_pos.x < min_x &&
                        alien_pos.y > platform_pos.y &&
                        (alien_pos.y + ALIEN_YPOS_OFFSET) < min_y +18)
                {
                    kindOfJump = @"GoodJump";
                }
                /*
                    [[SimpleAudioEngine sharedEngine] playEffect:@"pew-pew-lei.caf"];
                */
            }
            //NSLog(@"Kind of Jump: %@", kindOfJump);
        }
    }
}

-(void)jump
{
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
        [self showComboLabel];
    }
    kindOfJump = @"DefaultJump";
}

- (void)showComboLabel
{
    NSString *stringLabel;
    if(comboTally == 1){
        stringLabel = [NSString stringWithFormat:@"Perfect Jump!", comboTally];
    } else if(comboTally < 5){
        stringLabel = [NSString stringWithFormat:@"Perfect Jump x %d!", comboTally];
    } else if(comboTally < 10){
        stringLabel = [NSString stringWithFormat:@"Perfect Jump x %d!!", comboTally];
    } else {
        stringLabel = [NSString stringWithFormat:@"Perfect Jump x %d!!!", comboTally];
    }
    CCLabelBMFont *comboTallyDisplay = [CCLabelBMFont labelWithString:stringLabel fntFile:@"spaceJump-hd.fnt"];
    [self addChild:comboTallyDisplay];
    comboTallyDisplay.opacity = 0;
    comboTallyDisplay.position = ccpMidpoint(ccp(0,0), ccp(screenWidth,screenHeight/2));
    id a1 = [CCFadeIn actionWithDuration:0.25f];
    id a2 = [CCFadeOut actionWithDuration:0.75f];
    id a3 = [CCSequence actions:a1,a2,nil];
    [comboTallyDisplay runAction:a3];
}

#pragma mark CheckCollisions

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
             alien_vel.y = 1600.0f;
             hitStarBouns = YES;
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
             [self resetBonus];
         }
     }
}

- (void)checkForObjectCollisions
{
    //load object sprite sheet - this actually be done in the init method
    CGSize alien_size = self.alien.contentSize;
    CCSpriteBatchNode *platformNode = (CCSpriteBatchNode*)[self getChildByTag:kPlatformManager];
    justHitPlatform = NO;
    for(int t = kPlatformsStartTag; t < kPlatformsStartTag + kNumPlatforms; t++)
    {
        CCSprite *platform = (CCSprite*)[platformNode getChildByTag:t];
        
        CGSize platform_size = platform.contentSize;
        CGPoint platform_pos = platform.position;
        
        float max_x = platform_pos.x - ((platform_size.width/2)*PLATFORM_SCALE);
        float min_x = platform_pos.x + ((platform_size.width/2)*PLATFORM_SCALE);
        float min_y = platform_pos.y + (platform_size.height+alien_size.height)/2 - kPlatformTopPadding;
        
        
        if(alien_pos.x > max_x &&
           alien_pos.x < min_x &&
           alien_pos.y > platform_pos.y &&
           (alien_pos.y + ALIEN_YPOS_OFFSET) < min_y) {
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
        [self showGameOver];
    }
}

#pragma mark UpdateObjectPositions

- (void)updateAlienPosition:(ccTime)dt
{
    //update x position
    alien_pos.x += alien_vel.x * dt;
    CGSize alien_size = self.alien.contentSize;
    
    float max_x = 480-alien_size.width/2;
    float min_x = 0+alien_size.width/2;
    
    if(alien_pos.x>max_x) alien_pos.x = max_x;
    if(alien_pos.x<min_x) alien_pos.x = min_x;
    
    //update y position
    alien_vel.y += alien_acc.y * dt;
	alien_pos.y += alien_vel.y * dt;
}

- (void)updateVerticalScreenFramePosition
{
    //update the background position
    //calls moveup
    float delta = alien_pos.y - 180;
    alien_pos.y = 180;
    
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
        if(pos.y < -cloud.contentSize.height/2) {
            currentCloudTag = t;
            [self resetCloud];
        } else {
            cloud.position = pos;
        }
    }
    for(int t = kPlatformsStartTag; t < kPlatformsStartTag + kNumPlatforms; t++) {
        CCSprite *platform = (CCSprite*)[platformNode getChildByTag:t];
        CGPoint pos = platform.position;
        pos = ccp(pos.x,pos.y-delta);
        if(pos.y < -platform.contentSize.height/2)
        {
            currentPlatformTag = t;
            CCSpriteFrameCache* cache = [CCSpriteFrameCache sharedSpriteFrameCache];
            [platform setDisplayFrame:[cache spriteFrameByName:@"platform1.png"]];
            [self resetPlatform];
        } else
        {
            platform.position = pos;
        }
    }
    
     if(bonus.visible) {
        CGPoint pos = bonus.position;
        pos.y -= delta;
        if(pos.y < -bonus.contentSize.height/2) {
            [self resetBonus];
        } else {
            bonus.position = pos;
        }
     }
}

- (void)updateHorizontalScreenFramePosition
{
    //update the background position
    //calls moveleft, moveright
    float delta;
    if(alien_pos.x > 260)
    {
        delta = alien_pos.x - 260;
        alien_pos.x = 260;
    }
    else if(alien_pos.x < 220)
    {
        delta = alien_pos.x - 220;
        alien_pos.x = 220;
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
         if(pos.x > 480+cloud.contentSize.width/2) {
             currentCloudTag = t;
             [self resetCloud];
         } else {
            cloud.position = pos;
         }
     }
    for(int t = kPlatformsStartTag; t < kPlatformsStartTag + kNumPlatforms; t++)
    {
        CCSprite *platform = (CCSprite*)[platformNode getChildByTag:t];
        CGPoint pos = platform.position;
        pos = ccp(pos.x-delta,pos.y);
        if(pos.x < -200)
        {
            currentPlatformTag = t;
            [self updatePlatformPosition:@"left"];
        }
        else if(pos.x > 680)
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
        if(pos.x < -200 || pos.x > 680)
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
        platform.position = ccp(570, platform.position.y);
    }
    else
    {
        platform.position = ccp(-90, platform.position.y);
    }
}

-(void)updatePlatformSize
{
    if (currentPlatformTag == kPlatformsStartTag && !hasHitStartPlatform)
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

#pragma mark UpdateLabels

- (void)updateScore
{
    float delta = (alien_pos.y - 180);
    score += delta;
    NSString *scoreStr = [NSString stringWithFormat:@"%d",score/10];
    
    CCLabelBMFont *scoreLabel = (CCLabelBMFont*)[self getChildByTag:kScoreLabel];
    [scoreLabel setString:scoreStr];
}

-(void)updateAlienFinalPosition
{
    //Toggle the jump
    CCSpriteFrameCache* cache = [CCSpriteFrameCache sharedSpriteFrameCache];
    if (alien_vel.y < 20)
    {
        hitStarBouns = NO;
        [self.alien setDisplayFrame:[cache spriteFrameByName:@"alien1.png"]];
    } else if (hitStarBouns && alien_vel.y > 150)
    {
        [self.alien setDisplayFrame:[cache spriteFrameByName:@"alien3.png"]];
    } else
    {
        [self.alien setDisplayFrame:[cache spriteFrameByName:@"alien2.png"]];
    }
    self.alien.rotation = alien_vel.x/40;
    self.alien.position = alien_pos;
}

- (void)showGameOver
{
    NSLog(@"showGameOver");
	gameSuspended = YES;
	[[UIApplication sharedApplication] setIdleTimerDisabled:NO];
	
//	NSLog(@"score = %d",score);
	[[CCDirector sharedDirector] replaceScene:
     [CCTransitionFade transitionWithDuration:1 scene:[GameOver gameOverSceneWithScore:score/10] withColor:ccWHITE]];
}

- (void)accelerometer:(UIAccelerometer*)accelerometer didAccelerate:(UIAcceleration*)acceleration {
	if(gameSuspended) return;
	float accel_filter = 0.1f;
    int orientation = 1;
    if ([[UIDevice currentDevice] orientation] == UIInterfaceOrientationLandscapeRight)
    {
        orientation = 1;
    }
    else if ([[UIDevice currentDevice] orientation] == UIInterfaceOrientationLandscapeLeft)
    {
        orientation = -1;
    }
	alien_vel.x = alien_vel.x * accel_filter + acceleration.y * -1 * (1.0f - accel_filter) * (orientation*1000.0f);
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
//	NSLog(@"alertView:clickedButtonAtIndex: %i",buttonIndex);

	if(buttonIndex == 0) {
		[self startGame];
	} else {
		[self startGame];
	}
}

@end
