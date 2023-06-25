class AppPresenter
  def initialize(user)
    @t = Proc.new do |key, data| Translations.en(key, data) end
    @user = user
  end

  def welcome_msg
    @t.call("welcome", {player_name: @user.name})
  end
end
