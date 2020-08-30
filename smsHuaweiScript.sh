#!/bin/sh



sendSms(){
    r=`curl -s -X POST  http://192.168.8.1/api/sms/send-sms --compressed \
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
		<Date>2020-08-22 11:51:24</Date>
	</request>"`
    echo "$r"
}

getSmsList(){

    # BoxType
      #   0: inbox
      #   1: outbox
      #   2: drafts

    r=`curl -s -X POST  http://192.168.8.1/api/sms/sms-list --compressed\
    --proxy $ipAddress:8080 \
    -H "Cookie: $c" \
    -H "__RequestVerificationToken: $t" \
    -H "Content-Type: application/x-www-form-urlencoded; charset=UTF-8>" \
    --data "<?xml version="1.0" encoding="UTF-8"?>
	<request>
		<PageIndex>1</PageIndex>
		<ReadCount>$1</ReadCount>
		<BoxType>1</BoxType>
		<SortType>0</SortType>
		<Ascending>0</Ascending>
		<UnreadPreferred>0</UnreadPreferred>
	</request>"`

    echo "$r"

    local check=`echo "$r"| grep -oP "$2"`
    if [ -z "$check" ];then
         echo "0"
    else
         echo "1"
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
    echo "usage: huaweiScript [[[-i ip ] & [[-s number text] | [-c Amount(0-9) Check_string]] | [-h]]"
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


smsText=
phoneNumber=

smsAmount=
checkString=

ipAddress="127.0.0.1"

while [ "$1" != "" ]; do
    case $1 in
        -i | --ip )             shift
                                ipAddress=$1
                                ;;
        -s | --send )           shift
                                phoneNumber=$1
                                shift
                                smsText=$1
                                sendInfo=1
                                ;;
        -c | --check )          shift
                                smsAmount=$1
                                shift
                                checkString=$1
                                allInfo=1
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
echo "$phoneNumber"
if [ "$sendInfo" = "1" ]; then
            case ${phoneNumber//[ -]/} in
                 *[!0-9]* | 0* | ???????????* | \
                 ????????? | ???????? | ??????? | ?????? | ????? | ???? | ??? | ?? | ? | '')
                    sendSms "$phoneNumber" "$smsText";;  
                 *) sendSms "$phoneNumber" "$smsText";;  
            esac
fi

if [ "$allInfo" = "1" ]; then
        case $smsAmount in
             ''|*[!1-9]*) usage ;;
             *) getSmsList "$smsAmount" "$checkString";;
        esac  
	
fi



