class AddOwnershipToEvents < ActiveRecord::Migration[8.1]

  def change
    add_reference :events, :owner,
                  type: :uuid,
                  foreign_key: { to_table: :users, on_delete: :nullify },
                  null: true

    add_column :events, :creator_type, :string
    add_column :events, :creator_id,   :uuid
    add_index  :events, [ :creator_type, :creator_id ]
  end

end
