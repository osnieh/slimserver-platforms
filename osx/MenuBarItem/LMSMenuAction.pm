package LMSMenuAction;

use strict;

use Cwd;
use Encode qw(decode_utf8);
use File::Spec::Functions qw(catfile);
use Text::Unidecode;

sub handleAction {
	my $httpPort = main::getPort();

	my $item = getMenuItem();

	if ($item eq 'OPEN_GUI') {
		system("open http://localhost:$httpPort/");
	}
	elsif ($item eq 'OPEN_SETTINGS') {
		system("open http://localhost:$httpPort/settings/index.html");
	}
	elsif ($item eq 'START_SERVICE') {
		# we're going to re-use a shell script which will be used elsewhere, too
		runScript('start-server.sh');
	}
	elsif ($item eq 'STOP_SERVICE') {
		runScript('stop-server.sh');
	}
	elsif ($item eq 'AUTOSTART_ON') {
		runScript('remove-launchitem.sh');
	}
	elsif ($item eq 'AUTOSTART_OFF') {
		runScript('create-launchitem.sh');
	}
	elsif ($item eq 'UPDATE_AVAILABLE') {
		my $update = main::getUpdate();
		if ($update && $update !~ m/^http/) {
			runScript('stop-server.sh');
			unlink main::getVersionFile();
			system("open \"$update\"");
			print("QUITAPP\n");
		}
		# if we can't find the installer, fall back to showing instructions
		else {
			system("open $update") if $update;

			my $title = main::getString('UPDATE_TITLE');
			my $message = main::getString('INSTALL_UPDATE');
			print("ALERT:$title|$message\n");
		}
	}
	elsif ($item eq 'UNINSTALL_PREFPANE') {
		system("open https://lyrion.org/reference/uninstall-legacy-mac/");
	}
	elsif ($item eq 'SERVICE_STARTING') {
		# nothing to do here...
	}
	elsif ($item eq 'ABOUT_SERVER') {
		my $message = getSystemInformation();
		print "ALERT:Lyrion Music Server|$message\n";
	}
	else {
		my $x = unidecode(join(' ', @ARGV));
		print "ALERT:Selected Item...|$item $x\n";
	}
}

sub getSystemInformation {
	my $systemInfo = '';
	my $versionFile = catfile(cwd(), '..', 'Resources', 'server', 'revision.txt');

	if (-f $versionFile) {
		local $/ = undef;
		open(my $fh, $versionFile);
		my $versionInfo = <$fh>;
		close($fh);

		my $version = main::getString('VERSION');
		my ($revision, $buildtime) = split (/\n/, $versionInfo);

		# can't use line break - use some tabs to force wrapping...
		$systemInfo .= sprintf("Version: %-40s Revision: %-40s Buildtime: %s", $version, $revision, $buildtime);
	}

	require Config;
	$systemInfo .= sprintf(" Perl: %-40s", $Config::Config{'version'} . ' - ' . $Config::Config{'archname'});

	# fetching system information - should be in sync with Slim::Utils::OS::OSX
	open(my $fh, '/usr/sbin/system_profiler SPSoftwareDataType SPHardwareDataType 2>&1 |') or return;
	while (<$fh>) {
		if (/System Version:|Chip:/i) {
			chomp;
			$systemInfo .= sprintf("%-40s", $_);
		}
	}
	close($fh);

	return $systemInfo;
}

sub runScript {
	system('"' . catfile(cwd(), shift) . '"');
}

sub getMenuItem {
	my $token = join(' ', @ARGV);
	# I've spent hours trying to do without Text::Unidecode, but have failed misearably.
	# There's an encoding issue somewhere between Platypus and Perl.
	$token = unidecode(decode_utf8($token));

	while (my ($tokenId, $details) = each %{$main::STRINGS}) {
		foreach my $value (grep { !ref $_ } values %$details) {
			return $tokenId if unidecode($value) eq $token;
		}
	}

	return "UNKNOWN ($token)";
}

1;