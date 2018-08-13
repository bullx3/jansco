class User < ApplicationRecord
	has_many :players
	has_many :groups, through: :players
	has_many :comments
	has_many :logs

	module Permission
		GUEST  = 0
		NORMAL = 1
		ADMIN = 100
	end


	def self.authenticate(username, password)
		usr = find_by(username: username)
		if usr != nil && usr.password == createPassword(username, password)
			return usr
		else
			return
		end
	end

	def self.createPassword(username, password)
		hexdigest = Digest::SHA256.hexdigest([username, 'jan' , password].join(':'))
		logger.debug(hexdigest)
		return hexdigest

	end

	def self.check_params(username, password)

		if username.blank? || password.blank?
			
  			return '入力値がありません'
		end

		u_pattern = '^[a-zA-Z0-9_.]{3,12}$'
		p_pattern = '^[a-zA-Z0-9]{4,12}$'

		if username.match(u_pattern).nil?
  			return '不正なユーザー名入力値です'
		end

		if password.match(p_pattern).nil?
  			return '不正なパスワード入力値です'
		end


		return nil
	end

end
