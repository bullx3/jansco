class AddPermissionToPlayer < ActiveRecord::Migration[5.2]
  def change
    add_column :players, :permission, :integer, default: 0
  end
end
