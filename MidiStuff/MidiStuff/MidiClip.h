//
//  MidiClip.h
//  MidiEngine
//
//  Created by Nick on 07/11/2013.
//  Copyright (c) 2013 Nick. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kNumberOfPulsesPerQuarterNote 8
@class MidiLauncher;

@class MidiMessage;

typedef enum {
    kArp,
    kHorn,
    kSnare
} Instrument;

@interface MidiClip : NSObject

- (id) initWithNumberOfBars:(NSInteger)numberOfBars;

- (void) setNumberOfBars:(NSInteger)numberOfBars;

- (NSInteger) numberOfPulses;

- (NSInteger) numberOfCells;

- (void) setCellFilled:(BOOL)filled
  withHorizontalOffset:(NSInteger)hOffset
    withVerticalOffset:(NSInteger)vOffset;

- (NSArray*) messagesForPulse:(NSInteger)pulse;
- (CGFloat) progressForPulse:(NSInteger)pulse;

@property (nonatomic, assign) Instrument instrument;

@end
