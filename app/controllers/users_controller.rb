class UsersController < ApplicationController
  def new
  end

  def create
    user = User.new(name: params[:name], email: params[:email])

    if user.save!
      session[:user_id] = user.id
      redirect_to games_path
    else
      flash[:error_msg] = "Sorry, we weren't able to create a user for you"
    end
  end
end
