class Room::PlayerscoredController < RoomController

	M4 = 0
	M3 = 1

	GAME = 0
	CHIP = 1
	TOTAL = 2

	def index
	end

	def scored
		@players = Player.where(group_id: session[:grp], provisional: false)
	end

	def result_scored
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
			raise "no parameter player_id"
			return
		end

		logger.debug("complete check params")

		@player_id = p_id.to_i
		player = Player.find(@player_id)
		@player_name = player.name

		sections = Section.finished.where(group_id: session[:grp].to_i)

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


		where_sections = sections

		# sectionの絞り込みはここまで

		@results = [{gamekind: Section::Gamekind::M4},{gamekind: Section::Gamekind::M3}]
		@results.each {|result|

			p_sections = where_sections.includes(games: [scores: [:player]])
			p_sections = p_sections.where(games: {scores: {player_id: @player_id}})

			if result[:gamekind] == Section::Gamekind::M4
				result[:ranks] = [0,0,0,0]
				p_game_sections = p_sections.m4.game_by_includes
				p_chip_sections = p_sections.m4.chip_by_includes
			else
				result[:ranks] = [0,0,0]
				p_game_sections = p_sections.m3.game_by_includes
				p_chip_sections = p_sections.m3.chip_by_includes
			end

			result[:game_score] = p_game_sections.sum("scores.score")
			result[:chip_score] = p_chip_sections.sum("scores.score")
			result[:total_score] = result[:game_score] + result[:chip_score]



			p_game_ids = p_game_sections.pluck("games.id")

			play_sections = Section.includes(games: [scores: [:player]]).where("games.id IN(?)", p_game_ids)
			result[:game_sections] = play_sections.order(id: :desc).order("games.id asc").order("scores.score desc")

			result[:game_sections].each {|section|
				setRankCount(result[:ranks], section.games, @player_id)
			}


			# chart用
			chart_sections = where_sections
			chart_sections = chart_sections.joins(games: [:scores])
			chart_sections = chart_sections.where("scores.player_id = ?", @player_id)

			if result[:gamekind] == Section::Gamekind::M4
				daily_sections = chart_sections.m4
			else
				daily_sections = chart_sections.m3
			end

			daily_sections = daily_sections.select("games.scorekind")
			daily_sections = daily_sections.select(Section::Sql_select_daily)
			daily_sections = daily_sections.select("sum(scores.score) as sum_score")
			daily_sections = daily_sections.group(:daily, "games.scorekind")
			daily_sections = daily_sections.order("daily asc")

			result[:total_charts] = []
			result[:game_charts] = []
			result[:chip_charts] =[]

			total = 0
			game = 0
			chip = 0
			daily_sections.each {|section|
#				logger.debug(section.attributes)
				if section.scorekind == Game::Scorekind::GAME
					game += section.sum_score
					result[:game_charts].push([section.daily, game])
				else
					chip += section.sum_score
					result[:chip_charts].push([section.daily, chip])
				end

				total += section.sum_score
				result[:total_charts].push([section.daily, total])
			}
		}

	end

	def scoredvs
		@players_num = 4
		@players = Player.where(group_id: session[:grp], provisional: false)
	end

	def result_scoredvs
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


		@m4_sections = Section.includes(games: [scores: [:player]]).where("games.id IN(?)", m4_game_ids) \
								.order(id: :desc).order("games.id asc").order("scores.score desc")
		@m3_sections = Section.includes(games: [scores: [:player]]).where("games.id IN(?)", m3_game_ids) \
								.order(id: :desc).order("games.id asc").order("scores.score desc")

		@player_results.each { |p_result|
			if p_result[:id].nil?
				next
			end

			p_result[:m4_ranks] = [0,0,0,0]
			@m4_sections.each {|section|
				setRankCount(p_result[:m4_ranks], section.games, p_result[:id])
			}
			p_result[:m3_ranks] = [0,0,0]
			@m3_sections.each {|section|
				setRankCount(p_result[:m3_ranks], section.games, p_result[:id])
			}
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

	def vs_scored
		@players_num = 4
		@players = Player.where(group_id: session[:grp], provisional: false)
		@g_idname = params[:g_idname]

		@show_params = {player_ids: Array.new(@players_num, nil), player_count: 0 ,show_result: false, exist_results: Array.new(2, false), and_game_sections: Array.new(2,nil)}
		# 2x4の二次元配列作成(2は四麻(0)・三麻(1)。4はプレイヤー数)
		# [[nil, nil, nil, nil],[nil, nil, nil, nil]]
		@result_players_kinds = Array.new(2).map{Array.new(@players_num, nil)}



		# グループで最初に投稿した日付のある月を最初の日付とし、現在の日付をチェックする
		first_section = Section.select(:finished_at).where(status: Section::Status::FINISHED, group_id: session[:grp].to_i).order(:finished_at).first

		# 対象が一つもない場合はnilが返る為現在の月を最初の月とする
		first = first_section.nil? ? Time.current : first_section.finished_at
		puts first

		# 月の計算は １日の12時を基準とする
		first_month = Time.new(first.year, first.month, 1, 12, 0, 0, first.utc_offset)
		now = Time.current
		last_month = Time.new(now.year, now.month, 1, 12, 0, 0, now.utc_offset)

		puts first_month.strftime("%Y年%m月")
		puts last_month.strftime("%Y年%m月")
		puts Time.at(first_month.to_i)

		enable_months = []
		tmp_month = first_month
		end_month = last_month + 1.months
		while tmp_month < end_month do
			enable_months.push([tmp_month.strftime("%Y年%m月"), tmp_month.to_i])
			tmp_month += 1.months
		end

		# 指定なしの記述を開始月は最初に、終了月は最後に入れる
		none_select = ["指定なし", -1]
		@enable_start_months = enable_months.deep_dup.insert(0, none_select)
		@enable_end_months = enable_months.deep_dup.push(none_select)

		# 初期位置のvalueをしてする(TODO: GETの引数による外部からの指定がある場合はその値で書き換える)
		@select_start_month = -1
		@select_end_month = -1

		# 
		# ここまではフォーム作成用初期配置
		# 

		# 
		# ここからパラメータ指定のチェックと指定があった場合のフォームの値設定
		#

		# 日付のチェックと取得が数値でない、日付が１日ではないなどのチェックは省略)
		@date_start = nil
		if params.has_key?(:date_start)
			date_start_i = params[:date_start].to_i
			if date_start_i != -1
				@date_start = Time.at(date_start_i)
				@select_start_month = date_start_i # optionsの初期位置
			end
		end

		@date_end = nil
		if params.has_key?(:date_end)
			date_start_i = params[:date_end].to_i
			if date_start_i != -1
				@date_end = Time.at(date_start_i)
				@select_end_month = date_start_i # optionsの初期位置
			end
		end

		puts @date_start
		puts @date_end

		unless params.has_key?(:player)
			# 該当パラメータがない場合は指定パレメータがない（初期状態）ということで各種計算は行わない
			return
		end

		puts "プレイヤー指定あり"

		@show_params[:player_ids].length.times {|index|
			p_id = params[:player]["id#{index}"]
			unless p_id.blank?
				@show_params[:player_ids][index] = p_id.to_i
				@show_params[:player_count] += 1
			end
		}

		if @show_params[:player_count] == 0
			# player指定が一つもないので不正なパラメータ
			return
		end

		@show_params[:show_result] = true


=begin
		# 必要な情報を書き出してみる
		共通
			data_start
			date_end
			
			四麻・三麻それぞれ
				and_game_ids (重複しているゲームのgame.ids)
				and_chip_ids (重複しているチップのgame.ids)
					★ 全プレイヤーのgame_ids, chip_idsが必要
				and_game_sections(重複したゲームの結果(表示用))

		プレイヤー毎
			player_id
			player_name

			四麻・三麻でそれぞれ必要
				合計値(ゲーム、チップ、トータル)				
				順位数合計(1−４位)
				char_sections(ゲーム、チップ、トータル。daily_sum版で必要)
=end

		# M4/M3でループ
		@result_players_kinds.each_with_index {|result_players, gameKind|
			@show_params[:player_ids].each_with_index {|player_id, index|
				unless player_id.nil?
					@show_params[:player_ids][index] = player_id
					result_players[index] = PersonalResult.new(player_id, session[:grp], gameKind, @date_start, @date_end)
				end
			}

			# 各プレイヤーのGame.idを &でとって共通するGame.idを抽出する
			initflag = true
			and_game_ids = []
			and_chip_ids = []

			result_players.each {|result_player|
				if result_player.nil?
					next
				end

				if initflag
					and_game_ids = result_player.getGameIds(GAME).deep_dup
					and_chip_ids = result_player.getGameIds(CHIP).deep_dup
					initflag = false
				else
					and_game_ids &= result_player.getGameIds(GAME)
					and_chip_ids &= result_player.getGameIds(CHIP)
				end
			}

			# 結果がある場合
			if and_game_ids.length > 0 || and_chip_ids.length > 0
				@show_params[:exist_results][gameKind] = true
				@show_params[:and_game_sections][gameKind] \
					= Section.includes(games: [scores: [:player]]) \
							  .where("games.id IN(?)", and_game_ids) \
							  .order(id: :desc).order("games.id asc").order("scores.score desc")

				result_players.each { |result_player|
				if result_player.nil?
					next
				end
				# 以下の処理を行う
				#   各種合計値の計算、
				#   各順位数の取得
				#   chart情報の取得
				result_player.calculate(and_game_ids, and_chip_ids, @show_params[:and_game_sections][gameKind])
			}
				
			end

		}
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
#		logger.debug(rank_counts)

	end

	class PersonalResult
		attr_reader :player_id, :player_name
		attr_reader :game_sum, :chip_sum, :total_sum
		attr_reader :ranks
		attr_reader :total_charts, :game_charts, :chip_charts

		def initialize(player_id, group_id, gameKind, date_start, date_end)

			@player_id = player_id
			player = Player.find(player_id)
			@player_name = player.name
			@gameKind = gameKind
			@date_start = date_start
			@date_end = date_end

			sections = Section.includes(games: [:scores]) \
							.where(gamekind: gameKind)
							.where(status: Section::Status::FINISHED) \
							.where(group_id: group_id) \
							.where(games: {scores: {player_id: player_id}})
			
			unless @date_start.nil?
				sections = sections.where('finished_at >= ?', date_start)
			end
				
			unless @date_end.nil?
				sections = sections.where('finished_at < ?', date_end + 1.months)
			end

			@p_sections = sections

		end

		def getSections(scoreKind)
			sections = @p_sections

			if scoreKind == GAME
				sections = sections.where(games: {scorekind: Game::Scorekind::GAME})
			elsif scoreKind == CHIP
				sections = sections.where(games: {scorekind: Game::Scorekind::CHIP})
			elsif scoreKind == TOTAL
				# 必要なし
			else
				raise
			end

			return sections
		end

		def getGameIds(scoreKind)
			getSections(scoreKind).pluck("games.id")
		end

		def calculate(and_game_ids, and_chip_ids, and_game_sections)
			and_total_ids = and_game_ids + and_chip_ids

			# 該当するGameにおける各プレイヤーの合計値を算出
			@game_sum = Score.where(game_id: and_game_ids, player_id: @player_id).sum(:score)
			@chip_sum  = Score.where(game_id: and_chip_ids, player_id: @player_id).sum(:score)
			@total_sum = @game_sum + @chip_sum

			# 各順位数の取得
			rank_num = @gameKind == M4 ? 4 : 3
			@ranks = Array.new(rank_num, 0)
			and_game_sections.each { |section|
				setRankCount(@ranks, section.games, @player_id)
			}

			# chart情報の取得
			chart_sections = Section.joins(games: [:scores]) \
			.where("games.id IN(?)", and_total_ids)
			daily_sections = chart_sections \
								.select("games.scorekind") \
								.select(Section::Sql_select_daily) \
								.select("sum(scores.score) as sum_score") \
								.where("scores.player_id = ?", @player_id)
								.group(:daily, "games.scorekind") \
								.order("daily asc")

			@total_charts = []
			@game_charts = []
			@chip_charts = []

			total = 0
			game = 0
			chip = 0

			daily_sections.each {|section|
				if section.scorekind == Game::Scorekind::GAME
					game += section.sum_score
					@game_charts.push([section.daily, game])
				else
					chip += section.sum_score
					@chip_charts.push([section.daily, chip])
				end
				
				total += section.sum_score
				@total_charts.push([section.daily, total])
			}
		end

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
		end

	end

end
