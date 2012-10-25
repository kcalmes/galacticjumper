#import "Game.h"
#import "CCMain.h"
#import "GameOver.h"

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
- (void)oldJump;
- (void)showHighscores;

#define ALIEN_YPOS_OFFSET 0
#define PLATFORM_SCALE .65

@end

@implementation Game

//Added by Kory for animation
@synthesize alien = _alien;
//@synthesize jumpAction = _jumpAction;

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
	
	if(![super init]) return nil;
	
	gameSuspended = YES;

	CCSpriteBatchNode *batchNode = (CCSpriteBatchNode *)[self getChildByTag:kSpriteManager];

	[self initPlatforms];
	
	CCSprite *bonus;

	for(int i=0; i<kNumBonuses; i++)
    {
		bonus = [CCSprite spriteWithTexture:[batchNode texture] rect:CGRectMake(608+i*32,256,25,25)];
		[batchNode addChild:bonus z:4 tag:kBonusStartTag+i];
		bonus.visible = NO;
	}

//	LabelAtlas *scoreLabel = [LabelAtlas labelAtlasWithString:@"0" charMapFile:@"charmap.png" itemWidth:24 itemHeight:32 startCharMap:' '];
//	[self addChild:scoreLabel z:5 tag:kScoreLabel];
	
	CCLabelBMFont *scoreLabel = [CCLabelBMFont labelWithString:@"0" fntFile:@"bitmapFont.fnt"];
	[self addChild:scoreLabel z:5 tag:kScoreLabel];
	scoreLabel.position = ccp(350,300);
    
    CCLabelBMFont *comboLabel = [CCLabelBMFont labelWithString:@"0" fntFile:@"bitmapFont.fnt"];
	[self addChild:comboLabel z:6 tag:kComboLabel];
	comboLabel.position = ccp(10,300);

	[self schedule:@selector(step:)];
	
	self.isTouchEnabled = YES;
	self.isAccelerometerEnabled = YES;

	[[UIAccelerometer sharedAccelerometer] setUpdateInterval:(1.0 / kFPS)];
	
	[self startGame];
	
	return self;
}

#pragma mark InitializeObjects

- (void)initPlatforms {
    //	NSLog(@"initPlatforms");
	
	currentPlatformTag = kPlatformsStartTag;
	while(currentPlatformTag < kPlatformsStartTag + kNumPlatforms) {
		[self initPlatform];
		currentPlatformTag++;
	}
	
	[self resetPlatforms];
}

- (void)initPlatform {
    
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
	
	if(platformCount == currentBonusPlatformIndex) {
        //		NSLog(@"platformCount == currentBonusPlatformIndex");
		CCSprite *bonus = (CCSprite*)[batchNode getChildByTag:kBonusStartTag+currentBonusType];
		bonus.position = ccp(x,currentPlatformY+30);
		bonus.visible = YES;
	}
}

- (void)resetAlien
{
    //Create a sprite batch node
    CCSpriteBatchNode *spriteSheet = [CCSpriteBatchNode batchNodeWithFile:@"jump.png"];
    [self addChild:spriteSheet z:4];

    //Cache the sprite frames and texture
    CCSpriteFrame *frame;    
    frame = [CCSpriteFrame frameWithTexture:spriteSheet.texture rect:CGRectMake(0,2,46,65)];
    [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFrame:frame name:[NSString stringWithFormat:@"alien%d.png", 1]];
    frame = [CCSpriteFrame frameWithTexture:spriteSheet.texture rect:CGRectMake(55,0,46,67)];
    [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFrame:frame name:[NSString stringWithFormat:@"alien%d.png", 2]];

    //Gather the list of frames
    NSMutableArray *jumpAnimFrames = [NSMutableArray array];
    for(int i = 1; i <= 2; ++i) {
        [jumpAnimFrames addObject:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:[NSString stringWithFormat:@"alien%d.png", i]]];
    }
    
    
    //Create the sprite and run the animation action
    CGSize winSize = [CCDirector sharedDirector].winSize;
    self.alien = [CCSprite spriteWithSpriteFrameName:@"alien2.png"];
    self.alien.position = ccp(winSize.width/2, winSize.height/2);
    //self.alien.scale = 0.25f;
    self.alien.scale = 1.0f;
    
    alien_pos.x = 220;
	alien_pos.y = 160;
	self.alien.position = alien_pos;

	
	alien_vel.x = 0;
	alien_vel.y = 0;
	
	alien_acc.x = 0;
	alien_acc.y = -450.0f;
    
    //self.alien.rotation = 90;
    //self.jumpAction = [CCRepeatForever actionWithAction: [CCAnimate actionWithAnimation:jumpAnim restoreOriginalFrame:YES]];
    //self.jumpAction = [CCRepeat actionWithAction:[CCAnimate actionWithAnimation:jumpAnim restoreOriginalFrame:NO] times:1];
    //self.jumpAction = [CCAnimate actionWithAnimation:jumpAnim restoreOriginalFrame:YES];
    
    self.alien = [CCSprite spriteWithSpriteFrameName:@"alien1.png"];
    //self.alien.scale = 0.25f;
    self.alien.scale = 1.0f;

    [spriteSheet addChild: self.alien];
    
    


    //[self.alien runAction: self.jumpAction];
    justHitPlatform = NO;
    kindOfJump = @"DefaultJump";
    
}

- (void)resetBonus {
//	NSLog(@"resetBonus");
	
	CCSpriteBatchNode *batchNode = (CCSpriteBatchNode*)[self getChildByTag:kSpriteManager];
	CCSprite *bonus = (CCSprite*)[batchNode getChildByTag:kBonusStartTag+currentBonusType];
	bonus.visible = NO;
	currentBonusPlatformIndex += random() % (kMaxBonusStep - kMinBonusStep) + kMinBonusStep;
	if(score < 10000) {
		currentBonusType = 0;
	} else if(score < 50000) {
		currentBonusType = random() % 2;
	} else if(score < 100000) {
		currentBonusType = random() % 3;
	} else {
		currentBonusType = random() % 2 + 2;
	}
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
            [self updateComboTally];
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
                /*else if(bird_pos.x > max_x &&
                        bird_pos.x < min_x &&
                        bird_pos.y > platform_pos.y &&
                        bird_pos.y < min_y +20 )
                {
                    kindOfJump = @"okJump";
                    [[SimpleAudioEngine sharedEngine] playEffect:@"pew-pew-lei.caf"];
                }*/
            
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
    }
    [self updateComboTally];
    kindOfJump = @"DefaultJump";
}

#pragma mark CheckCollisions

- (void)checkForBonus
{
     CCSpriteBatchNode *batchNode = (CCSpriteBatchNode*)[self getChildByTag:kSpriteManager];
     CCSprite *bonus = (CCSprite*)[batchNode getChildByTag:kBonusStartTag+currentBonusType];
     if(bonus.visible) {
         CGPoint bonus_pos = bonus.position;
         float range = 20.0f;
         if(alien_pos.x > bonus_pos.x - range &&
         alien_pos.x < bonus_pos.x + range &&
         alien_pos.y > bonus_pos.y - range &&
         alien_pos.y < bonus_pos.y + range ) {
             switch(currentBonusType) {
                 case kBonus5:   score += 5000;   break;
                 case kBonus10:  score += 10000;  break;
                 case kBonus50:  score += 50000;  break;
                 case kBonus100: score += 100000; break;
             }
             NSString *scoreStr = [NSString stringWithFormat:@"%d",score];
             CCLabelBMFont *scoreLabel = (CCLabelBMFont*)[self getChildByTag:kScoreLabel];
             [scoreLabel setString:scoreStr];
             id a1 = [CCScaleTo actionWithDuration:0.2f scaleX:1.5f scaleY:0.8f];
             id a2 = [CCScaleTo actionWithDuration:0.2f scaleX:1.0f scaleY:1.0f];
             id a3 = [CCSequence actions:a1,a2,a1,a2,a1,a2,nil];
             [scoreLabel runAction:a3];
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
            //[self updatePlatformSize];
        }
    }
}

- (void)checkForGameOver
{
    CGSize alien_size = self.alien.contentSize;
    if(alien_pos.y < -alien_size.height/2)
    {
        [self showHighscores];
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
    //calls moveup, moveleft, moveright
    float delta = alien_pos.y - 180;
    alien_pos.y = 180;
    
    currentPlatformY -= delta;
    CCSpriteBatchNode *batchNode = (CCSpriteBatchNode*)[self getChildByTag:kSpriteManager];
    CCSpriteBatchNode *cloudsNode = (CCSpriteBatchNode*)[self getChildByTag:kCloudsManager];
    CCSpriteBatchNode *platformNode = (CCSpriteBatchNode*)[self getChildByTag:kPlatformManager];
    CCSprite *bonus = (CCSprite*)[batchNode getChildByTag:kBonusStartTag+currentBonusType];
    
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
        if(pos.y < -platform.contentSize.height/2) {
            currentPlatformTag = t;
            [self resetPlatform];
        } else {
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
    //calls moveup, moveleft, moveright
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
    CCSprite *bonus = (CCSprite*)[batchNode getChildByTag:kBonusStartTag+currentBonusType];
     
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
    CGRect rect = CGRectMake(180,0,69,46);
    CCSpriteBatchNode *platformNode = (CCSpriteBatchNode*)[self getChildByTag:kPlatformManager];
	CCSprite *platform = (CCSprite*)[platformNode getChildByTag:currentPlatformTag];
    platform = [CCSprite spriteWithTexture:[platformNode texture] rect:rect];
	platform.scaleX = PLATFORM_SCALE;
    platform.scaleY = PLATFORM_SCALE;
}

#pragma mark UpdateLabels

- (void)updateScore
{
    float delta = alien_pos.y - 180;
    score += (int)delta;
    NSString *scoreStr = [NSString stringWithFormat:@"%d",score];
    
    CCLabelBMFont *scoreLabel = (CCLabelBMFont*)[self getChildByTag:kScoreLabel];
    [scoreLabel setString:scoreStr];
}

- (void)updateComboTally
{
    NSString* comboStr = [NSString stringWithFormat:@"%d",comboTally];
    CCLabelBMFont* comboLabel = (CCLabelBMFont*)[self getChildByTag:kComboLabel];
    [comboLabel setString:comboStr];
}

-(void)updateAlienFinalPosition
{
    //Toggle the jump
    CCSpriteFrameCache* cache = [CCSpriteFrameCache sharedSpriteFrameCache];
    if (alien_vel.y < 0)
    {
        [self.alien setDisplayFrame:[cache spriteFrameByName:@"alien1.png"]];
    } else
    {
        [self.alien setDisplayFrame:[cache spriteFrameByName:@"alien2.png"]];
    }
    self.alien.rotation = alien_vel.x/40;
    self.alien.position = alien_pos;
}

- (void)showHighscores
{
    NSLog(@"showHighscores");
	gameSuspended = YES;
	[[UIApplication sharedApplication] setIdleTimerDisabled:NO];
	
//	NSLog(@"score = %d",score);
	[[CCDirector sharedDirector] replaceScene:
     [CCTransitionFade transitionWithDuration:1 scene:[GameOver gameOverSceneWithScore:score] withColor:ccWHITE]];
}

//- (BOOL)ccTouchesEnded:(NSSet*)touches withEvent:(UIEvent*)event {
//	NSLog(@"ccTouchesEnded");
//
////	[self showHighscores];
//
////	AtlasSpriteManager *spriteManager = (AtlasSpriteManager*)[self getChildByTag:kSpriteManager];
////	AtlasSprite *bonus = (AtlasSprite*)[spriteManager getChildByTag:kBonus];
////	bonus.position = ccp(160,30);
////	bonus.visible = !bonus.visible;
//
////	BitmapFontAtlas *scoreLabel = (BitmapFontAtlas*)[self getChildByTag:kScoreLabel];
////	id a1 = [ScaleTo actionWithDuration:0.2f scaleX:1.5f scaleY:0.8f];
////	id a2 = [ScaleTo actionWithDuration:0.2f scaleX:1.0f scaleY:1.0f];
////	id a3 = [Sequence actions:a1,a2,a1,a2,a1,a2,nil];
////	[scoreLabel runAction:a3];
//
//	AtlasSpriteManager *spriteManager = (AtlasSpriteManager*)[self getChildByTag:kSpriteManager];
//	AtlasSprite *platform = (AtlasSprite*)[spriteManager getChildByTag:kPlatformsStartTag+5];
//	id a1 = [MoveBy actionWithDuration:2 position:ccp(100,0)];
//	id a2 = [MoveBy actionWithDuration:2 position:ccp(-200,0)];
//	id a3 = [Sequence actions:a1,a2,a1,nil];
//	id a4 = [RepeatForever actionWithAction:a3];
//	[platform runAction:a4];
//	
//	return kEventHandled;
//}

- (void)accelerometer:(UIAccelerometer*)accelerometer didAccelerate:(UIAcceleration*)acceleration {
	if(gameSuspended) return;
	float accel_filter = 0.1f;
    if ([[UIDevice currentDevice] orientation] == UIInterfaceOrientationLandscapeRight)
    {
        alien_vel.x = alien_vel.x * accel_filter + acceleration.y * -1 * (1.0f - accel_filter) * 1000.0f;
    }
    else if ([[UIDevice currentDevice] orientation] == UIInterfaceOrientationLandscapeLeft)
    {
        alien_vel.x = alien_vel.x * accel_filter + acceleration.y * -1 * (1.0f - accel_filter) * -1000.0f;
    }
	
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
