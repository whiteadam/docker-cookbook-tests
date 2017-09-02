#!/bin/bash


ls -latr ~/.ssh

# Setup the SSH private key for Git clone operations
printf '%s\n' "$PRIVKEY" > ~/.ssh/id_rsa
chmod 0600 ~/.ssh/id_rsa

printf "$CR_SOURCE" | grep 'http' > /dev/null
if [ $? -ne 0 ] ; then
  # The source URL is not HTTP, assume SSH and grab the host/port to add the key to the known_hosts
  SOURCE_HOST=$(printf "$CR_SOURCE" | sed 's;\(\(ssh\)://\)*\(.*@\)*\([A-Za-z_\.0-9-]*\):*\([A-Za-z0-9]*\)*/\(.*\);\4;g')
  SOURCE_PORT=$(printf "$CR_SOURCE" | sed 's;\(\(ssh\)://\)*\(.*@\)*\([A-Za-z_\.0-9-]*\):*\([A-Za-z0-9]*\)*/\(.*\);-p \5;g')
  if [ "$SOURCE_PORT" == "-p " ] ; then
    ssh-keyscan -T60 $SOURCE_HOST >> ~/.ssh/known_hosts
  else
    ssh-keyscan -T60 $SOURCE_PORT $SOURCE_HOST >> ~/.ssh/known_hosts
  fi
fi

if [ -z $BUILD_DIR ] ; then
  printf "$CB_SOURCE" | grep 'http' > /dev/null
  if [ $? -ne 0 ] ; then
    # The source URL is not HTTP, assume SSH and grab the host/port to add the key to the known_hosts
    SOURCE_HOST=$(printf "$CB_SOURCE" | sed 's;\(\(ssh\)://\)*\(.*@\)*\([A-Za-z_\.0-9-]*\):*\([A-Za-z0-9]*\)*/\(.*\);\4;g')
    SOURCE_PORT=$(printf "$CB_SOURCE" | sed 's;\(\(ssh\)://\)*\(.*@\)*\([A-Za-z_\.0-9-]*\):*\([A-Za-z0-9]*\)*/\(.*\);-p \5;g')
    if [ "$SOURCE_PORT" == "-p " ] ; then
      ssh-keyscan -T60 $SOURCE_HOST >> ~/.ssh/known_hosts
    else
      ssh-keyscan -T60 $SOURCE_PORT $SOURCE_HOST >> ~/.ssh/known_hosts
    fi
  fi
fi

cd /chef
BR='master'
if [ ! -z $CR_BRANCH ] ; then
  BR="$CR_BRANCH"
fi
git archive --remote="${CR_SOURCE}" "$BR" | tar -xf -

if [ -z $BUILD_DIR ] ; then
  cd /chef/cookbook
  BR='master'
  if [ ! -z $CB_BRANCH ] ; then
    BR="$CB_BRANCH"
  fi
  git archive --remote="${CB_SOURCE}" "$BR" | tar -xf -
else
  rm -rf /chef/cookbook
  ln -s $BUILD_DIR /chef/cookbook 
fi

printf 'Running RuboCop...'
rubocop
COP_RET=$?
printf 'return value is %s\n' "$COP_RET"
if [ $COP_RET -ne 0 ] ; then
  exit $COP_RET
fi

printf 'Running FoodCritic...'
foodcritic .
printf 'return value is %s\n' "$FC_RET"
FC_RET=$?
if [ $FC_RET -ne 0 ] ; then
  exit $FC_RET
fi

printf 'Running ChefSpec...'
chef exec rspec
CS_RET=$?
printf 'return value is %s\n' "$CS_RET"
if [ $CS_RET -ne 0 ] ; then
  exit $CS_RET
fi

