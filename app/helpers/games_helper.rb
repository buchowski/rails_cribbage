require "card_svg_dimensions"

module GamesHelper
  def card_svg_dimensions(card_id)
    card = CardSvgDimensions[card_id]

    throw "could not find card" if card.nil?

    card
  end
end
