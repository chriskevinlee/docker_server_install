#!/bin/bash

echo""
echo "Refreshing Grafana Dashboard..."
sleep 3

normal_updates=$(dnf updateinfo list --available --assumeno | grep -v "^$" | grep -v "Last" | wc -l)
security_updates=$(dnf check-update --security | grep -v "^$" | grep -v "Last" | wc -l)
reboot_required=$(dnf needs-restarting -usr | grep -v "^$" | grep -v "Reboot" | grep -v "No" | wc -l)

normal_updates_metric_name=system_upgrades
security_updates_metric_name=system_security_upgrades
reboot_required_metric_name=reboot_required

reboot_required_status=$([[ $reboot_required -gt 0 ]] && echo 1 || echo 0)

cat <<EOF | curl --data-binary @- http://0.0.0.0:9091/metrics/job/normal_updates
$normal_updates_metric_name $normal_updates
EOF

cat <<EOF | curl --data-binary @- http://0.0.0.0:9091/metrics/job/security_updates
$security_updates_metric_name $security_updates
EOF

cat <<EOF | curl --data-binary @- http://0.0.0.0:9091/metrics/job/reboot_required
$reboot_required_metric_name $reboot_required_status
EOF
