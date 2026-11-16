#!/bin/bash
# ---------------------------------------------------------------------------
# Name.......: Email and SMS sender.
# Author.....: Omkar Dhekne <ogdhekne@yahoo.com> <https://github.com/ogdhekne>
# Date.......: 2021-07-31 <YYYY-MM-DD>
# Purpose....: Script to send email and sms
# Reference..: This script is created using requirement from Mr. Shrinivas Tilak.
# Revision...: v1.0
# Licence....: GPLv3 <https://www.gnu.org/licenses/gpl-3.0.en.html>
# ---------------------------------------------------------------------------

# Environment variables:
    # GENERAL:
        REV="v1.0"
        RANDOMX="$(shuf -i 1000-10000 -n 1)"

    #SMS:
        APIKEY="a81804bf-a8de-11eb-80ea-0200cd936042"
        TO="+91${2}"
        FROM="${3}"        
        TEMPLATE="${4}"

    #EMAIL:
        EMAILTO="${2}"
        BODY="${3}"
        SUBJECT="${4}"
# Functions:
    install()
    {
        # reference : https://www.thegeekdiary.com/how-to-install-and-configure-mutt-in-centos-rhel/
        
        # Install mutt, copy muttrc template and create .mutt and cache directories.

        sudo yum install mutt curl -y

        cp muttrc ~/.muttrc

        mkdir -p ~/.mutt/cache

        echo -e "\nPlease edit ${HOME}/.muttrc file for use."
    }

    sms()
    {
        # reference : https://2fa.api-docs.io/v1/send-sms-otp/sending-sms-otp-custom-otp
        
        # Send transactional sms

        curl -X POST https://2factor.in/API/V1/${APIKEY}/SMS/${TO}/${RANDOMX}/${TEMPLATE}

    }

    email()
    {
        echo ${BODY} | mutt -s "${SUBJECT}" -- ${EMAILTO}
    }

# Print Help.
  help()
  {
  cat <<EOF
  +-------------------------------+
  +  SMS and EMAIL Utility: $REV  +
  +-------------------------------+
  install: $0 install
  email:   $0 email <to> <sub> <body>
  sms:     $0 sms <to> <from> <template>
  help:    $0 help

  Examples:
  install: $0 install
  email:   $0 email "ogdhekne@gmail.com" "Test Mail Sent Sent using mutt command" "Test Email from Oracle 18C XE on www.niramayyog.com"
  sms:     $0 sms "9876543210" "SHSOFT" "SHRISOFT-OTP"
EOF
  }

# Execute functions:
  # If no commandline argument is passed then print help.
  if [[ -z $1 ]]
  then
    help
  else
    $1
  fi