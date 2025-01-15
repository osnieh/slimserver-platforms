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

	return $update || getPref('serverUpdateAvailable');
}

sub getVersionFile {
	return catfile(main::getPref('cachedir'), 'updates', 'server.version')
}

my $prefs;
sub getPref {
	my $pref = shift;
	my $ret;

	if (!$prefs) {
		$prefs = {};
		if (-r PREFS_FILE) {
			open(PREF, '<', PREFS_FILE) or return;

			while (<PREF>) {
				if (/^([a-z]\S+):\s*(.*)/) {
					my $key = $1;
					$prefs->{$key} = $2;
					$prefs->{$key} =~ s/^['"]//;
					$prefs->{$key} =~ s/['"\s]*$//s;
				}
			}

			close(PREF);
		}
	}

	return $prefs->{$pref};
}

sub getString {
	my ($token) = @_;
	return $STRINGS->{$token}->{$lang} || $STRINGS->{$token}->{EN};
}

# Dirty low level http request - optimized for speed. We don't even wait for a response...
sub fireAndForgetServerRequest {
	my $port = shift;
	require Net::HTTP;

	my $client  = Net::HTTP->new(Host => "127.0.0.1:$port") || die $@;
	$client->write_request(POST => '/jsonrpc.js', 'Content-Type' => 'application/json', encode_json({
		id => 1,
		method => 'slim.request',
		params => ['', \@_]
	}));
	$client->close;
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
		my $pid = fork();
		if (!$pid) {
			fireAndForgetServerRequest($port, 'pref', 'macMenuItemActive', time());
			exit;
		}

		printMenuItem('OPEN_GUI');
		printMenuItem('OPEN_SETTINGS');
		print("----\n");
		printMenuItem('STOP_SERVICE');
		printMenuItem($autoStartItem);
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

	print("----\n");
	printMenuItem('ABOUT_SERVER');
}

1;