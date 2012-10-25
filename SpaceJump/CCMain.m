#import "CCMain.h"
#import <mach/mach_time.h>

#define RANDOM_SEED() srandom((unsigned)(mach_absolute_time() & 0xFFFFFFFF))

@interface Main(Private)
- (void)initClouds;
- (void)initCloud;
@end


@implementation Main

- (id)init {
//	NSLog(@"Main::init");
	
	if(![super init]) return nil; //return nil if super class is not ready
	
	RANDOM_SEED();  //what does this mean?

	CCSpriteBatchNode *batchNode = [CCSpriteBatchNode batchNodeWithFile:@"sprites.png" capacity:10];
    CCSpriteBatchNode *cloudsNode = [CCSpriteBatchNode batchNodeWithFile:@"objectsclouds.png" capacity:10];
    CCSpriteBatchNode *platformNode = [CCSpriteBatchNode batchNodeWithFile:@"objectplatforms.png" capacity:10];
	[self addChild:batchNode z:-1 tag:kSpriteManager]; //call method inherited from ccnode to add our batchnode
    [self addChild:cloudsNode z:-2 tag:kCloudsManager];
    [self addChild:platformNode z:3 tag:kPlatformManager];

    CCSprite *background = [CCSprite spriteWithFile:@"bgiphone4.png" rect:CGRectMake(0, 0, 480, 320)];
	background.position = CGPointMake(240,160); 
    [self addChild:background z:-3];

	[self initClouds];

	[self schedule:@selector(step:)];
	
	return self;
}

- (void)dealloc {
//	NSLog(@"Main::dealloc");
	[super dealloc];
}

- (void)initClouds {
//	NSLog(@"initClouds");
	
	currentCloudTag = kCloudsStartTag;
	while(currentCloudTag < kCloudsStartTag + kNumClouds) {
		[self initCloud];
		currentCloudTag++;
	}
	
	[self resetClouds];
}

- (void)initCloud {
	//return;
	CGRect rect;
	switch(random()%2) {
		case 0: rect = CGRectMake(0,0,295,148); break;
		case 1: rect = CGRectMake(395,10,310,160); break;
	}	
	CCSpriteBatchNode *cloudsNode = (CCSpriteBatchNode*)[self getChildByTag:kCloudsManager];
	CCSprite *cloud = [CCSprite spriteWithTexture:[cloudsNode texture] rect:rect];
	[cloudsNode addChild:cloud z:-2 tag:currentCloudTag];
	
	cloud.opacity = 128;
}

- (void)resetClouds {
    //return;
//	NSLog(@"resetClouds");
	
	currentCloudTag = kCloudsStartTag;
	
	while(currentCloudTag < kCloudsStartTag + kNumClouds) {
		[self resetCloud];

		CCSpriteBatchNode *cloudsNode = (CCSpriteBatchNode*)[self getChildByTag:kCloudsManager];
		CCSprite *cloud = (CCSprite*)[cloudsNode getChildByTag:currentCloudTag];
		CGPoint pos = cloud.position;
		pos.y -= 320.0f;
		cloud.position = pos;
		
		currentCloudTag++;
	}
}

- (void)resetCloud {
   // return;
	
	CCSpriteBatchNode *cloudsNode = (CCSpriteBatchNode*)[self getChildByTag:kCloudsManager];
	CCSprite *cloud = (CCSprite*)[cloudsNode getChildByTag:currentCloudTag];
	
	float distance = random()%20 + 5;
	
	float scale = 5.0f / distance;
	cloud.scaleX = scale;
	cloud.scaleY = scale;
	if(random()%2==1) cloud.scaleX = -cloud.scaleX;
	
	CGSize size = cloud.contentSize;
	float scaled_width = size.width * scale;
	float x = random()%(480+(int)scaled_width) - scaled_width/2;
	float y = random()%(320-(int)scaled_width) + scaled_width/2 + 320;
	
	cloud.position = ccp(x,y);
}

- (void)step:(ccTime)dt {
//	NSLog(@"Main::step");
	CCSpriteBatchNode *cloudsNode = (CCSpriteBatchNode*)[self getChildByTag:kCloudsManager];
	
	for(int t = kCloudsStartTag; t < kCloudsStartTag + kNumClouds; t++) {
		CCSprite *cloud = (CCSprite*)[cloudsNode getChildByTag:t];
		CGPoint pos = cloud.position;
		CGSize size = cloud.contentSize;
		pos.x += 0.1f * cloud.scaleY;
		if(pos.x > 480 + size.width/2) {
			pos.x = -size.width/2;
		}
		cloud.position = pos;
	}
}

@end
