Gem::Specification.new do |s|
  s.name = "map_validator"
  s.authors = ["Sean Anderson"]
  s.version = "0.0.1"
  s.date = "2019-05-06"
  s.summary = "Validation for MAP file uploads"
  s.files = Dir.glob("lib/**/*")

  s.add_runtime_dependency("roo", "2.8.2")
end
