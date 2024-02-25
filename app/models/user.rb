class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
          :recoverable, :rememberable, :validatable,
          :confirmable, :lockable, :trackable
  validates :name, presence: true, length: { minimum: 3, maximum: 16 }
  has_many :games, foreign_key: :player_one_id

  def is_anon?
    false
  end

  def is_member(game_model)
    return false if game_model.nil?
    is_player_one = self.id == game_model.player_one_id
    is_player_two = self.id == game_model.player_two_id

    is_player_one || is_player_two
  end

  def is_creator(game_model)
    return false if game_model.nil?

    self.id == game_model.player_one_id
  end

  def is_dealer(game_model)
    return false if game_model.nil?

    self.id == game_model.dealer_id
  end
end
