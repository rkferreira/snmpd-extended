#!/usr/bin/perl

use strict;
use Config::Simple;

my $SNMP_METHOD = shift;
my $SNMP_OID = shift;

my %cfg = ();
Config::Simple->import_from("/etc/lastpasschange.ini", \%cfg);

sub getData {
	my ($user, $tool) = @_;
	my @res = undef;
	my @res2;

	@res = `$tool $user`;
	foreach(@res) {
		chomp $_;
		push @res2, $_ if (length($_)>=1) ;
	}
	return @res2;
}



sub LastPassChange {
        my ($reqMethod, $reqOid, %configFile) = @_;
        my $o_root	= $configFile{"agent.root"};
        my $o_base	= $configFile{"lastpasschange.root"};
        my $o_users	= $configFile{"lastpasschange.users"};
	my $o_cmdtool	= $configFile{"lastpasschange.tool"};

	#DISABLED my $baseOid	= $o_root . '.' . $o_base;
	my $baseOid	= $o_root;
        my @users	= split(";", $o_users);


	my @result = undef;
	my @data   = undef;
	my $maxcol = 5;
	my @aux	   = split('\.',$reqOid);

	my $a = 0;
	foreach(@users) {
		my @tmp = getData($_, $o_cmdtool);
		unshift(@tmp, $_);
		for (my $i=0; $i < $maxcol ; $i++) {
			if ($tmp[$i]) {
				$data[$a][$i] = $tmp[$i];
			} else {
				$data[$a][$i] = "UNKNOWN";
			}
		}
		$a++;
	}

	my $maxrow = scalar(@data);

	if ( $reqMethod eq "-n" ) {
		if (($reqOid eq $baseOid) || ($reqOid eq $baseOid.".0")) {
			@result = ( $baseOid.".0.0","string", $data[0][0] );
		}
		elsif ( $aux[$#aux-1] eq "0" ) {
			my $next = $aux[$#aux] + 1;
			if ($next < $maxrow)  {
				@result = ( $baseOid. ".0." . $next, "string", $data[$next][0] );
			} else {
				@result = ( $baseOid. ".1." . "0", "string", $data[0][1] );
			}
		}
		elsif ( $aux[$#aux-1] eq "1" ) {
			my $next = $aux[$#aux] + 1;
			if ($next < $maxrow)  {
				@result = ( $baseOid. ".1." . $next, "string", $data[$next][1] );
			} else {
				@result = ( $baseOid. ".2." . "0", "string", $data[0][2] );
			}
		}
		elsif ( $aux[$#aux-1] eq "2" ) {
			my $next = $aux[$#aux] + 1;
			if ($next < $maxrow)  {
				@result = ( $baseOid. ".2." . $next, "string", $data[$next][2] );
			} else {
				@result = ( $baseOid. ".3." . "0", "string", $data[0][3] );
			}
		}
		elsif ( $aux[$#aux-1] eq "3" ) {
			my $next = $aux[$#aux] + 1;
			if ($next < $maxrow)  {
				@result = ( $baseOid. ".3." . $next, "string", $data[$next][3] );
			} else {
				@result = ( $baseOid. ".4." . "0", "string", $data[0][4] );
			}
		}
		elsif ( $aux[$#aux-1] eq "4" ) {
			my $next = $aux[$#aux] + 1;
			if ($next < $maxrow)  {
				@result = ( $baseOid. ".4." . $next, "string", $data[$next][4] );
			} else {
				@result = ("","","");
			}
		}
	
	} elsif ( $reqMethod eq "-g" ) {
		my $one = $aux[$#aux];
		my $two = $aux[$#aux-1];
		@result = ( $reqOid , "string", $data[$one][$two] );
	}

	return @result;
	
}

#print $SNMP_METHOD;
#print $SNMP_OID;
#print %cfg;

my ($oid, $type, $value) = "";
($oid, $type, $value) = LastPassChange($SNMP_METHOD, $SNMP_OID, %cfg);
print "$oid\n$type\n$value\n";
