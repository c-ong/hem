#!/bin/sh
set -eu
USAGE="[-c] [-p] <profile>"
LONG_USAGE="Show connection status information for <profile>.

  -c, --check           Exit truthfully only if up. If down, exit falsibly.
  -p, --pid             Output the connection's PID. If down, no output is
                        generated.

When neither --check or --pid are specified, output a description of
the connection status. The format varies based on the connection state."

. hem-sh-setup
need_config

# parse arguments
check_mode=
output_pid=
while [ $# -gt 0 ]
do
	case "$1" in
		-c|--check)
			check_mode=1
			;;
		-p|--pid)
			output_pid=1
			;;
		-*)
			usage
			;;
		*)
			break
			;;
	esac
	shift
done

# get profile setup
profile_name="$1" ; shift
test -z "$profile_name" && usage
test $# -gt 0 && usage
profile_with $profile_name

# get some info on our process
pidfile_ok=n
pid_ok=n
pid=
if [ -r "$profile_pidfile" ] ; then
	pidfile_ok=y
	pid=$(cat $profile_pidfile)
	[ -n "$(ps -p $$ | grep $$)" ] && pid_ok=y
fi

# determine process status
case "$pidfile_ok,$pid_ok" in
	y,y) process_status="up";;
	n,n) process_status="down";;
	y,n) process_status="stale";;
	n,y) process_status="wtf";;
esac

# output the PID if --pid was given or a longer status if --check was not.
if [ $output_pid ] ; then
	test $pid_ok = y &&
	echo $pid
elif [ ! $check_mode ] ; then
	printf "%-45s%-10s%6s\n" "$profile_name" "$process_status" "$pid"
fi

# if --check was given, exit accordingly.
if [ $check_mode ] ; then
	[ $pid_ok = y ] &&
	exit 0 ||
	exit 1
fi
