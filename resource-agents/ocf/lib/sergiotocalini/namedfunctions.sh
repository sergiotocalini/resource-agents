#!/usr/bin/env ksh

PATH="${PATH}:/usr/local/bin:/usr/local/sbin"

named_handler() {
    ACTION="${1}"
    OWNER="${2}"
    CONFIG="${3}"
    if [[ ${ACTION} == "start" ]]; then
	if [ -f ${CONFIG} ]; then
	    OPTS+="-c ${CONFIG}"
	fi
	named -u ${OWNER} ${OPTS}
	return "${?}"
    elif [[ ${ACTION} == "stop" ]]; then
	pid=`pgrep -u ${OWNER} "named"`
	if [ ! -z ${pid} ]; then
	    pkill -9 -u "${OWNER}" named
	fi
	return 0
    else
	echo "Unknow action."
	return 1
    fi
}

named_status() {
    OWNER="${1}"
    rndc status > /dev/null
    rcode="${?}"
    if [[ "${rcode}" != 0 ]]; then
	pgrep -u ${OWNER} "named" > /dev/null
	rcode="${?}"
    fi
    return "${rcode}"
}
