class CreateSectionPlayers < ActiveRecord::Migration[5.2]
  def change
    create_table :section_players do |t|
      t.integer :section_id
      t.integer :player_id
      t.integer :total
      t.boolean :paid, default: false

      t.timestamps
    end
  end
end
