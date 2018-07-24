class Player < ApplicationRecord
	has_many :section_players
	has_many :scores
	belongs_to :group
	belongs_to :user, optional: true
end
