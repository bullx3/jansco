class Section < ApplicationRecord
	has_many :games, dependent: :destroy
	has_many :section_players, dependent: :destroy
	has_many :comments
	has_many :logs
	belongs_to :group

	#statusカラム値
	module Status
		FINISHED = 0
		PLAYING = 1
	end

	module Gamekind
		M4 = 0  # 四麻
		M3 = 1  # 三麻
	end

	GameKindString = ['四麻', '三麻']
end
