class User < ActiveRecord::Base
  acts_as_authentic do |c|
    c.log_in_after_create = false
  end

  def full_name
    if firstname.blank? && lastname.blank?
      return username
    else
      return "#{firstname} #{lastname}".strip
    end
  end
end