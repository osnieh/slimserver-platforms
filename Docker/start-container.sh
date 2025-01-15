#!/bin/bash

umask 0002

#
# Check if $PUID is a number and in the range 1...59999 (i.e. root is not allowed)
# Yes: Set uid of user squeezeboxserver to $PUID
# No:  Set $PUID to the current uid of the user squeezeboxserver
#

if [[ $PUID =~ ^[0-9]+$ ]] && [ $PUID -ge 1 ] && [ $PUID -le 59999 ] ; then

	# Print waring if $PUID is below 100
	if [ $PUID -lt 100 ] ; then
		echo Warning: PUID=$PUID is a reserved system user id.
	fi
   
	echo Set uid of user squeezeboxserver to $PUID
	usermod -o -u "$PUID" squeezeboxserver

else
	echo PUID=$PUID is not a number between 1 and 59999
	PUID=$(id -u squeezeboxserver)
	echo PUID is set to $PUID 
fi


#
# Check if $PGID is a number and in the range 1...59999 (i.e. root is not allowed)
# If not, set $PGID to the current gid of the user squeezeboxserver
#

if [[ $PGID =~ ^[0-9]+$ ]] && [ $PGID -ge 1 ] && [ $PGID -le 59999 ] ; then

	# Print waring if $PUID is below 100
	if [ $PGID -lt 100 ] ; then
		echo Warning: PGID=$PGID is a reserved system group id.
	fi
else
	echo PGID=$PGID is not a number between 1 and 59999
	PGID=$(id -g squeezeboxserver)
	echo  PGID is set to $PGID
fi


# Set id of group squeezeboxserver to $PGID and set gid of user squeezeboxserver to $PGID
echo Set id of group squeezeboxserver to $PGID
groupmod -o -g "$PGID" squeezeboxserver
echo Set gid of user squeezeboxserver to $PGID
usermod -g $PGID squeezeboxserver

#Add permissions
chown -R squeezeboxserver:squeezeboxserver /config /playlist

if [[ -f /config/custom-init.sh ]]; then
	echo "Running custom initialization script..."
	sh /config/custom-init.sh
fi

echo Starting Lyrion Music Server on port $HTTP_PORT...
if [[ -n "$EXTRA_ARGS" ]]; then
	echo "Using additional arguments: $EXTRA_ARGS"
fi
su squeezeboxserver -s /bin/sh -c '/usr/bin/perl /lms/slimserver.pl --prefsdir /config/prefs --logdir /config/logs --cachedir /config/cache --httpport $HTTP_PORT $EXTRA_ARGS'
