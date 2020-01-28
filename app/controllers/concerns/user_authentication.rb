module UserAuthentication
    extend ActiveSupport::Concern
  
    included do
      helper_method :current_user, :current_session, :logged_in?
    end
  
    def current_session
      return @current_session if defined?(@current_session)
      @current_session = UserSession.find
    end
  
    def current_user
      return @current_user if defined?(@current_user)
      @current_user = current_session && current_session.record
    end
  
    def logged_in?
      current_user
    end
  end