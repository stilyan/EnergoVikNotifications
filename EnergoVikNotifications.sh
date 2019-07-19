#!/bin/bash

EmailRecipient="xxxxxxxxxxxxxx@sms.mtel.net"
EnergoClientId="xxxxxxxxxxxx"

EmailSenderUsername="xxxxxxxxxxxxxxx@gmail.com"
EmailSenderPassword="xxxxxxxxxx"

###### End of config #######

GetElRaw=$(curl -s -d "kin=$EnergoClientId" -X POST https://www.energo-pro.bg/bg/proverka-na-smetka-za-elektroenergiya > /tmp/elraw.txt)

CalcElSum=$(cat /tmp/elraw.txt | \
        sed -n -e '/<table*/,/<\/table>/p' | \
        sed -n -e '/<tr class/,/<\/tr>/p' | \
        grep '<td>' | \
        sed -e 's/^[ \t]*//' \
        -e "/$EnergoClientId/,+1d" \
        -e '/^[^.]*\.[^.]*\.[^.]*$/d' \
        -e 's/<[^>]*>//g' | \
        awk '{s+=$1} END {print s}'\
        )

if [ "$CalcElSum" != "" ]; then
        ElPaymentDueDate=$(cat /tmp/elraw.txt | \
                sed -n -e '/<table*/,/<\/table>/p' | \
                sed -n -e '/<tr class/,/<\/tr>/p' | \
                grep '<td>' | \
                sed -e 's/^[ \t]*//' \
                -e "/$EnergoClientId/,+1d" \
                -e 's/<[^>]*>//g' | \
                tail -n 1\
                )

else
        echo "Skip"

fi

sendemail \
        -f $EmailSenderUsername \
        -u "Izvestiya za smetki" \
        -t $EmailRecipient \
        -s "smtp.gmail.com:587" \
        -o tls=yes \
        -xu $EmailSenderUsername \
        -xp $EmailSenderPassword \
        -m "(EnergoPro) Dalzhite ${CalcElSum} lv. do ${ElPaymentDueDate}"

rm -rf /tmp/elraw.txt
