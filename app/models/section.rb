class Section < ApplicationRecord
	has_many :games, dependent: :destroy
	has_many :section_players, dependent: :destroy
	has_many :comments
	has_many :logs
	belongs_to :group

	#statusカラム値
	module Status
		FINISHED = 0
		PLAYING = 1
	end

	module Gamekind
		M4 = 0  # 四麻
		M3 = 1  # 三麻
	end

	GameKindString = ['四麻', '三麻']

	# 終了状態
	scope :finished, -> {where(status: Section::Status::FINISHED)}
	# 四麻
	scope :m4, -> {where(gamekind: Section::Gamekind::M4)}
	# 三麻
	scope :m3, -> {where(gamekind: Section::Gamekind::M3)}
	# Game(includes)
	scope :game_by_includes, -> {where(games: {scorekind: Game::Scorekind::GAME})}
	scope :chip_by_includes, -> {where(games: {scorekind: Game::Scorekind::CHIP})}


	Sql_select_daily = "DATE_FORMAT((finished_at - INTERVAL 12 HOUR + INTERVAL 9 HOUR), '%Y-%m-%d') as daily"

end
