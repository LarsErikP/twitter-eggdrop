#!/bin/bash

err=$(wget -q -O - "http://api.twitter.com/1/statuses/user_timeline/${1}.xml?trim_user=true&count=10&include_rts=true" | wc -l)
if [ $err -eq 0 ]; then
	echo "No such user"
	exit 1
else
	if [ $# -eq 2 ]; then
		if [[ $2 =~ [0-9]+ ]] && [ $2 -gt 0 ] && [ $2 -le 10 ]; then
			tweet=$(wget -q -O - "http://api.twitter.com/1/statuses/user_timeline/${1}.xml?trim_user=true&count=10&include_rts=true" | xmlstarlet sel -t -v "//status[$2]/text")
		elif [ -z $2 ]; then
			tweet=$(wget -q -O - "http://api.twitter.com/1/statuses/user_timeline/${1}.xml?trim_user=true&count=10&include_rts=true" | xmlstarlet sel -t -v "//status[1]/text")
		else
			echo "Usage: !tweet <user> [1-10]"
			exit 1
		fi
	else
		tweet=$(wget -q -O - "http://api.twitter.com/1/statuses/user_timeline/${1}.xml?trim_user=true&count=10&include_rts=true" | xmlstarlet sel -t -v "//status[1]/text")
	fi
fi

if [ "$tweet" = "" ]; then
	echo "Could not find that tweet"
	exit 1
else	
	echo $tweet | sed 's/&amp;lt;/</g' | sed 's/&amp;gt;/>/g'
fi
