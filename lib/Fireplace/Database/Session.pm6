=begin pod

=head1 NAME

Fireplace::Database::Session - Session data storage.

=head1 SYNOPSIS

    use Fireplace::Database::Session;

    my $session := Fireplace::Database::Session.new;

    $session.enter(now, ‘foo’.encode);
    $session.leave(now);

    say $session.frames.perl;

=head1 DESCRIPTION

A session is a collection of information about serial subroutine calls. Each
subroutine call is represented by an I<enter>/I<leave> pair, each of which
includes timing information. An I<enter> entry records that a subroutine has
been called. A corresponding I<leave> entry records that the subroutine has
returned or thrown.

Note that the use of the word I<subroutine> in this context is very general:
it may include IPC or RPC calls or any other sort of invocation of a computer
program.

=end pod

unit class Fireplace::Database::Session;

use Fireplace::Database::Session::Frame;
use X::Fireplace::CausalityViolation;

my constant Frame = Fireplace::Database::Session::Frame;

my role Entry { has Instant $.instant; }
my class Enter does Entry { has Blob $.subroutine; }
my class Leave does Entry { }

#| Convenient function to create a frame from a pair of corresponding entries.
my sub frame(Int:D $depth, Enter:D $enter, Leave:D $leave --> Frame:D)
{
    Frame.new(
        :$depth,
        :subroutine($enter.subroutine),
        :enter($enter.instant),
        :leave($leave.instant),
    );
}

#| The entries for a session are stored in chronological order. This allows
#| them to be searched by time range easily.
has Entry @!entries;

#| To ensure that the chronological order of entries is preserved, the instant
#| of the latest entry is kept track of, so it can be compared with any new
#| entries that come in.
has Instant $!last;

#| Check the invariants of the session; should always return C<True>.
method invariant(::?CLASS:D: --> Bool:D)
{
    $!last.defined !^^ ?@!entries   and
    [≤] |@!entries».instant, $!last ;
}

#| Insert an entry into the session, ensuring that the invariants are
#| respected.
method !insert(::?CLASS:D: Entry:D $entry --> Nil)
{
    my $instant := $entry.instant;
    die(X::Fireplace::CausalityViolation.new)
        if defined($!last) && $instant < $!last;
    @!entries.push($entry);
    $!last = $instant;
}

#| Insert an I<enter> entry into the session. This records that a subroutine
#| has been called.
#|
#| O(1) time, O(1) space.
method enter(::?CLASS:D: Instant:D $instant, Blob:D $subroutine --> Nil)
{
    self!insert: Enter.new(:$instant, :$subroutine);
}

#| Insert a I<leave> entry into the session. This records that a subroutine
#| has returned or thrown.
#|
#| O(1) time, O(1) space.
method leave(::?CLASS:D: Instant:D $instant --> Nil)
{
    self!insert: Leave.new(:$instant);
}

#| Count how many times a particular subroutine was called within this
#| session.
#|
#| O(n) time, O(1) space.
method calls(::?CLASS:D: Blob:D $subroutine --> Int:D)
{
    @!entries
        .grep(Enter)
        .grep(*.subroutine eq $subroutine)
        .elems;
}

#| For each I<enter> that has a corresponding I<leave> in the session, the
#| returned sequence contains the frame of the call. The frames are returned
#| in chronological order of I<leaving>.
#|
#| This method is useful for drawing a timeline of the session.
#|
#| Θ(n) time, Θ(n) space.
method frames(::?CLASS:D: --> Seq:D)
{
    my Enter:D @stack;
    lazy gather for @!entries {
        @stack.push($_) when Enter;
        take frame(@stack.end, @stack.pop, $_) when Leave;
    }
}
