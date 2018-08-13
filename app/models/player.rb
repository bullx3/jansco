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

	def self.check_params(player_name)
		if player_name.length < 1 || player_name.length > 8
			return '不正なプレイヤー名入力値です'
		end
		
		return nil
	end

end
