class AddNameToUsers < ActiveRecord::Migration
  def change
    add_column :users, :name, :string
    ren
  end
end
