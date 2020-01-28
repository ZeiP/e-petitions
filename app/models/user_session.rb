class UserSession < Authlogic::Session::Base
  before_save do
    record.reset_persistence_token!
  end

  before_destroy do
    if stale?
      stale_record.reset_persistence_token!
    else
      record.reset_persistence_token!
    end
  end
end