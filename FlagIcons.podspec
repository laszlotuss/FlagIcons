Pod::Spec.new do |s|

s.name         = "FlagIcons"
s.version      = "0.1.0"
s.license      = "MIT"
s.homepage     = "https://github.com/malczak/flag-icon-swift"
s.summary      = "A collection of all country flags to be used in Swift"
s.author       = { "Mateusz Malczak" => "mateusz@malczak.info", "Laszlo Tuss" => "laszlotuss@me.com" }
s.source       = { :git => "https://github.com/malczak/flag-icon-swift.git", :branch => "swift" }

s.platform     = :ios, "8.0"

s.source_files  = "Sources/FlagIcons/*.swift"
s.resource_bundle = { 'assets' => 'Sources/FlagIcons/Resources/*'}

s.requires_arc = true
end
