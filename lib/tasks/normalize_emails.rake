namespace :db do
  namespace :normalize do
    desc "Convert all email addresses in the database to lowercase"
    task :emails => [:environment] do
      puts "Starting email normalization..."

      total_updated = 0

      # Normalize User emails
      puts "\nProcessing User emails..."
      users_updated = 0
      User.unscoped.find_each do |user|
        if user.email.present? && user.email != user.email.downcase
          old_email = user.email
          user.update_column(:email, user.email.downcase)
          users_updated += 1
          puts "  Updated User ##{user.id}: #{old_email} -> #{user.email}"
        end
      end
      puts "  Users updated: #{users_updated}"
      total_updated += users_updated

      # Normalize Person emails
      puts "\nProcessing Person emails..."
      people_updated = 0
      Person.find_each do |person|
        if person.email.present? && person.email != person.email.downcase
          old_email = person.email
          person.update_column(:email, person.email.downcase)
          people_updated += 1
          puts "  Updated Person ##{person.id}: #{old_email} -> #{person.email}"
        end
      end
      puts "  People updated: #{people_updated}"
      total_updated += people_updated

      # Normalize ClassyCacheOrgMember emails
      puts "\nProcessing ClassyCacheOrgMember emails..."
      members_updated = 0
      ClassyCacheOrgMember.find_each do |member|
        if member.email.present? && member.email != member.email.downcase
          old_email = member.email
          member.update_column(:email, member.email.downcase)
          members_updated += 1
          puts "  Updated ClassyCacheOrgMember ##{member.id}: #{old_email} -> #{member.email}"
        end
      end
      puts "  ClassyCacheOrgMembers updated: #{members_updated}"
      total_updated += members_updated

      puts "\n========================================="
      puts "Email normalization complete!"
      puts "Total records updated: #{total_updated}"
      puts "========================================="
    end

    desc "Check for uppercase email addresses without modifying them (dry run)"
    task :emails_check => [:environment] do
      puts "Checking for uppercase email addresses (dry run)...\n\n"

      total_found = 0

      # Check User emails
      puts "Users with uppercase emails:"
      users_found = 0
      User.unscoped.find_each do |user|
        if user.email.present? && user.email != user.email.downcase
          puts "  User ##{user.id}: #{user.email}"
          users_found += 1
        end
      end
      puts "  Found: #{users_found}\n\n"
      total_found += users_found

      # Check Person emails
      puts "People with uppercase emails:"
      people_found = 0
      Person.find_each do |person|
        if person.email.present? && person.email != person.email.downcase
          puts "  Person ##{person.id}: #{person.email}"
          people_found += 1
        end
      end
      puts "  Found: #{people_found}\n\n"
      total_found += people_found

      # Check ClassyCacheOrgMember emails
      puts "ClassyCacheOrgMembers with uppercase emails:"
      members_found = 0
      ClassyCacheOrgMember.find_each do |member|
        if member.email.present? && member.email != member.email.downcase
          puts "  ClassyCacheOrgMember ##{member.id}: #{member.email}"
          members_found += 1
        end
      end
      puts "  Found: #{members_found}\n\n"
      total_found += members_found

      puts "========================================="
      puts "Total records with uppercase emails: #{total_found}"
      puts "========================================="
      puts "\nRun 'rake db:normalize:emails' to convert these to lowercase."
    end
  end
end
