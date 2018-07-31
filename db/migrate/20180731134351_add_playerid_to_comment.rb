class AddPlayeridToComment < ActiveRecord::Migration[5.2]
  def change
    add_column :comments, :player_id, :integer
  end
end
