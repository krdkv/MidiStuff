//
//  MidiPlayer.h
//  MidiEngine
//
//  Created by Nick on 07/11/2013.
//  Copyright (c) 2013 Nick. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MidiClip.h"
#import <AVFoundation/AVFoundation.h>

@class MidiMessage;

@interface MidiPlayer : NSObject<AVAudioSessionDelegate>

- (void) forwardMessage:(MidiMessage*)message
         withInstrument:(Instrument)instrument;

@end
