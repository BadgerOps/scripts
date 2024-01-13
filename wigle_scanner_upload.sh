#!/bin/bash

# Example curl command:
# curl -i -H 'Accept:application/json' -u ${AUTH_TOKEN} --basic https://api.wigle.net/api/v2/profile/user
#set -x

# set variables, or inject via env vars
AUTH_TOKEN='TOKEN_HERE'
WARDRIVE_NAME='WIGLE_WIGLE_WIGLE_YEAH'
USERNAME='USER_NAME'
GROUP='USER_GROUP'

function requires_user_root() {
  if [ "$EUID" -ne 0 ]; then
    echo "${RED}Please run as root user (eg, with sudo)${RESET}"
    exit 1
  fi
}

create_wigle_upload_folder(){
  echo "checking to ensure wigle uploads folder exists..."
  if [[ -d /opt/kismet/upload_to_wigle ]]
  then 
    echo "wigle upload folder exists, continuing..."
  else 
    echo "wigle upload folder doesn't exist, creating..."
    sudo mkdir -p /opt/kismet/upload_to_wigle
    chown ${USERNAME}:${GROUP} /opt/kismet/upload_to_wigle
  fi
}

create_wigle_upload_complete_folder(){
  echo "checking to ensure wigle completed folder exists..."
  if [[ -d /opt/kismet/upload_complete ]]
  then 
    echo "wigle completed folder exists, continuing..."
  else 
    echo "wigle completed folder doesn't exist, creating..."
    sudo mkdir -p /opt/kismet/upload_complete
    chown ${USERNAME}:${GROUP} /opt/kismet/upload_complete
  fi
}

stop_kismet(){
  echo "stopping kismet to perform file upload..."
  kpid=`ps aux | grep kismet | grep -v grep | awk '{print $2}'`
  if [[ -z ${kpid+x} ]]
    then
      echo "unable to find kismet pid... is it even running?"
    else
      echo "killing Kismet pid ${kpid}"
      kill ${kpid}
  fi
}

start_kismet(){
  echo "starting kismet..."
  sudo -u ${USERNAME} /usr/bin/kismet -t ${WARDRIVE_NAME} --override wardrive --daemonize
  sleep 5
  kpid=`ps aux | grep kismet | grep -v grep | awk '{print $2}'`
  if [[ -z ${kpid+x} ]]
    then
      echo "unable to find kismet pid... did startup fail?"
    else
      echo "Kismet running as ${kpid}"
  fi
}

move_upload_file(){
  echo "getting file to upload..."
  file_list=`ls /opt/kismet/*.wiglecsv`
  if [[ $? != 0 ]]
  then
    echo "there doesn't appear to be any files to upload? Exiting!"
    exit 1
  else
    echo "found file(s) to upload: \n ${file_list}"
    start=`date +%s`
    path="/opt/kismet/upload_complete/wigle-`date +%d-%m-%-y_%H%M%S.tar.gz`"
    res=`time tar -cpzvf ${path} ${file_list}`
    echo ${path} > /opt/kismet/upload_complete/fileupload.txt
    end=`date +%s`
    runtime=$((end-start))
    echo "archive took ${runtime} seconds \n created at ${res}"
    echo ${res} > /opt/kismet/upload_to_wigle/upload.txt
  fi
}

upload_file_to_kismet(){
  fup=`cat /opt/kismet/upload_complete/fileupload.txt`
  if [[ -z ${fup+x} ]]
  then
    echo "I don't seem to have a file to upload..."
    exit 1
  else
    #todo: add error handling
    echo "uploading file to kismet"
    res=`curl -XPOST -F file=@${fup} -i -H 'Accept:application/json' -u ${AUTH_TOKEN} --basic https://api.wigle.net/api/v2/file/upload`
    echo ${res}
    echo ""
    echo "file uploaded! I think!"
  fi
}

cleanup_files(){
  echo "cleaning up files post-upload..."
  files=`cat /opt/kismet/cleanup.txt`
  mv ${files} /opt/kismet/uploaded/
}

test_net(){
  res=`timeout 1 ping -c1 8.8.8.8`
  if [[ $? != 0 ]]
  then
    echo "not connected to net, bailing out!"
    exit 1
  else
    res2=`timeout 1 curl -i -H 'Accept:application/json' -u ${AUTH_TOKEN} --basic https://api.wigle.net/api/v2/profile/user`
    if [[ ${res2} == 0 ]]
    then
      echo "connection test to wigle API success"
    fi
  fi
}

main(){
  #requires_user_root
  test_net
  if [[  "${DEBUG+x}"="True"  ]]
  then
    echo "DEBUG set, setting -x"
    set -x
  fi
  start=`date +%s`
  echo "starting Wigle upload at `date`"
  create_wigle_upload_folder
  create_wigle_upload_complete_folder
  stop_kismet
  move_upload_file
  start_kismet
  upload_file_to_kismet
  cleanup_files
  end=`date +%s`
  runtime=$((end-start))
  echo "whole process took ${runtime} seconds, nice." 
  exit 0
}

main
