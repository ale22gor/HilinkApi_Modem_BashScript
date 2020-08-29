#!/bin/sh


getRadioInfo(){
    
    getInfo "api/device/signal"

    local cellId=`echo "$r"| grep -oP '(?<=<cell_id>).*?(?=</cell_id>)'`
    local rssi=`echo "$r"| grep -oP '(?<=<rssi>).*?(?=dBm</rssi>)'`
    local ecio=`echo "$r"| grep -oP '(?<=<ecio>).*?(?=dB</ecio>)'`
    local sinr=`echo "$r"| grep -oP '(?<=<sinr>).*?(?=dB</sinr>)'`

    if [ "$cellId" -gt "0" ]; then
        echo "cellId = $cellId : ok"
    else
        echo "cellId = $cellId : bad"
    fi

    if [ "$rssi" -gt "-87" ]; then
        echo "rssi = $rssi dBm: ok"
    else
        echo "rssi = $rssi dBm: bad"
    fi

    if [ -z "$ecio" ];then
       echo "no ecio data"
    elif [ "$ecio" -gt "-15" ]; then
        echo "ecio = $ecio dBm: ok"
    else
        echo "ecio = $ecio dBm: bad"
    fi

    if [ -z "$sinr" ];then
       echo "no ecio data"
    elif [ "$sinr" -gt "0" ]; then
        echo "sinr = $sinr dBm: ok"
    else
        echo "sinr = $sinr dBm: bad"
    fi
}

getDataInfo(){
    getInfo "api/monitoring/traffic-statistics"


    local currentConnectTime=`echo "$r"| grep -oP '(?<=<CurrentConnectTime>).*?(?=</CurrentConnectTime>)'`
    local currentUpload=`echo "$r"| grep -oP '(?<=<CurrentUpload>).*?(?=</CurrentUpload>)'`
    local currentDownload=`echo "$r"| grep -oP '(?<=<CurrentDownload>).*?(?=</CurrentDownload>)'`
    local currentDownloadRate=`echo "$r"| grep -oP '(?<=<CurrentDownloadRate>).*?(?=</CurrentDownloadRate>)'`
    local currentUploadRate=`echo "$r"| grep -oP '(?<=<CurrentUploadRate>).*?(?=</CurrentUploadRate>)'`
    
    if [ "$currentConnectTime" -gt "0" ]; then
	currentConnectTime=`echo "$currentConnectTime" | awk '{ sec =$1 /60; print sec " Min" }'`
        echo "CurrentConnectTime = $currentConnectTime : ok"
    else
        echo "CurrentConnectTime = $currentConnectTime : bad"
    fi
    
    if [ "$currentUpload" -gt "0" ]; then
	currentUpload=`echo "$currentUpload" | awk '{ byte =$1 /1024/1024; print byte " MB" }'`
        echo "CurrentUpload = $currentUpload : ok"
    else
        echo "CurrentUpload = $currentUpload : bad"
    fi

     if [ "$currentDownload" -gt "0" ]; then
	currentDownload=`echo "$currentDownload" | awk '{ byte =$1 /1024/1024; print byte " MB" }'`
        echo "CurrentDownload = $currentDownload : ok"
    else
        echo "CurrentDownload = $currentDownload : bad"
    fi

    if [ "$currentDownloadRate" -gt "0" ]; then
	currentDownloadRate=`echo "$currentDownloadRate" | awk '{ byte =$1 *8 /1024; print byte " KB/s" }'`
        echo "CurrentDownloadRate = $currentDownloadRate : ok"
    else
        echo "CurrentDownloadRate = $currentDownloadRate : bad"
    fi

    if [ "$currentUploadRate" -gt "0" ]; then
	currentUploadRate=`echo "$currentUploadRate" | awk '{ byte =$1 *8 /1024; print byte " KB/s" }'`
        echo "CurrentUploadRate = $currentUploadRate : ok"
    else
        echo "CurrentUploadRate = $currentUploadRate : bad"
    fi


}

getSimInfo(){
    getInfo "api/net/current-plmn"

    local fullName=`echo "$r"| grep -oP '(?<=<FullName>).*?(?=</FullName>)'`
    local numeric=`echo "$r"| grep -oP '(?<=<Numeric>).*?(?=</Numeric>)'`

    getInfo "api/pin/status"

    local simState=`echo "$r"| grep -oP '(?<=<SimState>).*?(?=</SimState>)'`
    local pinOptState=`echo "$r"| grep -oP '(?<=<PinOptState>).*?(?=</PinOptState>)'`
    local simPinTimes=`echo "$r"| grep -oP '(?<=<SimPinTimes>).*?(?=</SimPinTimes>)'`

    if ! [ "$fullName" = "" ]; then
        echo "FullName = $fullName : ok"
    else
        echo "FullName = $fullName : bad"
    fi

    if [ "$numeric" -gt "0" ]; then
        echo "Numeric = $numeric : ok"
    else
        echo "Numeric = $numeric : bad"
    fi

    if [ "$simState" -gt "0" ]; then
        echo "SimState = $simState : ok"
    else
        echo "SimState = $simState : bad"
    fi

    if [ "$pinOptState" -gt "0" ]; then
        echo "PinOptState = $pinOptState : ok"
    else
        echo "PinOptState = $pinOptState : bad"
    fi

    if [ "$simPinTimes" -gt "0" ]; then
        echo "SimPinTimes = $simPinTimes : ok"
    else
        echo "SimPinTimes = $simPinTimes : bad"
    fi


    
}

getBalance(){
    local ussd="*100#"

    sendUSSD "$ussd"

    getInfo "api/ussd/get"

    local balance="$r"
    local balance=`echo "$balance"| grep -oP '(?<=<content>).*'`
    local balance=`echo "$balance"| grep -oP '(\d+[\.,]\d+)|(\d+)'`
    
    echo "$balance rub : ok"
    getToken
}

getNumber(){
    local ussd=
    getSimInfo
    local fullName=`echo "$r"| grep -oP '(?<=<FullName>).*?(?=</FullName>)'`
    if [[ $fullName == *"MTS"* ]]; then
	      ussd="*111*10#"
    elif [[ $fullName == *"BeeLine"* ]]; then
	      ussd="*100#"
    else [[ $fullName == *"MegaFon"* ]]
	      ussd="*205#"
    fi
    sendUSSD "$ussd"

    getInfo "api/ussd/get"

    local number=`echo "$r"| grep -oP '(?<=<content>).*?(?=</content>)'`
    
    echo "$number : ok"
    getToken
}

sendUSSD(){
    r=`curl -s -X POST http://192.168.8.1/api/ussd/send \
    --proxy $ipAddress:8080 \
    -H "Cookie: $c" \
    -H "__RequestVerificationToken: $t" \
    -H "Content-Type: application/x-www-form-urlencoded; charset=UTF-8" \
    --data "<?xml version='1.0' encoding='UTF-8'?>
    <request>
        <content>$1</content>
        <timeout>4</timeout>
    </request>"`
    sleep 4
}

getInfo(){
    r=`curl -s -X GET  http://192.168.8.1/$1 \
    --proxy $ipAddress:8080 \
    -H "Cookie: $c" \
    -H "__RequestVerificationToken: $t" \
    -H "Content-Type: application/x-www-form-urlencoded; charset=UTF-8>"`

    local error=`echo "$r"| grep 'error'`
    if [ "$error" ];then
       local errorCode=`echo "$r"| grep -oP '(?<=<code>).*?(?=</code>)'`
       echo "$errorCode"
       error_exit "api error $errorCode"
    fi
}

getToken(){
    c=`echo "$r"| grep SessionID=| cut -b 10-147`
    t=`echo "$r"| grep TokInfo| cut -b 10-41`
} 

testConnect(){
    r=`curl -s -i -X GET http://192.168.8.1/api/webserver/SesTokInfo \
    --proxy $ipAddress:8080`
    local http_status=$(echo "$r" | grep HTTP |  awk '{print $2}')
    if [ -z "$r" ];then
       error_exit "web server connection timeout"
    elif [ "$http_status" != "200" ]; then
       # handle error 
       error_exit "web server error $http_status"
    fi

}

usage(){
    echo "usage: huaweiScript [[[-i ip ] & [[-r radio] | [-s sim] | [-d data] | [-n number] | [-b balance]] | [-h]]"
}

error_exit()
{
     echo "$1" 1>&2
     exit 1
}

##### Main

r=
radioInfo=
simInfo=
dataInfo=
numberInfo=
balanceInfo=
ipAddress="127.0.0.1"

while [ "$1" != "" ]; do
    case $1 in
        -i | --ip )             shift
                                ipAddress=$1
                                ;;
        -r | --radio )          radioInfo=1
                                ;;
        -s | --sim )            simInfo=1
                                ;;
        -d | --data )           dataInfo=1
                                ;;
        -n | --number )         numberInfo=1
                                ;;
        -b | --balance )        balanceInfo=1
                                ;;
        -h | --help )           usage
                                exit
                                ;;
        * )                     usage
                                exit 1
    esac
    shift
done

if  ! expr "$ipAddress" : '[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*$' >/dev/null; then
    error_exit "invalid IP address"
fi
testConnect

getToken
if [ "$radioInfo" = "1" ]; then
	getRadioInfo
fi

if [ "$dataInfo" = "1" ]; then
	getDataInfo
fi

if [ "$simInfo" = "1" ]; then
	getSimInfo
fi

if [ "$numberInfo" = "1" ]; then
	getNumber
fi

if [ "$balanceInfo" = "1" ]; then
	getBalance
fi


