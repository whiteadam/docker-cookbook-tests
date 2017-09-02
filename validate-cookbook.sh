#!/bin/bash


# Setup the SSH private key for Git clone operations
printf '%s\n' "$PRIVKEY" > ~/.ssh/id_rsa
chmod 0600 ~/.ssh/id_rsa

SOURCE_HOST=$(printf "$CB_SOURCE" | sed 's;\(https\|ssh\)://\(.*@\)*\([A-Za-z_\.0-9-]*\)/.*;\3;g')
ssh-keyscan -T60 $SOURCE_HOST >> ~/.ssh/known_hosts

cd /chef
BR='master'
if [ ! -z $CR_BRANCH ] ; then
  BR="$CR_BRANCH"
fi
git archive --remote="${CR_SOURCE}" "$BR" | tar -xf -

cd /chef/cookbook
BR='master'
if [ ! -z $CB_BRANCH ] ; then
  BR="$CB_BRANCH"
fi
git archive --remote="${CB_SOURCE}" "$BR" | tar -xf -

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

