class Player < ApplicationRecord
	has_many :section_players
	has_many :scores
	belongs_to :group
	belongs_to :user, optional: true

	module Permission
		GUEST  = 0
		NORMAL = 1
		ADMIN = 100
	end
end
