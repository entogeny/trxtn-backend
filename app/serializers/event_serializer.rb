class EventSerializer < BaseSerializer

  view :base do
  end

  view :standard do
    include_view :base

    field :description
    field :end_at
    field :name
    field :start_at
  end

  view :extended do
    include_view :standard
  end

end
