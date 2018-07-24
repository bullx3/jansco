class Log < ApplicationRecord
	belongs_to :section
	belongs_to :user


	def self.newLog(section_id, user_id, log_text)
		log = Log.new
		log.section_id = section_id.to_i
		log.user_id = user_id.to_i
		log.log = log_text

		return log
	end


end
