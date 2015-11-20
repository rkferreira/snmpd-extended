## linuxDiskSpace

 Provides SNMP extension for monitoring real disk usage, I mean, like "df" on linux.
 Native snmpd disk space monitoring doesn't take care of reserved blocks.

 "ini" config file is like this:

 [disk]
 root=1
 devices=/;/boot



 It returns a table like this:

[root@ ~]# snmpwalk -v2c -c public 127.0.0.1 1.3.6.1.4.1.4.3.1
MIB::disk.0.0 = STRING: "/"
MIB::disk.0.1 = STRING: "/boot"
MIB::disk.1.0 = STRING: "119659748"
MIB::disk.1.1 = STRING: "126931"
MIB::disk.2.0 = STRING: "68696092"
MIB::disk.2.1 = STRING: "94668"
MIB::disk.3.0 = STRING: "60.48"
MIB::disk.3.1 = STRING: "78.64"

