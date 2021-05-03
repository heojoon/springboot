#!/bin/bash

#
# Spring Boot enbeded WAS launcher v1.210503
#

USER="wasuser"

# Java environments
export JAVA_HOME="/app/jdk-11"
export JAVA="/app/jdk-11/bin/java"

# Process name 
PROC_NAME="demo"

# Jar File Path
SVCPATH="/svcroot/runtime/webapps/springboot/"
JAR_FILE="demo-0.0.1-SNAPSHOT.jar"

# Loggin path
LOG_PATH="/app/was/springboot/log"
STDOUT_FILE="${LOG_PATH}/stdout.log"
PID_PATH="/app/was/springboot/log"
PROC_PID_FILE="${PID_PATH}/${PROC_NAME}.pid"
RUN_JAR_FILE="${PID_PATH}/${PROC_NAME}.runjar"

# Java option
JVM_OPTION="-Djava.security.egd=file:///dev/urandom"
# deploy envrionment PROFILE="dev" 
# stdin check
if [ Z != Z$2 ];then
        JAR_FILE="$2"
fi

[ -e ${RUN_JAR_FILE} ] && echo "JAR_FILE : $(cat ${RUN_JAR_FILE})"

userchk()
{
        if [ $(id -un) != ${USER} ];then
                echo "Please run user name : ${USER}"
                exit 0
        fi
}

get_status()
{
    # if JAR_FILE is global JAR_FILE
    [ -e ${RUN_JAR_FILE} ] && JAR_FILE="$(cat ${RUN_JAR_FILE})"
    ps ux | grep ${JAR_FILE} | grep -v $0 | grep -v grep | awk '{print $2}'

    # if JAR_FILE is stdin JAR_FILE (grepping YYmmddHHSS pattern)
    #ps -ef |grep -v grep | grep -v $0 | grep -e "(2[0-9][0-9][0-9])(1[0-2]|0[1-9])(3[0-1]|[0-2][1-9]|[1-2][0])(0[0-9]|1[0-9]|2[0-3])([0-5][0-9])([0-5][0-9])" | awk '{print $2}'
}

status()
{
    local PID=$(get_status)
    if [ -n "${PID}" ]; then
        echo 0
    else
        echo 1
    fi
}

start()
{
    if [ $(status) -eq 0 ]; then
        echo "${PROC_NAME} is already running"
        exit 0
    else
        nohup ${JAVA} -jar ${JVM_OPTION} ${SVCPATH}${JAR_FILE} >> ${STDOUT_FILE} 2>&1 &
        if [ $(status) -eq 1 ];then 
            echo "${PROC_NAME} is start ... [Failed]"
            exit 1
        else
            echo "JAR_FILE : ${JAR_FILE}"
            echo "${PROC_NAME} is start ... [OK]"
            local PID=$(get_status)
            echo ${PID} > ${PROC_PID_FILE}
            echo ${JAR_FILE} > ${RUN_JAR_FILE}
        fi
    fi
}

stop()
{
    # verify pid
    if [ ! -e ${PROC_PID_FILE} ];then
        PID=$(get_status)
    else
        PID=$(cat "${PROC_PID_FILE}")
    fi

    # If no have pid file and no have running process then PID set zero manual
    [ Z"${PID}" == Z ] && PID=0

    if [ "${PID}" -lt 3 ]; then
        echo "${PROC_NAME} was not running."
    else
        kill ${PID}
        if [ $(status) -eq 0 ];then
                echo "${PROC_NAME} is shutdown ... [OK]"
                rm -f ${PROC_PID_FILE}
                rm -f ${RUN_JAR_FILE}
        else
                echo "${PROC_NAME} is shutdown ... [Failed]"
        fi
    fi
}

case "$1" in
        start)
                userchk
                start
                sleep 1
        ;;
        stop)
                userchk
                stop
                sleep 1
        ;;
        restart)
                userchk
                stop
                sleep 2
                start
        ;;
        status)
                if [ $(status) -eq 0 ]; then
                    echo "${PROC_NAME} is running"
                else
                    echo "${PROC_NAME} is stopped"
                fi
        ;;
        *)
                echo "Useage : $0 {start | stop | restart | status}"
                echo "Useage : If you want uniq file jar file name stdin"
                echo "Useage : ex) $0 start example.jar"
        ;;
esac
