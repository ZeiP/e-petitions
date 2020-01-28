class User < ActiveRecord::Base
  acts_as_authentic do |c|
    c.log_in_after_create = false
  end
end