=begin pod

=head1 NAME

X::Fireplace::CausalityViolation - Causality violation error.

=head1 DESCRIPTION

Thrown when attempting to insert an entry that happened earlier than an entry
inserted previously; inserts must happen in chronological order.

=end pod

unit class X::Fireplace::CausalityViolation;

also is Exception;
