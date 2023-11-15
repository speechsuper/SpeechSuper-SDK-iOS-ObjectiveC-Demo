#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#include "skegn.h"
#import "TestViewController.h"



NSString *appKey = @"Insert your appKey here";
NSString *secretKey = @"Insert your secretKey here";


struct skegn *engine;
@interface ViewController ()<UITableViewDelegate, UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation ViewController

- (NSString *)objectToJsonString:(id)object {
    NSString *jsonString = nil;
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:object
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:&error];
    if (!jsonData) {
        NSLog(@"Got an error: %@", error);
    } else {
        jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
    return jsonString;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.tableFooterView = [UIView new];
    
    //init engine
    NSMutableDictionary *paramDic = [NSMutableDictionary dictionary];
    [paramDic setValue:appKey forKey:@"appKey"];
    [paramDic setValue:secretKey forKey:@"secretKey"];
    
    NSString *resourcePath = [[NSBundle mainBundle] pathForResource:@"native.res" ofType:nil];
    [paramDic setValue:resourcePath forKey:@"native"];

    NSString *resourcePathcn = [[NSBundle mainBundle] pathForResource:@"native_cn.res" ofType:nil];
    [paramDic setValue:resourcePathcn forKey:@"native_cn"];
    
    NSDictionary *logDic = @{
                             @"enable":@1,
                             @"output":[[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"sdkLog.txt"],
                             @"level":@3
                             };
    [paramDic setValue:logDic forKey:@"sdkLog"];

    NSString *jsonString = [self objectToJsonString:paramDic];
    NSLog(@"%@", jsonString);
    
    const char *params_char = jsonString.UTF8String;
    
    engine = skegn_new(params_char); //init engine
    //Determine authorization status and apply for authorization
    [self checkCameraAuthorizationGrand:^{
    } withNoPermission:^{
    }];
     
 }





#pragma mark - TableView Delegate
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.nativeTitleArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *identify = @"cellIdentify";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identify];
    if (!cell) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:identify];
    }
    cell.textLabel.text = [self.nativeTitleArray objectAtIndex:indexPath.row];


    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 44.0f;
}



- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self showTestViewControllerWith:[self.nativeTypeArray objectAtIndex:indexPath.row]];
}

// Display different question styles
//


- (void)showTestViewControllerWith:(NSString *)testType {
    TestViewController *testVC = [self.storyboard instantiateViewControllerWithIdentifier:@"TestVC"];
   testVC.coreType = testType;
   [self.navigationController pushViewController:testVC animated:YES];
}

- (NSArray *)nativeTypeArray {
    return @[ @"word.eval", @"sent.eval", @"para.eval",@"word.eval.cn", @"sent.eval.cn", @"para.eval.cn"];
}

- (NSArray *)nativeTitleArray {
    return @[ @"English Word", @"English Sentence", @"English Paragraph",@"Chinese Word", @"Chinese Sentence", @"Chinese Paragraph"];
}
 

#pragma mark - Microphone authorization judgment

- (void)checkCameraAuthorizationGrand:(void (^)())permissionGranted withNoPermission:(void (^)())noPermission{
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
    switch (authStatus) {
        case AVAuthorizationStatusNotDetermined:
        {
            //Prompt user for authorization for the first time
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeAudio completionHandler:^(BOOL granted) {
                granted ? permissionGranted() : noPermission();
            }];
            break;
        }
        case AVAuthorizationStatusAuthorized:
        {
            //By authorization
            permissionGranted();
            break;
        }
        case AVAuthorizationStatusRestricted:
            //Cannot authorize
            NSLog(@"Unable to complete authorization, access restrictions may have been enabled");
        case AVAuthorizationStatusDenied:{
            //Prompt to jump to settings
        }
            break;
        default:
            break;
    }
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


@end
