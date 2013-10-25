//
//  TNViewController.h
//  GeoBBS
//
//  Created by Jack He on 12/26/12.
//  Copyright (c) 2012 Telenav. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <ImageIO/ImageIO.h>
#import <CoreMotion/CoreMotion.h>
#import <AVFoundation/AVFoundation.h>


@interface TNViewController : UIViewController
@property (weak, nonatomic) IBOutlet UILabel *labelX;
@property (weak, nonatomic) IBOutlet UILabel *labelY;
@property (weak, nonatomic) IBOutlet UILabel *labelZ;
@property (weak, nonatomic) IBOutlet UIButton *btnStart;
@property (weak, nonatomic) IBOutlet UIView *videoView;
@property (weak, nonatomic) IBOutlet UILabel *labelDistance;

- (IBAction)onStartClicked:(id)sender;

@end
