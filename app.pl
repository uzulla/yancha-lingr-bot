use strict;
use utf8;
use warnings;
use FindBin;
use lib ("$FindBin::Bin/lib");
use AnyEvent::HTTP::Request;
use AnyEvent::Lingr;
use 5.010;
use Data::Dumper;
use URI::Escape;
use Encode;

binmode STDOUT, ':utf8';

my $config = do "$FindBin::Bin/config.pl";
my $fail_limit = 10;

my $done = AnyEvent->condvar;

my $tw_stream_listener;
my $create_listener;
my $listener_timer;
my $set_timer;

my $get_yancha_auth_token;
my $yancha_auth_token;
my $post_yancha_message;

#$post_yancha_message->("$tweet->{user}{screen_name}: $tweet->{text}");

my $lingr = AnyEvent::Lingr->new(
    user     => $config->{Lingr}->{userid},
    password => $config->{Lingr}->{password},
);


# error handler
$lingr->on_error(sub {
    my ($msg) = @_;
    warn 'Lingr error: ', $msg;

    if($msg=~/rate limited/){
        warn 'dont angry lingr, give up.';
        exit;
    }

    # reconnect after 5 seconds,
    $set_timer->(5);
});

# room info handler
$lingr->on_room_info(sub {
    my ($rooms) = @_;

    print "Joined rooms:\n";
    for my $room (@$rooms) {
        print "  $room->{id}\n";
    }
});

# event handler
$lingr->on_event(sub {
    my ($event) = @_;

    # print message
    if (my $msg = $event->{message}) {
        my $str = sprintf "[%s] %s: %s\n",
            $msg->{room}, $msg->{nickname}, $msg->{text};
        print $str;
        $post_yancha_message->($str);
    }
});

$set_timer = sub {
	my $after = shift || 0;

    if(0>$fail_limit--){
        warn "FAIL LIMIT OVER "; die;
        undef $lingr;
        die;
    }

	$listener_timer = AnyEvent->timer(
		after    => $after,
		cb => sub {
			say "connecting";
			undef $listener_timer;
			$lingr->start_session;
		},
	);
};

$get_yancha_auth_token = sub {
  my $req = AnyEvent::HTTP::Request->new({
    method => 'GET',
    uri  => $config->{YanchaUrl}.'/login?nick=lingrbot&token_only=1',
    cb   => sub {
    	my ($body, $headers) = shift;
    	$yancha_auth_token = $body;
    	say "yancha_auth_token: ".$yancha_auth_token;
    	if($yancha_auth_token){
    		$set_timer->(0);
    	}
    }
  });

  my $http_req = $req->to_http_message;
  $req->send();
};

$post_yancha_message = sub {
	my $message = shift;
	$message =~ s/#/＃/g;
	my $req = AnyEvent::HTTP::Request->new({
	    method => 'GET',
	    uri  => $config->{YanchaUrl}.'/api/post?token='.$yancha_auth_token.'&text='.uri_escape_utf8($message),
	    cb   => sub {
	    	my ($body, $headers) = shift;
	    	say "past yancha: \"".$message."\" yancha return-> ".$body;
	    	#TODO TOKEN失効時にTOKENを更新する必要がある。
	    }
  	});
	my $http_req = $req->to_http_message;
	$req->send();
};

say "start server";
$get_yancha_auth_token->();

$done->recv;
