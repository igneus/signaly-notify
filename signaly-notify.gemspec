# -*- coding: utf-8 -*-
Gem::Specification.new do |s|
  s.name        = 'signaly-notify'
  s.version     = '0.0.3'
  s.date        = '2014-01-05'
  s.summary     = "notification script for signaly.cz (Czech christian social network)"
  s.description = "signaly-notify.rb is a simple script 
logging in with your user data to the social network https://signaly.cz 
and notifying you - by the means of printing to the console 
as well as sending a visual notification using libnotify - 
when something new happens.
Currently it only detects pending private messages and notifications."
  s.authors     = ["Jakub Pavlík"]
  s.email       = 'jkb.pavlik@gmail.com'
  s.files       = Dir['bin/*.rb']
  s.executables = ['signaly-notify.rb']
  s.homepage    =
    'http://github.com/igneus/signaly-notify'
  s.licenses    = ['LGPL-3.0', 'MIT']

  s.add_runtime_dependency 'mechanize'
  s.add_runtime_dependency 'colorize'
  s.add_runtime_dependency 'highline'
  s.add_optional_dependency 'libnotify'
  s.add_optional_dependency 'ruby-growl'
end
