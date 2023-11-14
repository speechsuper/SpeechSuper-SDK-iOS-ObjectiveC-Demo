# SpeechSuper SDK iOS Objective-C Demo

This demo provides an example of how to integrate the SpeechSuper iOS Objective-C SDK into your iOS app for pronunciation assessment. Follow these steps to get started:

## Step 1: Configure Your Keys
1. Open the file `RecorderDemo/ViewController.m`.
2. Insert your `appKey` and `secretKey` into the following lines:

   ```objective-c
   NSString *appKey = @"Insert your appKey here";
   NSString *secretKey = @"Insert your secretKey here";
   ```

## Step 2: Customize Your Inputs
1. Open the file `RecorderDemo/evalScences/Controller/TestViewController.m`.
2. Modify the input parameters according to your needs in the following code block:

    ```objectivec
    - (void)startSkegn {
  
            ...
           
            [appDic setValue:@"userId" forKey:@"userId"];
            
            NSMutableDictionary *audioDic = [NSMutableDictionary dictionary];
            [audioDic setValue:@"wav" forKey:@"audioType"];
            [audioDic setValue:@16000 forKey:@"sampleRate"];
            [audioDic setValue:@1 forKey:@"channel"];
            [audioDic setValue:@2 forKey:@"sampleBytes"];
            
            NSMutableDictionary *requestDic = [NSMutableDictionary dictionary];
            [requestDic setValue:self.coreType forKey:@"coreType"];
            [requestDic setValue:self.testString forKey:@"refText"];
            
            NSMutableDictionary *paramDic = [NSMutableDictionary dictionary];
            [paramDic setValue:appDic forKey:@"app"];
            [paramDic setValue:audioDic forKey:@"audio"];
            [paramDic setValue:requestDic forKey:@"request"];
            [paramDic setValue:@"native" forKey:@"coreProvideType"];
            NSString *jsonString = [self objectToJsonString:paramDic];
            ...
    }
    ```
## Step 3: Run the Application
1. Run the application on your iOS device or simulator.
2. Click on the item on the screen to navigate to the evaluation screen.

## Step 4: Start and End Evaluation
1. On the evaluation screen, click the "Start Record" button to begin recording and evaluation.
2. Click the "End" button to stop recording and await the result.

Now you're ready to use the SpeechSuper iOS Objective-C SDK in your iOS app.
