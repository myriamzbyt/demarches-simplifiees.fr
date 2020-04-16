class RenameStateToStatusInArchives < ActiveRecord::Migration[5.2]
  def change
    rename_column :archives, :state, :status
  end
end
