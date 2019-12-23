class Room::HistoryController < RoomController

	HISTORIES = [
		{
			no: 1,
			date: "2018-09-25",
			title: "更新履歴機能追加",
			body: "更新履歴機能を追加しました。<br>
				   Newアイコンは更新日から三日間表示されます",
			images: nil,
			link: nil
		},
		{
			no: 2,
			date: "2018-09-27",
			title: "ランキングに総合ポイントと順位率追加",
			body: "表示するには「拡張ランキングを表示する」ボタンを押す必要があります<br>
				   総合ポイントは以下の式で得られる値です<br><br>
				   総合ポイント = １位の取得数 × １ + ２位の取得数 × ２ + ３位の取得数 × ３  + ４位の取得数 × ４<br><br>
				   １に近づくほど優秀な成績です<br>
				   全て１位を取るとポイントは１になります。<br>
				   追加したランキングは#{Room::RankingController::RankingMinCount}件以上の対局数を持つプレイヤーのみです",
			images: ["2-1.png",'2-2.png'],
			link: nil
		},
		{
			no: 3,
			date: "2019-12-25",
			title: "個人成績の対戦スコアを新しい順に変更",
			body: "プレイヤー個人成績で対戦戦績の日付が新しい順になるように変更しました",
			images: nil,
			link: nil
		},

	]

	def index
	end

end
