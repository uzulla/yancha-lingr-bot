#!perl

use strict;
use utf8;
use warnings;
use AnyEvent::HTTP::Request;
use AnyEvent::Lingr;
use FindBin;
use Yancha::Bot;
use 5.010;

binmode STDOUT, ':utf8';

my $done = AnyEvent->condvar;

my $config = do "$FindBin::Bin/config.pl";
my $lingr = AnyEvent::Lingr->new(
    user     => $config->{Lingr}->{userid},
    password => $config->{Lingr}->{password},
);

my $bot = Yancha::Bot->new( $config, $lingr->start_session );

# error handler
$lingr->on_error(
    sub {
        my ($msg) = @_;
        warn 'Lingr error: ', $msg;

        if ( $msg =~ /rate limited/ ) {
            warn 'dont angry lingr, give up.';
            exit;
        }

        # reconnect after 5 seconds,
        $bot->callback_later(5);
    }
);

# room info handler
$lingr->on_room_info(
    sub {
        my ($rooms) = @_;

        print "Joined rooms:\n";
        for my $room (@$rooms) {
            print "  $room->{id}\n";
        }
    }
);

# event handler
$lingr->on_event(
    sub {
        my ($event) = @_;

        # print message
        if ( my $msg = $event->{message} ) {
            my $str = sprintf "[%s] %s: %s\n",
              $msg->{room}, $msg->{nickname}, $msg->{text};
            if ( $str !~ $config->{ExcludeFilterREGEXP} ) {
                print $str;
                $bot->post_yancha_message($str);
            }
        }
    }
);

say "start server";
$bot->up();

$done->recv;
