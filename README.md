# EnergoVikNotifications
Bash script notifying for unpaid electricity and water bills.

## Prerequisites

### Additional packages
On Debian-like systems:

apt-get update\
apt-get install sendemail libio-socket-ssl-perl libnet-ssleay-perl\
apt-get install bc

The libraries are mandatory for TLS support.
BC (basic calculator) does some calculations which bash's math can't handle.

### Google mail security settings changes

Google identifies the sendemail software as a less-secure app and therefore requires a setting change to allow it.\
It's available at https://myaccount.google.com/lesssecureapps

### Mail2sms setup

The Bulgarian mobile operator A1 (ex-Mtel) offers free-to-use service - mail2sms.\
Messages sent to {MobilePhoneNumber}@sms.mtel.net are forwarded as text messages to the phone.

This is not mandatory, you may use regular mail box for the notifications.
