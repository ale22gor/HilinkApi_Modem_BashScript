#!/bin/sh



setLteBand(){
    r=`curl -s -X POST  http://192.168.8.1/api/sms/send-sms --compressed \
    --proxy $ipAddress:8080 \
    -H "Cookie: $c" \
    -H "__RequestVerificationToken: $t" \
    -H "Content-Type: application/x-www-form-urlencoded; charset=UTF-8>" \
    --data "<?xml version="1.0" encoding="UTF-8"?>
	<request>
		<NetworkMode>-1</NetworkMode>
		<NetworkBand>$1</NetworkBand>
		<LTEBand></LTEBand>
		<Content>$2</Content>
	</request>"`
    echo "$r"
}

getSimInfo(){
    getInfo "api/net/current-plmn"

    local fullName=`echo "$r"| grep -oP '(?<=<FullName>).*?(?=</FullName>)'`


    if ! [ "$fullName" = "" ]; then
        echo "FullName = $fullName : ok"
    else
        echo "FullName = $fullName : bad"
    fi
 
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
    echo "usage: huaweiScript [[[-i ip ] & [[-r radio] | [-s sim] | [-d data] [-c connection] | [-n number] | [-b balance]] | [-h]]"
}

error_exit()
{
     echo "$1" 1>&2
     exit 1
}

##### Main

r=
radioInfo=

ipAddress="127.0.0.1"

while [ "$1" != "" ]; do
    case $1 in
        -i | --ip )             shift
                                ipAddress=$1
                                ;;
        -r | --radio )          radioInfo=1
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




