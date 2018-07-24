class Section < ApplicationRecord
	has_many :games, dependent: :destroy
	has_many :section_players, dependent: :destroy
	has_many :comments, dependent: :destroy
	has_many :logs, dependent: :destroy
	belongs_to :group

	#statusカラム値
	module Status
		FINISHED = 0
		PLAYING = 1
	end
end
