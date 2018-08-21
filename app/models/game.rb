class Game < ApplicationRecord
	has_many :scores, dependent: :destroy
	belongs_to :section, counter_cache: true

	module Kind
		M4 = 0  # 四麻
		M3 = 1  # 三麻
		CHIP = 2 # チップ
	end

	module Scorekind
		GAME = 0 # 半荘・東風戦
		CHIP = 1 # チップ
	end

end
