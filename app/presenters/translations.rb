module Translations
  extend self

  def en(key, data)
    points = data && data[:points]
    player_name = data && data[:player_name]
    opponent_name = data && data[:opponent_name]

    case key
    when "welcome"
      "Welcome #{player_name}"
    when "discarding.you"
      data[:card_count] == 1 ? "Select one card to discard" : "Select two cards to discard"
    when "discarding.opponent"
      "Waiting for #{opponent_name} to discard"
    when "playing.you"
      "Select a card to play"
    when "playing.opponent"
      "Waiting for #{opponent_name} to play a card"
    when "you.scored"
      "You scored #{points} points!"
    when "opponent.scored"
      "#{opponent_name} scored #{points} points."
    when "you.won"
      "You won the game!"
    when "opponent.won"
      "#{opponent_name} won the game."
    when "game.over"
      "Game over"
    when "you_have_n_points"
      points == 1 ? "You: 1 pt" : "You: #{points} pts"
    when "player_has_n_points"
      points == 1 ? "#{player_name}: 1 pt" : "#{player_name}: #{points} pts"
    when "your_crib"
      "This is your crib"
    when "player_crib"
      "This is #{player_name}'s crib"
    else
      # todo only raise in dev env
      raise "no translation key #{key}"
    end
  end
end
