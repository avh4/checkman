#import "CheckCollection.h"
#import "Check.h"

@interface CheckCollection ()
@property (nonatomic, strong) NSMutableArray *checks;
@property (nonatomic, assign) CheckStatus status;
@property (nonatomic, assign, getter = isRunning) BOOL running;
@end

@implementation CheckCollection

@synthesize
    delegate = _delegate,
    checks = _checks,
    status = _status,
    running = _running;

- (id)init {
    if (self = [super init]) {
        self.checks = [NSMutableArray array];
        self.status = CheckStatusUndetermined;
        self.running = NO;
    }
    return self;
}

- (void)dealloc {
    for (Check *check in self.checks) {
        [self removeCheck:check];
    }
}

#pragma mark -

- (void)addCheck:(Check *)check {
    [self.checks addObject:check];
    [check addObserverForStatusAndRunning:self];
    [self.delegate checkCollection:self didAddCheck:check];
}

- (void)removeCheck:(Check *)check {
    [self.delegate checkCollection:self willRemoveCheck:check];
    [check removeObserverForStatusAndRunning:self];
    [self.checks removeObject:check];
}

- (NSUInteger)indexOfCheck:(Check *)check {
    return [self.checks indexOfObject:check];
}

- (Check *)checkWithTag:(NSInteger)tag {
    for (Check *check in self.checks) {
        if (check.tag == tag) return check;
    }
    return nil;
}

#pragma mark -

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    self.status = [self updateStatus];
    self.running = [self updateRunning];
    [self.delegate checkCollectionStatusAndRunningDidChange:self];
}

- (CheckStatus)updateStatus {
    for (Check *check in self.checks) {
        if (check.status == CheckStatusFail) return CheckStatusFail;
        if (check.status == CheckStatusUndetermined) return CheckStatusUndetermined;
    }
    return CheckStatusOk;
}

- (BOOL)updateRunning {
    for (Check *check in self.checks) {
        if (check.isRunning) return YES;
    }
    return NO;
}

- (NSString *)statusDescription {
    if (self.status == CheckStatusFail || self.status == CheckStatusUndetermined) {
        int count = [self numberOfChecksWithStatus:self.status];
        return [NSString stringWithFormat:@"%d", count];
    }
    return nil;
}

- (int)numberOfChecksWithStatus:(CheckStatus)status {
    int count = 0;
    for (Check *check in self.checks) {
        if (check.status == status) count++;
    }
    return count;
}

@end
