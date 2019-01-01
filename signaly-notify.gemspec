# -*- coding: utf-8 -*-
Gem::Specification.new do |s|
  s.name        = 'signaly-notify'
  s.version     = '0.0.5'
  s.date        = '2015-12-26'
  s.summary     = "notification script for signaly.cz (Czech christian social network)"
  s.description = "signaly-notify.rb signs in with your credentials
to the social network https://signaly.cz
and triggers a desktop notification whenever something new happens.
It detects pending private messages, notifications and invitations."
  s.authors     = ["Jakub Pavlík"]
  s.email       = 'jkb.pavlik@gmail.com'
  s.files       = Dir['bin/*.rb'] + Dir['lib/**/*.rb']
  s.executables = ['signaly-notify.rb']
  s.homepage    =
    'http://github.com/igneus/signaly-notify'
  s.licenses    = ['LGPL-3.0', 'MIT']

  s.add_runtime_dependency 'mechanize', '~> 2.7'
  s.add_runtime_dependency 'colorize', '~> 0.7'
  s.add_runtime_dependency 'highline', '~> 1.7'
  s.add_runtime_dependency 'autoloaded', '~> 2.1'
end
