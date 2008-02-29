#!/bin/sh
set -eu
USAGE="[-f] <profile>"
LONG_USAGE="Bring <profile> connection up.

  -f, --front           Don't go to background. This is typically only
                        useful for debugging configuration problems since
                        error messages come up on the console."

# Bring in basic sh configuration
. hem-sh-setup
need_config

# Parse arguments
front=
while [ $# -gt 0 ]
do
    case "$1" in
        -f,--front)   front=1 ;;
        -*)           usage   ;;
        *)            break   ;;
    esac
    shift
done

# Grab profile or die
profile_name="$1"
test -z "$profile_name" && usage
shift

# Die if more than one profile provided
test $# -gt 0 && usage

# Bring in profile settings
profile_with $profile_name

# Check that connection isn't already running.
$execdir/hem-status --check $profile_name &&
die "$profile_name is already up"

info "bringing up: $profile_name"
log "bringing up $profile_name"

# write monitor port to state file
echo $profile_monitor_port > $profile_statefile

# Setup autossh environment variables. See autossh(1) for detailed
# descriptions of each. The values below are typically the autossh
# defaults but check the documentation to be sure.
AUTOSSH_DEBUG=$front
AUTOSSH_GATETIME=30
AUTOSSH_LOGLEVEL=5
AUTOSSH_LOGFILE="$log_to"
AUTOSSH_MAXSTART=-1
AUTOSSH_MESSAGE=
AUTOSSH_PATH="$ssh_command"
AUTOSSH_PIDFILE="$profile_pidfile"
AUTOSSH_POLL=${poll_time:-600}
AUTOSSH_FIRST_POLL=$AUTOSSH_POLL
AUTOSSH_PORT=${profile_monitor_port:-0}

# export autossh environment
export AUTOSSH_DEBUG AUTOSSH_GATETIME AUTOSSH_LOGLEVEL AUTOSSH_LOGFILE \
    AUTOSSH_PATH AUTOSSH_PIDFILE AUTOSSH_POLL AUTOSSH_FIRST_POLL AUTOSSH_PORT

# There's some oddness with setting the AUTOSSH_PORT environment variable
# to zero that seems to stop autossh from coming up.
if test "$AUTOSSH_PORT" = 0 ; then
    unset AUTOSSH_PORT
    export AUTOSSH_PORT
fi

# Build autossh command
command="autossh -M $profile_monitor_port"
test -z "$front" && command="$command -f"
command="$command -- -l $profile_user -p $profile_port -NM $profile_host"

# Log it
log "+ $command"

if $command ; then
    log "autossh is up"
    exit 0
else
    result=$?
    log "autossh failed with $result"
    die "autossh failed with $result"
fi