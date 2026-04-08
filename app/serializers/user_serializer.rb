class UserSerializer < BaseSerializer

  view :base do
  end

  view :standard do
    include_view :base

    field :username
  end

  view :extended do
    include_view :standard
  end

end
