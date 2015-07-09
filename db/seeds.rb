# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

user = User.create({
  :email => "demo+admin@hy.ly",
  :full_name => "Hy.ly Admin",
  :password => "gggggggg",
  :password_confirmation => "gggggggg"
})

user.add_role :admin, Property

Region.create([
  { name: 'Washington DC' }, { name: 'Philadelphia' }, 
  { name: 'New York' }, { name: 'Baltimore/Annapolis' },
  { name: 'Boston' }, { name: 'Atlanta' }
])

Category.create([
  { name: 'Flooring', active: true },
  { name: 'Plumbing', active: true },
  { name: 'Other', active: true }
])


# smartrent
Smartrent::Setting.create([{:key => "sign_up_bonus", :value => "0"}, {:key => "monthly_awards", :value => "0"}])
Smartrent::User.create(:email => "demo+admin@hy.ly", :password => "gggggggg", :password_confirmation => "gggggggg")