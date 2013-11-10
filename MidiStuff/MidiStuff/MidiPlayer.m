//
//  MidiPlayer.m
//  MidiEngine
//
//  Created by Nick on 07/11/2013.
//  Copyright (c) 2013 Nick. All rights reserved.
//

#import "MidiPlayer.h"
#import <AudioToolbox/AudioToolbox.h>
#import "MidiMessage.h"

enum {
	kMIDIMessage_NoteOn    = 0x9,
	kMIDIMessage_NoteOff   = 0x8,
};

@interface MidiPlayer()

@property (readwrite) Float64   graphSampleRate;
@property (readwrite) AUGraph   processingGraph;
@property (readwrite) AudioUnit arpUnit;
@property (readwrite) AudioUnit hornUnit;
@property (readwrite) AudioUnit snareUnit;
@property (readwrite) AudioUnit ioUnit;
@property (readwrite) AudioUnit mixerUnit;

- (OSStatus)    loadSynthFromPresetURL:(NSURL *)presetURL toAudioUnit:(AudioUnit)unit;
- (void)        registerForUIApplicationNotifications;
- (BOOL)        createAUGraph;
- (void)        configureAndStartAudioProcessingGraph: (AUGraph) graph;
- (void)        stopAudioProcessingGraph;
- (void)        restartAudioProcessingGraph;

@end

@implementation MidiPlayer

@synthesize graphSampleRate     = _graphSampleRate;
@synthesize arpUnit             = _arpUnit;
@synthesize hornUnit            = _hornUnit;
@synthesize snareUnit           = _snareUnit;
@synthesize ioUnit              = _ioUnit;
@synthesize processingGraph     = _processingGraph;

- (id)init
{
    self = [super init];
    if (self) {
        [self setupAudioSession];
        [self createAUGraph];
        [self configureAndStartAudioProcessingGraph:self.processingGraph];
        [self loadPresets];
        [self registerForUIApplicationNotifications];
    }
    return self;
}

- (void) forwardMessage:(MidiMessage*)message
         withInstrument:(Instrument)instrument {
    
    
    //    onVelocity += 50;
    
	UInt32 noteCommand;
    
    switch (message.type) {
        case kNoteOn:
            noteCommand = kMIDIMessage_NoteOn << 4 | 0;
            break;
            
        case kNoteOff:
        default:
            noteCommand = kMIDIMessage_NoteOff << 4 | 0;
            break;
    }
    
    AudioUnit unit;
    
    switch (instrument) {
        case kArp:
            unit = self.arpUnit;
            break;
        case kSnare:
            unit = self.snareUnit;
            break;
        case kHorn:
        default:
            unit = self.hornUnit;
            break;
    }
    
	MusicDeviceMIDIEvent (unit, noteCommand, (UInt32)message.midiKey, (UInt32)message.velocity, 0);
}

- (BOOL) createAUGraph {
    
	OSStatus result = noErr;
	AUNode arpNode, hornNode, snareNode, ioNode, mixerNode;
    
	AudioComponentDescription cd = {};
	cd.componentManufacturer     = kAudioUnitManufacturer_Apple;
	cd.componentFlags            = 0;
	cd.componentFlagsMask        = 0;
    
	result = NewAUGraph (&_processingGraph);
    NSCAssert (result == noErr, @"Unable to create an AUGraph object. Error code: %d '%.4s'", (int) result, (const char *)&result);
    
	cd.componentType = kAudioUnitType_MusicDevice;
	cd.componentSubType = kAudioUnitSubType_Sampler;
	
	result = AUGraphAddNode (self.processingGraph, &cd, &arpNode);
    NSCAssert (result == noErr, @"Unable to add the Sampler unit to the audio processing graph. Error code: %d '%.4s'", (int) result, (const char *)&result);
    
	result = AUGraphAddNode (self.processingGraph, &cd, &hornNode);
    NSCAssert (result == noErr, @"Unable to add the Sampler unit to the audio processing graph. Error code: %d '%.4s'", (int) result, (const char *)&result);
    
	result = AUGraphAddNode (self.processingGraph, &cd, &snareNode);
    NSCAssert (result == noErr, @"Unable to add the Sampler unit to the audio processing graph. Error code: %d '%.4s'", (int) result, (const char *)&result);
    
    cd.componentType = kAudioUnitType_Mixer;
    cd.componentSubType = kAudioUnitSubType_MultiChannelMixer;
    
    result = AUGraphAddNode(self.processingGraph, &cd, &mixerNode);
    
	cd.componentType = kAudioUnitType_Output;
	cd.componentSubType = kAudioUnitSubType_RemoteIO;
    
	result = AUGraphAddNode (self.processingGraph, &cd, &ioNode);
    NSCAssert (result == noErr, @"Unable to add the Output unit to the audio processing graph. Error code: %d '%.4s'", (int) result, (const char *)&result);
    
	result = AUGraphOpen (self.processingGraph);
    NSCAssert (result == noErr, @"Unable to open the audio processing graph. Error code: %d '%.4s'", (int) result, (const char *)&result);
    
	result = AUGraphConnectNodeInput (self.processingGraph, arpNode, 0, mixerNode, 0);
    NSCAssert (result == noErr, @"Unable to interconnect the nodes in the audio processing graph. Error code: %d '%.4s'", (int) result, (const char *)&result);
    
	result = AUGraphConnectNodeInput (self.processingGraph, hornNode, 0, mixerNode, 1);
    NSCAssert (result == noErr, @"Unable to interconnect the nodes in the audio processing graph. Error code: %d '%.4s'", (int) result, (const char *)&result);
    
    result = AUGraphConnectNodeInput (self.processingGraph, snareNode, 0, mixerNode, 2);
    NSCAssert (result == noErr, @"Unable to interconnect the nodes in the audio processing graph. Error code: %d '%.4s'", (int) result, (const char *)&result);
    
	result = AUGraphConnectNodeInput (self.processingGraph, mixerNode, 0, ioNode, 0);
    NSCAssert (result == noErr, @"Unable to interconnect the nodes in the audio processing graph. Error code: %d '%.4s'", (int) result, (const char *)&result);
    
	result = AUGraphNodeInfo (self.processingGraph, arpNode, 0, &_arpUnit);
    NSCAssert (result == noErr, @"Unable to obtain a reference to the Sampler unit. Error code: %d '%.4s'", (int) result, (const char *)&result);

	result = AUGraphNodeInfo (self.processingGraph, hornNode, 0, &_hornUnit);
    NSCAssert (result == noErr, @"Unable to obtain a reference to the Sampler unit. Error code: %d '%.4s'", (int) result, (const char *)&result);
    
	result = AUGraphNodeInfo (self.processingGraph, snareNode, 0, &_snareUnit);
    NSCAssert (result == noErr, @"Unable to obtain a reference to the Sampler unit. Error code: %d '%.4s'", (int) result, (const char *)&result);
    
	result = AUGraphNodeInfo (self.processingGraph, mixerNode, 0, &_mixerUnit);
    NSCAssert (result == noErr, @"Unable to obtain a reference to the Mixer unit. Error code: %d '%.4s'", (int) result, (const char *)&result);
    
	result = AUGraphNodeInfo (self.processingGraph, ioNode, 0, &_ioUnit);
    NSCAssert (result == noErr, @"Unable to obtain a reference to the I/O unit. Error code: %d '%.4s'", (int) result, (const char *)&result);
    
    return YES;
}

- (void) configureAndStartAudioProcessingGraph: (AUGraph) graph {
    
    OSStatus result = noErr;
    UInt32 framesPerSlice = 0;
    UInt32 framesPerSlicePropertySize = sizeof (framesPerSlice);
    UInt32 sampleRatePropertySize = sizeof (self.graphSampleRate);
    
    result = AudioUnitInitialize (self.ioUnit);
    NSCAssert (result == noErr, @"Unable to initialize the I/O unit. Error code: %d '%.4s'", (int) result, (const char *)&result);
    
    result = AudioUnitSetProperty ( self.ioUnit, kAudioUnitProperty_SampleRate, kAudioUnitScope_Output, 0, &_graphSampleRate, sampleRatePropertySize);
    NSAssert (result == noErr, @"AudioUnitSetProperty (set Sampler unit output stream sample rate). Error code: %d '%.4s'", (int) result, (const char *)&result);
    
    result =    AudioUnitGetProperty ( self.ioUnit, kAudioUnitProperty_MaximumFramesPerSlice, kAudioUnitScope_Global, 0, &framesPerSlice, &framesPerSlicePropertySize);
    NSCAssert (result == noErr, @"Unable to retrieve the maximum frames per slice property from the I/O unit. Error code: %d '%.4s'", (int) result, (const
                                                                                                                                                     
                                                                                                                                                     
                                                                                                                                                     char *)&result);
    
    result =    AudioUnitSetProperty ( self.arpUnit, kAudioUnitProperty_SampleRate, kAudioUnitScope_Output, 0, &_graphSampleRate, sampleRatePropertySize);
    NSAssert (result == noErr, @"AudioUnitSetProperty (set Sampler unit output stream sample rate). Error code: %d '%.4s'", (int) result, (const char *)&result);
    
    result =    AudioUnitSetProperty ( self.hornUnit, kAudioUnitProperty_SampleRate, kAudioUnitScope_Output, 0, &_graphSampleRate, sampleRatePropertySize);
    NSAssert (result == noErr, @"AudioUnitSetProperty (set Sampler unit output stream sample rate). Error code: %d '%.4s'", (int) result, (const char *)&result);
    
    result =    AudioUnitSetProperty ( self.snareUnit, kAudioUnitProperty_SampleRate, kAudioUnitScope_Output, 0, &_graphSampleRate, sampleRatePropertySize);
    NSAssert (result == noErr, @"AudioUnitSetProperty (set Sampler unit output stream sample rate). Error code: %d '%.4s'", (int) result, (const char *)&result);
    
    
    
    
    result = AudioUnitSetProperty ( self.arpUnit, kAudioUnitProperty_MaximumFramesPerSlice, kAudioUnitScope_Global, 0, &framesPerSlice, framesPerSlicePropertySize );
    NSAssert( result == noErr, @"AudioUnitSetProperty (set Sampler unit maximum frames per slice). Error code: %d '%.4s'", (int) result, (const char *)&result);
    
    result = AudioUnitSetProperty ( self.hornUnit, kAudioUnitProperty_MaximumFramesPerSlice, kAudioUnitScope_Global, 0, &framesPerSlice, framesPerSlicePropertySize );
    NSAssert( result == noErr, @"AudioUnitSetProperty (set Sampler unit maximum frames per slice). Error code: %d '%.4s'", (int) result, (const char *)&result);
    
    result = AudioUnitSetProperty ( self.snareUnit, kAudioUnitProperty_MaximumFramesPerSlice, kAudioUnitScope_Global, 0, &framesPerSlice, framesPerSlicePropertySize );
    NSAssert( result == noErr, @"AudioUnitSetProperty (set Sampler unit maximum frames per slice). Error code: %d '%.4s'", (int) result, (const char *)&result);
    
    if (graph) {
        
        result = AUGraphInitialize (graph);
        NSAssert (result == noErr, @"Unable to initialze AUGraph object. Error code: %d '%.4s'", (int) result, (const char *)&result);
        
        result = AUGraphStart (graph);
        NSAssert (result == noErr, @"Unable to start audio processing graph. Error code: %d '%.4s'", (int) result, (const char *)&result);
        
        CAShow (graph);
    }
}

- (void)loadPresets {
    
    NSURL *presetURL = [[NSURL alloc] initFileURLWithPath:[[NSBundle mainBundle] pathForResource:@"arp" ofType:@"aupreset"]];
    [self loadSynthFromPresetURL:presetURL toAudioUnit:self.arpUnit];
    
    presetURL = [[NSURL alloc] initFileURLWithPath:[[NSBundle mainBundle] pathForResource:@"horn" ofType:@"aupreset"]];
    [self loadSynthFromPresetURL:presetURL toAudioUnit:self.hornUnit];
    
    presetURL = [[NSURL alloc] initFileURLWithPath:[[NSBundle mainBundle] pathForResource:@"snare" ofType:@"aupreset"]];
    [self loadSynthFromPresetURL:presetURL toAudioUnit:self.snareUnit];
}

- (OSStatus)    loadSynthFromPresetURL:(NSURL *)presetURL toAudioUnit:(AudioUnit)unit {
    
	CFDataRef propertyResourceData = 0;
	Boolean status;
	SInt32 errorCode = 0;
	OSStatus result = noErr;
	
	status = CFURLCreateDataAndPropertiesFromResource (
       kCFAllocatorDefault,
       (__bridge CFURLRef) presetURL,
       &propertyResourceData,
       NULL,
       NULL,
       &errorCode
    );
    
    NSAssert (status == YES && propertyResourceData != 0, @"Unable to create data and properties from a preset. Error code: %d '%.4s'", (int) errorCode, (const char *)&errorCode);
   	
	CFPropertyListRef presetPropertyList = 0;
	CFPropertyListFormat dataFormat = 0;
	CFErrorRef errorRef = 0;
	presetPropertyList = CFPropertyListCreateWithData (
                                                       kCFAllocatorDefault,
                                                       propertyResourceData,
                                                       kCFPropertyListImmutable,
                                                       &dataFormat,
                                                       &errorRef
                                                       );
    
	if (presetPropertyList != 0) {
        
		result = AudioUnitSetProperty(
          unit,
          kAudioUnitProperty_ClassInfo,
          kAudioUnitScope_Global,
          0,
          &presetPropertyList,
          sizeof(CFPropertyListRef)
        );
        
		CFRelease(presetPropertyList);
	}
    
    if (errorRef) CFRelease(errorRef);
	CFRelease (propertyResourceData);
    
	return result;
}

- (BOOL) setupAudioSession {
    
    AVAudioSession *mySession = [AVAudioSession sharedInstance];
    [mySession setDelegate: self];
    NSError *audioSessionError = nil;
    [mySession setCategory: AVAudioSessionCategoryPlayback error: &audioSessionError];
    if (audioSessionError != nil) {
        NSLog (@"Error setting audio session category."); return NO;
    }

    self.graphSampleRate = 44100.0;    // Hertz
    
    [mySession setPreferredHardwareSampleRate: self.graphSampleRate error: &audioSessionError];
    if (audioSessionError != nil) {NSLog (@"Error setting preferred hardware sample rate."); return NO;}
    
    [mySession setActive: YES error: &audioSessionError];
    if (audioSessionError != nil) {NSLog (@"Error activating the audio session."); return NO;}
    
    self.graphSampleRate = [mySession currentHardwareSampleRate];
    
    return YES;
}

- (void) stopAudioProcessingGraph {
    
    OSStatus result = noErr;
	if (self.processingGraph) result = AUGraphStop(self.processingGraph);
    NSAssert (result == noErr, @"Unable to stop the audio processing graph. Error code: %d '%.4s'", (int) result, (const char *)&result);
}

- (void) restartAudioProcessingGraph {
    
    OSStatus result = noErr;
	if (self.processingGraph) result = AUGraphStart (self.processingGraph);
    NSAssert (result == noErr, @"Unable to restart the audio processing graph. Error code: %d '%.4s'", (int) result, (const char *)&result);
}


#pragma mark -
#pragma mark Audio session delegate methods

- (void) beginInterruption {

    [self stopAudioProcessingGraph];
}


- (void) endInterruptionWithFlags: (NSUInteger) flags {
    
    NSError *endInterruptionError = nil;
    [[AVAudioSession sharedInstance] setActive: YES
                                         error: &endInterruptionError];
    if (endInterruptionError != nil) {
        
        NSLog (@"Unable to reactivate the audio session.");
        return;
    }
    
    if (flags & AVAudioSessionInterruptionFlags_ShouldResume) {
        [self restartAudioProcessingGraph];
    }
}


#pragma mark - Application state management

- (void) registerForUIApplicationNotifications {
    
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    
    [notificationCenter addObserver: self
                           selector: @selector (handleResigningActive:)
                               name: UIApplicationWillResignActiveNotification
                             object: [UIApplication sharedApplication]];
    
    [notificationCenter addObserver: self
                           selector: @selector (handleBecomingActive:)
                               name: UIApplicationDidBecomeActiveNotification
                             object: [UIApplication sharedApplication]];
}


- (void) handleResigningActive: (id) notification {
    
    [self stopAudioProcessingGraph];
}


- (void) handleBecomingActive: (id) notification {
    
    [self restartAudioProcessingGraph];
}

@end
