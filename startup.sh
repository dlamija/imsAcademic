#!/bin/bash

#temporary file
ecom_park=/dev/null
login_done=/dev/null

#template file
template=frmservlet.templ

#data file
record_location="$HOME/Library/Application Support/imsUMP"
#record_location="./"
record_data="$record_location/data.dat"
cookie_file="$record_location/cjarECOM21"
output_result="$record_location/out.html"
jnlp_file="$record_location/frmservlet.jnlp"

#url location
url1='https://community.ump.edu.my/ecommstaff/login_eccom/?para=1'
url2='https://community.ump.edu.my/ecommstaff/Login'
url3='https://community.ump.edu.my/ecommstaff/cmsformlink.jsp?form=IMS_ACADSYS_LOGON'

#date
yesterday=$(date -v -1d +"%d/%m/%Y")
if [ ! -f "$record_data" ]; then
    mkdir -p "$record_location"
    
    osa_result=$(osascript -e 'display dialog "Who are you?" default answer "nobody"')
    username=$(echo $osa_result |cut -d':' -f3)
    echo $username | base64 > "$record_data"

    osa_result=$(osascript -e 'display dialog "What is your password?" default answer "password" with title "Hey '"$username"'"')
    password=$(echo $osa_result |cut -d':' -f3)
    echo $password | base64 >> "$record_data"
else
    username=$(head -n 1 "$record_data" | base64 --decode)
    password=$(cat "$record_data" | sed -n 2p | base64 --decode)
fi

USERNAM=$(echo $username | tr '[:lower:]' '[:upper:]')
#parameter
para1='lat=3.5439698133525273'
para2='lon=103.42893672274202'
para3="userName=$username"
para4="datebefore=$yesterday"
para5="password=$password"
para6='level=Staf'
url2para="$para1&$para2&$para3&$para4&$para6"


if [ ! -f "$cookie_file" ]; then
    #open login page to create the cookie
    curl --cookie "$cookie_file" --cookie-jar "$cookie_file" --data 'para=1' --location $url1 > "$ecom_park"
fi
#login into e-community
curl --cookie "$cookie_file" --cookie-jar "$cookie_file" --data $url2para --data-urlencode $para5 --location $url2 -k > "$login_done"
#generate unique session-id for your credential
curl --cookie "$cookie_file" --cookie-jar "$cookie_file" --location $url3 --output "$output_result"

string=$(awk -F "\"" '{print $2}' "$output_result" | grep https )
sed -e "s/XxXxXxX/$USERNAM/g;s/HHHHHHHHHH-HHHHH/${string: -16}/g" $template > "$jnlp_file"
open "$jnlp_file"
