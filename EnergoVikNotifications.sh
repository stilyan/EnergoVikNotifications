#!/bin/bash

EnergoClientId="xxxxxxxxxxxx"
VikClientId="yyyyyyyy"

# Modify the sendmail arguments if you are not using gmail.
EmailSenderUsername="xxxxxxxxxxxxxx@gmail.com"
EmailSenderPassword="xxxxxxxxxxxxxxx"
EmailRecipient="xxxxxxxxx@sms.mtel.net"

# End of config

################################## ENERGO ##################################

GetElRaw=$(curl -s -d "kin=$EnergoClientId" -X POST https://www.energo-pro.bg/bg/proverka-na-smetka-za-elektroenergiya > /tmp/elraw.txt)

CalcElSum=$(cat /tmp/elraw.txt | \
        sed -n -e '/<table*/,/<\/table>/p' | \
        sed -n -e '/<tr class/,/<\/tr>/p' | \
        grep '<td>' | \
        sed -e 's/^[ \t]*//' \
	-e "/$EnergoClientId/,+1d" \
        -e '/^[^.]*\.[^.]*\.[^.]*$/d' \
        -e 's/<[^>]*>//g' | \
	`# Solution for issue where if sum is round, e.g. 12.00, the end message gets broken, has no deadline date. ` \
	`# With it the sum, e.g. 12.00, is shown as integer, e.g. 12. The downside is when sum is too low, e.g. 0.10, it shows as 0.1. ` \
	awk '{s+=$1} END {print s}' \
        )

# Their site doesn't have the same structure when there arent unpaid bills. In such case we do not need the date at all.
if [ "$CalcElSum" != "" ]
then
        ElPaymentDueDate=$(cat /tmp/elraw.txt | \
                sed -n -e '/<table*/,/<\/table>/p' | \
                sed -n -e '/<tr class/,/<\/tr>/p' | \
                grep '<td>' | \
                sed -e 's/^[ \t]*//' \
                -e "/$EnergoClientId/,+1d" \
                -e 's/<[^>]*>//g' | \
                tail -n 1\
                )

	MessageEl="(EnergoPro) Dalzhite $CalcElSum lv. do $ElPaymentDueDate"
fi

################################## VIK ##################################

GetVikRaw=$(curl -s -X POST -F "number=$VikClientId" https://www.vik-vt.com/index.php?mod=checkbill > /tmp/vikraw.txt)

VikTotalBill=$(cat /tmp/vikraw.txt | grep "Общо" -A 1 | sed -n '1!p' | sed -r 's/\s+//g' | sed 's/.\{8\}$//' | sed 's/^.\{4\}//')

# Basic Calculator (bc) returns 0/1 on false/true.
# Comparing float via bash's math is not possible.
if [ "$(echo "$VikTotalBill>0" | bc)" == "1" ]
then

VikBillDueDate=$(cat /tmp/vikraw.txt | grep "Срок за плащане" -A 1 | sed -n '1!p' | sed -r 's/\s+//g' | sed 's/.\{5\}$//' | sed 's/^.\{4\}//')

# Month in due date is string in cyrillic. I want DD.MM.YYYY.
case $(echo $VikBillDueDate | sed 's/[0-9]*//g') in

"Януари")
VikBillDueDate=$(echo $VikBillDueDate | sed 's/[^0-9]//g')".01."$(date +%Y)
;;

"Февруари")
VikBillDueDate=$(echo $VikBillDueDate | sed 's/[^0-9]//g')".02."$(date +%Y)
;;

"Март")
VikBillDueDate=$(echo $VikBillDueDate | sed 's/[^0-9]//g')".03."$(date +%Y)
;;

"Април")
VikBillDueDate=$(echo $VikBillDueDate | sed 's/[^0-9]//g')".04."$(date +%Y)
;;

"Май")
VikBillDueDate=$(echo $VikBillDueDate | sed 's/[^0-9]//g')".05."$(date +%Y)
;;

"Юни")
VikBillDueDate=$(echo $VikBillDueDate | sed 's/[^0-9]//g')".06."$(date +%Y)
;;

"Юли")
VikBillDueDate=$(echo $VikBillDueDate | sed 's/[^0-9]//g')".07."$(date +%Y)
;;

"Август")
VikBillDueDate=$(echo $VikBillDueDate | sed 's/[^0-9]//g')".08."$(date +%Y)
;;

"Септември")
VikBillDueDate=$(echo $VikBillDueDate | sed 's/[^0-9]//g')".09."$(date +%Y)
;;

"Октомври")
VikBillDueDate=$(echo $VikBillDueDate | sed 's/[^0-9]//g')".10."$(date +%Y)
;;

"Ноември")
VikBillDueDate=$(echo $VikBillDueDate | sed 's/[^0-9]//g')".11."$(date +%Y)
;;

"Декември")
VikBillDueDate=$(echo $VikBillDueDate | sed 's/[^0-9]//g')".12."$(date +%Y)
;;

*)
VikBillDueDate=$(echo $VikBillDueDate | sed 's/[^0-9]//g')" ThereIsABug"
;;

esac

MessageVik="(VIK) Dalzhite $VikTotalBill lv. do $VikBillDueDate"

fi

Message="${MessageVik} ${MessageEl}"
echo "Message body: "$Message

# Since Message is combo of two vars AND A SPACE CHAR it is always set no matter the other VARs values.
# So only send notification if there is more than one char (the space) in Message.
if [ $(echo $Message | wc -c) -ge 2 ]
then
	sendemail \
        -f $EmailSenderUsername \
        -u "Izvestiya za smetki" \
        -t $EmailRecipient \
        -s "smtp.gmail.com:587" \
        -o tls=yes \
        -xu $EmailSenderUsername \
        -xp $EmailSenderPassword \
        -m $Message

	echo "Message sent."
else
	echo "Message NOT sent."
fi

rm -rf /tmp/elraw.txt
rm -rf /tmp/vikraw.txt
