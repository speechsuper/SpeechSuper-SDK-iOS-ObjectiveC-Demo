#import <Foundation/Foundation.h>

@interface TestResultHandler : NSObject


// parse result
+ (NSString *)dealWithTestResult:(NSString *)result coreType:(NSString *)coreType;

@end
