path1 = File.expand_path("..", __FILE__)
path2 = File.expand_path("../data", __FILE__)
puts path1
puts path2
puts Dir.glob(File.join(path2, "*"))

puts "hello"