#!/bin/bash

user=$1
TWEETS=3 # Amount of tweets to load, when fetching a hashtag

############################### Functions ################################################

function gettweet()   {			# Fetch either the nth, or the last tweet of a user
	if [ $# -eq 2 ]; then		# Requested the Nth tweet of a user
		local t=$(wget -q -O - "http://api.twitter.com/1/statuses/user_timeline/${1}.xml?trim_user=true&count=10&include_rts=true" | xmlstarlet sel -t -v "//status[$2]/text" 2> /dev/null)
	elif [ $# -eq 1 ]; then		# Requested the last tweet of a user
		local t=$(wget -q -O - "http://api.twitter.com/1/statuses/user_timeline/${1}.xml?trim_user=true&count=10&include_rts=true" | xmlstarlet sel -t -v "//status[1]/text" 2> /dev/null)
	fi 
	echo $t
}

function error()   {				# Print error message, and exit
 	echo $1
	exit 1
}

function userexist()   {		# Checks if the user exists
	err=$(gettweet $user | wc -w) # If this returns zero words, the user is nonexistent
	if [ $err -eq 0 ]; then
		error "No such user"
	fi
}

function gethashtag()   {		# Fetch the last $TWEETS tweets wich contains the given hashtag
	tag=$(echo $1 |cut -d'#' -f2) 	# Get the keyword
   tags=()
	users=()
	tweets=()
	i=1
	
	while read line; do			# Get the actual tweets, and the user names
		tags[$i]="$line"
		(( i++ ))
	done < <(curl -s "https://search.twitter.com/search.json?q=%23${tag}&rpp=${TWEETS}" | python -mjson.tool | egrep -w 'from_user|text' | sed 's/^\s*//' | tr -d ",$") 
   # Strip leading spaces and trailing commas
   
	# Store usernames and corresponding tweets (and remove the json-stuff)
	for i in $(seq 1 $TWEETS); do
		users[$i]=$(echo "${tags["$i*2-1"]}" | tr -d "\"" | sed 's/from_user://')
   	tweets[$i]=$(echo "${tags["$i*2"]}" | sed 's/"text"://')
	done

	for j in $(seq 1 $TWEETS); do
		echo "${users[$j]}: ${tweets[$j]}" | sed 's/u00e6/æ/g;s/u00c6/Æ/g;s/u00f8/ø/g;s/u00d8/Ø/g;s/u00e5/å/g;s/u00c5/Å/g' # Norwegian letters are fun..... Possible bugs with other languages
	done
	
}

###########################################################################################	

################################ Main functionality #######################################

if [[ $user =~ ^[^#].*$ ]]; then 														# The argument is NOT a # (so we're looking for some user's tweet)
	userexist $user
	if [ $# -eq 2 ]; then 																	# Requested the nth tweet of a user
		if [[ $2 =~ ^[0-9]+$ ]] && [ $2 -gt 0 ] && [ $2 -le 10 ]; then			# $2 Must be a number between 1 and 10
			tweet=$(gettweet $user $2)
		elif [ "$2" = "" ]; then
			tweet=$(gettweet $user)
		else
			error "Usage: !tweet <user> [1-10]"
		fi
	elif [ $# -eq 1 ]; then
			tweet=$(gettweet $user)															# Requested the last tweet of a user
	fi

	if [ "$tweet" = "" ]; then																# Various errors handled. The requested tweet may not exist...
		error "Could not find that tweet"
	else																							# All good, print the tweet
		echo $tweet | sed 's/&amp;lt;/</g' | sed 's/&amp;gt;/>/g'				# Fixing some HTML to ASCII
	fi
else																								# Requested a hashtag
	gethashtag $user
fi


