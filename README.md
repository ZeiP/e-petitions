# Partiolaisaloite

* You will need `ruby 2.3.0`
* You will need PostgreSQL and Memcached

## Set up your development environment (without docker)

* Clone the repo to your local machine
* Install postgres. Easiest with homebrew using `brew install postgres`
	* If you like you can add postgres to your LaunchAgent. Follow instructions at end of console output
* Set up your dev and test databases
	* `$ psql postgres`
	* `# CREATE USER epets;`
	* `# GRANT all privileges ON database epets_development TO epets;`
	* `# GRANT all privileges ON database epets_test TO epets;`
	* `# ALTER USER epets WITH PASSWORD 'replace_me';`
	* `# \q` to quit
* You will need to set up the `config/database.yml`. Set the password you used earlier for the `epets` postgres user
* Run `$ bin/setup` - installs bundler, bundles, and sets up your dev/test databases

## Set up your development environment (with docker)

* Clone the repo to your local machine
* Install and configure Docker and Docker-compose
* remove `-d` from the `bundle exec rails s` line in the run_rails.sh file if it's there
* run `docker-compose -f docker-compose.dev.yml up`

## Run the app

* `rails s`

## Other info

## Running tests inside docker container
* First enter the container `docker-compose -f docker-compose.dev.yml exec app bash`
* Then run `RAILS_ENV=test DATABASE_CLEANER_ALLOW_REMOTE_DATABASE_URL=true bundle exec rspec spec/`

* If you want jobs (like emails) to be run, use `$ rake jobs:work`
* For setting up a sysadmin user
	* `rake epets:add_sysadmin_user` - to set up an admin user with email 'admin@example.com' and password 'Letmein1!'
	* go to `/admin` and log in. You will be asked to change your password. Remember, the password must contain a mix of upper and lower case letters, numbers and special characters.

## Authentication

* Partiolaisaloite is currnently integrated to PartioID SAML authentication
* For development purposes, either plug in another SAML IdP or use hard-coded sign_in logic
