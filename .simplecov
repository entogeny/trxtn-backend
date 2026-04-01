SimpleCov.start "rails" do
  minimum_coverage 100
  add_filter "/lib/"
  add_group "Services", "app/services"
  add_group "Errors", "app/errors"
end

SimpleCov.groups.delete("Libraries")

SimpleCov.at_exit do
  # Suppress the HTML formatter's built-in stdout output, then print our colored version
  original_stdout = $stdout
  $stdout = File.open(File::NULL, "w")
  SimpleCov.result.format!
  $stdout = original_stdout

  covered = SimpleCov.result.covered_percent
  total = SimpleCov.result.total_lines
  hits = SimpleCov.result.covered_lines
  meets = covered >= SimpleCov.minimum_coverage[:line]
  color = meets ? "\e[32m" : "\e[31m"
  reset = "\e[0m"
  puts "#{color}Line Coverage: #{format("%.1f", covered)}% (#{hits} / #{total})#{reset}"
end
