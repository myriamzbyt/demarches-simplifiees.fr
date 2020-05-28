class CreateArchives < ActiveRecord::Migration[5.2]
  def change
    create_table :archives do |t|
      t.datetime :month
      t.references :instructeur, foreign_key: true
      t.references :procedure, foreign_key: true

      t.timestamps
    end
  end
end
