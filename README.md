# lancom-router-nagios-plugin
Collection of Nagios Plugins which help to monitor a Lancom Router.

These Plugins can be used with Nagios/Thruk/Icinga.

## [exensio GmbH Blog](https://www.exensio.de/news-medien)

This repositroy is created for the blogpost: [Lancom Router per SNMP überwachen](https://www.exensio.de/news-medien/newsreader-blog/lancom-router-per-snmp-ueberwachen)

## Usage
```
./check_snmp_router_temperature.sh -H 192.168.0.1 -C public -w 60 -c 65
./check_snmp_router_cpu.sh -H 192.168.0.1 -C public -w 80 -c 90
./check_snmp_router_memory.sh -H 192.168.0.1 -C public -w 80 -c 90
```
