#!/bin/sh



sendSms(){
    r=`curl -s -X POST  http://$modemIp/api/sms/send-sms --compressed \
    --proxy $ipAddress:$port \
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

checkSms(){

    # BoxType
      #   0: inbox
      #   1: outbox
      #   2: drafts

    r=`curl -s -X POST  http://$modemIp/api/sms/sms-list --compressed\
    --proxy $ipAddress:$port \
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

    #SmsType
      #1 Opened
      # else not opened
    echo "$r"
	
}

getSMSInfo(){
    getInfo "api/sms/sms-count"

    local localUnread=`echo "$r"| grep -oP '(?<=<LocalUnread>).*?(?=</LocalUnread>)'`
    local localInbox=`echo "$r"| grep -oP '(?<=<LocalInbox>).*?(?=</LocalInbox>)'`

  

    echo "LocalUnread = $localUnread : ok"
    echo "LocalInbox = $localInbox : ok"

}

getInfo(){
    r=`curl -s -X GET  http://$modemIp/$1 \
    --proxy $ipAddress:$port \
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
    r=`curl -s -i -X GET http://$modemIp/api/webserver/SesTokInfo \
    --proxy $ipAddress:$port`
    local http_status=$(echo "$r" | grep HTTP |  awk '{print $2}')
    if [ -z "$r" ];then
       error_exit "web server connection timeout"
    elif [ "$http_status" != "200" ]; then
       # handle error 
       error_exit "web server error $http_status"
    fi

}

usage(){
    echo "usage: huaweiScript [-i ip ]|[-u]|[-s number text]|[-g Amount(0-9)]|[-m modemIp]|[-p port]|[-h]]
          where:
	        -i{ip} set proxy ip (default 127.0.0.1)
                -m{modem ip} set modem ip (default 192.168.8.1)
                -p{port} set proxy port (default 8080)
                -u get unread sms status
                -s send sms
                -g get get last amount of sms(0-9)
                -h help"
}

error_exit()
{
     echo "$1" 1>&2
     exit 1
}

##### Main

r=
sendInfo=
checkSms=
checkStatus=
getSmsText=

smsText=
phoneNumber=

smsAmount=

ipAddress="127.0.0.1"
port="8080"
modemIp="192.168.8.1"

while [ "$1" != "" ]; do
    case $1 in
        -i | --ip )             shift
                                ipAddress=$1
                                ;;
        -m | --modem )          shift
                                modemIp=$1
                                ;;
        -p | --port )           shift
                                port=$1
                                ;;
        -u | --unread )         checkStatus=1
                                ;;
        -s | --send )           shift
                                phoneNumber=$1
                                shift
                                smsText=$1
                                sendInfo=1
                                ;;
        -g | --check )          shift
                                smsAmount=$1
                                getSmsText=1
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

if [ "$checkStatus" = "1" ]; then
            getSMSInfo   
fi

if [ "$sendInfo" = "1" ]; then
            case ${phoneNumber//[ -]/} in
                 *[!0-9]* | 0* | ???????????* | \
                 ????????? | ???????? | ??????? | ?????? | ????? | ???? | ??? | ?? | ? | '')
                    sendSms "$phoneNumber" "$smsText";;  
                 *) sendSms "$phoneNumber" "$smsText";;  
            esac
fi

if [ "$getSmsText" = "1" ]; then
        case $smsAmount in
             ''|*[!1-9]*) usage ;;
             *) checkSms "$smsAmount";;
        esac  
	
fi



