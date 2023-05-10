class User < ApplicationRecord
  validates :name, presence: true
  has_many :games, foreign_key: :player_one_id
end
