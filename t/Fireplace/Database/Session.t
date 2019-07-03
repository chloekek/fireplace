use Fireplace::Database::Session;
use Test;
use X::Fireplace::CausalityViolation;

sub now { Instant.from-posix(++$) }
sub postfix:«b» { $^s.encode }

subtest ‘empty session satisfies invariants’ => {
    my $session := Fireplace::Database::Session.new;
    ok($session.invariant);
}

subtest ‘enter does not violate causality’ => {
    my $session := Fireplace::Database::Session.new;
    my ($t1, $t2) := now, now;
    $session.enter($t2, ‘foo’b);
    try $session.enter($t1, ‘foo’b);
    cmp-ok($!, ‘~~’, X::Fireplace::CausalityViolation);
    ok($session.invariant);
}

subtest ‘leave does not violate causality’ => {
    my $session := Fireplace::Database::Session.new;
    my ($t1, $t2) := now, now;
    $session.enter($t2, ‘foo’b);
    try $session.leave($t1);
    cmp-ok($!, ‘~~’, X::Fireplace::CausalityViolation);
    ok($session.invariant);
}

subtest ‘enter increases the call count of the subroutine’ => {
    my $session := Fireplace::Database::Session.new;
    cmp-ok($session.calls(‘foo’b), ‘==’, 0);
    cmp-ok($session.calls(‘bar’b), ‘==’, 0);
    $session.enter(now, ‘foo’b);
    $session.enter(now, ‘foo’b);
    $session.enter(now, ‘bar’b);
    $session.leave(now);
    cmp-ok($session.calls(‘foo’b), ‘==’, 2);
    cmp-ok($session.calls(‘bar’b), ‘==’, 1);
}

subtest ‘frames returns the frames of an example’ => {
    my $session := Fireplace::Database::Session.new;
    $session.enter(now, ‘foo’b);
    $session.enter(now, ‘bar’b);
    $session.leave(now);
    $session.enter(now, ‘baz’b);
    $session.leave(now);
    $session.leave(now);

    my @frames = $session.frames.map({ (.depth, .subroutine, .timing) });
    my @expected = (1, ‘bar’b, Duration.new(1)),
                   (1, ‘baz’b, Duration.new(1)),
                   (0, ‘foo’b, Duration.new(5));
    cmp-ok(@frames.eager, ‘eqv’, @expected);
}

done-testing;
