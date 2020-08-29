#!/bin/sh


getSms(){
 echo "nop"
}

sendSms(){
    r=`curl -s -X POST  http://192.168.8.1/api/sms/send-sms -o smslist.txt  \
    --proxy $ipAddress:8080 \
    -H "Cookie: $c" \
    -H "__RequestVerificationToken: $t" \
    -H "Content-Type: application/x-www-form-urlencoded; charset=UTF-8>" \
    --data "<?xml version="1.0" encoding="UTF-8"?>
	<request>
		<Index>-1</Index>
		<Phones>
			<Phone>$1</Phone>
		</Phones>
		<Sca></Sca>
		<Content>$2</Content>
		<Length>-1</Length>
		<Reserved>1</Reserved>
		<Date>-1</Date>
	</request>"`

    local error=`echo "$r"| grep 'error'`
    if [ "$error" ];then
       local errorCode=`echo "$r"| grep -oP '(?<=<code>).*?(?=</code>)'`
       echo "$errorCode"
       error_exit "api error $errorCode"
    fi
}

getSmsList(){

    r=`curl -s -X POST  http://192.168.8.1/api/sms/sms-list -o smslist.txt  \
    --proxy $ipAddress:8080 \
    -H "Cookie: $c" \
    -H "__RequestVerificationToken: $t" \
    -H "Content-Type: application/x-www-form-urlencoded; charset=UTF-8>" \
    --data "<?xml version="1.0" encoding="UTF-8"?>
	<request>
		<PageIndex>1</PageIndex>
		<ReadCount>20</ReadCount>
		<BoxType>1</BoxType>
		<SortType>0</SortType>
		<Ascending>0</Ascending>
		<UnreadPreferred>0</UnreadPreferred>
	</request>"`

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
    echo "usage: huaweiScript [[[-i ip ] & [[-s number text] | [-a all] | [-n number]] | [-h]]"
}

error_exit()
{
     echo "$1" 1>&2
     exit 1
}

##### Main

r=
sendInfo=
allInfo=
numberInfo=

smsText=
phoneNumber=


ipAddress="127.0.0.1"

while [ "$1" != "" ]; do
    case $1 in
        -i | --ip )             shift
                                ipAddress=$1
                                ;;
        -s | --send )           sendInfo=1
                                ;;
        -a | --all )            allInfo=1
                                ;;
        -n | --number )         numberInfo=1
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
if [ "$sendInfo" = "1" ]; then
	sendSms
fi
if [ "$allInfo" = "1" ]; then
	getSmsList
fi
if [ "$numberInfo" = "1" ]; then
	getSms
fi


