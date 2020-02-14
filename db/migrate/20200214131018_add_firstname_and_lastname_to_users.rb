class AddFirstnameAndLastnameToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :firstname, :string, limit: 255
    add_column :users, :lastname, :string, limit: 255
  end
end
