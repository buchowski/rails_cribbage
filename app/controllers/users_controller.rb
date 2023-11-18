class UsersController < ApplicationController

  def new
  end

  def create
    password = params[:password] || ""
    password_confirm = params[:password_confirm] || ""

    if !are_passwords_valid(password, password_confirm)
      flash[:error_msg] = "Sorry, your passwords do not match"
      flash[:name] = params[:name]
      flash[:email] = params[:email]
      redirect_back(fallback_location: root_path)
      return
    end

    user = User.new(name: params[:name], email: params[:email])

    if !password.empty?
      user.password_digest = BCrypt::Password.create(password)
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

  def are_passwords_valid(password, password_confirm)
    return true if password.blank? && password_confirm.blank?
    return false unless password == password_confirm
    password.length >= 5 && password.length <= 16
  end

  def does_password_match(user, password)
    return false if user.nil? || password.empty?
    BCrypt::Password.new(user.password_digest) == password
  end
end
