//
//  ViewController.h
//  NoiseControl
//
//  Created by 李 行 on 15/4/30.
//  Copyright (c) 2015年 lixing123.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>

@interface ViewController : UIViewController

@property(nonatomic,assign)AudioUnit remoteIOUnit;
@property(nonatomic,assign)AudioStreamBasicDescription streamFormat;

@end

