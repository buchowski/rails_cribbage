module Translations
  extend self

  def en(key, data)
    case key
    when "playing.you"
      "Select a card to play"
    when "playing.opponent"
      "Waiting for opponent to play a card"
    when "you.scored"
      "You scored #{data[:points]} points!"
    when "opponent.scored"
      "Your opponent scored #{data[:points]} points."
    else
      # todo only throw in dev env
      throw "no translation key #{key}"
    end
  end
end
