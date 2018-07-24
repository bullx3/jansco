class CreatePlayers < ActiveRecord::Migration[5.2]
  def change
    create_table :players do |t|
      t.integer :user_id
      t.integer :group_id
      t.string :name

      t.timestamps
    end
  end
end
