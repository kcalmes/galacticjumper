#import "Game.h"
#import "Main.h"
#import "Highscores.h"
#import "SimpleAudioEngine.h"

@interface Game (Private)
- (void)initPlatforms;
- (void)initPlatform;
- (void)startGame;
- (void)resetPlatforms;
- (void)resetPlatform;
- (void)resetBird;
- (void)resetAlien;
- (void)resetBonus;
- (void)step:(ccTime)dt;
- (void)jump;
- (void)oldJump;
- (void)showHighscores;

#define ALIEN_YPOS_OFFSET 95

@end

@implementation Game

//Added by Kory for animation
@synthesize alien = _alien;
@synthesize jumpAction = _jumpAction;

+ (CCScene *)scene
{
    CCScene *game = [CCScene node];
    
    Game *layer = [Game node];
    [game addChild:layer];
    
    return game;
}

- (id)init {
//	NSLog(@"Game::init");
	
	if(![super init]) return nil;
	
	gameSuspended = YES;

	CCSpriteBatchNode *batchNode = (CCSpriteBatchNode *)[self getChildByTag:kSpriteManager];

	[self initPlatforms];
	/*
    CCSpriteBatchNode * danceSheet = [CCSpriteBatchNode batchNodeWithFile:@"jump.png"];
    
    // create the sprite
    CCSprite *bird = [CCSprite spriteWithTexture:danceSheet.texture rect:CGRectMake(0,222,168,244)];
    
    //CCSprite *bird = [CCSprite spriteWithTexture:[batchNode texture] rect:CGRectMake(608,16,44,32)];
    [danceSheet addChild:bird z:4 tag:kBird];
	//[batchNode addChild:bird z:4 tag:kBird];
     */
	CCSprite *bonus;

	for(int i=0; i<kNumBonuses; i++) {
		bonus = [CCSprite spriteWithTexture:[batchNode texture] rect:CGRectMake(608+i*32,256,25,25)];
		[batchNode addChild:bonus z:4 tag:kBonusStartTag+i];
		bonus.visible = NO;
	}

//	LabelAtlas *scoreLabel = [LabelAtlas labelAtlasWithString:@"0" charMapFile:@"charmap.png" itemWidth:24 itemHeight:32 startCharMap:' '];
//	[self addChild:scoreLabel z:5 tag:kScoreLabel];
	
	CCLabelBMFont *scoreLabel = [CCLabelBMFont labelWithString:@"0" fntFile:@"bitmapFont.fnt"];
	[self addChild:scoreLabel z:5 tag:kScoreLabel];
	scoreLabel.position = ccp(160,430);

	[self schedule:@selector(step:)];
	
	self.isTouchEnabled = YES;
	self.isAccelerometerEnabled = YES;

	[[UIAccelerometer sharedAccelerometer] setUpdateInterval:(1.0 / kFPS)];
	
	[self startGame];
	
	return self;
}

- (void)dealloc {
//	NSLog(@"Game::dealloc");
	[super dealloc];
    self.alien = nil;
    self.jumpAction = nil;
}

-(void)jump
{
    if ([kindOfJump isEqualToString:@"defaultJump"] && !justHitPlatform)
    {
        alien_vel.y = 150.0f;
        justHitPlatform = YES;
    }
    else if ([kindOfJump isEqualToString:@"goodJump"])
    {
        alien_vel.y = 550.0f;
        justHitPlatform = NO;
    }
    else if ([kindOfJump isEqualToString:@"excellentJump"])
    {
        alien_vel.y = 750.0f;
        justHitPlatform = NO;
    }
    else if ([kindOfJump isEqualToString:@"perfectJump"])
    {
        alien_vel.y = 950.0f;
        justHitPlatform = NO;
    }
}

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

	CGRect rect;
	switch(random()%2) {
		case 0: rect = CGRectMake(608,64,102,36); break;
		case 1: rect = CGRectMake(608,128,90,32); break;
	}

	CCSpriteBatchNode *batchNode = (CCSpriteBatchNode*)[self getChildByTag:kSpriteManager];
	CCSprite *platform = [CCSprite spriteWithTexture:[batchNode texture] rect:rect];
	[batchNode addChild:platform z:3 tag:currentPlatformTag];
}

- (void)startGame {
//	NSLog(@"startGame");

	score = 0;
	
	[self resetClouds];
	[self resetPlatforms];
    [self resetAlien];
	//[self resetBird];
	[self resetBonus];
	
	[[UIApplication sharedApplication] setIdleTimerDisabled:YES];
	gameSuspended = NO;
}

- (void)resetPlatforms {
//	NSLog(@"resetPlatforms");
	
	currentPlatformY = -1;
	currentPlatformTag = kPlatformsStartTag;
	currentMaxPlatformStep = 60.0f;
	currentBonusPlatformIndex = 0;
	currentBonusType = 0;
	platformCount = 0;

	while(currentPlatformTag < kPlatformsStartTag + kNumPlatforms) {
		[self resetPlatform];
		currentPlatformTag++;
	}
}

- (void)resetPlatform {
	
	if(currentPlatformY < 0) {
		currentPlatformY = 30.0f;
	} else {
		currentPlatformY += random() % (int)(currentMaxPlatformStep - kMinPlatformStep) + kMinPlatformStep;
		if(currentMaxPlatformStep < kMaxPlatformStep) {
			currentMaxPlatformStep += 0.5f;
		}
	}
	
	CCSpriteBatchNode *batchNode = (CCSpriteBatchNode*)[self getChildByTag:kSpriteManager];
	CCSprite *platform = (CCSprite*)[batchNode getChildByTag:currentPlatformTag];
	
	if(random()%2==1) platform.scaleX = -1.0f;
	
	float x;
	CGSize size = platform.contentSize;
	if(currentPlatformY == 30.0f) {
		x = 160.0f;
	} else {
		x = random() % (480-(int)size.width) + size.width/2;
	}
	
	platform.position = ccp(x,currentPlatformY);
	platformCount++;
//	NSLog(@"platformCount = %d",platformCount);
	
	if(platformCount == currentBonusPlatformIndex) {
//		NSLog(@"platformCount == currentBonusPlatformIndex");
		CCSprite *bonus = (CCSprite*)[batchNode getChildByTag:kBonusStartTag+currentBonusType];
		bonus.position = ccp(x,currentPlatformY+30);
		bonus.visible = YES;
	}
}

- (void)resetAlien {
    //Create a sprite batch node
    CCSpriteBatchNode *spriteSheet = [CCSpriteBatchNode batchNodeWithFile:@"jump.png"];
    [self addChild:spriteSheet];

    //Cache the sprite frames and texture
    CCSpriteFrame *frame;    
    frame = [CCSpriteFrame frameWithTexture:spriteSheet.texture rect:CGRectMake(0,9,185,260)];
    [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFrame:frame name:[NSString stringWithFormat:@"alien%d.png", 1]];
    frame = [CCSpriteFrame frameWithTexture:spriteSheet.texture rect:CGRectMake(220,0,185,270)];
    [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFrame:frame name:[NSString stringWithFormat:@"alien%d.png", 2]];

    //Gather the list of frames
    NSMutableArray *jumpAnimFrames = [NSMutableArray array];
    for(int i = 1; i <= 2; ++i) {
        [jumpAnimFrames addObject:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:[NSString stringWithFormat:@"alien%d.png", i]]];
    }
    
    //Create the animation object
    CCAnimation *jumpAnim = [CCAnimation animationWithFrames:jumpAnimFrames delay:0.1f];
    
    //Create the sprite and run the animation action
    CGSize winSize = [CCDirector sharedDirector].winSize;
    self.alien = [CCSprite spriteWithSpriteFrameName:@"alien2.png"];
    self.alien.position = ccp(winSize.width/2, winSize.height/2);
    self.alien.scale = 0.25f;
    
    alien_pos.x = 160;
	alien_pos.y = 160;
	self.alien.position = alien_pos;

	
	alien_vel.x = 0;
	alien_vel.y = 0;
	
	alien_acc.x = 0;
	alien_acc.y = -550.0f;
    
    //self.alien.rotation = 90;
    //self.jumpAction = [CCRepeatForever actionWithAction: [CCAnimate actionWithAnimation:jumpAnim restoreOriginalFrame:YES]];
    self.jumpAction = [CCRepeat actionWithAction:[CCAnimate actionWithAnimation:jumpAnim restoreOriginalFrame:NO] times:1];
    //self.jumpAction = [CCAnimate actionWithAnimation:jumpAnim restoreOriginalFrame:YES];
    
    self.alien = [CCSprite spriteWithSpriteFrameName:@"alien1.png"];
    self.alien.scale = 0.25f;

    [spriteSheet addChild: self.alien];
    
    


    //[self.alien runAction: self.jumpAction];
    justHitPlatform = NO;
    kindOfJump = @"defaultJump";
    
}

- (void)resetBird {
//	NSLog(@"resetBird");
    /*

	CCSpriteBatchNode *batchNode = (CCSpriteBatchNode*)[self getChildByTag:kSpriteManager];
	CCSprite *bird = (CCSprite*)[batchNode getChildByTag:kBird];
	
	bird_pos.x = 160;
	bird_pos.y = 160;
	bird.position = bird_pos;
	
	bird_vel.x = 0;
	bird_vel.y = 0;
	
	bird_acc.x = 0;
	bird_acc.y = -350.0f;
	
	birdLookingRight = YES;
	bird.scaleX = 1.0f;

     */
    
    //-----------------------------------------------------------------------------------------------------------------
    
    
    // create the sprite sheet
    CCSpriteBatchNode * danceSheet = [CCSpriteBatchNode batchNodeWithFile:@"jump.png"];
    [self addChild:danceSheet];
    CCSpriteFrame *frame;
    frame = [CCSpriteFrame frameWithTexture:danceSheet.texture rect:CGRectMake(0,9,185,260)];
    [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFrame:frame name:[NSString stringWithFormat:@"man%d.png", 1]];
    frame = [CCSpriteFrame frameWithTexture:danceSheet.texture rect:CGRectMake(220,0,185,270)];
    [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFrame:frame name:[NSString stringWithFormat:@"man%d.png", 2]];
    
    
    // Load up the frames of our animation
    NSMutableArray *jumpAnimFrames = [NSMutableArray array];
    for(int i = 1; i <= 2; ++i) {
        [jumpAnimFrames addObject:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:[NSString stringWithFormat:@"man%d.png", i]]];
    }
    NSLog(@"after frame load");
    //CCAnimation *jumpAnim = [CCAnimation animationWithFrames:walkAnimFrames delay:0.1f];
    
    // create the animation
    CCAnimation *danceAnimation = [CCAnimation animationWithFrames:jumpAnimFrames delay:0.4f];
    NSLog(@"after create animation");
    // create the sprite
    CCSprite *bird = [CCSprite spriteWithTexture:danceSheet.texture rect:CGRectMake(0,9,185,260)];
    [danceSheet addChild:bird];
    NSLog(@"after create the sprite");
    // position the sprite in the center of the screen
    CGSize s = [[CCDirector sharedDirector] winSize];
    bird.position = ccp(s.width/2,s.height/2);
    
    
    bird_pos.x = 160;
	bird_pos.y = 160;
	bird.position = bird_pos;
	
	bird_vel.x = 0;
	bird_vel.y = 0;
	
	bird_acc.x = 0;
	bird_acc.y = -550.0f;
	
	birdLookingRight = YES;
    bird.scale = 0.25f;
    
    
    
    NSLog(@"after sprite position");
    // create the action
    CCAnimate *danceAction = [CCAnimate actionWithAnimation:danceAnimation];
    CCRepeatForever *repeat = [CCRepeatForever actionWithAction:danceAction];
    NSLog(@"after create action");
    // run the action
    [bird runAction:repeat];
    //[bird stopAction:repeat];
    NSLog(@"after run the action");
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

- (void)step:(ccTime)dt {
	//NSLog(@"Game::step");

	[super step:dt];
	
	if(gameSuspended) return;

	//CCSpriteBatchNode *batchNode = (CCSpriteBatchNode*)[self getChildByTag:kSpriteManager];
	//CCSprite *bird = (CCSprite*)[batchNode getChildByTag:kBird];
	
	alien_pos.x += alien_vel.x * dt;
	
    /*
	if(bird_vel.x < -30.0f && birdLookingRight) {
		birdLookingRight = NO;
		bird.scaleX = -1.0f;
	} else if (bird_vel.x > 30.0f && !birdLookingRight) {
		birdLookingRight = YES;
		bird.scaleX = 1.0f;
	}
     */
	CGSize alien_size = self.alien.contentSize;
	float max_x = 320-alien_size.width/2;
	float min_x = 0+alien_size.width/2;
	
	if(alien_pos.x>max_x) alien_pos.x = max_x;
	if(alien_pos.x<min_x) alien_pos.x = min_x;
	
	alien_vel.y += alien_acc.y * dt;
	alien_pos.y += alien_vel.y * dt;
    
    
	/*
	CCSprite *bonus = (CCSprite*)[batchNode getChildByTag:kBonusStartTag+currentBonusType];
	if(bonus.visible) {
		CGPoint bonus_pos = bonus.position;
		float range = 20.0f;
		if(bird_pos.x > bonus_pos.x - range &&
		   bird_pos.x < bonus_pos.x + range &&
		   bird_pos.y > bonus_pos.y - range &&
		   bird_pos.y < bonus_pos.y + range ) {
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
	*/
    
    
    //check for object collisions
	int t;
    //load object sprite sheet - this actually be done in the init method
	CCSpriteBatchNode *batchNode = (CCSpriteBatchNode*)[self getChildByTag:kSpriteManager];

	if(alien_vel.y < 0) {
		t = kPlatformsStartTag;
        justHitPlatform = NO;
		for(t; t < kPlatformsStartTag + kNumPlatforms; t++) {
			CCSprite *platform = (CCSprite*)[batchNode getChildByTag:t];

			CGSize platform_size = platform.contentSize;
			CGPoint platform_pos = platform.position;
			
			max_x = platform_pos.x - platform_size.width/2 - 10;
			min_x = platform_pos.x + platform_size.width/2 + 10;
			float min_y = platform_pos.y + (platform_size.height+alien_size.height)/2 - kPlatformTopPadding;
			

			if(alien_pos.x > max_x &&
			   alien_pos.x < min_x &&
			   alien_pos.y > platform_pos.y &&
			   (alien_pos.y + ALIEN_YPOS_OFFSET) < min_y) {
				[self jump];
                kindOfJump = @"defaultJump";
			}
		}
		
		if(alien_pos.y < -alien_size.height/2)
        {
			[self showHighscores];
		}
		
	}
    else if(justHitPlatform)
    {
        [self jump];
    }
    else if(alien_pos.y > 140) {
		
		float delta = alien_pos.y - 140;
		alien_pos.y = 140;

		currentPlatformY -= delta;
		
		for(int t = kPlatformsStartTag; t < kCloudsStartTag + kNumClouds; t++) {
			CCSprite *cloud = (CCSprite*)[batchNode getChildByTag:t];
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
			CCSprite *platform = (CCSprite*)[batchNode getChildByTag:t];
			CGPoint pos = platform.position;
			pos = ccp(pos.x,pos.y-delta);
			if(pos.y < -platform.contentSize.height/2) {
				currentPlatformTag = t;
				[self resetPlatform];
			} else {
				platform.position = pos;
			}
		}
		/*
		if(bonus.visible) {
			CGPoint pos = bonus.position;
			pos.y -= delta;
			if(pos.y < -bonus.contentSize.height/2) {
				[self resetBonus];
			} else {
				bonus.position = pos;
			}
		}
		*/
		score += (int)delta;
		NSString *scoreStr = [NSString stringWithFormat:@"%d",score];

		CCLabelBMFont *scoreLabel = (CCLabelBMFont*)[self getChildByTag:kScoreLabel];
		[scoreLabel setString:scoreStr];
	}
    //Toggle the jump
    CCSpriteFrameCache* cache = [CCSpriteFrameCache sharedSpriteFrameCache];
    if (alien_vel.y < 0) {
        [self.alien setDisplayFrame:[cache spriteFrameByName:@"alien1.png"]];
    } else {
        [self.alien setDisplayFrame:[cache spriteFrameByName:@"alien2.png"]];
    }
    
	self.alien.position = alien_pos;
}

- (void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSLog(@"Screen Touched");
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInView: [touch view]];
    
    CGRect mySurface = (CGRectMake(100, 100, 320, 480));
    if(CGRectContainsPoint(mySurface, location))
    {
        if(alien_vel.y < 0 || justHitPlatform)
        {
            
            CGSize alien_size = self.alien.contentSize;
            float max_x = 320-alien_size.width/2;
            float min_x = 0+alien_size.width/2;
            
            CCSpriteBatchNode *batchNode = (CCSpriteBatchNode*)[self getChildByTag:kSpriteManager];
            //potential bug - if 2 items are close this will not get the closest jump, it will get the one in the nearest order
            for(int t = kPlatformsStartTag; t < kPlatformsStartTag + kNumPlatforms; t++)
            {
                CCSprite *platform = (CCSprite*)[batchNode getChildByTag:t];
                
                CGSize platform_size = platform.contentSize;
                CGPoint platform_pos = platform.position;
                
                max_x = platform_pos.x - platform_size.width/2 - 10;
                min_x = platform_pos.x + platform_size.width/2 + 10;
                float min_y = platform_pos.y + (platform_size.height+alien_size.height)/2 - kPlatformTopPadding;
                
                if(alien_pos.x > max_x &&
                   alien_pos.x < min_x &&
                   alien_pos.y > platform_pos.y &&
                   alien_pos.y + ALIEN_YPOS_OFFSET < min_y +5)
                {
                    kindOfJump = @"PerfectJump";
                }
                else if(alien_pos.x > max_x &&
                        alien_pos.x < min_x &&
                        alien_pos.y > platform_pos.y &&
                        alien_pos.y + ALIEN_YPOS_OFFSET < min_y +10)
                {
                    kindOfJump = @"excellentJump";
                }
                else if(alien_pos.x > max_x &&
                        alien_pos.x < min_x &&
                        alien_pos.y > platform_pos.y &&
                        alien_pos.y + ALIEN_YPOS_OFFSET < min_y +15)
                {
                    kindOfJump = @"goodJump";
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
            NSLog(@"Kind of Jump: %@", kindOfJump);
        }
    }
}

- (void)oldJump {
	alien_vel.y = 350.0f + fabsf(alien_vel.x);
}

- (void)showHighscores {
    NSLog(@"showHighscores");
	gameSuspended = YES;
	[[UIApplication sharedApplication] setIdleTimerDisabled:NO];
	
//	NSLog(@"score = %d",score);
	[[CCDirector sharedDirector] replaceScene:
     [CCTransitionFade transitionWithDuration:1 scene:[Highscores sceneWithScore:score] withColor:ccWHITE]];
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
	alien_vel.x = alien_vel.x * accel_filter + acceleration.x * (1.0f - accel_filter) * 500.0f;
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
