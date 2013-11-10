//
//  MidiMessage.h
//  MidiEngine
//
//  Created by Nick on 07/11/2013.
//  Copyright (c) 2013 Nick. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    kNoteOn,
    kNoteOff
} MidiMessageType;

@interface MidiMessage : NSObject

+ (MidiMessage*) messageWithType:(MidiMessageType)type
                        midiKey:(NSInteger)midiKey
                       velocity:(NSInteger)velocity;

- (BOOL) isEqualToMessage:(MidiMessage*)message;

@property (nonatomic, assign) MidiMessageType type;
@property (nonatomic, assign) NSInteger midiKey;
@property (nonatomic, assign) NSInteger velocity;

@end
