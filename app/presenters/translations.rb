module Translations
  extend self

  def en(key, data)
    case key
    when "discarding.you"
      data[:card_count] == 1 ? "Select one card to discard" : "Select two cards to discard"
    when "discarding.opponent"
      "Waiting for opponent to discard"
    when "playing.you"
      "Select a card to play"
    when "playing.opponent"
      "Waiting for opponent to play a card"
    when "you.scored"
      "You scored #{data[:points]} points!"
    when "opponent.scored"
      "Your opponent scored #{data[:points]} points."
    when "you.won"
      "You won the game!"
    when "opponent.won"
      "Your opponent won the game."
    when "game.over"
      "Game over"
    else
      # todo only throw in dev env
      throw "no translation key #{key}"
    end
  end
end
