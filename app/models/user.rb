class User < ApplicationRecord
  validates :name, presence: true
  has_many :games, foreign_key: :player_one_id

  def is_anon?
    false
  end
end
