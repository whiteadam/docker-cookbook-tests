#!/bin/bash


# Setup the SSH private key for Git clone operations
if [ ! -z "$PRIVKEY" ] ; then
  printf 'Adding private key from $PRIVKEY\n'
  printf '%s\n' "$PRIVKEY" > ~/.ssh/id_rsa
  chmod 0600 ~/.ssh/id_rsa
fi

if [ ! -z "$SSH_HOSTS" ] ; then
  for ok_host in $(printf "$SSH_HOSTS") ; do 
    printf "Host $ok_host\n\tStrictHostKeyChecking no\n" >> ~/.ssh/config
  done
fi

# Set a default if the environment value is not specified
cd /chef
BR="${CR_BRANCH:-master}"
printf 'Checking out the chef-repo code from %s@%s\n' "$CR_SOURCE" "$BR"
git archive --remote="${CR_SOURCE}" "$BR" | tar -xf -

cd /chef/cookbook
BR="${CB_BRANCH:-master}"
printf 'Checking out the cookbook code from %s@%s\n' "$CB_SOURCE" "$BR"
git archive --remote="${CB_SOURCE}" "$BR" | tar -xf -

printf 'Running RuboCop...' ; rubocop ; COP_RET=$?
printf 'Running FoodCritic...' ; foodcritic . ; FC_RET=$?
printf 'Running ChefSpec...' ; chef exec rspec ; CS_RET=$?

if [[ $CP_RET -ne 0 || $FC_RET -ne 0 || $CS_RET -ne 0 ]] ; then
  printf 'Detected one or more failures, returning non-zero result\n'
  printf 'RuboCop = %s; FoodCritic = %s ; ChefSpec = %s\n' "$COP_RET" "$FC_RET" "$CS_RET"
  exit 1
fi

