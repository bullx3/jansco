class Group < ApplicationRecord
	has_many :players
	has_many :users , through: :players
	has_many :sections
end
