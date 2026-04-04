class BaseSerializer < Blueprinter::Base

  identifier :id

  view :base do
  end

  view :standard do
    include_view :base
  end

  view :extended do
    include_view :standard
  end

end
