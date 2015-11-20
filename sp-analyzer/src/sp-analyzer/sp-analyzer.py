#!/usr/bin/python

# *
# *  Copyright 2014 by Rodrigo Kellermann Ferreira <rkferreira@gmail.com>
# *        <http://www.gnu.org/licenses/>.

#
# Conf file at   '/etc/sp-analyzer.cfg'
#

# SP usage https://community.emc.com/thread/146280
# LUNs     https://community.emc.com/thread/180626
#	   https://community.emc.com/message/748679

import os
from os import popen
from time import sleep
import re
import ConfigParser
from tempfile import mkstemp

CLI   = "/nas/sbin/naviseccli"
USER  = "analyzer"
PASS  = "xxxxxx"
SP    = ( ['SPA','SPB'] )
FILEN = "sp-analyzer.txt"

exp1 = re.compile("\(optimal\)", re.IGNORECASE)

def getCpuUsage(sp):
	value = ['','']
	p = popen('%s -h %s -Scope 0 -User %s -Password %s getcontrol -cbt' % (CLI,sp,USER,PASS))
	r = p.read()
	p.close()
	s = r.split('\n')
	i = 0
	for a in s:
		b = a.split(':')
		if b and len(b) > 1:
			label = b[0]
			value[i] = b[1].rstrip()
		i = i +1
	avg =  ( float(value[0]) / ( float(value[0]) + float(value[1]) ) ) * 100
	return avg


def getLunUsage(sp, lun):
	value = ['','','','']
	#       SPA, SPB
	# busy -> 0, 1
	# idle -> 2, 3
	p = popen('%s -h %s -Scope 0 -User %s -Password %s getlun %s -lunbusytickssp -lunidletickssp' % (CLI,sp,USER,PASS,lun))
	r = p.read()
	p.close()
	s = r.split('\n')
	i = 0
	for a in s:
		b = a.split(':')
		if b and len(b) > 1:
			label = b[0]
			tmp = re.sub(exp1,'',b[1])
			value[i] = tmp.rstrip()
		i = i +1
	busySPA = ( float(value[0]) / ( float(value[2]) + float(value[0]) )) * 100
	busySPB = ( float(value[1]) / ( float(value[3]) + float(value[1]) )) * 100
	
	return ( busySPA, busySPB )
			

def main():
	# reading config file
	config = ConfigParser.RawConfigParser()
	config.readfp(open('/etc/sp-analyzer.cfg'))

	if config.has_option('main','OUTPUT_PATH'):
		path = config.get('main','OUTPUT_PATH')
	else:
		path='/tmp/monitoring/'

	FILE = "%s%s" % (path,FILEN)

	if (not(os.path.isdir(path))):
		os.mkdir(path,0755)

	if config.has_option('main','LUN_ARRAYS'):
		LUNS = eval(config.get('main','LUN_ARRAYS'), {}, {})
	else:
		LUNS = ( ['1','2','3'] )

	fdtmp, fpathtmp = mkstemp(prefix="sp-analyzer")
	f = open(fpathtmp, 'w+')
	m1SPA = getCpuUsage(SP[0])
	m1SPB = getCpuUsage(SP[1])
	sleep(60)
	m2SPA = getCpuUsage(SP[0])
	m2SPB = getCpuUsage(SP[1])
	cpuAvgSPA = (m1SPA + m2SPA) / 2
	cpuAvgSPB = (m1SPB + m2SPB) / 2
	f.write("%s_CPU_BUSY_%% %.2f\n" % (SP[0],cpuAvgSPA))
	f.write("%s_CPU_BUSY_%% %.2f\n" % (SP[1],cpuAvgSPB))
	#print "%s_CPU_BUSY_%% %.2f" % (SP[0],cpuAvgSPA)
	#print "%s_CPU_BUSY_%% %.2f" % (SP[1],cpuAvgSPB)

	for a in LUNS:
		i = 0
		for b in SP:
			ra, rb = getLunUsage(b,a)
			if i == 0:
				ga = ra
				gb = rb
			else:
				ga = (ga + ra)/2
				gb = (gb + rb)/2
				f.write("%s_LUN_%s_BUSY_%% %.6s\n" % ('SPA',a,ga))
				f.write("%s_LUN_%s_BUSY_%% %.6s\n" % ('SPB',a,gb))
				#print "%s_LUN_%s_BUSY_%% %.6s" % ('SPA',a,ga)
				#print "%s_LUN_%s_BUSY_%% %.6s" % ('SPB',a,gb)
			i = i + 1
	f.close()
	f = open(fpathtmp,'r')
	finalData = f.read()
	f.close()
	f = open(FILE, 'w+')
	f.write(finalData)
	f.close()
	os.close(fdtmp)
	os.remove(fpathtmp)


if __name__ == '__main__':
	main()
