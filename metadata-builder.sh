#!/bin/bash

#Modify $REPO (path to the desired mirror) and $SUITE (the target suite)
#REPO="/srv/mirror/lliurex"
#SUITE="xenial"
REPO="/srv/mirror/ppa-bionic"
SUITE="bionic"
#Don't touch this!!
CHROOT_DIR="/home/lliurex/workspace/appstream-generator/debootstrap"
ERROR=0

trap control_c INT

function ayuda
{
	echo "Usage: "$(basename $0)" [-r repo] [-s suite] [-c chroot_dir] "
	printf "Args:\n"
	printf "\t -h: Shows this message\n"
	printf "\t -s suite: Suite to process (xenial, trusty.. defaults to $SUITE) \n"
	printf "\t -r repo: Path to repo basedir(defaults to $REPO)\n"
	printf "\t -c chroot: Dir with the chroot (defaults to $CHROOT_DIR)\n"
	exit 2
}

function get_err
{
	case $ERROR in
		10)
			err_msg="Failed to copy /proc/mounts as chroot's mtab"
			;;
		20)
			err_msg="Failed to mount /proc"
			;;
		30)
			err_msg="Failed to mount /sys"
			;;
		40)
			err_msg="Failed to bind /dev/pts"
			;;
		50)
			err_msg="Failed to bind /dev"
			;;
		60)
			err_msg="Failed to bind $REPO"
			;;
		70)
			err_msg="Can't chroot to $CHROOT_DIR"
			;;
		80)
			err_msg="Can't remove chroot's mtab"
			;;
		90)
			err_msg="Can't unmount chroot's proc"
			;;
		100)
			err_msg="Can't unmount chroot's sys"
			;;
		110)
			err_msg="Can't unmount chroot's pts"
			;;
		120)
			err_msg="Can't unmount chroot's dev"
			;;
		130)
			err_msg="Can't unmount chroot's repo"
			;;
	esac
	echo $err_msg
	exit $ERROR
}

function setup_env
{
	echo "********************************************"
	echo "Setting up chroot environment in $CHROOT_DIR"
	echo "Config:"
	echo "Chroot: $CHROOT_DIR"
	echo "Repo: $REPO"
	echo "Suite: $SUITE"
	echo "********************************************"
	echo "Proceed (y/n)? [n]"
	read PROCESS
	if [[ $PROCESS != 'y' ]] && [[ $PROCESS != 'Y' ]]
	then
		exit 3
	fi

	if [ -e ${REPO}/asgen-config.json ]
	then
		mkdir /home/lliurex/workspace/appstream-generator/debootstrap/${REPO} -p
		cp /proc/mounts /home/lliurex/workspace/appstream-generator/debootstrap/etc/mtab 2>/dev/null|| (ERROR=10;get_err)
		mount -t proc /proc /home/lliurex/workspace/appstream-generator/debootstrap/proc/ 2>/dev/null|| (ERROR=20;get_err)
		mount -t sysfs /sys/ /home/lliurex/workspace/appstream-generator/debootstrap/sys/ 2>/dev/null|| (ERROR=30;get_err)
		mount -o bind /dev/pts /home/lliurex/workspace/appstream-generator/debootstrap/dev/pts 2>/dev/null|| (ERROR=40;get_err)
		mount -o bind /dev /home/lliurex/workspace/appstream-generator/debootstrap/dev/ 2>/dev/null|| (ERROR=50;get_err)
		mount --bind ${REPO} /home/lliurex/workspace/appstream-generator/debootstrap/${REPO} || (ERROR=60;get_err)
	else
		echo "asgen-config.json not found in ${REPO}"
		exit 5
	fi

}

function process_suite
{
	echo "Processing suite $SUITE using repo $REPO"
	cat << EOF | chroot ${CHROOT_DIR}
	cd ${REPO}
	appstream-generator cleanup
	appstream-generator remove-found $SUITE
	appstream-generator process $SUITE --force #Con esto generamos los datos
EOF

}

function clean_up
{
	echo "Cleaning up"
	rm  /home/lliurex/workspace/appstream-generator/debootstrap/etc/mtab 2>/dev/null #|| (ERROR=80;get_err)
	umount /home/lliurex/workspace/appstream-generator/debootstrap/proc/ 2>/dev/null #|| (ERROR=90;get_err)
	umount /home/lliurex/workspace/appstream-generator/debootstrap/sys/ 2>/dev/null #|| (ERROR=100;get_err)
	umount /home/lliurex/workspace/appstream-generator/debootstrap/dev/ 2>/dev/null #|| (ERROR=120;get_err)
	umount /home/lliurex/workspace/appstream-generator/debootstrap/dev/pts 2>/dev/null #|| (ERROR=110;get_err)
	umount /home/lliurex/workspace/appstream-generator/debootstrap/${REPO} 2>/dev/null # ||(ERROR=130;get_err)
}

function control_c
{
	clean_up
	exit 4
}


if [ $UID -ne 0 ]
then
	echo "This script must be run as root"
	exit 1
fi

args=0
while getopts ":hr:s:c:" optname
	do
	case "$optname" in
		"h")
			ayuda
			;;
		"r")
			REPO=$OPTARG
			let args=$args+1
			;;
		"s")
			SUITE=$OPTARG
			let args=$args+1
			;;
		"c")
			CHROOT_DIR=$OPTARGS
			;;
		"?")
			echo "Unknown option $OPTARG"
			ayuda
			;;
		":")
			echo "No argument value for option $OPTARG"
			ayuda
			;;
		*)
			# Should not occur
			echo "Unknown error while processing options"
			ayuda
		;;
	esac
done

setup_env
process_suite
clean_up
echo "Dep-11 generated in ${REPO}"


exit 0
