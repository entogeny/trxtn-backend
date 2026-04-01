class CreateEvents < ActiveRecord::Migration[8.1]

  def change
    create_table :events, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.string   :name,        null: false
      t.text     :description, null: false
      t.datetime :start_at,    null: false
      t.datetime :end_at

      t.timestamps
    end

    add_index :events, :start_at
  end

end
