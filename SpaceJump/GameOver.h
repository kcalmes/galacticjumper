#import "cocos2d.h"
#import "CCMain.h"

@interface GameOver : Main <UITextFieldDelegate>
+ (CCScene *)gameOverSceneWithScore:(int)lastScore andCombo:(int)lastCombo;
- (id)initWithScore:(int)currentScore andCombo:(int)lastCombo;
@end
