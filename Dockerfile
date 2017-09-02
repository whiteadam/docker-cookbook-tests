# TODO: Use specific version instead of latest
FROM chef/chefdk:latest

RUN apt-get update && apt-get install -y git-core
RUN mkdir -p /chef/foodcritic
RUN mkdir -p /chef/cookbook

RUN mkdir -p /root/.chef
COPY knife.rb /root/.chef/knife.rb
RUN chmod 0644 /root/.chef/knife.rb

RUN git clone https://github.com/customink-webops/foodcritic-rules.git /chef/foodcritic/customink
RUN git clone https://github.com/etsy/foodcritic-rules.git /chef/foodcritic/etsy
RUN git clone https://github.com/sous-chefs/sc-foodcritic-rules.git /chef/foodcritic/sous-chefs

RUN test -d ~/.ssh || mkdir ~/.ssh && chmod 0700 ~/.ssh
RUN ssh-keyscan -T60 bitbucket.org >> ~/.ssh/known_hosts
RUN ssh-keyscan -T60 github.com >> ~/.ssh/known_hosts

COPY validate-cookbook.sh /chef/validate-cookbook.sh
RUN chmod 0555 /chef/validate-cookbook.sh

CMD cd /chef && ./validate-cookbook.sh
