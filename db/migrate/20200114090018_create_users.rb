class CreateUsers < ActiveRecord::Migration[5.2]
  def change
    create_table :users do |t|
      t.string   :email, limit: 255, null: false
      t.string   :username, limit: 255, null: false
      t.string   :persistence_token, limit: 255
      t.datetime :created_at
      t.datetime :updated_at
    end
  end
end
