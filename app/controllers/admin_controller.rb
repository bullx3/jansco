class AdminController < ApplicationController
	before_action :check_admin, except: [:notice]

	def index

	end

	def newUser
		@users = User.all
	end #newUser

	def createUser
		username = params[:username]
		password = params[:password]

		alert = User.check_params(username, password)
		if alert
			redirect_to action: :notice, alert: alert
			return
		end

		if User.exists?(username: username)
			redirect_to action: :notice, alert: '同名のユーザーがいます'
  			return
		end


		user = User.new
		user.username = username
		user.password = User.createPassword(username, password)
		user.permission = User::Permission::NORMAL

		ActiveRecord::Base.transaction do
			user.save!
		end # トランザクション終了

		redirect_to action: :notice, notice: sprintf('ユーザー%sを登録しました',username)
	end

	def editUser
		@users = User.all

	end #editUser

	def updateUser
		user_id = params[:select][:id]
		password = params[:password]

		user = User.find(user_id)

		alert = User.check_params(user.username, password)
		if alert
			redirect_to action: :notice, alert: alert
			return
		end

		newPassword = User.createPassword(user.username, password)
		ActiveRecord::Base.transaction do
			user.update({password: newPassword})
		end # トランザクション終了

		redirect_to action: :notice, notice: sprintf('ユーザー%sのパスワードを変更しました',user.username)

		#パスワードの更新
	end #updateUser

	def destroyUser
		#playersから関連づけを削除
	end #destroyUser

	def newGroup
		@users = User.all
		@groups = Group.all
	end #end

	def createGroup
		user_id = params[:select][:username]
		group_idname = params[:idname]
		group_name = params[:name]
		player_name = params[:playername]
		user_name = params[:guest_user_name]
		user_paswd = params[:guest_user_pass]

		if user_id.blank? || group_idname.blank? || group_name.blank? || player_name.blank?
  			redirect_to action: :notice, alert: '入力値がありません'
  			return
		end

		unless User.exists?(id: user_id.to_i)
  			redirect_to action: :notice, alert: '不正なユーザ選択です'
  			return
		end

		gidname_pattern = '^[a-zA-Z0-9_]{4,12}$'
		gname_pattern = '^[.]{4,20}$'
		pname_pattern = '^[.]{1,8}$'

		if group_idname.match(gidname_pattern).nil?
  			redirect_to action: :notice, alert: '不正なグループID名入力値です'
  			return
		end

		if group_name.length < 4 || group_name.length > 20
  			redirect_to action: :notice, alert: '不正なグループ名入力値です'
  			return
		end

		if player_name.length < 1 || player_name.length > 8
  			redirect_to action: :notice, alert: '不正なプレイヤー名入力値です'
  			return
		end

		#同名のidnameとnameは不許可とする
		g = Group.where('idname = ? OR name = ?', group_idname, group_name).limit(1)
		if g.length > 0
  			redirect_to action: :notice, alert: '同名のグループID名かグループ名があります'
  			return
		end

		alert = User.check_params(user_name, user_paswd)
		if alert
			redirect_to action: :notice, alert: alert
			return
		end

		if User.exists?(username: user_name)
			redirect_to action: :notice, alert: '同名のユーザーがいます'
			return
		end



		# userとplayerをかならず関連づけさせる
		ActiveRecord::Base.transaction do
			group = Group.new
			group.idname = group_idname
			group.name = group_name
			group.save!

			player = Player.new
			player.name = player_name
			player.user_id = user_id.to_i
			player.group_id = group.id
			player.permission = Player::Permission::ADMIN # 作成者は管理者権限を与える
			player.provisional = false
			player.save!

			# ゲストユーザーとゲストプレイヤーを追加する
			guest_user = User.new
			guest_user.username = user_name
			guest_user.password = User.createPassword(username, password)
			guest_user.permission = User::Permission::GUEST
			guest_user.save!

			guest_player = Player.new
			guest_player.user_id = guest_user.id
			guest_player.group_id = group.id
			guest_player.name = group_idname.slice(0,3) + 'guest'
			guest_player.permission = Player::Permission::GUEST
			guest_player.provisional = true #ここでフラグを立てておくとプレイヤー一覧に表示されない
			guest_player.save!


		end # トランザクション終了

		redirect_to action: :notice, notice: sprintf('グループ%sを登録しました',group_idname)

	end

	def editGroup
	end 

	def updateGroup
		# userとplayerをかならず関連づけさせる
		#同名のidnameとnameは不許可とする
	end

	def destroyGroup
		#関連するプレイヤーを消す
	end

	def newPlayer
		@groups = Group.all
		@users = User.all
		@players = Player.all

	end #mewPlayer

	def createPlayer
		group_id = params[:group][:id]
		player_name = params[:playername]
		user_id = params[:user][:id]

		#group指定は必須。userは任意
		if group_id.blank? || player_name.blank?
  			redirect_to action: :notice, alert: 'グループが選択されていないかプレイヤー名が入力されていません'
  			return
		end

		if player_name.length < 1 || player_name.length > 8
  			redirect_to action: :notice, alert: '不正なプレイヤー名入力値です'
  			return
		end

		ActiveRecord::Base.transaction do
			player = Player.new
			player.name = player_name
			player.group_id = group_id.to_i
			player.user_id = user_id.blank? ? nil : user_id.to_i

			player.save!
		end # トランザクション終了

		redirect_to action: :notice, notice: sprintf('プレイヤー%sを登録しました',player_name)
	end

	def editPlayer
		#group指定は必須。userは任意だが引き継ぎ
	end

	def updatePlayer
		#group指定は必須。userは任意だが引き継ぎ
	end

	def destroyPlayer
		#
	end


	def notice
	  	@notice = params[:notice]
	  	@alert = params[:alert]
	end #notice

private
	def check_admin
	  	user_id = session[:usr]
	  	# ApplicationControllerでチェックしている為、存在しないことはないはず
  		usr = User.find(user_id)
  		if usr.username != 'admin'
  			#ユーザーがadmin以外はいれない
  			redirect_to controller: :admin, action: :notice, alert: 'Access denied'
  			return
  		end
	end

end
