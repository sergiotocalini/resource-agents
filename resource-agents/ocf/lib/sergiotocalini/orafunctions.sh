#!/usr/bin/env ksh

ORAENV="/usr/local/bin/oraenv"
PATH="${PATH}:/usr/local/bin:/usr/local/sbin"

oradb_handler() {
    ORAENV_ASK=NO
    ACTION="${1}"
    ORACLE_SID="${2:-+ASM}"
    ORACLE_OPT="${3}"
    ORACLE_AUTH="${4:-sysdba}"
    ORACLE_USER="${5:-oracle}"
    . ${ORAENV} > /dev/null
    if [[ ${ACTION} == "start" ]]; then
	sql="startup ${ORACLE_OPT};"
    elif [[ ${ACTION} == "stop" ]]; then
	sql="shutdown ${ORACLE_OPT};"
    else
	echo "Unknow action."
	return 1
    fi
    rval=`echo "${sql}" | su ${ORACLE_USER} -c "sqlplus -s / as ${ORACLE_AUTH}"`
    rcode="${?}"
    echo -e "${rval}"
    return "${rcode}"
}

oradb_status() {
    ORAENV_ASK=NO
    ORACLE_SID="${1}"
    ORACLE_AUTH="${2:-sysdba}"
    ORACLE_USER="${3:-oracle}"
    . ${ORAENV} > /dev/null
    sql="SET HEADING OFF
         SET PAGES 0
         SELECT to_char(case when inst_cnt > 0 then 0 else 1 end,'FM99999999999999990') retvalue
         FROM   (select count(*) inst_cnt FROM v\$instance 
         WHERE  status = 'OPEN'
         AND    logins = 'ALLOWED'
         AND    database_status = 'ACTIVE');"

    rcode=`echo "${sql}" | su ${ORACLE_USER} -c "sqlplus -s / as ${ORACLE_AUTH}"`
    if [[ "${rcode}" != 0 ]]; then
	ps -ef | grep -e "[a-z]_pmon_${ORACLE_SID}" > /dev/null
	rcode="${?}"
    fi
    return "${rcode}"
}

asmdg_handler() {
    ORAENV_ASK=NO
    ACTION="${1}"
    ORACLE_DG="${2}"
    ORACLE_SID="${3:-+ASM}"
    ORACLE_AUTH="${4:-sysasm}"
    ORACLE_USER="${5:-oracle}"
    . ${ORAENV} > /dev/null
    if [[ ${ACTION} == "mount" ]]; then
	sql="alter diskgroup ${ORACLE_DG} mount;"
    elif [[ ${ACTION} == "umount" ]]; then
	sql="alter diskgroup ${ORACLE_DG} dismount;"	
    else
	echo "Unknow action."
	return 1
    fi
    rval=`echo "${sql}" | su ${ORACLE_USER} -c "sqlplus -s / as ${ORACLE_AUTH}"`
    rcode="${?}"
    echo -e "${rval}"
    return "${rcode}"
}

asmdg_status_sid() {
    ORAENV_ASK=NO
    ORACLE_DGSID="${1}"
    ORACLE_SID="${2:-+ASM}"
    ORACLE_AUTH="${3:-sysasm}"
    ORACLE_USER="${4:-oracle}"
    . ${ORAENV} > /dev/null
    sql="SET HEADING OFF
         SET PAGES 0
         SELECT (CASE WHEN (SELECT count(*) from v\$asm_diskgroup
         WHERE  STATE <> 'MOUNTED' AND NAME LIKE '%${ORACLE_DGSID}%') > 0
         THEN   '1'
         ELSE   '0' END ) DG_STATUS
         FROM   dual;"
    rcode=`echo "${sql}" | su ${ORACLE_USER} -c "sqlplus -s / as ${ORACLE_AUTH}"`
    return "${rcode}"
}

asmdg_status() {
    ORAENV_ASK=NO
    ORACLE_DG="${1}"
    ORACLE_SID="${2:-+ASM}"
    ORACLE_AUTH="${3:-sysasm}"
    ORACLE_USER="${4:-oracle}"
    . ${ORAENV} > /dev/null
    sql="SET HEADING OFF
         SET PAGES 0
         SELECT (CASE state WHEN 'MOUNTED' THEN '0' ELSE '1' END ) DG_STATUS
         FROM   v\$asm_diskgroup
         WHERE  NAME = '${ORACLE_DG}';"
    rcode=`echo "${sql}" | su ${ORACLE_USER} -c "sqlplus -s / as ${ORACLE_AUTH}"`
    return "${rcode}"
}

oraln_handler() {
    ORAENV_ASK=NO
    ACTION="${1}"
    ORACLE_LSNR="${2}"
    ORACLE_SID="${3:-+ASM}"
    ORACLE_USER="${4:-oracle}"
    . ${ORAENV} > /dev/null
    if [[ ${ACTION} == "start" ]]; then
	cmd="lsnrctl start ${ORACLE_LSNR}"
    elif [[ ${ACTION} == "stop" ]]; then
	cmd="lsnrctl stop ${ORACLE_LSNR}"
    else
	echo "Unknow action."
	return 1
    fi
    rval=`su ${ORACLE_USER} -c "${cmd}"`
    rcode="${?}"
    echo -e "${rval}"
    return "${rcode}"
}

oraln_status() {
    ORAENV_ASK=NO
    ORACLE_LSNR="${1}"
    ORACLE_SID="${2:-+ASM}"
    ORACLE_USER="${3:-oracle}"
    . ${ORAENV} > /dev/null   
    rval=`su ${ORACLE_USER} -c "lsnrctl status ${ORACLE_LSNR}"`
    rcode="${?}"
    echo -e "${rval}"
    return "${rcode}"
}

asmfs_handler() {
    ORAENV_ASK=NO
    ACTION="${1}"
    ORACLE_DG="${2}"
    ORACLE_VN="${3}"
    ORACLE_SID="${4:-+ASM}"
    ORACLE_USER="${5:-oracle}"
    . ${ORAENV} > /dev/null
    if [[ ${ACTION} == "mount" ]]; then
	rval=$(asmdg_status ${ORACLE_DG})
	rcode="${?}"
	if [ ${rcode} != 0 ]; then
	    rval=$(asmdg_handler "mount" ${ORACLE_DG})
	    rcode="${?}"
	fi
	rval=$(orafs_status "${ORACLE_DG}" "${ORACLE_VN}")
	rcode="${?}"
	if [ ${rcode} != 0 ]; then
	    if [ ${rcode} == 1 ];then
		rval=`su ${ORACLE_USER} -c "volenable -G '${ORACLE_DG}' '${ORACLE_VN}'"`
		rcode="${?}"
	    fi
	    echo "mount -t acfs"
	fi  
    elif [[ ${ACTION} == "umount" ]]; then
	rval=$(orafs_status "${ORACLE_DG}" "${ORACLE_VN}")
	rcode="${?}"
	if [ ${rcode} == 0 ]; then
	    echo "umount"
	fi
	rval=$(asmdg_status ${ORACLE_DG})
	rcode="${?}"
	if [ ${rcode} != 0 ]; then
	    rval=$(asmdg_handler "umount" ${ORACLE_DG})
	    rcode="${?}"
	fi	
    else
	echo "Unknow action."
	return 1
    fi
    echo -e "${rval}"
    return "${rcode}"
}

asmfs_status() {
    ORAENV_ASK=NO
    ORACLE_DG="${1}"
    ORACLE_VN="${2}"
    ORACLE_SID="${3:-+ASM}"
    ORACLE_USER="${4:-oracle}"
    # . ${ORAENV} > /dev/null
    # cmd="asmcmd volinfo -G ${ORACLE_DG} ${ORACLE_VN}"
    # for i in `su ${ORACLE_USER} -c "${cmd}"| egrep "Volume Device|State|Mountpath"`; do
    typeset -A options
    while read -r line; do
	key=`echo ${line} | awk -F : '{print $1}'`
	value=`echo ${line} | awk -F : '{print $2}'`
	options["${key}"]="${value}"
    done < /tmp/pepe
    echo -e "${options[@]}"
    return "${rcode:-1}"
}
