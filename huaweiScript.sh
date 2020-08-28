#!/bin/sh


getRadioInfo(){
    
    getInfo "api/device/signal"
    #echo "$r"

    cellId=`echo "$r"| grep -oP '(?<=<cell_id>).*?(?=</cell_id>)'`
    rssi=`echo "$r"| grep -oP '(?<=<rssi>).*?(?=dBm</rssi>)'`
    ecio=`echo "$r"| grep -oP '(?<=<ecio>).*?(?=dB</ecio>)'`

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

    if [ "$ecio" -gt "-15" ]; then
        echo "ecio = $ecio dBm: ok"
    else
        echo "ecio = $ecio dBm: bad"
    fi
}

getDataInfo(){
    getInfo "api/monitoring/traffic-statistics"
    #echo "$r"

    currentConnectTime=`echo "$r"| grep -oP '(?<=<CurrentConnectTime>).*?(?=</CurrentConnectTime>)'`
    currentUpload=`echo "$r"| grep -oP '(?<=<CurrentUpload>).*?(?=</CurrentUpload>)'`
    currentDownload=`echo "$r"| grep -oP '(?<=<CurrentDownload>).*?(?=</CurrentDownload>)'`
    currentDownloadRate=`echo "$r"| grep -oP '(?<=<CurrentDownloadRate>).*?(?=</CurrentDownloadRate>)'`
    currentUploadRate=`echo "$r"| grep -oP '(?<=<CurrentUploadRate>).*?(?=</CurrentUploadRate>)'`
    
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
    #echo "$r"

    fullName=`echo "$r"| grep -oP '(?<=<FullName>).*?(?=</FullName>)'`
    numeric=`echo "$r"| grep -oP '(?<=<Numeric>).*?(?=</Numeric>)'`

    getInfo "api/pin/status"
    #echo "$r"

    simState=`echo "$r"| grep -oP '(?<=<SimState>).*?(?=</SimState>)'`
    pinOptState=`echo "$r"| grep -oP '(?<=<PinOptState>).*?(?=</PinOptState>)'`
    simPinTimes=`echo "$r"| grep -oP '(?<=<SimPinTimes>).*?(?=</SimPinTimes>)'`

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
    ussd=
    getSimInfo
    fullName=`echo "$r"| grep -oP '(?<=<FullName>).*?(?=</FullName>)'`
    if [[ $fullName == *"MTS"* ]]; then
	      ussd="*100#"
    elif [[ $fullName == *"BeeLine"* ]]; then
	      ussd="*100#"
    else [[ $fullName == *"MegaFon"* ]]; then
	      ussd="*100#"
    fi

    sendUSSD ussd
    #echo "$r"
    getInfo "api/ussd/get"
    #echo "$r"
    balance=`echo "$r"| grep -oP '(?<=<content>).*?(?=</content>)'`
    
    echo "$balance : ok"
    getToken
}

getNumber()
    ussd=
    getSimInfo
    fullName=`echo "$r"| grep -oP '(?<=<FullName>).*?(?=</FullName>)'`
    if [[ $fullName == *"MTS"* ]]; then
	      ussd="*111*10# "
    elif [[ $fullName == *"BeeLine"* ]]; then
	      ussd="*100#"
    else [[ $fullName == *"MegaFon"* ]]; then
	      ussd="*205#"
    fi
    sendUSSD ussd
    #echo "$r"
    getInfo "api/ussd/get"
    #echo "$r"
    number=`echo "$r"| grep -oP '(?<=<content>).*?(?=</content>)'`
    
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

}

getToken(){
    r=`curl -s -X GET http://192.168.8.1/api/webserver/SesTokInfo \
    --proxy $ipAddress:8080`
    c=`echo "$r"| grep SessionID=| cut -b 10-147`
    t=`echo "$r"| grep TokInfo| cut -b 10-41`

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


