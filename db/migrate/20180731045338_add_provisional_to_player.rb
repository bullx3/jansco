class AddProvisionalToPlayer < ActiveRecord::Migration[5.2]
  def change
    add_column :players, :provisional, :boolean, default: false
  end
end
