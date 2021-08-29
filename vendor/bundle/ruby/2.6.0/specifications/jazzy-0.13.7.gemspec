# -*- encoding: utf-8 -*-
# stub: jazzy 0.13.7 ruby lib

Gem::Specification.new do |s|
  s.name = "jazzy".freeze
  s.version = "0.13.7"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["JP Simard".freeze, "Tim Anglade".freeze, "Samuel Giddins".freeze, "John Fairhurst".freeze]
  s.date = "2021-05-06"
  s.description = "Soulful docs for Swift & Objective-C. Run in your Xcode project's root directory for instant HTML docs.".freeze
  s.email = ["jp@jpsim.com".freeze]
  s.executables = ["jazzy".freeze]
  s.files = ["bin/jazzy".freeze]
  s.homepage = "https://github.com/realm/jazzy".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.0.0".freeze)
  s.rubygems_version = "3.0.3".freeze
  s.summary = "Soulful docs for Swift & Objective-C.".freeze

  s.installed_by_version = "3.0.3" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<cocoapods>.freeze, ["~> 1.5"])
      s.add_runtime_dependency(%q<mustache>.freeze, ["~> 1.1"])
      s.add_runtime_dependency(%q<open4>.freeze, [">= 0"])
      s.add_runtime_dependency(%q<redcarpet>.freeze, ["~> 3.4"])
      s.add_runtime_dependency(%q<rouge>.freeze, [">= 2.0.6", "< 4.0"])
      s.add_runtime_dependency(%q<sassc>.freeze, ["~> 2.1"])
      s.add_runtime_dependency(%q<sqlite3>.freeze, ["~> 1.3"])
      s.add_runtime_dependency(%q<xcinvoke>.freeze, ["~> 0.3.0"])
      s.add_development_dependency(%q<bundler>.freeze, ["~> 1.7"])
      s.add_development_dependency(%q<rake>.freeze, ["~> 13.0"])
    else
      s.add_dependency(%q<cocoapods>.freeze, ["~> 1.5"])
      s.add_dependency(%q<mustache>.freeze, ["~> 1.1"])
      s.add_dependency(%q<open4>.freeze, [">= 0"])
      s.add_dependency(%q<redcarpet>.freeze, ["~> 3.4"])
      s.add_dependency(%q<rouge>.freeze, [">= 2.0.6", "< 4.0"])
      s.add_dependency(%q<sassc>.freeze, ["~> 2.1"])
      s.add_dependency(%q<sqlite3>.freeze, ["~> 1.3"])
      s.add_dependency(%q<xcinvoke>.freeze, ["~> 0.3.0"])
      s.add_dependency(%q<bundler>.freeze, ["~> 1.7"])
      s.add_dependency(%q<rake>.freeze, ["~> 13.0"])
    end
  else
    s.add_dependency(%q<cocoapods>.freeze, ["~> 1.5"])
    s.add_dependency(%q<mustache>.freeze, ["~> 1.1"])
    s.add_dependency(%q<open4>.freeze, [">= 0"])
    s.add_dependency(%q<redcarpet>.freeze, ["~> 3.4"])
    s.add_dependency(%q<rouge>.freeze, [">= 2.0.6", "< 4.0"])
    s.add_dependency(%q<sassc>.freeze, ["~> 2.1"])
    s.add_dependency(%q<sqlite3>.freeze, ["~> 1.3"])
    s.add_dependency(%q<xcinvoke>.freeze, ["~> 0.3.0"])
    s.add_dependency(%q<bundler>.freeze, ["~> 1.7"])
    s.add_dependency(%q<rake>.freeze, ["~> 13.0"])
  end
end
