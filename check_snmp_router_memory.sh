#!/bin/bash

# check_snmp_router_memory
# Description : Checks memory usage on a Lancom Router

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
CMD_BASENAME="$(which basename)"
CMD_SNMPGET="$(which snmpget)"
CMD_SNMPWALK="$(which snmpwalk)"
CMD_AWK="$(which awk)"
CMD_GREP="$(which grep)"
CMD_BC="$(which bc)"
CMD_EXPR="$(which expr)"

# Script name
SCRIPTNAME=`$CMD_BASENAME $0`

# Version
VERSION="1.0"

# Plugin return codes
STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3

OID_MEMORYTOTAL="LCOS-MIB::lcsStatusHardwareInfoTotalMemoryKbytes"
OID_MEMORYFREE="LCOS-MIB::lcsStatusHardwareInfoFreeMemoryKbytes"

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
  echo "Usage: ./check_snmp_memory -H 192.168.0.1 -C public -w 80 -c 90"
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
  echo "This nagios plugin come with ABSOLUTELY NO WARRANTY."
  echo "You may redistribute copies of the plugin under the terms of the MIT License."
}

print_help() {
  print_version
  echo ""
  print_usage
  echo ""
  echo "Checks memory usage on a Lancom Router"
  echo ""
  echo "-H ADDRESS"
  echo "   Name or IP address of host (default: 192.168.0.1)"
  echo "-C STRING"
  echo "   Community name for the host's SNMP agent (default: public)"
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

# Plugin processing
size_convert() {
  if [ $VALUE -ge 1048576 ]; then
    VALUE=`echo "scale=2 ; ( ( $VALUE / 1024 ) / 1024 ) / 1024" | $CMD_BC`
    VALUE="$VALUE GB"
  elif [ $VALUE -ge 1024 ]; then
    VALUE=`echo "scale=2 ; ( $VALUE / 1024 ) / 1024" | $CMD_BC`
    VALUE="$VALUE MB"
  elif [ $VALUE -ge 0 ]; then
    VALUE=`echo "scale=2 ; $VALUE / 1024" | $CMD_BC`
    VALUE="$VALUE KB"
  else
    VALUE="$VALUE Octets"
  fi
}

# Get memory usage from router
TOTALMEMORY=`$CMD_SNMPWALK -t 2 -r 2 -v 1 -c $COMMUNITY $HOSTNAME $OID_MEMORYTOTAL | $CMD_AWK '{ print $4}'`
FREEMEMORY=`$CMD_SNMPWALK -t 2 -r 2 -v 1 -c $COMMUNITY $HOSTNAME $OID_MEMORYFREE | $CMD_AWK '{ print $4}'`

# Process data
if [ -n "$TOTALMEMORY" ] && [ -n "$FREEMEMORY" ]; then
  # calculate usage
  USEDMEMORY=`$CMD_EXPR \( $TOTALMEMORY - $FREEMEMORY \)`
  USEDMEMORY_POURCENT=`$CMD_EXPR \( $USEDMEMORY \* 100 \) / $TOTALMEMORY`
  
  if [ $WARNING != 0 ] || [ $CRITICAL != 0 ]; then
    PERFDATA_WARNING=`$CMD_EXPR \( $TOTALMEMORY \* $WARNING \) / 100`
    PERFDATA_CRITICAL=`$CMD_EXPR \( $TOTALMEMORY \* $CRITICAL \) / 100`
    if [ $USEDMEMORY_POURCENT -gt $CRITICAL ] && [ $CRITICAL != 0 ]; then
      STATE=$STATE_CRITICAL
    elif [ $USEDMEMORY_POURCENT -gt $WARNING ] && [ $WARNING != 0 ]; then
      STATE=$STATE_WARNING
    else
      STATE=$STATE_OK
    fi
    
    VALUE=$USEDMEMORY
    size_convert
    USEDMEMORY_FORMAT=$VALUE

    VALUE=$FREEMEMORY
    size_convert
    FREEMEMORY_FORMAT=$VALUE

    VALUE=$TOTALMEMORY
    size_convert
    TOTALMEMORY_FORMAT=$VALUE

    DESCRIPTION="Memory usage : $USEDMEMORY_FORMAT used for a total of $TOTALMEMORY_FORMAT (${USEDMEMORY_POURCENT}%)"
    DESCRIPTION="${DESCRIPTION}| used=${USEDMEMORY}B;$PERFDATA_WARNING;$PERFDATA_CRITICAL;0"
    
  else
    echo "Values not allowed"
    exit $STATE_UNKNOWN
  fi
else
  echo "Values may not be NULL"
  exit $STATE_UNKNOWN
fi

echo $DESCRIPTION
exit $STATE