#!/bin/bash

# check_snmp_router_temperature
# Description : Checks Temperature of Lancom Router

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

OID_TEMP="LCOS-MIB::lcsStatusHardwareInfoTemperatureDegrees"
OID_TEMPMAX="LCOS-MIB::lcsSetupTemperatureMonitorUpperLimitDegrees"
OID_TEMPMIN="LCOS-MIB::lcsSetupTemperatureMonitorLowerLimitDegrees"

# Default variables
DESCRIPTION="Unknown"
STATE=$STATE_UNKNOWN

# Default options
COMMUNITY="public"
HOSTNAME="192.168.0.1"
WARNING=60
CRITICAL=65

# Option processing
print_usage() {
  echo "Usage: ./check_snmp_cpu -H 192.168.0.1 -C public -w 60 -c 65"
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
  echo "You may redistribute copies of the plugin under the terms of the MIT License."}

print_help() {
  print_version
  echo ""
  print_usage
  echo ""
  echo "Checks Temperature of Lancom Router"
  echo ""
  echo "-H ADDRESS"
  echo "   Name or IP address of host (default: 192.168.0.1)"
  echo "-C STRING"
  echo "   Community name for the host SNMP agent (default: public)"
  echo "-w INTEGER"
  echo "   Warning level for memory usage in percent (default: 60)"
  echo "-c INTEGER"
  echo "   Critical level for memory usage in percent (default: 65)"
  echo "-h"
  echo "   Print this help screen"
  echo "-V"
  echo "   Print version and license information"
  echo ""
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

# Get Temperature in degrees Celsius
TEMP=`$CMD_SNMPWALK -t 2 -r 2 -v 1 -c $COMMUNITY $HOSTNAME $OID_TEMP | $CMD_AWK '{ print $4 }'`
TEMPMIN=`$CMD_SNMPWALK -t 2 -r 2 -v 1 -c $COMMUNITY $HOSTNAME $OID_TEMPMIN | $CMD_AWK '{ print $4 }'`
TEMPMAX=`$CMD_SNMPWALK -t 2 -r 2 -v 1 -c $COMMUNITY $HOSTNAME $OID_TEMPMAX | $CMD_AWK '{ print $4 }'`

if [ $WARNING -gt $TEMPMAX ] || [ $CRITICAL -gt $TEMPMAX ]; then
  echo "Value not allowed"
  exit $STATE_UNKNOWN
fi

if [ $WARNING != 0 ] || [ $CRITICAL != 0 ]; then
  if [ $TEMP -gt $CRITICAL ] && [ $CRITICAL != 0 ]; then
    STATE=$STATE_CRITICAL
  elif [ $TEMP -gt $CRITICAL ] && [ $CRITICAL != 0 ]; then
    STATE=$STATE_CRITICAL
  else
    STATE=$STATE_OK
  fi
fi

DESCRIPTION="Temperature : $TEMP°C | temperature=$TEMP;$WARNING;$CRITICAL;0"

echo $DESCRIPTION
exit $STATE
