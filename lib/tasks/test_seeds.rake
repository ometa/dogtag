# Rake task to seed test data for integration tests
# Usage:
#   rails test_seeds:basic                    (for local development)
#   heroku run rails test_seeds:basic -r staging  (for staging environment)

namespace :test_seeds do
  desc "Create basic test environment: admin user, open race, team with 4 people"
  task basic: :environment do
    puts "🌱 Seeding basic test environment..."

    # Clean up existing test data
    puts "  Cleaning up existing test data..."
    User.where("email LIKE ?", "%test+%").destroy_all
    Team.where("name LIKE ?", "Test Team%").destroy_all
    Race.where("name LIKE ?", "Test Race%").destroy_all

    # Create admin user
    puts "  Creating admin user..."
    admin = User.create!(
      first_name: "Admin",
      last_name: "User",
      email: "test+admin@example.com",
      phone: "555-111-2222",
      password: "password123",
      password_confirmation: "password123",
      roles_mask: User.mask_for(:admin)
    )
    puts "    ✓ Admin user created: #{admin.email}"

    # Create race open for registration
    puts "  Creating open race..."
    race = Race.create!(
      name: "Test Race #{Time.now.to_i}",
      race_datetime: 30.days.from_now,
      registration_open: 1.day.ago,
      registration_close: 7.days.from_now,
      final_edits_close: 8.days.from_now,
      max_teams: 100,
      people_per_team: 5
    )
    puts "    ✓ Race created: #{race.name}"
    puts "      - Open for registration: #{race.registration_open} to #{race.registration_close}"
    puts "      - People per team: #{race.people_per_team}"

    # Create team captain user
    puts "  Creating team captain user..."
    captain = User.create!(
      first_name: "Captain",
      last_name: "TestUser",
      email: "test+captain@example.com",
      phone: "555-222-3333",
      password: "password123",
      password_confirmation: "password123"
    )
    puts "    ✓ Captain created: #{captain.email}"

    # Create team with 4 people (needs 5 to finalize)
    puts "  Creating team with 4 people..."
    team = Team.create!(
      name: "Test Team Awesome",
      description: "A test team ready for one more member!",
      experience: 1,
      race: race,
      user: captain
    )

    # Add 4 people to the team
    4.times do |i|
      person = Person.create!(
        team: team,
        first_name: "Person#{i + 1}",
        last_name: "TestMember",
        email: "test+person#{i + 1}@example.com",
        phone: "555-#{300 + i}-#{4000 + i}",
        zipcode: "60601",
        experience: i
      )
      puts "    ✓ Added person #{i + 1}: #{person.first_name} #{person.last_name}"
    end

    puts "    Team status: #{team.people.count}/#{race.people_per_team} people"
    puts "    Finalized: #{team.finalized.inspect} (needs #{race.people_per_team - team.people.count} more)"

    # Create 5th user who will join the team
    puts "  Creating 5th user (the one who will join)..."
    fifth_user = User.create!(
      first_name: "Fifth",
      last_name: "Joiner",
      email: "test+fifth@example.com",
      phone: "555-999-8888",
      password: "password123",
      password_confirmation: "password123"
    )
    puts "    ✓ Fifth user created: #{fifth_user.email}"

    puts ""
    puts "✅ Test environment seeded successfully!"
    puts ""
    puts "📋 Summary:"
    puts "  Admin user: #{admin.email} / password123"
    puts "  Captain user: #{captain.email} / password123"
    puts "  Fifth user: #{fifth_user.email} / password123"
    puts "  Race: #{race.name} (ID: #{race.id})"
    puts "  Team: #{team.name} (ID: #{team.id})"
    puts "  Team status: #{team.people.count}/#{race.people_per_team} people (needs 1 more to finalize)"
    puts ""
    puts "🧪 Ready for integration tests!"
    puts "   The fifth user can now join the team to trigger finalization."
  end

  desc "Create race with 2 payment requirements (1 tier and 3 tiers)"
  task payment_tiers: :environment do
    puts "🌱 Seeding payment tiers test..."

    # Clean up
    User.where("email LIKE ?", "%test+%").destroy_all
    Team.where("name LIKE ?", "Test Team%").destroy_all
    Race.where("name LIKE ?", "Test Race%").destroy_all

    # Create captain
    captain = User.create!(
      first_name: "Captain",
      last_name: "Tester",
      email: "test+captain@example.com",
      phone: "555-100-1000",
      password: "password123",
      password_confirmation: "password123"
    )

    # Create race
    race = Race.create!(
      name: "Test Race Payment #{Time.now.to_i}",
      race_datetime: 30.days.from_now,
      registration_open: 10.days.ago,
      registration_close: 20.days.from_now,
      final_edits_close: 21.days.from_now,
      max_teams: 100,
      people_per_team: 5
    )

    # Payment requirement #1: Single tier (mock success)
    pr1 = MockPaymentRequirement.create!(
      name: "Registration Fee",
      race: race
    )
    Tier.create!(
      requirement: pr1,
      price: 5000, # $50.00
      begin_at: 10.days.ago
    )

    # Payment requirement #2: 3 tiers (tier 2 is active, mock success)
    pr2 = MockPaymentRequirement.create!(
      name: "Team Fee",
      race: race
    )
    Tier.create!(requirement: pr2, price: 4000, begin_at: 10.days.ago) # Early: $40
    Tier.create!(requirement: pr2, price: 5000, begin_at: 1.day.ago)  # Active: $50
    Tier.create!(requirement: pr2, price: 6000, begin_at: 10.days.from_now) # Late: $60

    # Create team with 5 people
    team = Team.create!(
      name: "Test Team Payment",
      description: "Test team for payment tiers",
      experience: 1,
      race: race,
      user: captain
    )

    5.times do |i|
      Person.create!(
        team: team,
        first_name: "Person#{i + 1}",
        last_name: "Member",
        email: "test+person#{i + 1}@example.com",
        phone: "555-#{200 + i}-#{3000 + i}",
        zipcode: "60601",
        experience: i
      )
    end

    puts "✅ Seeded!"
    puts "  Captain: #{captain.email} / password123"
    puts "  Race: #{race.name} (ID: #{race.id})"
    puts "  Team: #{team.name} (ID: #{team.id})"
    puts "  Payment #1: #{pr1.name} - 1 tier ($50)"
    puts "  Payment #2: #{pr2.name} - 3 tiers (tier 2 active: $50)"
  end

  desc "Clean up all test data"
  task cleanup: :environment do
    puts "🧹 Cleaning up test data..."

    count = {
      users: User.where("email LIKE ?", "%test+%").count,
      teams: Team.where("name LIKE ?", "Test Team%").count,
      races: Race.where("name LIKE ?", "Test Race%").count
    }

    User.where("email LIKE ?", "%test+%").destroy_all
    Team.where("name LIKE ?", "Test Team%").destroy_all
    Race.where("name LIKE ?", "Test Race%").destroy_all

    puts "  ✓ Deleted #{count[:users]} test users"
    puts "  ✓ Deleted #{count[:teams]} test teams"
    puts "  ✓ Deleted #{count[:races]} test races"
    puts ""
    puts "✅ Test data cleaned up!"
  end
end
