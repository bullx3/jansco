class CreateSections < ActiveRecord::Migration[5.2]
  def change
    create_table :sections do |t|
      t.integer :status
      t.integer :rate
      t.integer :games_count, default: 0
      t.integer :section_players_count, default: 0
      t.integer :group_id
      t.boolean :all_paid, default: false

      t.timestamps
    end
  end
end
