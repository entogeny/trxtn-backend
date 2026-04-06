class EventSerializer < BaseSerializer

  view :base do
  end

  view :standard do
    include_view :base

    field :description
    field :end_at
    field :name
    field :start_at

    association :owner, blueprint: UserSerializer, view: :base
  end

  view :extended do
    include_view :standard

    association :owner, blueprint: UserSerializer, view: :standard
  end

end
