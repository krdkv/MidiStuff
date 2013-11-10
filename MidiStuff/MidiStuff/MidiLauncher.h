//
//  MidiLauncher.h
//  MidiEngine
//
//  Created by Nick on 07/11/2013.
//  Copyright (c) 2013 Nick. All rights reserved.
//

#import <Foundation/Foundation.h>
@class MidiClip;

@protocol MidiLauncherProgressDelegate

- (void) clip:(NSInteger)clip progress:(CGFloat)progress;

@end

@interface MidiLauncher : NSObject

- (void) start;
- (void) stop;

- (void) addMidiClip:(MidiClip*)clip;

- (void) setTempo:(NSInteger)tempo;

- (void) setClipEnabled:(NSInteger)clip enabled:(BOOL)enabled;

@property (nonatomic, strong) id<MidiLauncherProgressDelegate> progressDelegate;

@end
