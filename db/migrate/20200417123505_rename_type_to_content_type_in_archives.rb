class RenameTypeToContentTypeInArchives < ActiveRecord::Migration[5.2]
  def change
    rename_column :archives, :type, :content_type
  end
end
