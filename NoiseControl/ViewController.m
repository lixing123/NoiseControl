//
//  ViewController.m
//  NoiseControl
//
//  Created by 李 行 on 15/4/30.
//  Copyright (c) 2015年 lixing123.com. All rights reserved.
//

#import "ViewController.h"
#import <AudioToolbox/AudioToolbox.h>

static void CheckError(OSStatus error, const char *operation)
{
    if (error == noErr) return;
    char errorString[20];
    // See if it appears to be a 4-char-code
    *(UInt32 *)(errorString + 1) = CFSwapInt32HostToBig(error);
    if (isprint(errorString[1]) && isprint(errorString[2]) &&
        isprint(errorString[3]) && isprint(errorString[4])) {
        errorString[0] = errorString[5] = '\'';
        errorString[6] = '\0';
    } else
        // No, format it as an integer
        sprintf(errorString, "%d", (int)error);
    fprintf(stderr, "Error: %s (%s)\n", operation, errorString);
    exit(1);
}

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    //Set up a RemoteIO to synchronously playback
    AudioUnit remoteIOUnit;
    
    AudioComponentDescription inputcd = {0};
    inputcd.componentType = kAudioUnitType_Output;
    inputcd.componentSubType = kAudioUnitSubType_RemoteIO;
    inputcd.componentManufacturer = kAudioUnitManufacturer_Apple;
    
    AudioComponent comp = AudioComponentFindNext(NULL,
                                                 &inputcd);
    
    CheckError(AudioComponentInstanceNew(comp,
                                         &remoteIOUnit),
               "AudioComponentInstanceNew failed");
    
    //Open input of the bus 1(input mic)
    UInt32 enableFlag = 1;
    CheckError(AudioUnitSetProperty(remoteIOUnit,
                                    kAudioOutputUnitProperty_EnableIO,
                                    kAudioUnitScope_Input,
                                    1,
                                    &enableFlag,
                                    sizeof(enableFlag)),
               "Open input of bus 1 failed");
    
    //Open output of bus 0(output speaker)
    CheckError(AudioUnitSetProperty(remoteIOUnit,
                                    kAudioOutputUnitProperty_EnableIO,
                                    kAudioUnitScope_Output,
                                    0,
                                    &enableFlag,
                                    sizeof(enableFlag)),
               "Open output of bus 0 failed");
    
    //Connect output of input bus to input of output bus
    AudioUnitConnection connection;
    connection.sourceAudioUnit = remoteIOUnit;
    connection.sourceOutputNumber = 1;
    connection.destInputNumber = 0;
    CheckError(AudioUnitSetProperty(remoteIOUnit,
                                    kAudioUnitProperty_MakeConnection,
                                    kAudioUnitScope_Input,
                                    0,
                                    &connection,
                                    sizeof(connection)),
               "kAudioUnitProperty_MakeConnection failed");
    
    //Initialize the unit and start
    AudioUnitInitialize(remoteIOUnit);
    AudioOutputUnitStart(remoteIOUnit);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
