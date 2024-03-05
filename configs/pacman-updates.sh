#!/bin/bash

echo""
echo "Refreshing Grafana Dashboard..."
sleep 3

pacman -Sy > /dev/null
normal_updates=$(pacman -Qu | wc -l)


###### reboot
VERSION=""

# Iterate output of `file` in linux images
# If the keyword 'version' is found: mark the next field as "value"
IS_IN_NEXTLINE=0
for I in `file /boot/vmlinuz*`; do
        if [ $IS_IN_NEXTLINE -eq 1 ]; then
                VERSION="${I}"
                IS_IN_NEXTLINE=0
        else
                if [ "${I}" = "version" ]; then
                        IS_IN_NEXTLINE=1
                fi
        fi
done

if [ ! "${VERSION}" = "" ]; then
    CURRENT_KERNEL=`uname -r`
    if [ ! "${CURRENT_KERNEL}" = "${VERSION}" ]; then
        reboot_required=1
else
    reboot_required=0
    fi
fi
#####

normal_updates_metric_name=system_upgrades
reboot_required_metric_name=reboot_required


cat <<EOF | curl --data-binary @- http://0.0.0.0:9091/metrics/job/normal_updates
$normal_updates_metric_name $normal_updates
EOF


cat <<EOF | curl --data-binary @- http://0.0.0.0:9091/metrics/job/reboot_required
$reboot_required_metric_name $reboot_required
EOF



























# #!/bin/bash

# echo""
# echo "Refreshing Grafana Dashboard..."
# sleep 3

# normal_updates=$(command_here)
# security_updates=$(command_here)
# reboot_required=$(command_here)

# normal_updates_metric_name=system_upgrades
# security_updates_metric_name=system_security_upgrades
# reboot_required_metric_name=reboot_required

# reboot_required_status=$([[ $reboot_required -gt 0 ]] && echo 1 || echo 0)

# cat <<EOF | curl --data-binary @- http://0.0.0.0:9091/metrics/job/normal_updates
# $normal_updates_metric_name $normal_updates
# EOF

# cat <<EOF | curl --data-binary @- http://0.0.0.0:9091/metrics/job/security_updates
# $security_updates_metric_name $security_updates
# EOF

# cat <<EOF | curl --data-binary @- http://0.0.0.0:9091/metrics/job/reboot_required
# $reboot_required_metric_name $reboot_required_status
# EOF
