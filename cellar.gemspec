# encoding: utf-8

Gem::Specification.new do |s|
  s.name        = "cellar"
  s.version     = `grep -m 1 '^\s*VERSION' lib/cellar.rb | head -1 | cut -f 2 -d '"'`
  s.author      = "Steve Shreeve"
  s.email       = "steve.shreeve@gmail.com"
  s.summary     =  "A " +
  s.description = "Ruby gem to deal with cells of data in rows and columns"
  s.homepage    = "https://github.com/shreeve/cellar"
  s.license     = "MIT"
  s.platform    = Gem::Platform::RUBY
  s.files       = `git ls-files`.split("\n") - %w[.gitignore]
end
