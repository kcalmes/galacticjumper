#import "cocos2d.h"
#import "CCMain.h"

@interface GameOver : Main <UITextFieldDelegate>
{
	NSString *currentPlayer;
	int currentScorePosition;
	NSMutableArray *highscores;
	UIAlertView *changePlayerAlert;
	UITextField *changePlayerTextField;
}
+ (CCScene *)gameOverSceneWithScore:(int)lastScore;
- (id)initWithScore:(int)lastScore;
@end
