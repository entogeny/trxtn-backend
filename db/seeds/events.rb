puts "Seeding events..."

users = User.all.to_a

100.times do
  description = case rand(3)
  when 0 then Faker::Lorem.sentences(number: rand(1..2)).join(" ")
  when 1 then Faker::Lorem.paragraph
  when 2 then Faker::Lorem.paragraphs(number: rand(2..3)).join("\n\n")
  end

  start_at = rand(1..90).days.from_now
  owner    = users.sample

  Event.find_or_create_by!(name: Faker::Commerce.product_name) do |event|
    event.description  = description
    event.start_at     = start_at
    event.end_at       = [ nil, rand(1..4).hours ].sample.then { |h| h && start_at + h }
    event.owner        = owner
    event.creator      = owner
    event.creator_type = "User"
  end
end

puts "  → Done"
