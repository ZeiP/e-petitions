source 'https://rubygems.org'

# Load environment variables
gem 'dotenv-rails', :require => 'dotenv/rails-now'

gem 'rails', '5.2.3'

gem 'mimemagic', github: 'mimemagicrb/mimemagic', ref: '01f92d86d15d85cfd0f20dabd025dcbd36a8a60f'

gem 'rake'
gem 'pg'
gem 'authlogic'
gem 'will_paginate'
gem 'json'
gem 'delayed_job_active_record'
gem 'whenever'
gem 'appsignal'
gem 'dynamic_form'
gem 'faraday'
gem 'faraday_middleware'
gem 'net-http-persistent'
gem 'sass-rails', '~> 5.0'
gem 'textacular'
gem 'uglifier'
gem 'bcrypt'
gem 'faker'
gem 'slack-notifier'
gem 'daemons'
gem 'jquery-rails'
gem 'delayed-web'
gem 'dalli', '2.7.6'
gem 'ruby-saml', '~> 1.9.0'
gem 'connection_pool'
gem 'lograge'
gem 'logstash-logger'
gem 'jbuilder'
gem 'paperclip'
gem 'maxminddb'
gem 'redcarpet'
gem 'rollbar'

gem 'aws-sdk-codedeploy'
gem 'aws-sdk-cloudwatchlogs'
gem 'aws-sdk-s3'

group :development, :test do
  gem 'simplecov'
  gem 'brakeman', require: false
  gem 'bundler-audit', require: false
  gem 'rspec-rails'
  gem 'jasmine-rails'
  gem 'pry'
  gem 'byebug'
end

group :test do
  gem 'knapsack'
  gem 'nokogiri'
  gem 'shoulda-matchers', '4.0.1'
  gem 'pickle'
  gem 'cucumber', '~> 2.4.0'
  gem 'cucumber-rails', require: false
  gem 'database_cleaner', git: 'https://github.com/DatabaseCleaner/database_cleaner'
  gem 'capybara', '~> 3.13.2'
  gem 'factory_bot_rails'
  gem 'email_spec'
  gem 'launchy'
  gem 'webdrivers', '~> 3.8.1'
  gem 'webmock'
  gem 'rails-controller-testing'
end

group :production do
  gem 'puma'
end
