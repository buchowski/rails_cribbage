class ApplicationController < ActionController::Base
  before_action :get_user

  def get_user
    @user = User.find_by_id(session[:user_id]) || AnonUser.new
    @app = AppPresenter.new(@user)
  end
end
