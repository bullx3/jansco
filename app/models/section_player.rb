class SectionPlayer < ApplicationRecord
	belongs_to :section, counter_cache: true
	belongs_to :player
end
