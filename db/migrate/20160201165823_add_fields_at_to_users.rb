class AddFieldsAtToUsers < ActiveRecord::Migration
  def change
    rename_column :users,:name,:username
    add_column :users, :email, :string
    add_column :users,:timestamps,:datetime
  end
end
