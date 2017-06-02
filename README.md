##### Forked from https://github.com/PickinA/nagios2influx and adjusted to work out of the box with Naemon with Adagios & Pynag.

nagios2influx takes Nagios/Naemon performance data and writes it directly into InfluxDB's time sequence database in order that this data might be presented, for example using Grafana.

The motivation for this plugin came when I failed to to get other projects, based that were around the carbon/graphite interface, to work. I had no need for Graphite and thought there should be a simpler and more straight forward solution. I had previously used the nagiosgraph plugin (indeed still do) to display graphic historic data from Nagios. However I wanted to get the performance data into other dashboards where data is gathered from other sources, while still alowing me to use legecy systems of graphing. Further, I didn't want to create a separate service that could fail, I wanted something that would use Nagios's internal scheduler to operate.

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
## Package building
The make file is capable of building RPM and Debian like packages, using 

 `# make rpm`

or

 `# make deb`

as appropriate. (Note for the debian version you need to be root or sudo)

If you wish to install by hand here is the RPM manifest.
```
-rw-rw----    1 naemon  naemon /etc/naemon/nagios2influx.cfg
-rwxr-xr-x    1 root    root   /usr/bin/nagios-perf
-rwxr-xr-x    1 root    root   /usr/bin/nagios2influx
-rw-r--r--    1 root    root   /usr/share/man/man1/nagios2influx.1.gz
-rw-r--r--    1 root    root   /usr/share/man/man5/nagios2influx.cfg.5.gz
```
 `# sudo make install `

Will install these files.

You can install the files anywhere you wish, but you will need to adjust configuration accordingly. YMMV.

## Naemon Configuration

Ensure that you have service checks producing performace data in the standard format.

Ensure that these service have process_perf_data=1

```
pynag add command command_name=process-service-perfdata-nagios2influx command_line='/usr/local/bin/nagios-perf > /tmp/nagios-perf 2>&1'
pynag config --set process_performance_data=1
pynag config --set service_perfdata_file_processing_command=process-service-perfdata-nagios2influx
pynag config --set service_perfdata_file_mode=a
pynag config --set service_perfdata_file_processing_interval=15
pynag config --set service_perfdata_file_template='$TIMET$\t$HOSTNAME$\t$SERVICECHECKCOMMAND$\t$SERVICEDESC$\t$SERVICESTATE$\t$SERVICEPERFDATA$'
pynag config --set service_perfdata_file=/var/lib/naemon/service-perfdata
```
The above configuration will write a performace datafile into the location, and of the format expected by the default nagios2influx.cfg  configuration. If you wish to change the location or format of this file then see the nagios2influx man pages on how change the configuration.

It is recommended that once you have grafana dashboards presenting data for each host, to add action_url properties to your host templates of the form:

	action_url http://<grafana-server>:<grafana-port>/dashboard/db/$HOSTNAME$
