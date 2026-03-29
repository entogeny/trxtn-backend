class CreateUsers < ActiveRecord::Migration[8.1]

  def change
    create_table :users, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.string :username, null: false
      t.string :password_digest, null: false

      t.timestamps
    end
    add_index :users, :username, unique: true
  end

end
