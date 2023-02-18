module Translations
  extend self

  def en(key, data)
    points = data && data[:points]

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
      "You scored #{points} points!"
    when "opponent.scored"
      "Your opponent scored #{points} points."
    when "you.won"
      "You won the game!"
    when "opponent.won"
      "Your opponent won the game."
    when "game.over"
      "Game over"
    when "you_have_n_points"
      points == 1 ? "You have one point" : "You have #{points} points"
    when "opponent_has_n_points"
      points == 1 ? "Your opponent has one point" : "Your opponent has #{points} points"
    else
      # todo only throw in dev env
      throw "no translation key #{key}"
    end
  end
end
