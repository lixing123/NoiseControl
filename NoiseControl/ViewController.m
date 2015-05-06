//
//  ViewController.m
//  NoiseControl
//
//  Created by 李 行 on 15/4/30.
//  Copyright (c) 2015年 lixing123.com. All rights reserved.
//

#import "ViewController.h"

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

OSStatus InputCallback(void *inRefCon,
                       AudioUnitRenderActionFlags *ioActionFlags,
                       const AudioTimeStamp *inTimeStamp,
                       UInt32 inBusNumber,
                       UInt32 inNumberFrames,
                       AudioBufferList *ioData){
    //TODO: implement this function
    ViewController* controller = (__bridge ViewController*)inRefCon;
    
    //Get samples from input bus(bus 1)
    CheckError(AudioUnitRender(controller.remoteIOUnit,
                               ioActionFlags,
                               inTimeStamp,
                               1,
                               inNumberFrames,
                               ioData),
               "AudioUnitRender failed");
    
    return noErr;
}

@interface ViewController ()

@end

@implementation ViewController

@synthesize remoteIOUnit;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    //Set up a RemoteIO to synchronously playback
    
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
    //This will easily playback to the output speaker
    //But we will set the render callback, so we'll not use this function
    /*
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
     */
    
    AudioStreamBasicDescription asbd = {0};
    asbd.mFormatID = kAudioFormatLinearPCM;
    asbd.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
    asbd.mSampleRate = 44100;
    asbd.mFramesPerPacket = 1;
    asbd.mBytesPerFrame = 2;
    asbd.mBytesPerPacket = 2;
    asbd.mBitsPerChannel = 16;
    asbd.mChannelsPerFrame = 1;
    
    CheckError(AudioUnitSetProperty(remoteIOUnit,
                                    kAudioUnitProperty_StreamFormat,
                                    kAudioUnitScope_Input,
                                    0,
                                    &asbd,
                                    sizeof(asbd)),
               "kAudioUnitProperty_StreamFormat of bus 0 failed");
    
    CheckError(AudioUnitSetProperty(remoteIOUnit,
                                    kAudioUnitProperty_StreamFormat,
                                    kAudioUnitScope_Output,
                                    1,
                                    &asbd,
                                    sizeof(asbd)),
               "kAudioUnitProperty_StreamFormat of bus 1 failed");
    
    AURenderCallbackStruct input;
    input.inputProc = InputCallback;
    input.inputProcRefCon = (__bridge void *)(self);
    CheckError(AudioUnitSetProperty(remoteIOUnit,
                                    kAudioUnitProperty_SetRenderCallback,
                                    kAudioUnitScope_Global,
                                    0,//input mic
                                    &input,
                                    sizeof(input)),
               "kAudioUnitProperty_SetRenderCallback failed");
    
    //Initialize the unit and start
    AudioUnitInitialize(remoteIOUnit);
    AudioOutputUnitStart(remoteIOUnit);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
