use Test;
use ØMQ;

sub postfix:«b» { $^s.encode }

subtest ‘pub–sub interactions complete’ => {
    my $endpoint := ‘inproc://foo’;
    my $recv-size := 4;
    my %messages{Blob:D} =
        ‘’b       => ‘’b     ,
        ‘foo’b    => ‘foo’b  ,
        ‘foobar’b => ‘foob’b ;

    my $context := ØMQ::ctx-new();

    my $sub-socket := ØMQ::socket($context, ØMQ::SUB);
    ØMQ::bind($sub-socket, $endpoint);
    ØMQ::setsockopt($sub-socket, ØMQ::SUBSCRIBE, ‘’b);

    my $pub-socket := ØMQ::socket($context, ØMQ::PUB);
    ØMQ::connect($pub-socket, $endpoint);

    Thread.start: {
        sleep(0.1);
        ØMQ::send($pub-socket, $_, 0)
            for %messages.keys;
    };

    for %messages.values {
        my $message := ØMQ::recv($sub-socket, $recv-size, 0);
        cmp-ok($message, ‘eq’, $_);
    }
}

done-testing;
