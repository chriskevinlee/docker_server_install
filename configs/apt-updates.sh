#!/bin/bash

echo""
echo "Refreshing Grafana Dashboard..."
sleep 3

normal_updates=$(apt list --upgradable 2>/dev/null | grep -c 'upgradable from':)
security_updates=$(apt list --upgradable 2>/dev/null | grep -c 'security')
reboot_required=$([ -f /var/run/reboot-required ] || [ -f /var/run/reboot-required.pkgs ] && echo 1 || echo 0)

normal_updates_metric_name=system_upgrades
security_updates_metric_name=system_security_upgrades
reboot_required_metric_name=reboot_required


cat <<EOF | curl --data-binary @- http://0.0.0.0:9091/metrics/job/normal_updates
$normal_updates_metric_name $normal_updates
EOF


cat <<EOF | curl --data-binary @- http://0.0.0.0:9091/metrics/job/security_updates
$security_updates_metric_name $security_updates
EOF


cat <<EOF | curl --data-binary @- http://0.0.0.0:9091/metrics/job/reboot_required
$reboot_required_metric_name $reboot_required
EOF


