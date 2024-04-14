class BotUser < User
  # include UserConcern

  def name
    "Spookey-bot"
  end

  def id
    # TODO 4 is a hack since the bot is still coupled to the DB
    4
  end

  def is_bot
    true
  end

  def is_admin?
    false
  end

end
