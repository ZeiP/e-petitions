require 'knapsack'
require 'database_cleaner'
require 'email_spec'
require 'shoulda-matchers'
require 'factory_bot_rails'

if ENV['COVERAGE'] == 'true'
  require 'simplecov'
  SimpleCov.start 'rails'
end

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.filter_run :focus
  config.run_all_when_everything_filtered = true
  config.disable_monkey_patching!

  if config.files_to_run.one?
    config.default_formatter = 'doc'
  end

  config.order = :random

  Kernel.srand config.seed
end

Knapsack::Adapters::RspecAdapter.bind