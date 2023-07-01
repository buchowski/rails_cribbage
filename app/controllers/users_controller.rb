class UsersController < ApplicationController

  def new
  end

  def create
    if !are_passwords_valid(params)
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
    user = User.find_by_email(params[:email])

    if user.nil?
      flash[:error_msg] = "Sorry, we can't find user \"#{params[:email]}\""
      redirect_to login_path
      return
    end

    if !does_password_match(user, params[:password])
      flash[:error_msg] = "Sorry, that's not the correct password"
      redirect_back(fallback_location: root_path)
      return
    end


    session[:user_id] = user.id
    redirect_to games_path
  end

  def admin_login
    user = User.find(params[:user_id])
    session[:user_id] = user.id
    redirect_to games_path
  end

  def logout
    session.delete(:user_id)
    flash[:error_msg] = "You have been logged out"
    redirect_to login_path
  end

  private

  def are_passwords_valid(params)
    return true if params[:password].empty? && params[:password_confirm].empty?

    # TODO add length requirement
    params[:password] == params[:password_confirm]
  end

  def does_password_match(user, password)
    return false if user.nil? || password.empty?
    BCrypt::Password.new(user.password_digest) == password
  end
end
