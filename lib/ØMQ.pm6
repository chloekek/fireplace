=begin pod

=head1 NAME

ØMQ - Binding to libzmq.

=head1 SYNOPSIS

    use ØMQ;

    my $context := ØMQ::ctx_new();

    my $pub := ØMQ::socket($context, ØMQ::PUB);
    ØMQ::send($pub, ‘foo’.encode, 0);

    my $sub := ØMQ::socket($context, ØMQ::SUB);
    ØMQ::setsockopt($sub, ØMQ::SUBSCRIBE, ‘’.encode);
    say ØMQ::recv($sub, 512, 0);

=head1 DESCRIPTION

The ØMQ module provides a memory-safe binding to libzmq. The interface is
identical to that of libzmq, except for the following differences:

=item
The I<ZMQ_> and I<zmq_> prefixes are dropped from all names, and hyphens are
substituted for underscores.

=item
Pointers and lengths are not specified separately, but rather through Blob
and Str arguments.

=item
Failures and exceptions are thrown in case something goes wrong, so that the
caller does not need to check a return code and errno.

=end pod

unit module ØMQ;

use NativeCall;

#`[ Foreign declarations ]

my constant L = ‘zmq’;

our class Context is repr(‘CPointer’) {…}
our class Socket is repr(‘CPointer’) {…}

my sub zmq_bind(Socket, Str --> int32) is native(L) {*}
my sub zmq_close(Socket --> int32) is native(L) {*}
my sub zmq_connect(Socket, Str --> int32) is native(L) {*}
my sub zmq_ctx_new(--> Context) is native(L) {*}
my sub zmq_ctx_term(Context --> int32) is native(L) {*}
my sub zmq_recv(Socket, Pointer, size_t, int32 --> int32) is native(L) {*}
my sub zmq_send(Socket, Pointer, size_t, int32 --> int32) is native(L) {*}
my sub zmq_setsockopt(Socket, int32, Pointer, size_t --> int32) is native(L) {*}
my sub zmq_socket(Context, int32 --> Socket) is native(L) {*}

#`[ Constants ]

our constant PUB = 1;
our constant SUB = 2;

our constant SUBSCRIBE = 6;

#`[ RAII wrappers ]

our class Context { submethod DESTROY { zmq_ctx_term(self) } }
our class Socket { submethod DESTROY { zmq_close(self) } }

#`[ Subroutine wrappers ]

our sub bind(Socket:D $socket, Str:D $endpoint --> Nil)
{
    zmq_bind($socket, $endpoint)
        == −1 and die(‘zmq_bind’);
}

our sub connect(Socket:D $socket, Str:D $endpoint --> Nil)
{
    zmq_connect($socket, $endpoint)
        == −1 and die(‘zmq_connect’);
}

our sub ctx-new(--> Context:D)
{
    zmq_ctx_new()
        orelse fail(‘zmq_ctx_new’);
}

our sub recv(Socket:D $socket, Int:D $len, Int:D $flags --> Blob:D)
{
    my $buf := Blob.allocate($len);
    my $n := zmq_recv($socket, nativecast(Pointer, $buf), $len, $flags);
    $n == −1 and fail ‘zmq_recv’;
    $buf.subbuf(^$n);
}

our sub send(Socket:D $socket, Blob:D $buf, Int:D $flags --> Nil)
{
    zmq_send($socket, nativecast(Pointer, $buf), $buf.elems, $flags)
        == −1 and die(‘zmq_send’);
}

our proto sub setsockopt(Socket:D $socket, Int:D $name, Any $value) {*}
our multi sub setsockopt(Socket:D $socket, Int:D $name, Blob:D $value)
{
    zmq_setsockopt($socket, $name, nativecast(Pointer, $value), $value.elems)
        == −1 and die(‘zmq_setsockopt’);
}

our sub socket(Context:D $context, Int:D $type --> Socket:D)
{
    zmq_socket($context, $type)
        orelse fail(‘zmq_socket’);
}

=begin pod

=head1 BUGS

Not all sockets created with libzmq are thread-safe, and this module does not
take extra measures to ensure thread-safety.

Reported errors are not very descriptive; they only include the name of the
function that failed.

=end pod
