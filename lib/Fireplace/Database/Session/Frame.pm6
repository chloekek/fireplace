=begin pod

=head1 NAME

Fireplace::Database::Session::Frame - Call frames.

=head1 SYNOPSIS

    use Fireplace::Database::Session;

    my $session := Fireplace::Database::Session.new;
    $session.enter(now, ‘foo’.encode);
    $session.leave(now);

    my $frame := $session.frames[0];
    say $frame.depth;      # OUTPUT: «0␤»
    say $frame.subroutine; # OUTPUT: «foo␤»
    say $frame.enter;      # OUTPUT: «Instant:1␤»
    say $frame.leave;      # OUTPUT: «Instant:3␤»
    say $frame.timing;     # OUTPUT: «2␤»

=head1 DESCRIPTION

A frame corresponds to a particular subroutine call in a session. A frame is
an (enter, leave) pair, including the subroutine name and the timing
information. The depth of the frame is also included; this is its index in
the call stack at the point of entering. It is zero for the first call in the
session.

=end pod

unit class Fireplace::Database::Session::Frame;

has Int $.depth is required;
has Blob $.subroutine is required;
has Instant $.enter is required;
has Instant $.leave is required;

#| The amount of time the call took, from enter till leave.
method timing(::?CLASS:D: --> Duration:D)
{
    $!leave - $!enter;
}

=begin pod

=head1 SEE ALSO

The I<frames> method on the I<Fireplace::Database::Session> class.

=end pod
