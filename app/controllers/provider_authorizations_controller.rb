class ProviderAuthorizationsController < ApplicationController

  # change the /auth/:provider/callback route to point to this if you want to examine the rack data returned by omniauth
  def auth_callback_test
    render(:text=>request.env['rack.auth'].to_yaml)
  end

  def create
    auth_info = request.env['rack.auth']
    existing_authorization = ProviderAuthorization.find_from_omniauth(auth_info)
    if existing_authorization.nil?  # first time logging in with this provider + provider uid combo
      if current_user # if logged in, link provider to existing inat user
        current_user.provider_authorizations.create({
          :provider_name => auth_info['provider'], 
          :provider_uid => auth_info['uid'], 
          :token => (auth_info["credentials"]["token"] || auto_info["credentials"]["secret"])
        }) 
        flash[:notice] = "You've successfully linked your #{auth_info['provider'].capitalize} account."
      else # create a new inat user and link provider to that user
        logout_keeping_session!
        self.current_user = User.create_from_omniauth(auth_info)
        handle_remember_cookie! true # set 'remember me' to true
        flash[:notice] = "Welcome back!"
      end
    else # existing provider + inat user, so log him in
      self.current_user = existing_authorization.user
      handle_remember_cookie! true # set 'remember me' to true
      flash[:notice] = "Welcome back!"
    end
    if session[:return_to]
      redirect_to session[:return_to]
    else
      redirect_back_or_default('/')
    end
  end

end