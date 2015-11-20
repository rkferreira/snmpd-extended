### Perl Package ###

package MonitStorageSP;

use strict;


# Table
# #
# plugin-OID.0.X = sps
# plugin-OID.1.X = sps CPU BUSY %
# plugin-OID.2.X = luns
# plugin-OID.3.X = lun SPA BUSY %
# plugin-OID.4.X = lun SPB BUSY %

### Functions ###

sub ReadFile {
        open(FILE, shift) or return "";
        my @result = <FILE>;
        close(FILE);
        return @result;
}

sub SPGetData {
        my ($string, $file) = @_;
        my @data = ReadFile($file);
        my $result;
	my @tmp;

        foreach(@data) {
                if (/$string/) {
                        @tmp = split(' ',$_);
                        $tmp[1] =~ s/ +//g;
                        $result = $tmp[1];
			# stop the loop!
			last;
                }
        }
        return $result;
}

sub SPColector {
	my ($reqMethod, $reqOid, %configFile) = @_;
	
	my $o_root   	 = $configFile{"agent.root"};
	my $o_base   	 = $configFile{"storageSP.root"};
	my $o_sps	 = $configFile{"storageSP.sps"};
	my $o_luns 	 = $configFile{"storageSP.luns"};
	my $o_file 	 = $configFile{"storageSP.file"};

	my @sps 	 = split(";", $o_sps);
	my @luns	 = split(";", $o_luns);

	my $countSps 	 = @sps;
	my $countLuns	 = @luns;

	my $now		 = undef;
	my $tmp		 = undef;
	my $ind		 = undef;
	my $baseOid 	 = $o_root . '.' . $o_base;
	my @aux 	 = split('\.',$reqOid);
	my @result	 = undef;

	my $countAux	 = @aux;

	#for testing, because start '.'
	#$baseOid = "1.3.6.1.4.1.4.3.100";
	#print $countAux."\n";

        if ( $reqMethod eq "-n" ) {
		$ind = $aux[$#aux - 1];

                if ( $reqOid eq $baseOid || $reqOid eq $baseOid.".0" )
                {
                        @result = ( $baseOid.".0.0","string", $sps[0] );

                }
                elsif( $aux[$#aux - 1] eq "0" ) {
                        $now = $aux[$#aux] + 1;

                        if ( $aux[$#aux] < $countSps ) {

                                if ( length $sps[$now] ) {
                                        @result = ($baseOid.".0.".$now,"string", $sps[$now] );
                                }
                                else {
                                        $now = 0;
					$ind++;
                                        $tmp = SPGetData("$sps[0]_CPU_BUSY_%",$o_file);
                                        @result = ($baseOid.".$ind.".$now,"string", $tmp);
                                }
                        }

                }
		elsif( $reqOid eq $baseOid.".1" ) {
			$tmp = SPGetData("$sps[0]_CPU_BUSY_%",$o_file);
			@result = ( $baseOid.".1.0","string", $tmp);
		}
                elsif( $aux[$#aux - 1] eq "1" ) {
			$now = $aux[$#aux] + 1;

			if ( $aux[$#aux] < $countSps ) {
				if ( length $sps[$now] ) {
					$tmp = SPGetData("$sps[$now]_CPU_BUSY_%",$o_file);
					@result = ($baseOid.".$ind.".$now,"string", $tmp);
				}
				else {
                                        $now = 0;
                                        $ind++;
                                        $tmp = $luns[$now];
					@result = ($baseOid.".$ind.".$now,"string", $tmp);
				}
			}

		}
		elsif( $reqOid eq $baseOid.".2" ) {
			$tmp = $luns[0];
			@result = ( $baseOid.".2.0","string", $tmp);
		}
		elsif( $aux[$#aux - 1] eq "2" ) {
			$now = $aux[$#aux] + 1; 

			if ( $aux[$#aux] < $countLuns ) {
				if ( length $luns[$now] ) {
					$tmp = $luns[$now];
					@result = ($baseOid.".$ind.".$now,"string", $tmp);
				}
				else {
                                        $now = 0;
                                        $ind++;
					# SPA_LUN_170_BUSY_%
                                        $tmp = SPGetData("SPA_LUN_$luns[$now]_BUSY_%",$o_file);
					@result = ($baseOid.".$ind.".$now,"string", $tmp);
				}
			}
		}
		elsif( $reqOid eq $baseOid.".3" ) {
			$tmp = SPGetData("SPA_LUN_$luns[0]_BUSY_%",$o_file);
			@result = ( $baseOid.".3.0","string", $tmp);
		}
		elsif( $aux[$#aux - 1] eq "3" ) {
			$now = $aux[$#aux] + 1;
		
			if ( $aux[$#aux] < $countLuns ) {
				if ( length $luns[$now] ) {
					$tmp = SPGetData("SPA_LUN_$luns[$now]_BUSY_%",$o_file);
					@result = ($baseOid.".$ind.".$now,"string", $tmp);
				}
				else {
					$now = 0;
					$ind++;
                                        # SPA_LUN_170_BUSY_%
                                        $tmp = SPGetData("SPB_LUN_$luns[$now]_BUSY_%",$o_file);
                                        @result = ($baseOid.".$ind.".$now,"string", $tmp);
				}
			}
		}
		elsif( $reqOid eq $baseOid.".4" ) {
			$tmp = SPGetData("SPB_LUN_$luns[0]_BUSY_%",$o_file);
			@result = ( $baseOid.".4.0","string", $tmp);
		}
		elsif( $aux[$#aux - 1] eq "4" ) {
			$now = $aux[$#aux] + 1;

			if ( $aux[$#aux] < $countLuns ) {
				if ( length $luns[$now] ) {
					$tmp = SPGetData("SPB_LUN_$luns[$now]_BUSY_%",$o_file);
					@result = ($baseOid.".$ind.".$now,"string", $tmp);
				}
				else {
					@result = ("","","");
				}
			}
		}
		elsif( $countAux <= 11 ) {
			@result = SPColector($reqMethod, $reqOid.".0", %configFile);
			#@result = ($reqOid.".0","string",$countAux);
		}


	} elsif ( $reqMethod eq "-g" ) {

		if ( $aux[$#aux - 1] eq "0" ) {
			$now = $aux[$#aux];
			@result = ($baseOid.".".$ind.".".$now,"string", $sps[$now] );
		}
		elsif ( $aux[$#aux - 1] eq "1" ) {
			$now = $aux[$#aux];
			$tmp = SPGetData("$sps[$now]_CPU_BUSY_%",$o_file);
			@result = ($baseOid.".".$ind.".".$now,"string", $tmp);
		}
		elsif ( $aux[$#aux - 1] eq "2" ) {
			$now = $aux[$#aux];
			$tmp = $luns[$now];
			@result = ($baseOid.".".$ind.".".$now,"string", $tmp);
		}
		elsif ( $aux[$#aux - 1] eq "3" ) {
			$now = $aux[$#aux];
			$tmp = SPGetData("SPA_LUN_$luns[$now]_BUSY_%",$o_file);
			@result = ($baseOid.".".$ind.".".$now,"string", $tmp);
		}
		elsif ( $aux[$#aux - 1] eq "4" ) {
			$now = $aux[$#aux];
			$tmp = SPGetData("SPB_LUN_$luns[$now]_BUSY_%",$o_file);
			@result = ($baseOid.".".$ind.".".$now,"string", $tmp);
		}
		else {
			@result = ("","","");
		}

        }

	return @result;
}
1;
