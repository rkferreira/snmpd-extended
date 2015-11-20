## RPM generation

1. Create tar
   cd src
   tar cvzf sp-analyzer-<version>-<release>.tar.gz sp-analyzer

2. Copy tar to SOURCES dir
   cd <topdir>/SOURCES

3. Do it
   rpmbuild -bb sp-analyzer.spec


General tips:

  - Create:  ~/.rpmmacros 
           %_topdir      %(echo $HOME)/rpmbuild
	   %_source_filedigest_algorithm 1
           %_binary_filedigest_algorithm 1
           %_binary_payload w9.gzdio
	   %packager  YOUR NAME <aaaa@aaa.com>
           %_arch noarch


## SNMP integration

 I'm providing a base for that, its not complet HERE as it is for lastpasschange project.
 But the idea is the same, you can take it as basis and just make some adjustments.
 It's working here, but there is base program that call that, but I'm not able to provide that one.

 File: snmp/MonitStorageSP.pm
