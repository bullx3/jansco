class Game < ApplicationRecord
	has_many :scores, dependent: :destroy
	belongs_to :section, counter_cache: true

	module Kind
		M4 = 0  # 四麻
		M3 = 1  # 三麻
		CHIP = 2 # チップ
	end

end
