class Room::RankingController < RoomController
  before_action :preset

  def index
	@simple_ranking_count = 3
	# 総合ランキング
	@total_rankings = calcRankings(@simple_ranking_count, nil)

	#今月のランキング
	current = Time.current
	# 1日の12時を切り変わりとする為12時間巻き戻す
	current = current - 12.hour
	current = current.beginning_of_month

	logger.debug("current:#{current}")
	month = current.strftime("%-m月")
	logger.debug("month:#{month}")

	@this_month = month
	@this_rankings = calcRankings(@simple_ranking_count, current)

	#先月のランキング
	last = current.prev_month
	logger.debug("last:#{last}")
	month = last.strftime("%-m月")
	logger.debug("month:#{month}")

	@last_month = month
	@last_rankings = calcRankings(@simple_ranking_count, last)

  end

  def total
	@rankings = calcRankings(@ranking_count, nil)
  end

  def thisMonth
	current = Time.current
	current = current - 12.hour
	current = current.beginning_of_month
	@subtitle = "今月(#{current.strftime('%-Y/%-m')})のランキング"

	@rankings = calcRankings(@ranking_count, current)

	render 'month'
  end

  def lastMonth
	current = Time.current
	current = current - 12.hour
	current = current.beginning_of_month
	current = current - 1.month
	@subtitle = "先月(#{current.strftime('%-Y/%-m')})のランキング"

	@rankings = calcRankings(@ranking_count, current)

	render 'month'
  end

  def past
	@time_jst = nil

	unless params.has_key?(:past)
		# 初回
		current = Time.current
		current = current - 12.hour
		current = current.beginning_of_month
		@time_jst = current
	else
		year = params[:past]["date(1i)"];
		month = params[:past]["date(2i)"];
		logger.debug(year)
		logger.debug(month)
		@time_jst = Time.zone.local(year, month, 1, 0, 0)
		logger.debug(@time_jst)
	end


	@rankings = calcRankings(@ranking_count, @time_jst)

  end

private
  def preset
	# 表示するカウント
    if session[:grp_per] == Player::Permission::ADMIN
		# ルームの管理者は全員の集計が見える
	    @ranking_count = Player.where(group_id: session[:grp], provisional: false).count
    else
	    @ranking_count = 5
	end
  end

  def calcRankings(count, time_jst)
	rankings = Array(2)

	rankings[0] = {title: "四麻", gamekind: Section::Gamekind::M4}
	rankings[1] = {title: "三麻", gamekind: Section::Gamekind::M3}

	rankings.each {|ranking|

		#該当するセクション（ 実際にはここで日付も意識する)
		sections = Section.where(status: Section::Status::FINISHED, group_id: session[:grp].to_i, gamekind: ranking[:gamekind])

		# 12時間の差異とJSTの9時間を考慮して有効月のみ抽出
		unless time_jst.nil?
			begin_time = time_jst + 12.hour
			end_time = time_jst + 1.month + 12.hour
			sections = sections.where("finished_at >= ?", begin_time)
			sections = sections.where("finished_at < ?", end_time)
		end

		section_ids = sections.pluck(:id)
		logger.debug(section_ids)

		#該当するsectionのゲームすべて
		sections = sections.joins(games: [scores: [:player]]).select("sections.*, games.* , scores.*, players.name")

		#総得点ランキング(チップを含む)
		ranking[:rank_totalscores] = sections.select('SUM(score) as sum_total').group(:player_id).order('sum_total desc').limit(count)

		# 対局数、平均スコアの為条件を更新
		no_chip_games = sections.where("games.scorekind = ?", Game::Scorekind::GAME)

		# ﾁｯﾌﾟなし総得点
		ranking[:rank_no_chip_scores] = no_chip_games.select('SUM(score) as sum_total').group(:player_id).order('sum_total desc').limit(count)


		#対局数ランキング
		ranking[:rank_counts] = no_chip_games.select('COUNT(*) as count_score').order('count_score desc').group(:player_id).limit(count)

		#平均値ランキング
		ranking[:rank_avgs] = no_chip_games.select('AVG(score) as avg_score').order('avg_score desc').group(:player_id).limit(count)

		#MAXスコア
		ranking[:max_scores] = no_chip_games.order('scores.score desc').limit(count)

		# 最高スコア(集計あたりの合計)
		ranking[:max_total_scores] = sections.select('SUM(score) as sum_score').group(:id, :player_id).order('sum_score desc').limit(count)


		chip_games = sections.where("games.scorekind = ?", Game::Scorekind::CHIP)

		#チップ合計
		ranking[:total_chips] = chip_games.select('SUM(score) as sum_chip').group(:player_id).order('sum_chip desc').limit(count)


		#チップ最高点(一集計あたり)
		ranking[:max_chips] = chip_games.select('SUM(score) as sum_chip').group(:id, :player_id).order('sum_chip desc').limit(count)
	}

	return rankings
  end

end
