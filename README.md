# ncdapi - (unofficial) Netcup DNS API Bash Client

## About

- a bash client for the [Netcup DNS API](https://helpcenter.netcup.com/de/wiki/general/unsere-api)
- a fork of unmaintained [ncdapi](https://github.com/linxside/ncdapi)
- differences to the original version: 
  - some colors
  - netcup credentials are used from env variables
 
## WARNING
This client is well tested, but it is possible that some actions provoke a bug, so the use of this client is on your own risk and may result in lost of your zone data.

## Requirements
- jq (a json parser)
- curl

## Netcup API Credentials
The script expects these environment variables to be set:
```
NETCUP_APIKEY
NETCUP_APIPASSWORD
NETCUP_CUSTOMERNUMBER
```

These credentials can be stored a file and sourced before running the script:
```bash
# my-netcup-credentials.sh
export NETCUP_APIKEY="your-api-key"
export NETCUP_APIPASSWORD="your-api-password"
export NETCUP_CUSTOMERNUMBER="your-customer-number"
```

To load these environment variables from the file:
```bash
source my-netcup-credentials.sh
```


## How to use
```
ncdapi.sh - a script to manage DNS records at netcup

USAGE: ncdapi.sh <options>...

OPTIONS
Note: Only ONE Argument like -N or -dN
Note: If you have a string which is including spaces use "argument with spaces"
    -d Debug Mode       ncdapi.sh -d...
    -N NEW Record       ncdapi.sh -N HOST DOMAIN RECORDTYPE DESTINATION [PRIORITY]
    -M MOD Record       ncdapi.sh -M ID HOST DOMAIN RECORDTYPE DESTINATION [PRIORITY]
    -D DEL Record       ncdapi.sh -D ID HOST DOMAIN RECORDTYPE DESTINATION [PRIORITY]
    -g get all Records  ncdapi.sh -g DOMAIN
    -b backup from Zone ncdapi.sh -b DOMAIN
    -R Restore Zone     ncdapi.sh -R FILE
    -s get SOA          ncdapi.sh -s DOMAIN
    -S change SOA       ncdapi.sh -S DOMAIN TTL REFRESH RETRY EXPIRE DNSSECSTATUS
    -l list all Domains ncdapi.sh -l
    -h this help

 CREDENTIALS - make sure the following environment variables are set
    NETCUP_APIKEY
    NETCUP_APIPASSWORD
    NETCUP_CUSTOMERNUMBER

EXAMPLES
    New CAA Record:  ncdapi.sh -N @ example.com CAA "0 issue letsencrypt.org"
    New   A Record:  ncdapi.sh -N @ example.com A 127.0.0.1
    New  MX Record:  ncdapi.sh -N @ example.com MX mail.example.com 20
    Get all records: ncdapi.sh -g example.com
    Delete Record:   ncdapi.sh -D 1234567 @ example.com A 127.0.0.1
    Change SOA:      ncdapi.sh -S example.com 3600 28800 7200 1209600 true
```

## Functions
* add new record
* modify record/SOA
* delete record
* get all records/domains
* backup/restore of zone + SOA
* If the api returns a failure the session will automatically make invalid and the plain JSON from the api will be written to stdout

## TODO
- get credentials from environment variables optionally load them from a .env file
- DynDNS capability if the api get the possibility for per record TTL in near future
- ...

## How to obtain the DNS entry ID?

First, login to the [netcup](https://netcup.de) website. Navigate to "Domains" -> choose your domain -> "DNS" section:

![netcup NDS section](./screenshots/netcup-1.png)

Then click with the right mouse button on the desired DNS entry from which the ID should come from. Choose the "inspect element" menue entry.

![DNS entries for a domain](./screenshots/netcup-2.png)

Now you should see the developer tools and a `<input>`-element. The number in the `name`-attribute's value after `record[` is the wanted number.

![DNS entry's ID](./screenshots/netcup-3.png)

Copy this ID (here: 12176576) into your script.

developed by linxside @GPN18
