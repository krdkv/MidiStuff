//
//  MidiClip.m
//  MidiEngine
//
//  Created by Nick on 07/11/2013.
//  Copyright (c) 2013 Nick. All rights reserved.
//

#import "MidiClip.h"
#import "MidiMessage.h"

#define kDefaultUpperTimeSignature 4
#define kDefaultLowerTimeSignature 4

#define kDefaultVelocity 80

#define kDefaultInstrument kSnare

@interface MidiClip() {
    NSInteger upperTimeSignature;
    NSInteger lowerTimeSignature;
    
    NSMutableDictionary * pulses;
    
    NSInteger numberOfPulsesPerBar;
    
    NSInteger numberOfBars;
}

- (void) addMessage:(MidiMessage*)message atPulse:(NSInteger)pulse;
- (void) removeMessage:(MidiMessage*)message atPulse:(NSInteger)pulse;
- (NSInteger) midiNoteForVerticalOffset:(NSInteger)offset;

@end

@implementation MidiClip

- (id)init
{
    return [self initWithNumberOfBars:3];
}

- (id) initWithNumberOfBars:(NSInteger)number {
    self = [super init];
    if (self) {
        upperTimeSignature = kDefaultUpperTimeSignature;
        lowerTimeSignature = kDefaultLowerTimeSignature;
        pulses = [[NSMutableDictionary alloc] init];
        
        numberOfBars = number;
        
        self.instrument = kDefaultInstrument;
        
        numberOfPulsesPerBar = ( kNumberOfPulsesPerQuarterNote * upperTimeSignature * 4 ) /
            lowerTimeSignature;
    }
    return self;
}

- (void) setNumberOfBars:(NSInteger)number {
    numberOfBars = number;
}

- (NSInteger) numberOfPulses {
    return numberOfBars * numberOfPulsesPerBar;
}

- (NSInteger) numberOfBars {
    return numberOfBars;
}

- (NSInteger) numberOfPulsesPerBar {
    return numberOfPulsesPerBar;
}

- (NSArray*) messagesForPulse:(NSInteger)pulse {
    
    if ( pulse < 0 ) {
        return nil;
    }
    
    while ( pulse >= [self numberOfPulses] ) {
        pulse -= [self numberOfPulses];
    }
    
    if ( pulse < 0 ) {
        return nil;
    }
    
    return pulses[@(pulse)];
}

- (CGFloat) progressForPulse:(NSInteger)pulse {
    
    while ( pulse >= [self numberOfPulses] ) {
        pulse -= [self numberOfPulses];
    }
    
    if ( pulse < 0 ) {
        return 0.f;
    }
    
    return (CGFloat)pulse / (CGFloat)([self numberOfPulses]);
}

#pragma mark Private

- (NSInteger) midiNoteForVerticalOffset:(NSInteger)offset {
    
    if ( self.instrument == kSnare ) {
        return 24 + offset;
    }
    
    if ( self.instrument == kArp ) {
        return 40 + offset;
    }
    
    return 24 + offset;
}

- (void) removeMessage:(MidiMessage*)message atPulse:(NSInteger)pulse {
    
    if ( pulse < 0 || pulse > [self numberOfPulses] ) {
        return;
    }
    
    NSMutableArray * messagesAtPulse = pulses[@(pulse)];
    
    if ( messagesAtPulse ) {
        for ( MidiMessage * currentMessage in messagesAtPulse ) {
            if ( [currentMessage isEqualToMessage:message] ) {
                [messagesAtPulse removeObject:currentMessage];
                if ( messagesAtPulse.count == 0 ) {
                    [pulses removeObjectForKey:@(pulse)];
                }
                break;
            }
        }
    }
}

- (void) addMessage:(MidiMessage*)message atPulse:(NSInteger)pulse {
    
    if ( pulse < 0 || pulse > [self numberOfPulses] ) {
        return;
    }
    
    if ( ! pulses[@(pulse)] ) {
        [pulses setObject:[[NSMutableArray alloc] init] forKey:@(pulse)];
    }
    
    [(NSMutableArray*)pulses[@(pulse)] addObject:message];
}

#pragma mark Cell related methods

- (void) setCellFilled:(BOOL)filled
  withHorizontalOffset:(NSInteger)hOffset
    withVerticalOffset:(NSInteger)vOffset {
    
    NSInteger pulse = hOffset * kNumberOfPulsesPerQuarterNote;
    
    NSInteger midiNote = [self midiNoteForVerticalOffset:vOffset];
    
    BOOL leftNeighbourExists = [self leftNeighbourExistsForCell:hOffset forNote:midiNote];
    BOOL rightNeighbourExists = [self rightNeighbourExistsForCell:hOffset forNote:midiNote];
    
    if ( filled ) {
        
        if ( ! leftNeighbourExists && ! rightNeighbourExists ) {
            
            [self addMessage:[MidiMessage messageWithType:kNoteOn midiKey:midiNote velocity:kDefaultVelocity] atPulse:pulse];
            [self addMessage:[MidiMessage messageWithType:kNoteOff midiKey:midiNote velocity:kDefaultVelocity] atPulse:pulse + kNumberOfPulsesPerQuarterNote - 1];
            
        } else if ( leftNeighbourExists && ! rightNeighbourExists ) {
            
            [self removeMessage:[MidiMessage messageWithType:kNoteOff midiKey:midiNote velocity:kDefaultVelocity] atPulse: pulse - 1];
            [self addMessage:[MidiMessage messageWithType:kNoteOff midiKey:midiNote velocity:kDefaultVelocity] atPulse:pulse + kNumberOfPulsesPerQuarterNote - 1];
            
        } else if ( ! leftNeighbourExists && rightNeighbourExists ) {
            
            [self removeMessage:[MidiMessage messageWithType:kNoteOn midiKey:midiNote velocity:kDefaultVelocity] atPulse:pulse + kNumberOfPulsesPerQuarterNote];
            [self addMessage:[MidiMessage messageWithType:kNoteOn midiKey:midiNote velocity:kDefaultVelocity] atPulse:pulse];
            
        } else {
            
            [self removeMessage:[MidiMessage messageWithType:kNoteOff midiKey:midiNote velocity:kDefaultVelocity] atPulse:pulse - 1];
            [self removeMessage:[MidiMessage messageWithType:kNoteOn midiKey:midiNote velocity:kDefaultVelocity] atPulse:pulse + kNumberOfPulsesPerQuarterNote];
            
        }
        
    } else {
        
        if ( ! leftNeighbourExists && ! rightNeighbourExists ) {
            
            [self removeMessage:[MidiMessage messageWithType:kNoteOn midiKey:midiNote velocity:kDefaultVelocity] atPulse:pulse];
            [self removeMessage:[MidiMessage messageWithType:kNoteOff midiKey:midiNote velocity:kDefaultVelocity] atPulse:pulse + kNumberOfPulsesPerQuarterNote - 1];
            
        } else if ( leftNeighbourExists && ! rightNeighbourExists ) {
            
            [self removeMessage:[MidiMessage messageWithType:kNoteOff midiKey:midiNote velocity:kDefaultVelocity] atPulse:pulse + kNumberOfPulsesPerQuarterNote - 1];
            [self addMessage:[MidiMessage messageWithType:kNoteOff midiKey:midiNote velocity:kDefaultVelocity] atPulse:pulse - 1];
            
        } else if ( ! leftNeighbourExists && rightNeighbourExists ) {

            [self removeMessage:[MidiMessage messageWithType:kNoteOn midiKey:midiNote velocity:kDefaultVelocity] atPulse:pulse];
            [self addMessage:[MidiMessage messageWithType:kNoteOn midiKey:midiNote velocity:kDefaultVelocity] atPulse:pulse + kNumberOfPulsesPerQuarterNote];
            
        } else {

            [self addMessage:[MidiMessage messageWithType:kNoteOff midiKey:midiNote velocity:kDefaultVelocity] atPulse:pulse - 1];
            [self addMessage:[MidiMessage messageWithType:kNoteOn midiKey:midiNote velocity:kDefaultVelocity] atPulse:pulse + kNumberOfPulsesPerQuarterNote];
            
        }
        
    }
    
    
}

- (BOOL) cellHasStartMessage:(NSInteger)cell withNote:(NSInteger)key {
    NSArray * startOfCellMessages = [self messagesForPulse:cell * kNumberOfPulsesPerQuarterNote];
    BOOL onMessageExists = NO;
    
    for ( MidiMessage * currentMesage in startOfCellMessages ) {
        if ( currentMesage.type == kNoteOn && currentMesage.midiKey == key ) {
            onMessageExists = YES;
            break;
        }
    }
    
    return onMessageExists;
}

- (BOOL) cellHasStopMessage:(NSInteger)cell withNote:(NSInteger)key {
    NSArray * stopOfCellMessages = [self messagesForPulse:(cell+1) * kNumberOfPulsesPerQuarterNote - 1];
    BOOL offMessageExists = NO;
    
    for ( MidiMessage * currentMesage in stopOfCellMessages ) {
        if ( currentMesage.type == kNoteOff && currentMesage.midiKey == key ) {
            offMessageExists = YES;
            break;
        }
    }
    
    return offMessageExists;
}

- (BOOL) leftNeighbourExistsForCell:(NSInteger)cell forNote:(NSInteger)note {
    
    NSInteger currentCell = cell - 1;
    
    while (currentCell >= 0) {
        
        BOOL onMessageExists  = [self cellHasStartMessage:currentCell withNote:note];
        BOOL offMessageExists = [self cellHasStopMessage:currentCell withNote:note];
        
        if ( currentCell == cell - 1 && (offMessageExists || onMessageExists) ) {
            return YES;
        }
        
        if ( currentCell != cell - 1 && offMessageExists ) {
            return NO;
        }
        
        if ( currentCell != cell - 1 && onMessageExists ) {
            return YES;
        }
        
        currentCell -= 1;
    }
    
    return NO;
    
}

- (BOOL) rightNeighbourExistsForCell:(NSInteger)cell forNote:(NSInteger)note {
    
    NSInteger currentCell = cell + 1;
    
    while ( currentCell < numberOfBars * ( upperTimeSignature * 4 / lowerTimeSignature ) ) {
        
        BOOL onMessageExists  = [self cellHasStartMessage:currentCell withNote:note];
        BOOL offMessageExists = [self cellHasStopMessage:currentCell withNote:note];
        
        if ( currentCell == cell + 1 && (onMessageExists || offMessageExists) ) {
            return YES;
        }
        
        if ( currentCell != cell + 1 && onMessageExists ) {
            return NO;
        }
        
        if ( currentCell != cell + 1 && offMessageExists ) {
            return YES;
        }
        
        currentCell += 1;
    }
    
    return NO;
    
}

- (NSInteger) numberOfCells {
    
    return numberOfBars * 4 * upperTimeSignature / lowerTimeSignature;
    
}

@end