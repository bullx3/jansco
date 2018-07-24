class Game < ApplicationRecord
	has_many :scores, dependent: :destroy
	belongs_to :section, counter_cache: true
end
