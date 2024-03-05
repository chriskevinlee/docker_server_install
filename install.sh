#!/bin/bash

### (JUST A NOTE FOR MYSELF)sudo -u www-data php /var/www/html/occ files:scan --all (next for new files when files are created/uploaded via terminal)

###  FIRST check to make sure moreutils install for monitor for each package manager

### add wordpress bills letters

### look at unintened upgrades for auto updates

### may need to add a section to check to make sure docker if running and enabled, 
### if not try and enable and restart docker if not ask user to reboot and re run script with opion 2




################################################################

# (Variable) Check to see if pacman is installed
	pac=$(command -v pacman)

# (Variable) Check to see if apt is installed
	apt=$(command -v apt)

# (Variable) Check to see if dnf is installed
	dnf=$(command -v dnf)

# Check what firewall is installed. This is to create a variable so can I can display the right firewall when asking the user ...
 # Would you like to use $firewall as front end tool to manage iptables? y/n 
	if command -v firewalld > /dev/null; then
    	firewall="firewalld(firewall-cmd)"
	elif command -v ufw > /dev/null; then
	    firewall=ufw
	fi

# (Variable) Check what distro is being used
	os_check=$(cat /etc/os-release | grep -w NAME= | awk -F '"' '{print $2}')

# (Variable) This Will get the private or public IP address and display the IP address to the user when needed
	 ip_address=$(ip route get 1 | grep -oP 'src \K\S+')

# (Variable) This sets default path for the users configs to the user home directory with a config directory
	# Getting the user's home directory
	user_home=$(eval echo ~$SUDO_USER)
	# Set the default path to the user's home directory
	path=$user_home/container_configs

# (Variable) checks to see if firewalld is active or inactive
	firewalld=$(systemctl is-active firewalld)

# (Function) container_names will check to make sure the user have not typed any special characters for container names. 
# Nextcloud has its own code for checking this
	container_names () {
		clear
		read -p "Enter a name for $user_option container? " container_name

		while [[ $container_name =~ [^a-zA-Z0-9_] ]]; do
			clear
			echo "Invaild Input. Please enter letters, numbers and under score"
			read -p "Enter a name for $user_option container? " container_name
		done
	}

# (Function) ports_used will check to see if a port number is already in use before running a container 
	ports_used () {
		used_ports=$(ss -tuln | awk 'NR > 1 {print $5}' | cut -d ':' -f 2)
	}

# (Function) check_all_ports will check to make sure a user have added a port number and not character
	check_all_ports() {
					while true; do   
					    clear
					    if ! [[ "$check_port" =~ ^[0-9]+$ ]]; then
					    	echo "Invaild Input, enter a port number between 0 and 65535"
					        read -p "Please enter a Port Number. " check_port
					    elif (($check_port < 0 || $check_port > 65535)); then
					    	echo "Invaild Input, enter a port number between 0 and 65535"
					        read -p "Please enter a Port Number. " check_port
					    elif echo "${used_ports[*]}" | grep -w -q "$check_port"; then
					    	echo "Port $check_port is already in use. Please choose a different Port Number."
					        read -p "Please enter a Port Number. " check_port
					    else
					        break
					    fi
					done
	}

# (Function) path_configs sets up there to store the configs for containers 
	path_configs () {

	read -p "Use 1 to use default path of $path or 2 for a custom path " default_custom

	while [[ ! $default_custom = 1 ]] && [[ ! $default_custom = 2 ]]; do
		clear
		echo "Invaild Input Please enter 1/2"
		read -p "Use 1 to use default path of $path or 2 for a custom path " default_custom
	done

	if [[ $default_custom = 2 ]]; then
		clear
		read -p "Enter a path where you would like to put $user_option Directories? eg /home/myuser/  " path

		while [[ -z $path ]]; do
			clear
			echo "Invaild Input. You did not enter a path."
			read -p "Where you would like to put $user_option Directories? eg /home/myuser/  " path
		done

		clear
		read -p "You have entered $path, Please comfirm by re-entering the path or type RE-TRY! " comfirm_path

		if [[ $comfirm_path = "RE-TRY!" ]]; then
			unset comfirm_path
			clear
			read -p "Enter a path where you would like to put $user_option Directories? eg /home/myuser/  " path
			clear
			read -p "You have entered $path, Please comfirm by re-entering the path " comfirm_path
		fi

		while [[ -z $comfirm_path ]]; do
			clear
			echo "Invaild Input. You did not comfirm the path $path. "
			read -p "Enter a path where you would like to put $user_option Directories? eg /home/myuser/  " comfirm_path
		done

		while [[ ! $path = $comfirm_path ]]; do
			clear
			echo "Invaild Input. You have entered $path, and $comfirm_path which are differnt"
			read -p "Please comfirm by re-entering the path " comfirm_path
		done
	fi
	}
										
# (Function) list_containers will display a option for the user to install any containers that are in the list
	list_containers () {

	# Lists the options in the menu for the user to choose, below also need to watch
	container_options=("Portainer" "Nginx" "Jellyfin" "qBittorrent" "Nextcloud" "AdGuard Home" "Memos" "Watchtower" "BeamMP Server" "Monitor" "Exit Script")
	PS3=" Please Enter a Number? "

	# Menu items below need to match above
	select user_option in "${container_options[@]}" 
	do
		case $user_option in
			"Portainer" )
				clear
				echo "Downloading Portainer CE"
				sleep 3
				docker pull portainer/portainer-ce
				clear
				docker volume create portainer_data
				clear

				container_names

				clear

				ports_used
																		
				read -p "Please choose a port number to access Portainter Web Interface? " check_port
																		
				check_all_ports
																		
				echo "WebApp=Portainer:Container=$container_name: "$ip_address":"$check_port"" >> docker_ports.log
				clear

				echo "Running Docker run for Portainer"
				sleep 3
				docker run -d -p 8000:8000 -p "$check_port":9000 --name=$container_name --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce
				clear

				echo "Please go to "$ip_address":"$check_port" and create a user."
				read -p "Once Done please enter y to comfirm? " y

				while [[ -z $y || ("$y" != y) ]]; do
					clear
					echo "Invaild Input. Please enter y"
					echo "Please go to "$ip_address":"$check_port" and create a user."
					read -p "Once Done please enter y to comfirm? " y
				done
				;;
			"Nginx" )
				clear
				echo "Downloading nginx-proxy-manager"
				sleep 3
				docker pull jc21/nginx-proxy-manager

				clear

				ports_used

				path_configs

				clear

				container_names

				clear
				read -p "Please choose a port number to access Nginx Web Interface? " check_port

				check_all_ports

				echo "WebApp=Nginx:Container=$container_name: "$ip_address":"$check_port"" >> docker_ports.log

				clear
				echo "Running Docker run for nginx"
				sleep 3

				docker run -d \
				--name "$container_name" \
				-p 80:80 \
				-p 443:443 \
				-p $check_port:81 \
				-v "$path"/nginx/data:/data \
				-v "$path"/nginx/letsencrypt:/etc/letsencrypt \
				--restart=unless-stopped \
				jc21/nginx-proxy-manager

				clear

				echo "Please go to "$ip_address":"$check_port" and login with default email_address=admin@example.com and password=changeme."
				read -p "Once Done Please enter y to confirm? " y
				while [[ -z $y || ("$y" != y) ]]; do
					echo "Invaild Input. Please enter y"
					echo "Please go to "$ip_address":"$check_port" and login with default email_address=admin@example.com and password=changeme."
					read -p "Once Done Please enter y to confirm? " y
				done
				;;
			"Jellyfin" )
				clear
				echo "Downloading Jellyfin..."
				sleep 3
				docker pull jellyfin/jellyfin

				clear

				container_names

				clear

				path_configs

				clear

				ports_used
				read -p "Please choose a port number to access Jellyfin Web Interface? " check_port
				check_all_ports

				echo "WebApp=Jellyfin:Container=$container_name: "$ip_address":"$check_port"" >> docker_ports.log

				clear
				echo "Running Docker run for Jellyfin"
				sleep 3
				docker run -d \
				 --name "$container_name" \
				 --user 0:0 \
				 --publish "$check_port":8096 \
				 --volume "$path"/"$container_name"/config:/config \
				 --volume "$path"/"$container_name"/cache:/cache \
				 --volume "$path"/"$container_name"/music:/media \
				 --restart=unless-stopped \
				 jellyfin/jellyfin

				 clear
				 echo "Please go to "$ip_address":"$check_port" and create a user and optionally create any libraries needed."
				 read -p "Once Done please enter y to comfirm? " y
				 while [[ -z $y || ("$y" != y) ]]; do
				 	echo "Invaild Input. Please Enter y"
				 	echo "Please go to "$ip_address":"$check_port" and create a user and optionally create any libraries needed."
				    read -p "Once Done please enter y to comfirm? " y
				 done
				;;
			"qBittorrent" )
				clear
				echo "Downloading qBittorrent..."
				sleep 3
				docker pull linuxserver/qbittorrent

				clear

				container_names

				clear

				path_configs

				clear

				ports_used
				read -p "Please Choose a Port Number to Access qBittorrent Web Interface? " check_port
				check_all_ports

				echo "WebApp=qBittorrent:Container=$container_name: "$ip_address":"$check_port"" >> docker_ports.log

				clear
				echo "Running Docker run for qBittorrent"
				sleep 3

				docker run -d \
				  --name="$container_name" \
				  -e PUID=0 \
				  -e PGID=0 \
				  -e WEBUI_PORT="$check_port" \
				  -p "$check_port":"$check_port" \
				  -v "$path"/"$container_name"/config/config \
				  -v "$path"/"$container_name"/downloads:/downloads \
				  --restart unless-stopped \
				  lscr.io/linuxserver/qbittorrent:latest
				  # -p 6881:6881 \
				  # -p 6881:6881/udp \

				 clear
				 echo "Please go to "$ip_address":"$check_port" and login with the default username=admin and for the password see docker logs "$container_name" and change default login. "
				 read -p "Once Done please enter y to comfirm? " y
				 while [[ -z $y || ("$y" != y) ]]; do
				 	echo "Invaild Input. Please enter y"
				 	echo "Please go to "$ip_address":"$check_port" and login with the default username=admin and for the password see docker logs "$container_name" and change default login. "
				    read -p "Once Done please enter y to comfirm? " y
				 done
				;;
			"Nextcloud" ) 
				clear
				echo "Downloading Nextcloud"
				sleep 3
				docker pull nextcloud

				clear
				echo "Downloading mariadb"
				sleep 3
				docker pull mariadb

				clear
				read -p "Enter a name for mariadb container to use with nextcloud? " container_name
				while [[ $container_name =~ [^a-zA-Z0-9_] ]]; do
					clear
					echo "Invaild Input. Please enter letters, numbers and under score"
					read -p "Enter a name for mariadb container to use with nextcloud? " container_name
				done

				container_name_db=$(echo $container_name)

				clear
				read -p "Enter a name for Nextcloud container? " container_name
				while [[ $container_name =~ [^a-zA-Z0-9_] ]]; do
					clear
					echo "Invaild Input. Please enter letters, numbers and under score"
					read -p "Enter a name for Nextcloud container? " container_name
				done

				clear
				echo "Please choose mariadb details this will be used to connect mariadb to nextcloud"
				read -p "Please choose a mysql root password? " mysql_root_password
				read -p "Please choose a mysql password? " mysql_password
				read -p "Please choose a mysql database name? " mysql_database
				read -p "please choose a mysql user? " mysql_user
				clear

				path_configs

				clear

				ports_used
				read -p "Please Choose a port to Access Nextcloud Web Interface? " check_port
				check_all_ports

				echo "WebApp=Nextcloud:Container=$container_name: "$ip_address":"$check_port"" >> docker_ports.log

				clear
				echo "Running Docker run for mariadb"
				sleep 3

				docker run -d \
				  --name "$container_name_db" \
				  -e MYSQL_ROOT_PASSWORD="$mysql_root_password" \
				  -e MYSQL_PASSWORD="$mysql_password" \
				  -e MYSQL_DATABASE="$mysql_database" \
				  -e MYSQL_USER="$mysql_user" \
				  -e MYSQL_HOST="$container_name_db" \
				  -v "$container_name_db"_data:/var/lib/mysql \
				  --restart unless-stopped \
				  mariadb
				  sleep 4

				clear
				echo "Running Docker run for Nextcloud"
				sleep 3

				  docker run -d \
				   --name "$container_name" \
				   --link "$container_name_db":mariadb \
				   --restart unless-stopped \
				   -v "$container_name":/var/www/html \
				   -e MYSQL_ROOT_PASSWORD="$mysql_root_password" \
				   -e MYSQL_PASSWORD="$mysql_password" \
				   -e MYSQL_DATABASE="$mysql_database" \
				   -e MYSQL_USER="$mysql_user" \
				   -e MYSQL_HOST="$container_name_db" \
				   -v "$container_name"_apps:/var/www/html/custom_apps \
				   -v "$container_name"_config:/var/www/html/config \
				   -v "$path"/"$container_name"/:/var/www/html/data \
				   -p "$check_port":80 \
				  nextcloud
				  sleep 4

				clear

				echo "If you wish to use https you may need to add OVERWRITEPROTOCOL=https to environment variable in the docker container."
				echo "Please go to "$ip_address":"$check_port" and setup database and user."
				read -p "Once Done please enter y to comfirm? " y
				while [[ -z $y || ("$y" != y) ]]; do
					echo "Invaild Input. Please enter y"
					echo "If you wish to use https you may need to add OVERWRITEPROTOCOL=https to environment variable in the docker container."
					echo "Please go to "$ip_address":"$check_port" and setup database and user."
					read -p "Once Done please enter y to comfirm? " y
				done
				;;
			"AdGuard Home" )
				aduard=$(docker ps -a | grep -o adguard | uniq)

				if [[ $adguard = adguard ]]; then
				    echo "adguard is already installed. Only ONE instance can be ruuning using this script. If you need another instance ruuning please install manually"
				fi
				clear
				echo "Downloading AdGuard Home"
				sleep 3
				docker pull adguard/adguardhome

				clear

				echo "Disabling DNSStubListener..."
				echo "If you try to run AdGuardHome on a system where the resolved daemon is started, docker will fail to bind on port 53, because resolved daemon is listening on 127.0.0.53:53"
				sleep 5
				mkdir /etc/systemd/resolved.conf.d/
				echo "[Resolve]" >> /etc/systemd/resolved.conf.d/adguardhome.conf
				echo "DNS=127.0.0.1" >> /etc/systemd/resolved.conf.d/adguardhome.conf
				echo "DNSStubListener=no" >> /etc/systemd/resolved.conf.d/adguardhome.conf
				mv /etc/resolv.conf /etc/resolv.conf.backup
				ln -s /run/systemd/resolve/resolv.conf /etc/resolv.conf
				systemctl reload-or-restart systemd-resolved

				clear

				path_configs

				container_names

				ports_used
				clear
				read -p "Please Choose a Port to use for AdGuard Home? " check_port
				check_all_ports

				clear

				echo "WebApp=AdGuard Home:Container=$container_name: "$ip_address":"$check_port"" >> docker_ports.log

				clear
				echo "Running docker run for AdGuard Home"
				sleep 3
				docker run --name adguard\
				    --restart unless-stopped\
				    -v "$path"/adguard/workdir:/opt/adguardhome/work\
				    -v "$path"/adguard/confdir:/opt/adguardhome/conf\
				    -p 53:53/tcp -p 53:53/udp\
				    -p 67:67/udp \
				    -p "$check_port":3000/tcp\
				    -p 853:853/tcp\
				    -p 784:784/udp -p 853:853/udp -p 8853:8853/udp\
				    -p 5443:5443/tcp -p 5443:5443/udp\
				    -d adguard/adguardhome

				clear
				echo "Please go to "$ip_address":"$check_port" to finish Setup (WARRNING! Make sure you use port 3000 at the setup page, otherwise you will be unable to access admin login page). You must use "$ip_address":"$adguard_port" after setup is complete."
				read -p "Once Done Please enter y to confirm? " y

				while [[ -z $y || ("$y" != y) ]]; do
					echo "Invaild Input. Please enter y"
					echo "Please go to "$ip_address":"$check_port" to finish Setup (WARRNING! Make sure you use port 3000 at the setup page, otherwise you will be unable to access admin login page). You must use "$ip_address":"$adguard_port" after setup is complete."
					read -p "Once Done Please enter y to confirm? " y
				done
				;;
			"Memos" )
				clear
				echo "Downloading Memos"
				sleep 3
				docker pull ghcr.io/usememos/memos:latest

				clear

				container_names

				clear

				path_configs

				clear

				ports_used

				read -p "Please choose a port number to access Memos Web Interface? " check_port

				check_all_ports

				echo "WebApp=Memos:Container=$container_name: "$ip_address":"$check_port"" >> docker_ports.log

				clear
				echo "Running docker run for Memos"

				docker run -d \
				--name $container_name \
				-p $check_port:5230 \
				-v "$path"/"$container_name"/:/var/opt/memos \
				--restart unless-stopped \
				ghcr.io/usememos/memos:latest

				clear

				echo "Please go to "$ip_address":"$check_port" and create a user."
				read -p "Once Done please enter y to comfirm? " y
				while [[ -z $y || ("$y" != y) ]]; do
					clear
					echo "Invaild Input. Please Enter y"
					echo "Please go to "$ip_address":"$check_port" and create a user."
					read -p "Once Done please enter y to comfirm? " y
				done
				;;
			"Watchtower" )
				clear
				echo "Downloading Watchtower"
				sleep 3
				docker pull containrrr/watchtower

				echo "Running docker run for Watchtower, using default settings of..."
				echo "--schedule 0 0 0 * * 0 --cleanup --include-stopped --log-level debug"
				sleep 3

				docker run -d \
				--name watchtower \
				--restart unless-stopped \
				-v /var/run/docker.sock:/var/run/docker.sock \
				containrrr/watchtower \
				--schedule "0 0 0 * * 0" --cleanup --include-stopped --log-level debug
				;;
			"BeamMP Server" )

				# Downloading/clone BeamMP repository, renaming directory, making a copy of .env file, making mods directory and setting permissions 
					clear
					path_configs
					container_names
					echo "Downloading BeamMP docker-compose"
					sleep 3
					git clone https://github.com/RouHim/beammp-container-image.git $path/$container_name #$path added
					clear
					cd $path/$container_name
					cp .env.example .env
					mkdir client-mods server-mods
					chmod 777 client-mods server-mods

				# Asking the user if they want to set their server to be private or to be public
				# Public servers will show on the list of BeamMP Server lists
					clear
					read -p "Please Set BEAMMP_PRIVATE to true or false (Default: true) " tf

					while [[ ! $tf = true ]] && [[ ! $tf = false ]]; do
						clear
						echo "Invaild Input"
						read -p "Please Set BEAMMP_PRIVATE to true or false (Default: true) " tf
					done

					if [[ $tf = true ]]; then
						sed -i 's/BEAMMP_PRIVATE=true/BEAMMP_PRIVATE=true/g' .env
					elif [[ $tf = false ]]; then
						sed -i 's/BEAMMP_PRIVATE=true/BEAMMP_PRIVATE=false/g' .env
					fi

				# Asking the user how many cars per player can have
					clear
					read -p "Please Set BEAMMP_MAX_CARS to a Number (Default: 1) " numcar

					while [[ ! $numcar =~ ^[0-9]+$ ]]; do
						clear
						echo "Invaild Input"
						read -p "Please Set BEAMMP_MAX_CARS to a Number (Default: 1) " numcar
					done

					if [[ $numcar =~ ^[0-9]+$ ]]; then
						sed -i "s/BEAMMP_MAX_CARS=1/BEAMMP_MAX_CARS=$numcar/g" .env	
					fi

					# Asking the user how many players can be on the server
					clear
					read -p "Please Set BEAMMP_MAX_PLAYERS to a Number (Default: 10) " numplayers

					while [[ ! $numplayers =~ ^[0-9]+$ ]]; do
						clear
						echo "Invaild Input"
						read -p "Please Set BEAMMP_MAX_PLAYERS to a Number (Default: 10)" numplayers
					done

					if [[ $numplayers =~ ^[0-9]+$ ]]; then
						sed -i "s/BEAMMP_MAX_PLAYERS=10/BEAMMP_MAX_PLAYERS=$numplayers/g" .env
						
					fi

				# Asking the user what map they want to use
					clear
					read -p "Please Set BEAMMP_MAP to add a map (Default: /levels/gridmap_v2/info.json) " beammp_map

					while [[ -z $beammp_map ]]; do
					    clear
					    echo "Invalid Input"
					    read -p "Please Set BEAMMP_MAP to add a map (Default: /levels/gridmap_v2/info.json) " beammp_map
					done

					if [[ ! -z $beammp_map ]]; then
					    # Escape special characters in beammp_map
					    escaped_beammp_map=$(printf '%s\n' "$beammp_map" | sed 's/[\&/]/\\&/g')
					    sed -i "s#BEAMMP_MAP=\"/levels/gridmap_v2/info.json\"#BEAMMP_MAP=\"$escaped_beammp_map\"#g" .env
					fi

				# Asking the user what name they want to give to the server, will name will show on the public server list
					clear
					read -p "Please Set BEAMMP_NAME for the name of the server (Default: BeamMP New Server) " servername
					while [[ -z $servername ]]; do
					    clear
					    echo "Invalid Input"
					    read -p "Please Set a name for the BeamMP Server (Default: BeamMP New Server) " servername
					done

					if [[ ! -z $servername ]]; then
					    escaped_servername=$(printf '%s\n' "$servername" | sed 's/[\&/]/\\&/g')
					    sed -i "s/BEAMMP_NAME=\"BeamMP New Server\"/BEAMMP_NAME=\"$escaped_servername\"/g" .env
					fi

				# Asking the user to enter a desscription
					clear
					read -p "Please Set BEAMMP_DESCRIPTION for a description for the server (Default: BeamMP Default Description) " beammp_description

					while [[ -z $beammp_description ]]; do
					    clear
					    echo "Invalid Input"
						read -p "Please Set BEAMMP_DESCRIPTION for a description for the server (Default: BeamMP Default Description) " beammp_description
					done

					if [[ ! -z $beammp_description ]]; then
					    escaped_beammp_description=$(printf '%s\n' "$beammp_description" | sed 's/[\&/]/\\&/g')
					    sed -i "s/BEAMMP_DESCRIPTION=\"BeamMP Default Description\"/BEAMMP_DESCRIPTION=\"$escaped_beammp_description\"/g" .env

					fi

				# Asking the user what port they want to use for the BeamMP server. This will be the port a client need's to connect
					clear
					ports_used # Added	
					read -p "Please Set BEAMMP_PORT port number (Default: 30814) " check_port
					check_all_ports

					while [[ ! $check_port =~ ^[0-9]+$ ]]; do
						clear
						echo "Invaild Input"
						read -p "Please Set BEAMMP_PORT port number (Default: 30814) " check_port
					done

					if [[ ! -z $check_port ]]; then
						sed -i "s/BEAMMP_PORT=30814/BEAMMP_PORT=$check_port/g" .env
					fi

				# Asking the user if they want to have debug logging, this will show extra logs
					clear
					read -p "Please Set BEAMMP_DEBUG to true or false (Default: false) " tf

					while [[ ! $tf = true ]] && [[ ! $tf = false ]]; do
						clear
						echo "Invaild Input"
						read -p "Please Set BEAMMP_DEBUG to true or false (Default: false) " tf
					done

					if [[ $tf = true ]]; then
						sed -i 's/BEAMMP_DEBUG=false/BEAMMP_DEBUG=true/g' .env
					elif [[ $tf = false ]]; then
						sed -i 's/BEAMMP_DEBUG=false/BEAMMP_DEBUG=false/g' .env
					fi

				# Asking the user to enter their auth key. The user needs to go to keymaster.beammp.com and login with discord to genterate a key
					clear
					read -p "Please Set BEAMMP_AUTH_KEY and add your auth key, you can create one here keymaster.beammp.com " beammp_auth_key

					while [[ -z $beammp_auth_key ]]; do
					    clear
					    echo "Invalid Input"
					    read -p "Please Set BEAMMP_AUTH_KEY and add your auth key, you can create one here keymaster.beammp.com " beammp_auth_key
					done

					if [[ ! -z $beammp_auth_key ]]; then
					    # Escape special characters in beammp_auth_key
					    escaped_beammp_auth_key=$(printf '%s\n' "$beammp_auth_key" | sed 's/[\&/]/\\&/g')
					    sed -i "s/BEAMMP_AUTH_KEY=\".*\"/BEAMMP_AUTH_KEY=\"$escaped_beammp_auth_key\"/g" .env
					fi

				# Removing port mappings and adding container to "host" docker network. As it seems that client can't connect if
				 # the container is in a "bridge" docker network
					sed -i '/ports:/d' docker-compose.yml
					sed -i '/"${BEAMMP_PORT}:${BEAMMP_PORT}\/tcp"/d' docker-compose.yml
					sed -i '/"${BEAMMP_PORT}:${BEAMMP_PORT}\/udp"/d' docker-compose.yml
					sed -i '/^    logging:/i \    network_mode: host' docker-compose.yml
					sed -i "s/beammp-server:/&\n    container_name: $container_name/" docker-compose.yml
					sed -i '/network_mode: host/ a\    restart: unless-stopped' docker-compose.yml

				# Running Docker pull and docker-compose to download and run docker container
					clear
					echo "Running Docker pull and docker-compose up -d"
					docker-compose pull && docker-compose up -d
					ln -s .env env_configuration #added

			  ;;
			"Monitor" )
				clear
				echo "Install Node Exporter on Host"
				sleep 3

				if [[ ! -z $pac ]]; then
					pacman -Sy
					pacman -S wget
				fi

				wget -P /tmp/ https://github.com/prometheus/node_exporter/releases/download/v1.5.0/node_exporter-1.5.0.linux-amd64.tar.gz
				clear
				tar -xvzf /tmp/node_exporter-1.5.0.linux-amd64.tar.gz -C /tmp/
				clear
				mv /tmp/node_exporter-1.5.0.linux-amd64/node_exporter /usr/local/bin/
				sleep 3
				cp configs/node_exporter.service /etc/systemd/system/node_exporter.service
				systemctl daemon-reload
				systemctl enable node_exporter
				systemctl start node_exporter

				# Telling SELinux to allow node exporter to run on fedora
				if [[ ! -z $dnf ]]; then
				  sudo chcon -v -t bin_t /usr/local/bin/node_exporter
				  sudo systemctl restart node_exporter
				fi

				clear
				echo "Downloading Prometheus"
				sleep 3
				docker pull prom/prometheus

				clear
				read -p "Please Enter a name for Prometheus Container " container_name_prom
				while [[ $container_name_prom =~ [^a-zA-Z0-9_] ]] || [[ -z $container_name_prom ]]; do
				clear
				echo "Invaild Invaild. Please enter letters, numbers and under score"
				read -p "Enter a name for Prometheus container? " container_name_prom
				done

				clear
				ports_used
				read -p "Please choose a port number to access Prometheus Web Interface? " check_port
				check_all_ports

				clear

				read -p "Use 1 to use default path of $path or 2 for a custom path for prometheus.yml file " default_custom

				while [[ ! $default_custom = 1 ]] && [[ ! $default_custom = 2 ]]; do
				clear
				echo "Invaild Invaild. You need to use 1 or 2."
				read -p "Use 1 to use default path of $path or 2 for a custom path " default_custom
				done

				if [[ $default_custom = 1 ]]; then
				mkdir -p "$path"/prometheus/
				sleep 3
				cp configs/prometheus.yml "$path"/prometheus/prometheus.yml
				sed -i s/0.0.0.0/$ip_address/ "$path"/prometheus/prometheus.yml
				sleep 3
				elif [[ $default_custom = 2 ]]; then
				read -p "Enter a path where you would like to put prometheus.yml file? eg /home/myuser/  " path

				while [[ -z $path ]]; do
					clear
					echo "Invaild Input. Please enter a path"
					read -p "Enter a path where you would like to put prometheus.yml file? eg /home/myuser/  " path
				done

				mkdir -p "$path"/prometheus/
				sleep 3
				cp configs/prometheus.yml "$path"/prometheus/prometheus.yml
				sed -i s/0.0.0.0/$ip_address/ "$path"/prometheus/prometheus.yml
				sleep 3
				fi

				clear
				echo "Running docker run for Prometheus"
				docker run -d \
				--name $container_name_prom \
				--restart unless-stopped \
				-p "$check_port":9090 \
				-v "$path"/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml \
				prom/prometheus

				clear
				echo "Downloading Grafana"
				sleep 3
				docker pull grafana/grafana

				clear
				read -p "Please Enter a name for Grafana Container " container_name_gra
				while [[ $container_name_gra =~ [^a-zA-Z0-9_] ]] || [[ -z $container_name_gra ]]; do
				clear
				echo "Invaild Input. Please enter letters, numbers and under score"
				read -p "Enter a name for Grafana container? " container_name_gra
				done

				clear
				ports_used
				read -p "Please choose a port number to access Grafana Web Interface? " check_port
				check_all_ports

				clear

				read -p "Use 1 to use default path of $path or 2 for a custom path for grafana.ini " default_custom

				while [[ ! $default_custom = 1 ]] && [[ ! $default_custom = 2 ]]; do
				clear
				echo "Invaild Input. You need to use 1 or 2."
				read -p "Use 1 to use default path of $path or 2 for a custom path " default_custom
				done

				if [[ $default_custom = 1 ]]; then
				mkdir -p "$path"/grafana/
				sleep 3
				cp configs/grafana.ini "$path"/grafana/grafana.ini
				sleep 3
				elif [[ $default_custom = 2 ]]; then

				read -p "Enter a path where you would like to put grafana.ini file? eg /home/myuser/  " path

				while [[ -z $path ]]; do
					clear
					echo "Invaild Input. Please enter a path"
					read -p "Enter a path where you would like to put grafana.ini file? eg /home/myuser/  " path
				done

				mkdir -p "$path"/grafana/
				sleep 3
				cp configs/grafana.ini "$path"/grafana/grafana.ini
				sleep 3
				fi

				docker run -d --name=$container_name_gra --restart unless-stopped -p "$check_port":3000 -v "$path"/grafana/grafana.ini:/etc/grafana/grafana.ini grafana/grafana
				clear

				echo "Setting up to show upgrades on Grafana Dashboard"
				sleep 3

				docker pull prom/pushgateway
				docker run -d --name pushgateway --restart unless-stopped -p 9091:9091 prom/pushgateway

				##### need to create pacman updates file and work on this section
				if [[ ! -z $pac ]]; then
				  cp configs/pacman-updates.sh /usr/local/bin/pacman-updates.sh
				  sed -i s/0.0.0.0/$ip_address/ /usr/local/bin/pacman-updates.sh
				  chmod +x /usr/local/bin/pacman-updates.sh

				  pacman -Sy
				  pacman -S vi
				  pacman -S cronie
				  systemctl enable cronie
				  systemctl start cronie

				  echo "" >> /etc/bash.bashrc
				  echo "sudo() {" >> /etc/bash.bashrc
				  echo '    if [ "$1" == "pacman" ] && [ "$2" == "-Syu" ]; then' >> /etc/bash.bashrc
			      echo '        command sudo pacman -Syu && /usr/local/bin/pacman-updates.sh' >> /etc/bash.bashrc
			      echo '    else' >> /etc/bash.bashrc
				  echo '        command sudo "$@"' >> /etc/bash.bashrc
				  echo '    fi' >> /etc/bash.bashrc
				  echo "}" >> /etc/bash.bashrc

				  (echo "@reboot sleep 10 && /usr/local/bin/pacman-updates.sh"; echo "0 */6 * * * /usr/local/bin/pacman-updates.sh") | crontab -

				elif [[ ! -z $apt ]]; then
				  apt install -y curl
				  sleep 3
				  cp configs/apt-updates.sh /usr/local/bin/apt-updates.sh
				  sed -i s/0.0.0.0/$ip_address/ /usr/local/bin/apt-updates.sh
				  chmod +x /usr/local/bin/apt-updates.sh

				  # for apt upgrade command
				  echo "" >> /etc/bash.bashrc
				  echo "sudo() {" >> /etc/bash.bashrc
				  echo '    if [ "$1" == "apt" ] && [ "$2" == "upgrade" ]; then' >> /etc/bash.bashrc
				  echo '        command sudo apt upgrade && sudo apt update && sudo /usr/local/bin/apt-updates.sh' >> /etc/bash.bashrc
				  echo '    else' >> /etc/bash.bashrc
				  echo '        command sudo "$@"' >> /etc/bash.bashrc
				  echo '    fi' >> /etc/bash.bashrc
				  echo "}" >> /etc/bash.bashrc

				  # for apt update command
				  echo "" >> /etc/bash.bashrc
				  echo "sudo() {" >> /etc/bash.bashrc
				  echo '    if [ "$1" == "apt" ] && [ "$2" == "update" ]; then' >> /etc/bash.bashrc
				  echo '        command sudo apt update && sudo /usr/local/bin/apt-updates.sh' >> /etc/bash.bashrc
				  echo '    else' >> /etc/bash.bashrc
				  echo '        command sudo "$@"' >> /etc/bash.bashrc
				  echo '    fi' >> /etc/bash.bashrc
				  echo "}" >> /etc/bash.bashrc

				  (echo "@reboot sleep 10 && /usr/local/bin/apt-updates.sh"; echo "0 */6 * * * /usr/local/bin/apt-updates.sh") | crontab -

				elif [[ ! -z $dnf ]]; then
				  dnf install -y curl
				  dnf install -y cronie
				  dnf install -y dnf-utils
				  sleep 3
				  cp configs/dnf-updates.sh /usr/local/bin/dnf-updates.sh
				  sed -i s/0.0.0.0/$ip_address/ /usr/local/bin/dnf-updates.sh
				  chmod +x /usr/local/bin/dnf-updates.sh

				  echo "" >> /etc/bashrc
				  echo "sudo() {" >> /etc/bashrc
				  echo '    if [ "$1" == "dnf" ] && [ "$2" == "update" ]; then' >> /etc/bashrc
				  echo '        command sudo dnf update && sudo /usr/local/bin/dnf-updates.sh' >> /etc/bashrc
				  echo '    else' >> /etc/bashrc
				  echo '        command sudo "$@"' >> /etc/bashrc
				  echo '    fi' >> /etc/bashrc
				  echo "}" >> /etc/bashrc

				 (echo "@reboot sleep 10 && /usr/local/bin/dnf-updates.sh"; echo "0 */6 * * * /usr/local/bin/dnf-updates.sh") | crontab -

				 sudo chcon -t bin_t /usr/local/bin/dnf-updates.sh

				fi

				sed -i s/0.0.0.0/$ip_address/ "$path"/prometheus/prometheus.yml

				clear
				read -p "Would you like to use ssh tunnels to access prometheus, node and granfana? y/n " yn

				while [[ $yn != [yn] ]]; do
				clear
				echo "Invaild Input. Please enter y/n"
				read -p "Would you like to use ssh tunnels to access prometheus, node and granfana? y/n " yn
				done

				if [[ "$yn" = y ]]; then
				clear
				echo "A docker network needs to be created for prometheus to have a static ip address so that a firewall rule can be added to allow prometheus to commincate with node exporter on the host system"
				read -p "Please Enter a name for docker network " name
				clear
				echo "Creating $name Network..."
				sleep 3
				docker network create --subnet=192.168.10.0/24 $name
				clear
				echo "Disconnecting prometheus from default bridge network"
				sleep 3
				docker network disconnect bridge prometheus
				clear
				echo "Connecting prometheus to $name network"
				sleep 3
				docker network connect $name prometheus
				clear
				if [[ ! -z $apt ]]; then
					echo "Adding ufw firewall rules...(firewall will not be enabled)"
				    sleep 3
					ufw allow from 192.168.10.2 to any port 9100 comment 'Allow prometheus to connect to node exporter on port 9100'
					ufw allow in on docker0 to any port 9090 comment 'Allow docker0 to connect to port promtheus on port 9090'
				elif [[ ! -z $dnf ]]; then
					echo "Adding firewalld rules, firewall is enabled and started"
					sleep 3

					if [[ $firewalld = inactive ]]; then
					    systemctl start firewalld
					    sleep 3
					    firewall-cmd --permanent --zone=trusted --add-interface=docker0
					    firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="192.168.10.2" port port="9100" protocol="tcp" accept'
					    firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="192.168.10.2" port port="9191" protocol="tcp" accept'
					    firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="192.168.10.2" port port="9091" protocol="tcp" accept'
					    firewall-cmd --reload
					    sleep 3
					    systemctl stop firewalld
					  if [[ $firewalld = active ]]; then
						firewall-cmd --permanent --zone=trusted --add-interface=docker0
						firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="192.168.10.2" port port="9100" protocol="tcp" accept'
						firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="192.168.10.2" port port="9191" protocol="tcp" accept'
						firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="192.168.10.2" port port="9091" protocol="tcp" accept'
						firewall-cmd --reload
					  fi
					fi



				fi

				clear
				echo "$user_option Successfully Installed, it is safe to reboot or logout"
				echo "You need to logout and back in, reboot or run source /etc/bashrc to reload /etc/bashrc file to allow a function to run"
				echo "and update grafana dashboard with the correct update information. If you choose to Continue Please run source /etc/bashrc "
				read -p "Would you  like to reboot(r), logout(l) or Continuing with script(c) " rlc

				while [[ -z $rlc || ! $rlc = r && ! $rlc = l && ! $rlc = c ]]; do
					clear
					echo "Invaild Input, Please use r,l,c"
					echo "$user_option Successfully Installed, it is safe to reboot or logout"
					echo "You need to logout and back in, reboot or run source /etc/bashrc to reload /etc/bashrc file to allow a function to run"
				 	echo "and update grafana dashboard with the correct update information. If you choose to Continue Please run source /etc/bashrc "
					read -p "Would you  like to reboot(r), logout(l) or Continuing with script(c) " rlc
				done

				if [[ $rlc = r ]]; then
					sudo reboot
				elif [[ $rlc = l ]]; then
				      sshd_pid=$(pgrep -u $USER -o sshd)
							  pkill -P $sshd_pid -u $USER
				fi

				fi
				;;
			"Exit Script" )
				clear
				echo "Exiting..."
				sleep 3
				exit 0
				;;
		esac
		REPLY=
	clear
	done
	}

# Main Part of the script, this what runs first.
	clear

	# Checks to see if pacman. apt and dnf is NOT installed. If they are NOT installed it tells the user the script is 
	# NOT compatabile and exits the script
		if [[ -z $pac ]] && [[ -z $apt ]] && [[ -z $dnf ]]; then
			echo "It Appears that this script is not compatabile with your Disto, Exiting..."
			sleep 3
			exit 1
		fi 

	# Check to see if the root user started the script if not then ask the user to use sudo. 
	# Checks to see if EUID is 0. When running script as root the EUID is already set to 0. 
	# If a user runs the script and the EUID is set the same as user UID. When using sudo the EUID is then set to 0
		if [[ $EUID -eq 0 ]]; then
			echo "Welcome to Docker Server Installation Script"
			echo ""
		else
			if [[ $EUID -ne 0 ]]; then
				echo "Please use sudo, Exiting..."
				sleep 3
				exit 1
			fi
		fi

	# Main Menu system		
		options=("Fresh Install" "Add a Docker Service" "Exit")
		PS3="Please Enter a Number to Start a fresh install of docker or to add a service? "
		select user_opion in "${options[@]}"
		do
			case $user_opion in
				"Fresh Install" )
					clear

					read -p "Looks like you are using $os_check is this correct? y/n " yn

					while [[ -z $yn || ($yn != "y" && $yn != "n") ]]; do
						clear
						echo "Invaild Input. Please enter y or n"
						read -p "Looks like you are using $os_check is this correct? y/n " yn
					done

					if [[ $yn = n ]]; then
						clear
						echo "Exiting, Please Wait..."
						sleep 3
						exit 0
					fi

					# This runs when y is Selected to the question... Looks like you are using $os_check is this correct? y/n
						if [[ $yn = y ]]; then
							clear

							# Asks the user to run update. If y is selected it runs the updates. If n is selected
							# is jumps to "Installing docker". If anything else is selected it displays a invaild input
								read -p "It is recommened to run updates, Would you like to run updates now? y/n " yn							
								
								# Display invaild input and ask the user again to run updates
								while [[ -z $yn || ("$yn" != y && "$yn" != n) ]]; do
									clear
									echo "Invaild Input. Please enter y/n"
									read -p "It is recommened to run updates, Would you like to run updates now? y/n " yn
								done
								
								# Runs updates if y is selected
								if [[ ! -z $pac ]] && [[ $yn = y ]]; then
								    pacman -Syu --noconfirm
								elif [[ ! -z $apt ]] && [[ $yn = y ]]; then
								    apt update && apt upgrade -y
								elif [[ ! -z $dnf ]] && [[ $yn = y ]]; then
								    dnf -y update
								fi

							# Starts the install of Docker
								clear
								echo "Installing Docker..."
								sleep 5

								if [[ ! -z $pac ]]; then
								    pacman -S --noconfirm docker
								    pacman -S --noconfirm docker-compose
								    systemctl start docker.service  
								    systemctl enable docker.service
								    pacman -S --noconfirm firewalld
								    pacman -S --noconfirm git
								elif [[ ! -z $apt ]]; then
									apt update
								    apt install -y docker.io
								    apt install -y docker-compose
								    systemctl start docker.service
								    systemctl enable docker.service 
								    apt install -y git 
								elif [[ ! -z $dnf ]]; then
								    dnf -y install dnf-plugins-core
								    dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
								    dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
								    dnf install -y docker-compose
								    systemctl start docker.service
								    systemctl enable docker.service
								    dnf install -y git  
								fi

								 clear

								# Asks the user if they would like to add daemon.json to /etc/docker directory. If daemon.json
								# is not added then any firewalls rules add wont affect docker. For example if default firewall
								# says block everything then docker container can still be accessed
									echo "By default docker manages its own iptables rules which will affect how to rules work."
									echo "By adding daemon.json to /etc/docker you can then use $firewall to manage firewall rules"
									read -p "Would you like to use $firewall as front end tool to manage iptables? y/n " yn
									while [[ -z $yn || ($yn != y && $yn != n) ]]; do
										clear
										echo "Invaild Input. Please enter y/n"
										echo "By default docker manages its own iptables rules which will affect how to rules work."
										echo "By adding daemon.json to /etc/docker you can then use $firewall to manage firewall rules"
										read -p "Would you like to use $firewall as front end tool to manage iptables? y/n " yn
									done

									if [[ $yn = y ]] && [[ ! -d /etc/docker ]]; then
										mkdir /etc/docker
										cp configs/daemon.json /etc/docker/daemon.json
										systemctl restart docker
									elif [[ $yn = y ]] && [[ -d /etc/docker ]]; then
										cp configs/daemon.json /etc/docker/daemon.json
										systemctl restart docker
									fi

								clear
								read -p "Would you like to add any docker containers listed here? You can always exit out of the list y/n " yn

								while [[ -z $yn || ($yn != y && $yn != n) ]]; do
									clear
									echo "Invaild Input. Please enter y/n"
									read -p "Would you like to add any docker containers listed here? You can always exit out of the list y/n " yn
								done

								if [[ $yn = n ]]; then
									clear
									echo "Docker engine install completed. Exiting..."
									sleep 3
									exit 0
								fi

								if [[ $yn = y ]]; then
								 list_containers
								fi
								fi
								;;
				"Add a Docker Service" )
					clear
					# Check to make sure docker is installed before allowing a user to install a container
					docker_installed=$(command -v docker)
					if [[ -z $docker_installed ]]; then
					    echo "Docker is not installed, please install docker or run Fresh install from the menu"
					    echo "Exiting..."
					    sleep 8
					    exit 1
					fi

					# If docker is installed, then runs the list_containers function 
					list_containers
					;;
				"Exit" )
					clear
					echo "Exiting..."
					sleep 3
					exit 0
					;;
				*)
					clear
					echo "Invaild Input, Please enter a number from the list"
					echo ""
					REPLY=
					;;
			esac
		done