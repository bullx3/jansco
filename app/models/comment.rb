class Comment < ApplicationRecord
	belongs_to :section
	belongs_to :player
end
