#import "cocos2d.h"

#define kNumClouds			4

enum {
	kSpriteManager = 0,
    kCloudsManager = 1,
    kPlatformManager = 2,
	kBird,
	kScoreLabel,
	kCloudsStartTag = 100,
    kTimerLabel = 101,
    kComboLabel = 102,
	kPlatformsStartTag = 200,
	kBonusStartTag = 300
    
};

@interface Main : CCLayer
{
	int currentCloudTag;
}
- (void)resetClouds;
- (void)resetCloud;
- (void)step:(ccTime)dt;
@end
