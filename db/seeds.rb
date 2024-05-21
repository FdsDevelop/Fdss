# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

puts "====================="
puts "create default data"
puts "====================="

unless FdssNode.find_by(e_id: -1)
  root_node = FdssNode.new(e_id: -1, parent_node_id: nil, node_type: FdssNode.DIR_TYPE, name: "root")
  root_node.save(validate: false)
end