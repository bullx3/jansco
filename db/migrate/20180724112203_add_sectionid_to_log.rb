class AddSectionidToLog < ActiveRecord::Migration[5.2]
  def change
    add_column :logs, :section_id, :integer
  end
end
