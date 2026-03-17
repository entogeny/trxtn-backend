SimpleCov.start "rails" do
  minimum_coverage 100
  add_filter "/lib/"
  add_group "Services", "app/services"
  add_group "Errors", "app/errors"
end
SimpleCov.groups.delete("Libraries")
