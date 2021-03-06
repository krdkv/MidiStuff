//
//  ViewController.h
//  MidiStuff
//
//  Created by Nick on 09/11/2013.
//  Copyright (c) 2013 Nick. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GridView.h"
#import "MidiLauncher.h"

@interface ViewController : UIViewController <GridViewDelegate, MidiLauncherProgressDelegate>

@property (nonatomic, strong) IBOutlet GridView * snareGridView;
@property (nonatomic, strong) IBOutlet GridView * synthGridView;

@property (nonatomic, strong) IBOutlet UISlider * midiNoteSlider;
@property (nonatomic, strong) IBOutlet UISlider * tempoSlider;

@end
