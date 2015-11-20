### Perl Package ###

package linuxDiskSpace;

require "syscall.ph";

use strict;

### Functions ###

sub DiskData {
        my ($disk)        = @_;

        my $buf = "\0"x64;

        my $bsize = undef;
        my $blocks = undef;
        my $bfree = undef;
        my $bavail = undef;
        my $files = undef;
        my $ffree = undef;
        my $namelen = undef;

        syscall(&SYS_statfs, $disk, $buf) == 0 or die;

        my $arch = `/bin/uname -m`;
        $arch =~ s/\n//g;
        if (lc($arch) eq "x86_64") {
                ($bsize, $blocks, $bfree, $bavail, $files, $ffree, $namelen) = unpack  "x4 Q6 x8 Q", substr($buf,4);
        } else {
                ($bsize, $blocks, $bfree, $bavail, $files, $ffree, $namelen) = unpack  "x4 L6 x8 L", $buf;
        }

        # For non 1024 blocks
	my $convertBlock  = $bsize / 1024;
        my $diskTotal     = ( ($blocks - ($bfree - $bavail) ) * $convertBlock) ;
        my $diskAvalSpace = $bavail * $convertBlock;
	my $diskUsed	  = $diskTotal - $diskAvalSpace ;
	my $diskAll       = $blocks * $convertBlock ;
        my $diskUsage     = undef;

        if(defined($diskTotal)) {
                $diskUsage     = 100 - ( ( $diskAvalSpace * 100 ) / $diskTotal ) ;
        }
        else {
                $diskUsage = "U";
        }

        #print  ($diskTotal,$diskUsed,sprintf("%.2f", $diskUsage));
        return ($diskAll,$diskUsed,sprintf("%.2f", $diskUsage));

}

sub DiskColector {
	my ($reqMethod, $reqOid, %configFile) = @_;
	
	my $o_root   	 = $configFile{"agent.root"};
	my $o_base   	 = $configFile{"disk.root"};
	my $o_devices    = $configFile{"disk.devices"};

	my @devices      = split(";", $o_devices);
	my $countDevices = @devices;
	my @diskData	 = undef;
	my @result 	 = undef;
	my $value	 = undef;
	my $now		 = undef;
	my $baseOid 	 = $o_root . '.' . $o_base;
	my @aux 	 = split('\.',$reqOid);

	# zero  tree is indexname
	# one   tree is totalsize
	# two   tree is used size
	# three tree is used %
	# four  tree is iostat value
	
	if ( $reqMethod eq "-n" ) {
		
		if ( $reqOid eq $baseOid || $reqOid eq $baseOid.".0" )
		{
			@result = ( $baseOid.".0.0","string", $devices[0] );

		}
		# if in indexname table
		elsif( $aux[$#aux - 1] eq "0" ) {
			$now = $aux[$#aux] + 1;

			if ( $aux[$#aux] < $countDevices ) {
				
				if ( length $devices[$now] ) {
					@result = ($baseOid.".0.".$now,"string", $devices[$now] );
				}
				else {
					$now = 0;
					@diskData = DiskData($devices[$now]);
					@result = ($baseOid.".1.".$now,"string", $diskData[0]);
				}
			}

		}
		# if in disks data tables
		elsif( $aux[$#aux - 1] eq "1" || $aux[$#aux - 1] eq "2" || $aux[$#aux - 1] eq "3" ) {
			$now = $aux[$#aux] + 1;

			if ( $aux[$#aux] < $countDevices ) {
					
					if ( $aux[$#aux - 1] eq "1" ) {
						if ( length $devices[$now] ) {
							@diskData = DiskData($devices[$now]);
							@result = ($baseOid.".1.".$now,"string", $diskData[0]);
						}
						else {
							$now = 0;
							@diskData = DiskData($devices[$now]);
							@result = ($baseOid.".2.".$now,"string", $diskData[1]);
						}
					} 
					elsif ( $aux[$#aux - 1] eq "2" ) {
						if ( length $devices[$now] ) {
							@diskData = DiskData($devices[$now]);
							@result = ($baseOid.".2.".$now,"string", $diskData[1]);
						}
						else {
                                                        $now = 0;
                                                        @diskData = DiskData($devices[$now]);
                                                        @result = ($baseOid.".3.".$now,"string", $diskData[2]);
                                                }
					}
					elsif ( $aux[$#aux - 1] eq "3" ) {
						if ( length $devices[$now] ) {
							@diskData = DiskData($devices[$now]);
							@result = ($baseOid.".3.".$now,"string", $diskData[2]);
						}
                                                else {
                                                        @result = ("","","");
                                                }
					}
				
			}
		}



	} elsif ( $reqMethod eq "-g" ) {

		if ( $aux[$#aux] < $countDevices )
                {
			if ( $aux[$#aux - 1] eq "0" ) {
                        	@result = ($baseOid.".0.".$aux[$#aux],"string", $devices[$aux[$#aux]] );
			}
			elsif ( $aux[$#aux - 1] eq "1" ) {
				@diskData = DiskData($devices[$aux[$#aux]]);
				@result = ($baseOid.".1.".$aux[$#aux],"string", $diskData[0] );
			}
			elsif ( $aux[$#aux - 1] eq "2" ) {
				@diskData = DiskData($devices[$aux[$#aux]]);
				@result = ($baseOid.".2.".$aux[$#aux],"string", $diskData[1] );
			}
			elsif ( $aux[$#aux - 1] eq "3" ) {
				@diskData = DiskData($devices[$aux[$#aux]]);
				@result = ($baseOid.".3.".$aux[$#aux],"string", $diskData[2] );
			}
                }

	}

	return @result;
}
1;
