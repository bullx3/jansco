class Room::ConfigController < RoomController

	def index
	end #index

	def newPlayer
		@players = Player.where(group_id: session[:grp])

	end #newPlayer

	def createPlayer
		p_name = params[:playername]

		if p_name.blank?
		    redirect_to action: :notice , alert: sprintf('プレイヤー名が入力されていません')
		    return
		end

		if p_name.length > 8
		    redirect_to action: :notice , alert: sprintf('プレイヤー名が長すぎます')
			return
		end

		if Player.exists?(group_id: session[:grp], name: p_name)
		    redirect_to action: :notice , alert: sprintf('%sはすでに存在します', p_name)
		    return
		end

		player = Player.new
		player.name = p_name
		player.user_id = nil  #ユーザー
		player.group_id = session[:grp]

	    ActiveRecord::Base.transaction do
	    	player.save!
	    end # トランザクション終了

	    redirect_to action: :notice , notice: sprintf('プレイヤー%sを登録しました', p_name)
	end

	def notice
	    @notice = params[:notice]
		@alert = params[:alert]

		render '/room/notice'
	end #notice


end
