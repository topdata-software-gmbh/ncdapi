#!/bin/bash
# - developed by linux-insideDE @GPN18
# - 2024/04 upgraded by topdata software gmbh

declare -gr ERROR_CODE_NO_NETCUP_CREDENTIALS=1
declare -gr ERROR_CODE_NO_ARGUMENTS=2
declare -gr ERROR_CODE_INVALID_ARGUMENTS=3


# Regular             Bold                  Underline             High Intensity        BoldHigh Intens       Background            High Intensity Backgrounds
Bla='\033[0;30m';     BBla='\033[1;30m';    UBla='\033[4;30m';    IBla='\033[0;90m';    BIBla='\033[1;90m';   On_Bla='\033[40m';    On_IBla='\033[0;100m';
Red='\033[0;31m';     BRed='\033[1;31m';    URed='\033[4;31m';    IRed='\033[0;91m';    BIRed='\033[1;91m';   On_Red='\033[41m';    On_IRed='\033[0;101m';
Gre='\033[0;32m';     BGre='\033[1;32m';    UGre='\033[4;32m';    IGre='\033[0;92m';    BIGre='\033[1;92m';   On_Gre='\033[42m';    On_IGre='\033[0;102m';
Yel='\033[0;33m';     BYel='\033[1;33m';    UYel='\033[4;33m';    IYel='\033[0;93m';    BIYel='\033[1;93m';   On_Yel='\033[43m';    On_IYel='\033[0;103m';
Blu='\033[0;34m';     BBlu='\033[1;34m';    UBlu='\033[4;34m';    IBlu='\033[0;94m';    BIBlu='\033[1;94m';   On_Blu='\033[44m';    On_IBlu='\033[0;104m';
Pur='\033[0;35m';     BPur='\033[1;35m';    UPur='\033[4;35m';    IPur='\033[0;95m';    BIPur='\033[1;95m';   On_Pur='\033[45m';    On_IPur='\033[0;105m';
Cya='\033[0;36m';     BCya='\033[1;36m';    UCya='\033[4;36m';    ICya='\033[0;96m';    BICya='\033[1;96m';   On_Cya='\033[46m';    On_ICya='\033[0;106m';
Whi='\033[0;37m';     BWhi='\033[1;37m';    UWhi='\033[4;37m';    IWhi='\033[0;97m';    BIWhi='\033[1;97m';   On_Whi='\033[47m';    On_IWhi='\033[0;107m';

# ---- Text Reset
RCol='\033[0m'
# ---- Warning: black-on-yellow
Warning='\e[30;43m'
# ---- Error: white-on-red
Error='\e[97;41m'
# ---- Success: white-on-green
Success='\e[97;42m'


# ==== convenience echo functions

function echo_yellow() {
    echo -e "${Yel}$*${RCol}"
}

function echo_blue() {
    echo -e "${Blu}$*${RCol}"
}

function echo_green() {
    echo -e "${Gre}$*${RCol}"
}

function echo_red() {
    echo -e "${Red}$*${RCol}"
}

function echo_warning() {
    echo -e "${Warning}$*${RCol}"
}
function echo_error() {
    echo -e "${Error}$*${RCol}"
}

function echo_success() {
    echo -e "${Success}$*${RCol}"
}



# ---- Function to print usage instructions
usage() {
    SELF=$(basename "${BASH_SOURCE[0]}")
    echo "$SELF - a script to manage DNS records at netcup"
    echo ""
    echo "USAGE: $SELF <options>..."
    echo ""
    echo "OPTIONS"
    echo "Note: Only ONE Argument like -N or -dN"
    echo "Note: If you have a string which is including spaces use \"argument with spaces\""
    echo "    -d Debug Mode       $SELF -d..."
    echo "    -N NEW Record       $SELF -N HOST DOMAIN RECORDTYPE DESTINATION [PRIORITY]"
    echo "    -M MOD Record       $SELF -M ID HOST DOMAIN RECORDTYPE DESTINATION [PRIORITY]"
    echo "    -D DEL Record       $SELF -D ID HOST DOMAIN RECORDTYPE DESTINATION [PRIORITY]"
    echo "    -g get all Records  $SELF -g DOMAIN"
    echo "    -b backup from Zone $SELF -b DOMAIN"
    echo "    -R Restore Zone     $SELF -R FILE"
    echo "    -s get SOA          $SELF -s DOMAIN"
    echo "    -S change SOA       $SELF -S DOMAIN TTL REFRESH RETRY EXPIRE DNSSECSTATUS"
    echo "    -l list all Domains $SELF -l"
    echo "    -h this help"
    echo ""
    echo " CREDENTIALS - make sure the following environment variables are set"
    echo "    NETCUP_APIKEY"
    echo "    NETCUP_APIPASSWORD"
    echo "    NETCUP_CUSTOMERNUMBER"
    echo ""  
    echo "EXAMPLES"
    echo "    New CAA Record:  $SELF -N @ example.com CAA \"0 issue letsencrypt.org\""
    echo "    New   A Record:  $SELF -N @ example.com A 127.0.0.1"
    echo "    New  MX Record:  $SELF -N @ example.com MX mail.example.com 20"
    echo "    Get all records: $SELF -g example.com"
    echo "    Delete Record:   $SELF -D 1234567 @ example.com A 127.0.0.1"
    echo "    Change SOA:      $SELF -S example.com 3600 28800 7200 1209600 true"
}

# ---- print error message, usage instructions and exit
function error_message_and_exit() {
    # -- init
    errorMessage=$1
    exitCode=$2

    # -- main
    echo_error "$errorMessage"
    usage
    exit $exitCode
}

# ---- dns api functions
login() {
    tmp=$(curl -s -X POST -d "{\"action\": \"login\", \"param\": {\"apikey\": \"$apikey\", \"apipassword\": \"$apipw\", \"customernumber\": \"$cid\"}}" "$end")
    sid=$(echo "${tmp}" | jq -r .responsedata.apisessionid)
    if [ $debug = true ]; then
        msg=$(echo "${tmp}" | jq -r .shortmessage)
        echo "$msg"
    fi
    if [ "$(echo "$tmp" | jq -r .status)" != "success" ]; then
        echo "Error: $tmp"
        return 1
    fi
}
logout() {
    tmp=$(curl -s -X POST -d "{\"action\": \"logout\", \"param\": {\"apikey\": \"$apikey\", \"apisessionid\": \"$sid\", \"customernumber\": \"$cid\"}}" "$end")
    if [ $debug = true ]; then
        msg=$(echo "${tmp}" | jq -r .shortmessage)
        echo "$msg"
    fi
    if [ "$(echo "$tmp" | jq -r .status)" != "success" ]; then
        echo "Error: Session isn't made invalid !!!"
        echo "Error: $tmp"
        return 1
    fi
}
addRecord() {
    login
    if [ "$3" == "CAA" ] || [ "$3" == "caa" ]; then
        if [ "$(echo "$4" | cut -d' ' -f2)" == "issue" ] || [ "$(echo "$4" | cut -d' ' -f2)" == "iodef" ] || [ "$(echo "$4" | cut -d' ' -f2)" == "issuewild" ]; then
            prepstate=$(echo "$4" | cut -d' ' -f3)
            dest=${4//$prepstate/\\"\"$prepstate\\"\"}
        else
            echo "Error: Please Check your CAA Record"
            logout
            exit 1
        fi
    else
        dest=$4
    fi
    tmp=$(curl -s -X POST -d "{\"action\": \"updateDnsRecords\", \"param\": {\"apikey\": \"$apikey\", \"apisessionid\": \"$sid\", \"customernumber\": \"$cid\",\"clientrequestid\": \"$client\" , \"domainname\": \"$2\", \"dnsrecordset\": { \"dnsrecords\": [ {\"id\": \"\", \"hostname\": \"$1\", \"type\": \"$3\", \"priority\": \"${5:-"0"}\", \"destination\": \"$dest\", \"deleterecord\": \"false\", \"state\": \"yes\"} ]}}}" "$end")
    if [ $debug = true ]; then
        echo "${tmp}"
    fi
    if [ "$(echo "$tmp" | jq -r .status)" != "success" ]; then
        echo "Error: $tmp"
        logout
        return 1
    fi
    echo "${tmp}" | jq --arg host "$1" --arg type "$3" --arg dest "$dest" '.responsedata.dnsrecords[] | select(.hostname==$host and .type==$type and .destination==$dest) .id' | tr -d \"
    logout
}
delRecord() {
    login
    if [ "$4" == "CAA" ] || [ "$4" == "caa" ]; then
        if [ "$(echo "$5" | cut -d' ' -f2)" == "issue" ] || [ "$(echo "$5" | cut -d' ' -f2)" == "iodef" ] || [ "$(echo "$5" | cut -d' ' -f2)" == "issuewild" ]; then
            prepstate=$(echo "$5" | cut -d' ' -f3)
            dest=${5//$prepstate/\\"\"$prepstate\\"\"}
        else
            echo "Error: Please Check your CAA Record"
            logout
            exit 1
        fi
    else
        dest=$5
    fi
    tmp=$(curl -s -X POST -d "{\"action\": \"updateDnsRecords\", \"param\": {\"apikey\": \"$apikey\", \"apisessionid\": \"$sid\", \"customernumber\": \"$cid\",\"clientrequestid\": \"$client\" , \"domainname\": \"$3\", \"dnsrecordset\": { \"dnsrecords\": [ {\"id\": \"$1\", \"hostname\": \"$2\", \"type\": \"$4\", \"priority\": \"${6:-"0"}\", \"destination\": \"$dest\", \"deleterecord\": \"TRUE\", \"state\": \"yes\"} ]}}}" "$end")
    if [ $debug = true ]; then
        echo "${tmp}"
    fi
    if [ "$(echo "$tmp" | jq -r .status)" != "success" ]; then
        echo "Error: $tmp"
        logout
        return 1
    fi
    logout
}
modRecord() {
    login
    if [ "$4" == "CAA" ] || [ "$4" == "caa" ]; then
        if [ "$(echo "$5" | cut -d' ' -f2)" == "issue" ] || [ "$(echo "$5" | cut -d' ' -f2)" == "iodef" ] || [ "$(echo "$5" | cut -d' ' -f2)" == "issuewild" ]; then
            prepstate=$(echo "$5" | cut -d' ' -f3)
            dest=${5//$prepstate/\\"\"$prepstate\\"\"}
        else
            echo "Error: Please Check your CAA Record"
            logout
            exit 1
        fi
    else
        dest=$5
    fi
    tmp=$(curl -s -X POST -d "{\"action\": \"updateDnsRecords\", \"param\": {\"apikey\": \"$apikey\", \"apisessionid\": \"$sid\", \"customernumber\": \"$cid\",\"clientrequestid\": \"$client\" , \"domainname\": \"$3\", \"dnsrecordset\": { \"dnsrecords\": [ {\"id\": \"$1\", \"hostname\": \"$2\", \"type\": \"$4\", \"priority\": \"${6:-"0"}\", \"destination\": \"$dest\", \"deleterecord\": \"FALSE\", \"state\": \"yes\"} ]}}}" "$end")
    if [ $debug = true ]; then
        echo "${tmp}"
    fi
    if [ "$(echo "$tmp" | jq -r .status)" != "success" ]; then
        echo "Error: $tmp"
        logout
        return 1
    fi
    logout
}
getSOA() {
    login
    tmp=$(curl -s -X POST -d "{\"action\": \"infoDnsZone\", \"param\": {\"apikey\": \"$apikey\", \"apisessionid\": \"$sid\", \"customernumber\": \"$cid\", \"domainname\": \"$1\"}}" "$end")
    if [ $debug = true ]; then
        echo "$tmp"
    fi
    if [ "$(echo "$tmp" | jq -r .status)" != "success" ]; then
        echo "Error: $tmp"
        logout
        return 1
    fi
    xxd=$(echo "${tmp}" | jq -r '.responsedata')
    echo "$xxd"
    logout
}
getSOAONESESSION() {
    tmp=$(curl -s -X POST -d "{\"action\": \"infoDnsZone\", \"param\": {\"apikey\": \"$apikey\", \"apisessionid\": \"$sid\", \"customernumber\": \"$cid\", \"domainname\": \"$1\"}}" "$end")
    xxd=$(echo "${tmp}" | jq -r '.responsedata')
    echo "$xxd"
}
setSOA() {
    login
    tmp=$(curl -s -X POST -d "{\"action\": \"updateDnsZone\", \"param\": {\"apikey\": \"$apikey\", \"apisessionid\": \"$sid\", \"customernumber\": \"$cid\",\"clientrequestid\": \"$client\" , \"domainname\": \"$1\", \"dnszone\": { \"name\": \"$1\", \"ttl\": \"$2\", \"serial\": \"\", \"refresh\": \"$3\", \"retry\": \"$4\", \"expire\": \"$5\", \"dnssecstatus\": \"$6\"} }}" "$end")
    if [ $debug = true ]; then
        echo "${tmp}"
    fi
    if [ "$(echo "$tmp" | jq -r .status)" != "success" ]; then
        echo "Error: $tmp"
        logout
        return 1
    fi
    logout
}
listDomains() {
    login
    tmp=$(curl -s -X POST -d "{\"action\": \"listallDomains\", \"param\": {\"apikey\": \"$apikey\", \"apisessionid\": \"$sid\", \"customernumber\": \"$cid\", \"domainname\": \"$1\"}}" "$end")
    if [ $debug = true ]; then
        echo "$tmp"
    fi
    if [ "$(echo "$tmp" | jq -r .status)" != "success" ]; then
        echo "Error: $tmp"
        logout
        return 1
    fi
    xxd=$(echo "${tmp}" | jq -r '.responsedata[].domainname')
    echo "$xxd"
    logout
}
getRecords() {
    login
    tmp=$(curl -s -X POST -d "{\"action\": \"infoDnsRecords\", \"param\": {\"apikey\": \"$apikey\", \"apisessionid\": \"$sid\", \"customernumber\": \"$cid\", \"domainname\": \"$1\"}}" "$end")
    if [ $debug = true ]; then
        echo "$tmp"
    fi
    if [ "$(echo "$tmp" | jq -r .status)" != "success" ]; then
        echo "Error: $tmp"
        logout
        return 1
    fi
    xxd=$(echo "${tmp}" | jq -r '.responsedata.dnsrecords')
    echo "$xxd"
    logout
}
getRecordsONESESSION() {
    tmp=$(curl -s -X POST -d "{\"action\": \"infoDnsRecords\", \"param\": {\"apikey\": \"$apikey\", \"apisessionid\": \"$sid\", \"customernumber\": \"$cid\", \"domainname\": \"$1\"}}" "$end")
    xxd=$(echo "$tmp" | jq -r '.responsedata.dnsrecords')
    echo "$xxd"
}
backup() {
    login
    debug=false
    soa=$(getSOAONESESSION "$1")
    records=$(getRecordsONESESSION "$1")
    statement="{\"soa\":$soa,\"records\":$records}"
    echo "$statement" > backup-"$1"-"$(date +%Y%m%d)"-"$(date +%H%M%S)".txt
    logout
}
restore() {
    login
    bfile=$(cat "$1")
    name=$(echo "$bfile" | jq -r '.soa.name')
    ttl=$(echo "$bfile" | jq -r '.soa.ttl')
    refresh=$(echo "$bfile" | jq -r '.soa.refresh')
    retry=$(echo "$bfile" | jq -r '.soa.retry')
    expire=$(echo "$bfile" | jq -r '.soa.expire')
    dnssecstatus=$(echo "$bfile" | jq -r '.soa.dnssecstatus')
    currec=$(getRecordsONESESSION "$name")
    inc=0

    #update soa
    tmp=$(curl -s -X POST -d "{\"action\": \"updateDnsZone\", \"param\": {\"apikey\": \"$apikey\", \"apisessionid\": \"$sid\", \"customernumber\": \"$cid\",\"clientrequestid\": \"$client\" , \"domainname\": \"$name\", \"dnszone\": { \"name\": \"$name\", \"ttl\": \"$ttl\", \"serial\": \"\", \"refresh\": \"$refresh\", \"retry\": \"$retry\", \"expire\": \"$expire\", \"dnssecstatus\": \"$dnssecstatus\"} }}" "$end")
    if [ $debug = true ]; then
        echo "${tmp}"
    fi
    if [ "$(echo "$tmp" | jq -r .status)" != "success" ]; then
        echo "Error: $tmp"
        logout
        return 1
    fi

    #del all
    len=$(echo "$currec" | jq '. | length')
    statement=""
    while [ "$inc" != "$len" ]; do
        id=$(echo "$currec" | jq -r .[$inc].id)
        host=$(echo "$currec" | jq -r .[$inc].hostname)
        type=$(echo "$currec" | jq -r .[$inc].type)
        prio=$(echo "$currec" | jq -r .[$inc].priority)
        dest=$(echo "$currec" | jq -r .[$inc].destination)
        if [ "$type" == "CAA" ] || [ "$type" == "caa" ]; then
            if [ "$(echo "$dest" | cut -d' ' -f2)" == "issue" ] || [ "$(echo "$dest" | cut -d' ' -f2)" == "iodef" ] || [ "$(echo "$dest" | cut -d' ' -f2)" == "issuewild" ]; then
                prepstate=$(echo "$dest" | cut -d' ' -f3)
                # shellcheck disable=SC2001
                dest=$(echo "$dest" | sed 's/\"/\\"/g')
            else
                echo "Error: Please Check your CAA Record"
                logout
                exit 1
            fi
        else
            dest=$dest
        fi

        if [ "$inc" = "$((len-1))" ]; then
            statement+="{\"id\": \"$id\", \"hostname\": \"$host\", \"type\": \"$type\", \"priority\": \"$prio\", \"destination\": \"$dest\", \"deleterecord\": \"TRUE\", \"state\": \"yes\"}"
        else
            statement+="{\"id\": \"$id\", \"hostname\": \"$host\", \"type\": \"$type\", \"priority\": \"$prio\", \"destination\": \"$dest\", \"deleterecord\": \"TRUE\", \"state\": \"yes\"},"

        fi
        inc=$((inc+1))
    done
    tmp=$(curl -s -X POST -d "{\"action\": \"updateDnsRecords\", \"param\": {\"apikey\": \"$apikey\", \"apisessionid\": \"$sid\", \"customernumber\": \"$cid\",\"clientrequestid\": \"$client\" , \"domainname\": \"$name\", \"dnsrecordset\": { \"dnsrecords\": [ $statement ]}}}" "$end")
    if [ $debug = true ]; then
        echo "${tmp}"
    fi
    if [ "$(echo "$tmp" | jq -r .status)" != "success" ]; then
        echo "Error: $tmp"
        logout
        return 1
    fi

    inc=0
    #add all
    statement=""
    len=$(echo "$bfile" | jq '.records | length')
    while [ "$inc" != "$len" ]; do
        host=$(echo "$bfile" | jq -r .records[$inc].hostname)
        type=$(echo "$bfile" | jq -r .records[$inc].type)
        prio=$(echo "$bfile" | jq -r .records[$inc].priority)
        dest=$(echo "$bfile" | jq -r .records[$inc].destination)
        if [ "$type" == "CAA" ] || [ "$type" == "caa" ]; then
            if [ "$(echo "$dest" | cut -d' ' -f2)" == "issue" ] || [ "$(echo "$dest" | cut -d' ' -f2)" == "iodef" ] || [ "$(echo "$dest" | cut -d' ' -f2)" == "issuewild" ]; then
                prepstate=$(echo "$dest" | cut -d' ' -f3)
                # shellcheck disable=SC2001
                dest=$(echo "$dest" | sed 's/\"/\\"/g')
            else
                echo "Error: Please Check your CAA Record"
                logout
                exit 1
            fi
        else
            dest=$dest
        fi
        if [ "$inc" = "$((len-1))" ]; then
            statement+="{\"id\": \"\", \"hostname\": \"$host\", \"type\": \"$type\", \"priority\": \"$prio\", \"destination\": \"$dest\", \"deleterecord\": \"false\", \"state\": \"yes\"}"
        else
            statement+="{\"id\": \"\", \"hostname\": \"$host\", \"type\": \"$type\", \"priority\": \"$prio\", \"destination\": \"$dest\", \"deleterecord\": \"false\", \"state\": \"yes\"},"
        fi
        inc=$((inc+1))
    done
    tmp=$(curl -s -X POST -d "{\"action\": \"updateDnsRecords\", \"param\": {\"apikey\": \"$apikey\", \"apisessionid\": \"$sid\", \"customernumber\": \"$cid\",\"clientrequestid\": \"$client\" , \"domainname\": \"$name\", \"dnsrecordset\": { \"dnsrecords\": [ $statement ]}}}" "$end")
    if [ $debug = true ]; then
        echo "${tmp}"
    fi
    if [ "$(echo "$tmp" | jq -r .status)" != "success" ]; then
        echo "Error: $tmp"
        logout
        return 1
    fi
    logout
}



# ==== main ====

# ---- vars
end="https://ccp.netcup.net/run/webservice/servers/endpoint.php?JSON"
client=""
debug=false
# -- Check if environment variables are set, exit with error message if not
if [ -z "$NETCUP_APIKEY" ] || [ -z "$NETCUP_APIPASSWORD" ] || [ -z "$NETCUP_CUSTOMERNUMBER" ]; then
    if [ -z "$NETCUP_APIKEY" ]; then
        echo_error "NETCUP_APIKEY is missing"
    fi
    if [ -z "$NETCUP_APIPASSWORD" ]; then
        echo_error "NETCUP_APIPASSWORD is missing"
    fi
    if [ -z "$NETCUP_CUSTOMERNUMBER" ]; then
        echo_error "NETCUP_CUSTOMERNUMBER is missing"
    fi

    error_message_and_exit "Netcup not found in env." $ERROR_CODE_NO_NETCUP_CREDENTIALS
fi
apikey=$NETCUP_APIKEY
apipw=$NETCUP_APIPASSWORD
cid=$NETCUP_CUSTOMERNUMBER

# -- assert that at least one argument is given
if [ $# -eq 0 ]; then
    error_message_and_exit "No argument given" $ERROR_CODE_NO_ARGUMENTS
fi

# -- decide what to do
while getopts 'NdDgMbRhslS' opt; do
    case "$opt" in
        d) debug=true ;;
        N) addRecord "$2" "$3" "$4" "$5" "$6" ;;
        D) delRecord "$2" "$3" "$4" "$5" "$6" "$7" "$8" ;;
        g) getRecords "$2" ;;
        M) modRecord "$2" "$3" "$4" "$5" "$6" "$7" ;;
        b) backup "$2" ;;
        R) restore "$2" ;;
        s) getSOA "$2" ;;
        S) setSOA "$2" "$3" "$4" "$5" "$6" "$7" ;;
        l) listDomains "$2" ;;
        h) usage ;;
        *) error_message_and_exit "Invalid argument given" $ERROR_CODE_INVALID_ARGUMENTS ;;
    esac
done
