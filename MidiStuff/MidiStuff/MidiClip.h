//
//  MidiClip.h
//  MidiEngine
//
//  Created by Nick on 07/11/2013.
//  Copyright (c) 2013 Nick. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kNumberOfPulsesPerQuarterNotes 24

@class MidiMessage;

typedef enum {
    kArp,
    kHorn,
    kSnare
} Instrument;

@interface MidiClip : NSObject

- (id) init;

- (id) initWithUpperTimeSignature:(NSInteger)upperSignature
            andLowerTimeSignature:(NSInteger)lowerSignature;

- (void) addMessage:(MidiMessage*)message atPulse:(NSInteger)pulse;

- (void) removeMessage:(MidiMessage*)message atPulse:(NSInteger)pulse;

- (NSArray*) messagesForPulse:(NSInteger)pulse;

- (CGFloat) progressForPulse:(NSInteger)pulse;

- (NSInteger) numberOfPulses;

@property (nonatomic, assign) Instrument instrument;

@end
