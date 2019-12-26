module RoomHelper
    # 対戦成績へのリンクをクエリパラメータ付きで作成する
    # name : リンクテキスト。プレイヤー名を文字列で指定
    # player_id : 付与するプレイヤーのPlayer.idを指定
    def link_to_vsscored(name, player_id)
        link_to name, room_player_vs_scored_path({"player[id0]" => player_id})
    end
end
