class Room::PlayerscoredController < RoomController

	def index
	end

	def scored
		@players = Player.where(group_id: session[:grp], provisional: false)
		@player_id = nil
		@checkedStart = false
		@checkedEnd = false
		@date_start = nil
		@date_end = nil
		@g_idname = params[:g_idname]

		unless params.has_key?(:player)
			return
		end

		if params[:date_check][:start] == "1"
			@checkedStart = true
		end

		if params.has_key?(:date) && params[:date].has_key?(:start)
			@date_start = params[:date][:start]
		end

		if params[:date_check][:end] == "1"
			@checkedEnd = true
		end

		if params.has_key?(:date) && params[:date].has_key?(:end)
			@date_end = params[:date][:end]
		end

		p_id = params[:player][:id]

		if p_id.blank?
			return
		end

		@player_id = p_id.to_i
		player = Player.find(@player_id)
		@player_name = player.name

#		sections = Section.includes(games: [scores: [:player]]).where(status: Section::Status::FINISHED,  group_id: session[:grp].to_i)
		sections = Section.includes(games: [:scores]).where(status: Section::Status::FINISHED,  group_id: session[:grp].to_i)
		sections = sections.where(games:  {scores: {player_id: @player_id}})

		if @checkedStart && !(@date_start.nil?)
			start_time_widh_zone = @date_start.in_time_zone
			start_time_widh_zone += 12.hours
			sections = sections.where('finished_at >= ?', start_time_widh_zone)
		end

		if @checkedEnd && !(@date_end.nil?)
			end_time_widh_zone = @date_end.in_time_zone
			end_time_widh_zone += 36.hours
			sections = sections.where('finished_at < ?', end_time_widh_zone)
		end


#		sections.each {|section|
#			section.games.each { |game|
#				@txt = "game:#{game.id} "
#				game.scores.each{|score|
#					@txt += "#{score.player.name}:#{score.score} "
#				}
#				logger.debug(@txt)
#			}
#		}

		game_ids = sections.pluck("games.id")
		m4_games = sections.where(gamekind: Section::Gamekind::M4)
		m4_game_ids = m4_games.where(games: {scorekind: Game::Scorekind::GAME}).pluck("games.id")
		m4_chip_ids = m4_games.where(games: {scorekind: Game::Scorekind::CHIP}).pluck("games.id")

		m3_games = sections.where(gamekind: Section::Gamekind::M3)
		m3_game_ids = m3_games.where(games: {scorekind: Game::Scorekind::GAME}).pluck("games.id")
		m3_chip_ids = m3_games.where(games: {scorekind: Game::Scorekind::CHIP}).pluck("games.id")

		logger.debug(game_ids)
		logger.debug(m4_game_ids)
		logger.debug(m4_chip_ids)
		logger.debug(m3_game_ids)
		logger.debug(m3_chip_ids)


		@m4_score = Score.where(game_id: m4_game_ids, player_id: @player_id).sum(:score)
		@m3_score = Score.where(game_id: m3_game_ids, player_id: @player_id).sum(:score)
		@m4_chip_score = Score.where(game_id: m4_chip_ids, player_id: @player_id).sum(:score)
		@m3_chip_score = Score.where(game_id: m3_chip_ids, player_id: @player_id).sum(:score)
		@m4_total = @m4_score + @m4_chip_score
		@m3_total = @m3_score + @m3_chip_score


		@m4_games = Game.includes(scores: [:player]).where(id: m4_game_ids).order(created_at: :desc).order("scores.score desc")
#		@m4_games.each { |game|
#			@txt = "game:#{game.id} "
#			game.scores.each{|score|
#				@txt += "#{score.player.name}:#{score.score} "
#			}
#			logger.debug(@txt)
#		}

		@m4_ranks = [0,0,0,0]
		setRankCount(@m4_ranks, @m4_games, @player_id)

		@m3_games = Game.includes(scores: [:player]).where(id: m3_game_ids).order(created_at: :desc).order("scores.score desc")
#		@m3_games.each { |game|
#			@txt = "game:#{game.id} "
#			game.scores.each{|score|
#				@txt += "#{score.player.name}:#{score.score} "
#			}
#			logger.debug(@txt)
#		}

		@m3_ranks = [0,0,0]
		setRankCount(@m3_ranks, @m3_games, @player_id)
		

	end

	def scoredvs
		@players = Player.where(group_id: session[:grp], provisional: false)
		@player_results = [{id: nil}, {id: nil},{id: nil},{id: nil}]
		@checkedStart = false
		@checkedEnd = false
		@date_start = nil
		@date_end = nil
		@g_idname = params[:g_idname]

		unless params.has_key?(:player)
			return
		end

		if params[:date_check][:start] == "1"
			@checkedStart = true
		end

		if params.has_key?(:date) && params[:date].has_key?(:start)
			@date_start = params[:date][:start]
		end

		if params[:date_check][:end] == "1"
			@checkedEnd = true
		end

		if params.has_key?(:date) && params[:date].has_key?(:end)
			@date_end = params[:date][:end]
		end

		@player_results.length.times {|player_no|
			p_id = params[:player]["id#{player_no}"]
			unless p_id.blank?
				@player_results[player_no] = {}
				@player_results[player_no][:id] = p_id.to_i
				player = Player.find(@player_results[player_no][:id])
				@player_results[player_no][:name] = player.name
			end
		}

		@select_flag = false
		@player_results.each { |p_result|
			unless p_result[:id].nil?
				@select_flag = true
				break
			end
		}
		unless @select_flag
			# 一つも選択がなければ処理を終える
			return
		end

		@player_results.each { |p_result|
			if p_result[:id].nil?
				next
			end

			sections = Section.includes(games: [:scores]).where(status: Section::Status::FINISHED,  group_id: session[:grp].to_i)
			sections = sections.where(games:  {scores: {player_id: p_result[:id]}})

			if @checkedStart && !(@date_start.nil?)
				start_time_widh_zone = @date_start.in_time_zone
				start_time_widh_zone += 12.hours
				sections = sections.where('finished_at >= ?', start_time_widh_zone)
			end

			if @checkedEnd && !(@date_end.nil?)
				end_time_widh_zone = @date_end.in_time_zone
				end_time_widh_zone += 36.hours
				sections = sections.where('finished_at < ?', end_time_widh_zone)
			end

			p_result[:game_ids] = sections.pluck("games.id")
			p_result[:m4_game_ids] = sections.where(gamekind: Section::Gamekind::M4, games: {scorekind: Game::Scorekind::GAME}).pluck("games.id")
			p_result[:m4_chip_ids] = sections.where(gamekind: Section::Gamekind::M4, games: {scorekind: Game::Scorekind::CHIP}).pluck("games.id")
			p_result[:m3_game_ids] = sections.where(gamekind: Section::Gamekind::M3, games: {scorekind: Game::Scorekind::GAME}).pluck("games.id")
			p_result[:m3_chip_ids] = sections.where(gamekind: Section::Gamekind::M3, games: {scorekind: Game::Scorekind::CHIP}).pluck("games.id")

			logger.debug(p_result[:game_ids])
			logger.debug(p_result[:m4_game_ids])
			logger.debug(p_result[:m4_chip_ids])
			logger.debug(p_result[:m3_game_ids])
			logger.debug(p_result[:m3_chip_ids])

		}


		initflag = true
		game_ids = []
		m4_game_ids = []
		m3_game_ids = []
		m4_chip_ids = []
		m3_chip_ids = []
		chip_game_ids  = []

		@player_results.each {|p_result| 

			if p_result[:id].nil?
				next
			end

			if initflag
				game_ids = p_result[:game_ids].deep_dup
				m4_game_ids = p_result[:m4_game_ids].deep_dup
				m3_game_ids = p_result[:m3_game_ids].deep_dup
				m4_chip_ids = p_result[:m4_chip_ids].deep_dup
				m3_chip_ids = p_result[:m3_chip_ids].deep_dup
				initflag = false
			else
				game_ids &= p_result[:game_ids]
				m4_game_ids &= p_result[:m4_game_ids]
				m3_game_ids &= p_result[:m3_game_ids]
				m4_chip_ids &= p_result[:m4_chip_ids]
				m3_chip_ids &= p_result[:m3_chip_ids]
			end
		}
		logger.debug(game_ids)
		logger.debug(m4_game_ids)
		logger.debug(m3_game_ids)
		logger.debug(m4_chip_ids)
		logger.debug(m3_chip_ids)

		@player_results.each {|p_result| 
			if p_result[:id].nil?
				next
			end

			p_result[:m4_score] = Score.where(game_id: m4_game_ids, player_id: p_result[:id]).sum(:score)
			p_result[:m3_score] = Score.where(game_id: m3_game_ids, player_id: p_result[:id]).sum(:score)
			p_result[:m4_chip_score] = Score.where(game_id: m4_chip_ids, player_id: p_result[:id]).sum(:score)
			p_result[:m3_chip_score] = Score.where(game_id: m3_chip_ids, player_id: p_result[:id]).sum(:score)
			p_result[:m4_total] = p_result[:m4_score] + p_result[:m4_chip_score]
			p_result[:m3_total] = p_result[:m3_score] + p_result[:m3_chip_score]
		}


		@m4_games = Game.includes(scores: [:player]).where(id: m4_game_ids).order(created_at: :desc).order("scores.score desc")
		@m3_games = Game.includes(scores: [:player]).where(id: m3_game_ids).order(created_at: :desc).order("scores.score desc")

		@player_results.each { |p_result|
			if p_result[:id].nil?
				next
			end

			p_result[:m4_ranks] = [0,0,0,0]
			setRankCount(p_result[:m4_ranks], @m4_games, p_result[:id])
			p_result[:m3_ranks] = [0,0,0]
			setRankCount(p_result[:m3_ranks], @m3_games, p_result[:id])
		}

=begin
		logger.debug("四麻")
		@m4_games.each { |game|
			@txt = "game:#{game.id} "
			game.scores.each{|score|
				@txt += "#{score.player.name}:#{score.score} "
			}
			logger.debug(@txt)
		}
		logger.debug("三麻")
		@m3_games.each { |game|
			@txt = "game:#{game.id} "
			game.scores.each{|score|
				@txt += "#{score.player.name}:#{score.score} "
			}
			logger.debug(@txt)
		}
=end

	end

private
	def setRankCount(rank_counts, games, player_id)
		games.each { |game|
			rank = 0
			game.scores.each {|score|
				if score.player_id == player_id
					rank_counts[rank] += 1
				end
				rank += 1
			}
		}
		logger.debug(rank_counts)

	end

end
