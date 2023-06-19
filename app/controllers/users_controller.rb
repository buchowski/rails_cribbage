class UsersController < ApplicationController

  def new
  end

  def create
    if !passwords_valid?(params)
      flash[:error_msg] = "Sorry, your passwords do not match"
      redirect_back(fallback_location: root_path)
      return
    end

    user = User.new(name: params[:name], email: params[:email])

    if !params[:password].empty?
      user.password_digest = BCrypt::Password.create(params[:password])
    end

    if user.save!
      session[:user_id] = user.id
      redirect_to games_path
    else
      flash[:error_msg] = "Sorry, we weren't able to create a user for you"
    end
  end

  def login
    user = User.find(params[:user_id])
    session[:user_id] = user.id
    redirect_to games_path
  end

  private

  def passwords_valid?(params)
    return true if params[:password].empty? && params[:password_confirm].empty?

    # TODO add length requirement
    params[:password] == params[:password_confirm]
  end
end
