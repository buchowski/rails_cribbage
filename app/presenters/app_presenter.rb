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
end
