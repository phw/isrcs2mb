# -*- coding: utf-8 -*-
# $Id$
# Copyright (c) 2010, Philipp Wolfer
# All rights reserved.
# See LICENSE for permissions.
 
# Rakefile for isrcs2mb

require 'rake/gempackagetask'

task :default do
  puts "Please see 'rake --tasks' for an overview of the available tasks."
end

# Packaging tasks: -------------------------------------------------------

PKG_NAME = 'isrcs2mb'
PKG_VERSION = '0.1.0'
PKG_FILES = FileList[
  "Rakefile", "LICENSE", "README", "CHANGES", "bin/*", "lib/**/*.rb"
]
PKG_EXTRA_RDOC_FILES = []

spec = Gem::Specification.new do |spec|
  spec.platform = Gem::Platform::RUBY
  spec.summary = 'Simple command line tool to submit ISRCs from a CD to MusicBrainz.'
  spec.name = PKG_NAME
  spec.version = PKG_VERSION
  spec.files = PKG_FILES
  spec.bindir = 'bin'
  spec.executables << 'isrcs2mb'
  spec.add_dependency('rbrainz', '>= 0.5.1')
  spec.add_dependency('discid', '>= 1.0.0.rc1')
  spec.add_dependency('highline', '>= 1.6.1')
  spec.add_dependency('launchy', '>= 0.3.5')
  spec.description = <<EOF
    Simple command line tool to submit ISRCs from a CD to MusicBrainz.
    For usage details run "isrcs2mb --help".
EOF
  spec.authors = ['Philipp Wolfer']
  spec.email = 'phw@rubyforge.org'
  spec.homepage = 'http://rbrainz.rubyforge.org'
  spec.rubyforge_project = 'rbrainz'
  spec.has_rdoc = false
  spec.extra_rdoc_files = PKG_EXTRA_RDOC_FILES
end

Rake::GemPackageTask.new(spec) do |pkg|
  pkg.need_zip = true
  pkg.need_tar_gz= true
end

# Build the RBrainz gem and install it"
task :install => [:test] do
  sh %{ruby setup.rb}
end

# Other tasks: -----------------------------------------------------------

def egrep(pattern)
  Dir['**/*.rb'].each do |fn|
    count = 0
    open(fn) do |f|
      while line = f.gets
    	count += 1
    	if line =~ pattern
    	  puts "#{fn}:#{count}:#{line}"
    	end
      end
    end
  end
end

desc "Look for TODO and FIXME tags in the code"
task :todo do
  egrep(/#.*(FIXME|TODO)/)
end

desc "Print version information"
task :version do
  puts "%s %s" % [PKG_NAME, PKG_VERSION]
end
