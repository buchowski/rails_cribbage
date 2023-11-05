class AppPresenter
  def initialize(user)
    @t = Proc.new do |key, data| Translations.en(key, data) end
    @user = user
  end

  def welcome_msg
    @t.call("welcome", {player_name: @user.name})
  end

  def is_show_admin_link
    ['development'].include? ENV['RAILS_ENV']
  end

  def is_show_log_out
    @user.is_anon? == false
  end

  def is_show_login_sign_up
    @user.is_anon? == true
  end
end
