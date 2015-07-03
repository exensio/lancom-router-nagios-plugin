#!/bin/bash

# check_snmp_router_cpu
# Description : Checks CPU load of a Lancom Router

# The MIT License (MIT)
# 
# Copyright (c) 2015, Roland Rickborn (roland.rickborn@exensio.de)
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
# Revision history:
# 2015-07-01  Created
#             Based on the work of Yoann LAMY
#             (https://exchange.nagios.org/directory/Owner/Yoann/1)
# ---------------------------------------------------------------------------

# Commands
CMD_BASENAME=`which basename`
CMD_SNMPWALK=`which snmpwalk`
CMD_AWK=`which awk`

# Script name
SCRIPTNAME=`$CMD_BASENAME $0`

# Version
VERSION="1.0"

# Plugin return codes
STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3

OID_CPULOAD="LCOS-MIB::lcsStatusHardwareInfoCpuLoadPercent"
OID_CPULOAD5S="LCOS-MIB::lcsStatusHardwareInfoCpuLoad5sPercent"
OID_CPULOAD60S="LCOS-MIB::lcsStatusHardwareInfoCpuLoad60sPercent"
OID_CPULOAD300S="LCOS-MIB::lcsStatusHardwareInfoCpuLoad300sPercent"

# Default variables
DESCRIPTION="Unknown"
STATE=$STATE_UNKNOWN

# Default options
COMMUNITY="public"
HOSTNAME="192.168.0.1"
WARNING=0
CRITICAL=0

# Option processing
print_usage() {
  echo "Usage: ./check_snmp_cpu -H 192.168.0.1 -C public -w 80 -c 90"
  echo "  $SCRIPTNAME -H ADDRESS"
  echo "  $SCRIPTNAME -C STRING"
  echo "  $SCRIPTNAME -w INTEGER"
  echo "  $SCRIPTNAME -c INTEGER"
  echo "  $SCRIPTNAME -h"
  echo "  $SCRIPTNAME -V"
}

print_version() {
  echo $SCRIPTNAME version $VERSION
  echo ""
  echo "This nagios plugin comes with ABSOLUTELY NO WARRANTY."
  echo "You may redistribute copies of the plugin under the terms of the MIT License."
}

print_help() {
  print_version
  echo ""
  print_usage
  echo ""
  echo "Checks CPU load of a Lancom Router"
  echo ""
  echo "-H ADDRESS"
  echo "   Name or IP address of host (default: 192.168.0.1)"
  echo "-C STRING"
  echo "   Community name for the host SNMP agent (default: public)"
  echo "-w INTEGER"
  echo "   Warning level for memory usage in percent (default: 0)"
  echo "-c INTEGER"
  echo "   Critical level for memory usage in percent (default: 0)"
  echo "-h"
  echo "   Print this help screen"
  echo "-V"
  echo "   Print version and license information"
  echo ""
}

while getopts H:C:w:c:hV OPT
do
  case $OPT in
    H) HOSTNAME="$OPTARG" ;;
    C) COMMUNITY="$OPTARG" ;;
    w) WARNING=$OPTARG ;;
    c) CRITICAL=$OPTARG ;;
    h)
      print_help
      exit $STATE_UNKNOWN
      ;;
    V)
      print_version
      exit $STATE_UNKNOWN
      ;;
   esac
done

# Get CPU Load in Percent
CPULOAD5S=`$CMD_SNMPWALK -t 2 -r 2 -v 1 -c $COMMUNITY $HOSTNAME $OID_CPULOAD5S | $CMD_AWK '{ print $4 }'`
CPULOAD60S=`$CMD_SNMPWALK -t 2 -r 2 -v 1 -c $COMMUNITY $HOSTNAME $OID_CPULOAD60S | $CMD_AWK '{ print $4 }'`
CPULOAD300S=`$CMD_SNMPWALK -t 2 -r 2 -v 1 -c $COMMUNITY $HOSTNAME $OID_CPULOAD300S | $CMD_AWK '{ print $4 }'`
CPULOAD=`$CMD_SNMPWALK -t 2 -r 2 -v 1 -c $COMMUNITY $HOSTNAME $OID_CPULOAD | $CMD_AWK '{ print $4 }'`

if [ $WARNING != 0 ] || [ $CRITICAL != 0 ]; then
  if [ $CPULOAD5S -gt $CRITICAL ] && [ $CRITICAL != 0 ]; then
    CPUSTATE=$STATE_CRITICAL
  elif [ $CPULOAD60S -gt $CRITICAL ] && [ $CRITICAL != 0 ]; then
    CPUSTATE=$STATE_CRITICAL
  elif [ $CPULOAD300S -gt $CRITICAL ] && [ $CRITICAL != 0 ]; then
    CPUSTATE=$STATE_CRITICAL
  elif [ $CPULOAD5S -gt $WARNING ] && [ $WARNING != 0 ]; then
    CPUSTATE=$STATE_WARNING
  elif [ $CPULOAD60S -gt $WARNING ] && [ $WARNING != 0 ]; then
    CPUSTATE=$STATE_WARNING
  elif [ $CPULOAD300S -gt $WARNING ] && [ $WARNING != 0 ]; then
    CPUSTATE=$STATE_WARNING
  else
    CPUSTATE=$STATE_OK
  fi
fi

DESCRIPTION="CPU Load : $CPULOAD5S%|$CPULOAD60S%|$CPULOAD300S% | cpu_load_current=$CPULOAD;$WARNING;$CRITICAL;0 cpu_load_average5S=$CPULOAD5S;$WARNING;$CRITICAL;0 cpu_load_average60S=$CPULOAD60S;$WARNING;$CRITICAL;0 cpu_load_average300S=$CPULOAD300S;$WARNING;$CRITICAL;0"

echo $DESCRIPTION
exit $CPUSTATE
