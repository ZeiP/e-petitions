#!/bin/bash
#source /etc/profile.d/rvm.sh

cd /app

if [ -f tmp/pids/server.pid ]; then
	echo "Server did not shutdown cleanly, removing existing pid-file..."
	rm -f tmp/pids/server.pid
fi

echo "RAILS_ENV=$RAILS_ENV"

bin/rake db:exists && bin/rake db:migrate || bin/rake db:setup

echo "Installing bundle..."
bundle check || bundle install

bundle exec rails s -p 3000 -b '0.0.0.0'