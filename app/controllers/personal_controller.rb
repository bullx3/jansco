class PersonalController < ApplicationController
  def index
  	user_id = session[:usr]
  	@user = User.includes(:groups).find(user_id)
  end

  def profit
	user_id = session[:usr]
  	@user = User.find(user_id)

	player_ids = Player.where(user_id: user_id).pluck(:id)
	logger.debug("player_ids:#{player_ids}")

	sections = Section.where(status: Section::Status::FINISHED)

	sections = sections.joins(games: [:scores]).select("sections.*, games.*, scores.*")
	sections = sections.includes(:group)
	sections = sections.where("player_id IN(?)", player_ids)

	profits = sections.select("SUM(rate * score) as sum_profit")
	profits = profits.select("SUM(score) as sum_score")
	profits = profits.select("COUNT(scorekind = #{Game::Scorekind::GAME} OR NULL) as count_game")
	profits = profits.where.not(rate: nil)

	@profit_totals = profits.group(:group_id)

	logger.debug("@profit_totals.length:#{@profit_totals.length}")

	# 月ごとの集計 実際は 12時間後(例 2018/8分は 8/1 12:00 ～ 9/1 11:59までに終了した対局)
	# JST での時間で集計する為 +9Hで判定する（MySQLはUTCで保存）
	@profit_months = profits.select(Section::Sql_select_monthly).group("monthly", :group_id).order("monthly asc")
	logger.debug("@profit_months.length:#{@profit_months.length}")

	@profit_dailys = profits.select(Section::Sql_select_daily).group("daily", :group_id).order("daily asc")
	logger.debug("@profit_dailys.length:#{@profit_dailys.length}")


	no_rates = sections
	no_rates = no_rates.select("SUM(score) as sum_score")
	no_rates = no_rates.select("COUNT(scorekind = #{Game::Scorekind::GAME} OR NULL) as count_game")
	@no_rate_sections = no_rates.where(rate: nil).group("games.section_id")


  end
end
