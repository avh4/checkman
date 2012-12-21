#import "Checkfile.h"
#import "CheckfileEntry.h"

@interface Checkfile ()
@property (strong, nonatomic) NSString *resolvedFilePath;
@property (strong, nonatomic) NSArray *entries;
@property (strong, nonatomic) FSChangesNotifier *fsChangesNotifier;
@end

@implementation Checkfile

@synthesize
    delegate = _delegate,
    resolvedFilePath = _resolvedFilePath,
    entries = _entries,
    fsChangesNotifier = _fsChangesNotifier;

- (id)initWithFilePath:(NSString *)filePath fsChangesNotifier:(FSChangesNotifier *)fsChangesNotifier {
    if (self = [super init]) {
        self.resolvedFilePath = [filePath stringByResolvingSymlinksInPath];
        self.fsChangesNotifier = fsChangesNotifier;        
    }
    return self;
}

- (void)dealloc {
    [self.fsChangesNotifier stopNotifying:self];
}

- (NSString *)resolvedDirectoryPath {
    return [self.resolvedFilePath stringByDeletingLastPathComponent];
}

- (void)trackChanges {
    // avoid immediately populating entries to avoid 
    // populating entries as part of CheckfileCollection delegate calls
    [self performSelector:@selector(_startTrackingChanges) withObject:nil afterDelay:0 
                  inModes:[NSArray arrayWithObjects:NSRunLoopCommonModes, NSEventTrackingRunLoopMode, nil]];
}

- (void)_startTrackingChanges {
    [self _reloadEntries];
    [self.fsChangesNotifier startNotifying:self forFilePath:self.resolvedFilePath];
}

- (NSUInteger)indexOfEntry:(CheckfileEntry *)entry {
    return [self.entries indexOfObject:entry];
}

- (void)_reloadEntries {
    for (CheckfileEntry *entry in self.entries) {
        [self.delegate checkfile:self willRemoveEntry:entry];
    }
    self.entries = self._loadEntries;
    for (CheckfileEntry *entry in self.entries) {
        [self.delegate checkfile:self didAddEntry:entry];
    }
}

- (NSArray *)_loadEntries {
    NSError *error = nil;
    NSString *fileContents = [NSString stringWithContentsOfFile:self.resolvedFilePath encoding:NSUTF8StringEncoding error:&error];

    if (error) {
        NSLog(@"Checkfile - error: %@", error);
        return nil;
    } else {
        NSLog(@"Checkfile - read: %@", self.resolvedFilePath);
    }

    NSArray *lines = [fileContents componentsSeparatedByString:@"\n"];
    NSMutableArray *entries = [[NSMutableArray alloc] init];

    for (NSString *line in lines) {
        CheckfileEntry *entry = [CheckfileEntry fromLine:line];
        if (entry) [entries addObject:entry];
    }
    return entries;
}

#pragma mark - FSChangesNotifierDelegate

- (void)fsChangesNotifier:(FSChangesNotifier *)notifier filePathDidChange:(NSString *)filePath {
    [self _reloadEntries];
}

@end
