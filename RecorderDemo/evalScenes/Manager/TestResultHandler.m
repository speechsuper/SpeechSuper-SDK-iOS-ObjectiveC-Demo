#import "TestResultHandler.h"

@implementation TestResultHandler

+ (NSString *)dealWithTestResult:(NSString *)result coreType:(NSString *)coreType {
    NSString *ret = @"";
    if ([result containsString:@"result"]) {
        NSError *error;
        NSData *rdata = [result dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *dataDic = [NSJSONSerialization JSONObjectWithData:rdata options:NSJSONReadingMutableLeaves  error:&error];
        NSDictionary *resultDic = [dataDic objectForKey:@"result"];
        
        NSString *overall = [resultDic objectForKey:@"overall"];
        NSString *integrity = [resultDic objectForKey:@"integrity"];
        NSString *recognition = [resultDic objectForKey:@"recognition"];
        NSString *confidence = [resultDic objectForKey:@"confidence"];
        NSString *fluency = [resultDic objectForKey:@"fluency"];
        NSString *pronunciation = [resultDic objectForKey:@"pronunciation"];
        NSString *speed = [resultDic objectForKey:@"speed"];
        NSString *rear_tone = [resultDic objectForKey:@"rear_tone"];
        
        if (overall) {
            ret = [ret stringByAppendingString:[NSString stringWithFormat:@"overall：%@\n", overall]];
        }
        if (integrity) {
            ret = [ret stringByAppendingString:[NSString stringWithFormat:@"integrity：%@\n", integrity]];
        }
        if (recognition) {
            ret = [ret stringByAppendingString:[NSString stringWithFormat:@"recognition：%@\n", recognition]];
        }
        if (confidence) {
            ret = [ret stringByAppendingString:[NSString stringWithFormat:@"confidence：%@\n", confidence]];
        }
        if (fluency) {
            ret = [ret stringByAppendingString:[NSString stringWithFormat:@"fluency：%@\n", fluency]];
        }
        if (pronunciation) {
            ret = [ret stringByAppendingString:[NSString stringWithFormat:@"pronunciation：%@\n", pronunciation]];
        }
        if (speed) {
            ret = [ret stringByAppendingString:[NSString stringWithFormat:@"speed：%@\n", speed]];
        }
        if (rear_tone && ([coreType isEqual:@"sent.eval"] || [coreType isEqual:@"sent.eval.cn"])) {
            ret = [ret stringByAppendingString:[NSString stringWithFormat:@"rear_tone：%@\n", rear_tone]];
        }
        
        NSArray *wordArray = [resultDic objectForKey:@"words"];
        
        if (wordArray) {
            if ([coreType isEqual:@"word.eval"]) {
                NSString *phonemesString = @"phonemes：/";
                NSArray *phonemesArray = [[wordArray firstObject] objectForKey:@"phonemes"];
                for (NSDictionary *phonemesDic in phonemesArray) {
                    NSString *phonemeScore = [NSString stringWithFormat:@"%@:%@ /", [phonemesDic objectForKey:@"phoneme"], [phonemesDic objectForKey:@"pronunciation"]];
                    phonemesString = [phonemesString stringByAppendingString:phonemeScore];
                }
                ret = [ret stringByAppendingString:phonemesString];
                
            } else if ([coreType isEqual:@"sent.eval"] || [coreType isEqual:@"sent.eval.cn"]) {
                NSString *wordString = @"overall：";
                for (NSDictionary *wordDic in wordArray) {
                    NSString *wordScore = [NSString stringWithFormat:@"%@:%@ ", [wordDic objectForKey:@"word"], [[wordDic objectForKey:@"scores"] objectForKey:@"overall"]];
                    wordString = [wordString stringByAppendingString:wordScore];
                }
                ret = [ret stringByAppendingString:wordString];
            }
        }
    }
    return ret;
}

@end
