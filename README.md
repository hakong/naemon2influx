### Forked from https://github.com/PickinA/nagios2influx and adjusted to work out of the box with Naemon with Adagios & Pynag.

naemon2influx takes Naemon performance data and writes it directly into InfluxDB's time sequence database in order that this data might be presented, for example using Grafana.

## Installation

Install naemon, pynag, influxdb and grafana.

Naemon/Adagios/Pynag install guide: https://github.com/opinkerfi/adagios/wiki/Naemon-and-Adagios-Install-Guide

#### Quick Influxdb how-to:
```
cat <<EOF | tee /etc/yum.repos.d/influxdb.repo
[influxdb]
name = InfluxDB Repository - RHEL \$releasever
baseurl = https://repos.influxdata.com/centos/\$releasever/\$basearch/stable
enabled = 1
gpgcheck = 1
gpgkey = https://repos.influxdata.com/influxdb.key
EOF

yum -y install influxdb
systemctl enable influxdb.service
systemctl start influxdb.service
echo 'create database naemon' | influx
```
##### Make sure influx is listening on HTTP
```
# /etc/influxdb/influxdb.conf, lines 207-215
[http]
  # Determines whether HTTP endpoint is enabled.
   enabled = true

  # The bind address used by the HTTP service.
   bind-address = "localhost:8086"

  # Determines whether HTTP authentication is enabled.
   auth-enabled = false
```
#### Quick Grafana how-to:
```
curl -s https://packagecloud.io/install/repositories/grafana/stable/script.rpm.sh | sudo bash
yum -y install grafana
firewall-cmd --add-port=3000/tcp --permanent
firewall-cmd --reload
systemctl enable grafana-server.service
systemctl start grafana-server.service
```
## Installing naemon2influx
`yum install https://github.com/hakong/naemon2influx/releases/download/v1.0.1/naemon2influx-1.0-01.el7.x86_64.rpm`
## Naemon Configuration

Ensure that you have service checks producing performace data in the standard format.

Ensure that these service have process_perf_data=1

```
pynag add command command_name=process-service-perfdata-naemon2influx command_line='/usr/bin/naemon-perf > /tmp/naemon-perf 2>&1'
pynag config --set process_performance_data=1
pynag config --set service_perfdata_file_processing_command=process-service-perfdata-naemon2influx
pynag config --set service_perfdata_file_mode=a
pynag config --set service_perfdata_file_processing_interval=15
pynag config --set service_perfdata_file_template='$TIMET$\t$HOSTNAME$\t$SERVICECHECKCOMMAND$\t$SERVICEDESC$\t$SERVICESTATE$\t$SERVICEPERFDATA$'
pynag config --set service_perfdata_file=/var/lib/naemon/service-perfdata
```
The above configuration will write a performace datafile into the location, and of the format expected by the default naemon2influx.cfg  configuration. If you wish to change the location or format of this file then see the naemon2influx man pages on how change the configuration.

It is recommended that once you have grafana dashboards presenting data for each host, to add action_url properties to your host templates of the form:

	action_url http://<grafana-server>:<grafana-port>/dashboard/db/$HOSTNAME$

## Notes
Data will be collected every time nagios runs a check, which by default is every 10 minutes. Increase the default check frequency if you want.
Example methods of increasing check frequency:
```
# Method 1:
# Update the generic-service template which most services use to have an interval of 1 minute instead of 10.
pynag update set check_interval=1 where name=generic-service and register=0
# Method 2:
# Use the naemon core config to set the interval length to 6 seconds instead of 60, making all intervals 1/10th.
pynag config --set interval_length=6
```
## Package building
The make file is capable of building RPM and Debian like packages, using 

 `# make rpm`

or

 `# make deb`

as appropriate. (Note for the debian version you need to be root or sudo)

If you wish to install by hand here is the RPM manifest.
```
-rw-rw----    1 naemon  naemon /etc/naemon/naemon2influx.cfg
-rwxr-xr-x    1 root    root   /usr/bin/naemon-perf
-rwxr-xr-x    1 root    root   /usr/bin/naemon2influx
-rw-r--r--    1 root    root   /usr/share/man/man1/naemon2influx.1.gz
-rw-r--r--    1 root    root   /usr/share/man/man5/naemon2influx.cfg.5.gz
```
 `# sudo make install `

Will install these files.

You can install the files anywhere you wish, but you will need to adjust configuration accordingly. YMMV.
