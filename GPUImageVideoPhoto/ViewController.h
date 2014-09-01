//
//  ViewController.h
//  GPUImageVideoPhoto
//
//  Created by Administrator on 2014/09/01.
//  Copyright (c) 2014年 mhfm001. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GPUImage.h"


@interface ViewController : UIViewController  <GPUImageVideoCameraDelegate>
{
    dispatch_queue_t main_queue;
    dispatch_queue_t sub_queue;
}

- (IBAction)takePhotoNow:(id)sender;


@end
