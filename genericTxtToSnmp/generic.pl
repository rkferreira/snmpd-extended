#!/usr/bin/perl

# Global

use strict;
use Config::Simple;

my $SNMP_METHOD = shift;
my $SNMP_OID = shift;

my %cfg = ();
Config::Simple->import_from("/etc/genericTxtToSnmp.ini", \%cfg);

sub ReadFile {
	open(FILE, shift) or return "";
	my @result = <FILE>;
	close(FILE);
	return @result;
}

sub CheckFileAge {
	my ($file, $maxage) = @_;

	my @st = stat($file);
	if (time-$maxage >= @st[9]) {
		return "WARNING - Status files are not updated.";
	}

	return "OK";
}

sub ParseData {
	my ($file) = @_;
	my @label = undef;
	my @values = undef;

	my @data = ReadFile($file);

	foreach my $d (@data) {
		my @aux = split(' ',$d);
		push @label, $aux[0];
		push @values, $aux[1];
	}

	return (\@label, \@values);
}


sub Generic {
	my ($reqMethod, $reqOid, %configFile) = @_;
	my $o_root	= $configFile{"agent.root"};
	my $o_base	= $configFile{"generic.root"};
	my $o_file	= $configFile{"generic.statusfile"};
	my $o_age	= $configFile{"generic.maxage"};

	my $baseOid	= $o_root . '.' . $o_base;
	my @aux		= split('\.',$reqOid);
	my $lastEl	= $aux[$#aux];
	my $sizeAux	= @aux;
	my @result	= undef;
	my @retLabels	= undef;
	my @retValues	= undef;
	my $sizeL	= undef;
	my $sizeV	= undef;

	my $fileAge = CheckFileAge($o_file, $o_age);

	if ( $fileAge eq "OK" ) {
		my ($refLabels, $refValues) = ParseData($o_file);
		@retLabels = @$refLabels;
		@retValues = @$refValues;
		shift @retLabels;
		shift @retValues;
	} else {
		
		push @retLabels, $fileAge;
		push @retValues, $fileAge;
	}

	$sizeL = @retLabels;
	$sizeV = @retValues;

	if ($reqMethod eq "-n") {
		if ($reqOid eq $baseOid || $reqOid eq $baseOid.".0" ) {
			@result = ( $baseOid.".0.0","string",$retLabels[0]  );
		}
		else {
			if ($sizeAux >= 12) {
				if ($aux[$#aux-1] == 0) {
					if ($lastEl < $sizeL-1) {
						my $next = $lastEl+1;
						@result = ( $baseOid.".0.".$next,"string",$retLabels[$next] );
					} else {
						@result = ( $baseOid.".1.0","string",$retValues[0]  );
					}
				} else {
					if ($lastEl < $sizeV-1) {
						my $next = $lastEl+1;
						@result = ( $baseOid.".1.".$next,"string",$retValues[$next] );
					} else {
						@result = ("","","");	
					}

				}
			} else {
				if ($aux[$#aux] == 0) {
					@result = ( $baseOid.".0.0","string",$retLabels[0]  );
				} else {
					@result = ( $baseOid.".1.0","string",$retValues[0]  );
				}

			}
		}
       	} elsif ( $reqMethod eq "-g" ) {
		if ($reqOid eq $baseOid.".0") {
			@result = ( $baseOid.".0.0","string", $retLabels[0] );
		}
		else {
			if ($aux[$#aux-1] == 0) {
				@result = ( $baseOid.".".$aux[$#aux-1].".".$lastEl,"string",$retLabels[$lastEl] );
			} else {
				@result = ( $baseOid.".".$aux[$#aux-1].".".$lastEl,"string",$retValues[$lastEl] );
			}
		}
	}

	return @result;
}

my ($oid, $type, $value) = "";
($oid, $type, $value) = Generic($SNMP_METHOD, $SNMP_OID, %cfg);
print "$oid\n$type\n$value\n";

