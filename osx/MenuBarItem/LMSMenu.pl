#!../MacOS/perl -Iserver/CPAN -Iserver -I.

use strict;

use File::Spec::Functions qw(catfile);
use IO::Socket::INET;
use JSON::PP;

use LMSMenuAction;

binmode(STDOUT, ":utf8");
our $STRINGS = decode_json(do {
    local $/ = undef;
    open my $fh, "<", 'LMSMenu.json'
        or die "could not open LMSMenu.json: $!";
    <$fh>;
});

my $lang = uc(substr(`/usr/bin/defaults read -g AppleLocale` || 'EN', 0, 2));

use constant PRODUCT_NAME => 'Squeezebox';
# use constant LOG_FOLDER => catdir($ENV{HOME}, 'Library', 'Logs', PRODUCT_NAME);
use constant PREFS_FILE => catfile($ENV{HOME}, 'Library', 'Application Support', PRODUCT_NAME, 'server.prefs');

sub getPort {
	my $port = getPref('httpport');
	my $remote = IO::Socket::INET->new(
		Proto    => 'tcp',
		PeerAddr => '127.0.0.1',
		PeerPort => $port,
	);

	if ( $remote ) {
		close $remote;
		return $port;
	}

	return;
}

sub isProcessRunning {
	return `ps -axww | grep "slimserver.pl" | grep -v grep`;
}

sub getUpdate {
	my $updatesFile = getVersionFile();
	my $update;

	if (-r $updatesFile) {
		open(UPDATE, '<', $updatesFile) or return;

		while (<UPDATE>) {
			chomp;
			if ($_ && -r $_) {
				$update = $_;
				last;
			}
		}

		close(UPDATE);
	}

	return $update;
}

sub getVersionFile {
	return catfile(main::getPref('cachedir'), 'updates', 'server.version')
}

sub getPref {
	my $pref = shift;
	my $ret;

	if (-r PREFS_FILE) {
		open(PREF, '<', PREFS_FILE) or return;

		while (<PREF>) {
			if (/^$pref: ['"]?(.*)['"]?/) {
				$ret = $1;
				$ret =~ s/^['"]//;
				$ret =~ s/['"\s]*$//s;
				last;
			}
		}

		close(PREF);
	}

	return $ret;
}

sub getString {
	my ($token) = @_;
	return $STRINGS->{$token}->{$lang} || $STRINGS->{$token}->{EN};
}

sub serverRequest {
	my $port = shift;

	my $postdata;
	eval { $postdata = '{"id":1,"method":"slim.request","params":["",' . encode_json(\@_) . ']}' };

	return if $@ || !$postdata;

	require HTTP::Tiny;

	HTTP::Tiny->new(
		timeout => 2,
	)->request('POST', "http://127.0.0.1:$port/jsonrpc.js", {
		headers => {
			'Content-Type' => 'application/json',
		},
		content => $postdata,
	});

	# Should we ever be interested in the result, uncomment the following lines:
	# my $content = $res->{content} if $res->{success};
	# if ($content) {
	# 	eval {
	# 		$content = decode_json($content);
	# 	}
	# }

	# return $content;
}

sub printMenuItem {
	my ($token, $icon) = @_;
	$icon = "MENUITEMICON|$icon|" if $icon;

	my $string = getString($token) || $token;
	print "$icon$string\n";
}

sub getPrefPane {
	-e '/Library/PreferencePanes/Squeezebox.prefPane' || -e catfile($ENV{HOME}, 'Library/PreferencePanes/Squeezebox.prefPane');
}

if (scalar @ARGV > 0) {
	LMSMenuAction::handleAction();
}
else {
	my $autoStartItem = -f catfile($ENV{HOME}, 'Library', 'LaunchAgents', 'org.lyrion.lyrionmusicserver.plist')
		? 'AUTOSTART_ON'
		: 'AUTOSTART_OFF';

	if (my $port = getPort()) {
		printMenuItem('OPEN_GUI');
		printMenuItem('OPEN_SETTINGS');
		print("----\n");
		printMenuItem('STOP_SERVICE');
		printMenuItem($autoStartItem);

		serverRequest($port, 'pref', 'macMenuItemActive', time());
	}
	else {
		printMenuItem(isProcessRunning() ? 'SERVICE_STARTING' : 'START_SERVICE');
		printMenuItem($autoStartItem);
	}

	if (getUpdate()) {
		print("----\n");
		printMenuItem('UPDATE_AVAILABLE');
	}

	if (getPrefPane()) {
		print("----\n");
		printMenuItem('UNINSTALL_PREFPANE');
	}
}

1;