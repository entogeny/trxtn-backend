puts "Seeding users..."

%w[developer alice carol diana edgar].each do |username|
  User.find_or_create_by!(username: username) do |user|
    user.password              = "password"
    user.password_confirmation = "password"
  end
end

puts "  → Done"
