class UserSerializer < BaseSerializer

  view :base do
    field :username
  end

  view :standard do
    include_view :base
  end

  view :extended do
    include_view :standard
  end

end
