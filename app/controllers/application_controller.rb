class ApplicationController < ActionController::Base
  before_action :get_user

  def get_user
    if ENV["RAILS_ENV"] == "test"
      @user = current_user || AnonUser.new
    else
      @user = AnonUser.new
    end
    @app = AppPresenter.new(@user)
  end
end
