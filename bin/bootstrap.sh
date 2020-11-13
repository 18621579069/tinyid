#!/bin/bash

appName=$2
if [[ -z ${appName} ]]; then
    appName=`ls -t | grep .jar$ | head -n1`
fi
check=`echo ${appName} | grep ".jar$"`
if [[ -n check ]]; then
    appName="${appName%.*}"
fi
echo "application name: ${appName}"

function start()
{
    count=`ps -ef | grep ${appName}.jar | grep -v grep | wc -l`
    if [[ ${count} -gt 0 ]]; then
        echo "${appName} is still running..."
    else
        nohup java -jar `pwd`/${appName}.jar > /dev/null 2>&1 &
        PID=`ps -ef | grep ${appName}.jar | grep -v grep | awk '{print $2}'`
        if [[ -n ${PID} ]]; then
            echo "${appName} ${PID} started..."
        else
            echo "${appName} is not started..."
        fi
    fi
}

function stop()
{
    PID=`ps -ef | grep ${appName}.jar | grep -v grep | awk '{print $2}'`
    if [[ -n ${PID} ]]; then
        kill ${PID}
        echo "${appName} ${PID} is stopping..."
        sleep 5
    fi

    PID=`ps -ef | grep ${appName}.jar | grep -v grep | awk '{print $2}'`
    if [[ -n ${PID} ]]; then
        kill -9 ${PID}
        echo "${appName} ${PID} is force stopping..."
        sleep 5

        PID=`ps -ef | grep ${appName}.jar | grep -v grep | awk '{print $2}'`
        if [[ -n ${PID} ]]; then
            echo "${appName} ${PID} is not stopped..."
        else
            echo "${appName} force stopped..."
        fi
    else
        echo "${appName} stopped..."
    fi
}

function restart()
{
    stop
    start
}

function upgrade()
{
    if [[ -d pending ]]; then
        stop

        tar -zcvf ${appName}-$(date +%Y%m%d-%H%M).tar.gz ${appName}.jar
        if [[ ! -d backup ]]; then
            mkdir backup -p
        fi
        mv *.tar.gz backup/
        rm -rf ${appName}.jar
        mv pending/${appName}.jar .
        rm -rf pending
        echo "the version is upgraded..."

        start
    else
        echo "there is no '/pending' folder..."
    fi
}

function degrade()
{
    if [[ -d backup ]]; then
        stop

        rm -rf ${appName}.jar
        bakName=`ls -t -F backup/ | grep .tar.gz$ | head -n1`
        bakName="${bakName%.tar.gz}"
        tar -zxvf backup/${bakName}.tar.gz
        echo "the version is degraded..."

        start
    else
        echo "there is no '/backup' folder..."
    fi
}

function usage()
{
    echo "Usage: $0 {start|stop|restart|upgrade|degrade} -f"
    exit 1
}

case $1 in
    start)
    start;;
    stop)
    stop;;
    restart)
    restart;;
    upgrade)
    upgrade;;
    degrade)
    degrade;;
    *)
    usage;;
esac
