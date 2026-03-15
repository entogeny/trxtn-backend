puts "Seeding users..."

User.find_or_create_by!(username: "developer") do |user|
  user.password = "password"
  user.password_confirmation = "password"
end

puts "  → Done"
