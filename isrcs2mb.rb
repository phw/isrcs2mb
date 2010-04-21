#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
#
# Simple command line tool to submit ISRCs from a CD to MusicBrainz.
# For usage details run "ruby submitisrcs.rb --help".
#
# Requirements:
# * Ruby
# * RBrainz and MB-DiscID (http://rbrainz.rubyforge.org)
# * icedax
#
# Copyright (C) 2009 Philipp Wolfer <ph.wolfer@googlemail.com>
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
# 3. Neither the name of the RBrainz project nor the names of the
#    contributors may be used to endorse or promote products derived from
#    this software without specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
# TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
# PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
# LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
# NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# Load RBrainz and include the MusicBrainz namespace.
require 'rbrainz'
require 'mb-discid'
require 'optparse'
include MusicBrainz

ICEDAX = (`which icedax`).strip
ISRC_COMMAND = "%s -device %s --info-only --no-infofile -v trackid 2>&1"

STDOUT.sync = true

def read_isrcs(device)
    isrcs = []
    IO.popen(ISRC_COMMAND % [ICEDAX, device]) do |io|
      io.each_line do |line|
        if line =~ /T:\s+(\d+)\s+ISRC:\s+([A-Z]{2}-?\w{3}-?\d{2}-?\d{5})$/
          isrcs[$1.to_i - 1] = Model::ISRC.parse($2)
        end
      end
    end
    return isrcs
end

device = DiscID.default_device
username = ''
password = ''

# Read the command line parameters
opts = OptionParser.new do |o|
    o.banner = "Usage: submit_isrcs [options]"
    o.on( "-r", "--device DEVICE", "CD device." ) do |r|
        device = r
    end
    o.on( "-u", "--username USERNAME", "MusicBrainz username." ) do |u|
        username = u
    end
    o.on( "-p", "--password PASSWORD", "MusicBrainz password." ) do |p|
        password = p
    end
    o.on("-h", "--help", "This help message." ) do
        puts o
        exit
    end
end

opts.parse!(ARGV)

if ICEDAX.empty?
    puts "icedax not found. Please make sure that you have installed icedax."
    exit 1
end

# Read the disc ID
begin
    disc = MusicBrainz::DiscID.new
    disc.read(device)
    puts "Disc ID: %s" % disc.id
rescue Exception => e
    puts "Can not read disc in %s" % device
    exit 1
end

print "Reading ISRCs from %s..." % device
isrcs = read_isrcs(device)
puts " %d ISRCs found." % isrcs.size

if isrcs.size == 0
    puts "No ISRCs found, exiting."
    exit 1
end

# Set the authentication for the webservice.
ws = Webservice::Webservice.new(
   :host     => 'musicbrainz.org',
   :username => username,
   :password => password
)

# Create a new Query object which will provide
# us an interface to the MusicBrainz web service.
query = Webservice::Query.new(ws, :client_id => 'RBrainz ISRC submission ' + RBRAINZ_VERSION)
releases = query.get_releases(:discid => disc)

# Show all releases to the user
for i in 0...releases.size do
  release = releases[i].entity
  puts "%2.2d: '%s' by '%s' (%s)" % [i+1, release, release.artist, release.id.uuid]
end

# Let the user select one release
if releases.size == 0
    puts "No release found. Submit: %s" % disc.submission_url
    exit 1
elsif releases.size > 1
    begin
      print "Select release: "
      release_no = STDIN.gets.strip.to_i
    end while release_no <= 0 or release_no > releases.size
else
    release_no = 1
end

# Create a mapping between track IDs and ISRCs
release = releases[release_no-1].entity
track_isrc_map = []
for i in 0...release.tracks.size do
  track = release.tracks[i]
  isrc = isrcs[i]
  track_isrc_map << [track.id.uuid, isrc.to_str] unless isrc.nil?
end

# Submit the ISRCs for some tracks.
print "Submitting ISRCs for %d tracks to MusicBrainz..." % track_isrc_map.size
begin
  query.submit_isrcs(track_isrc_map)
rescue Webservice::AuthenticationError => e
  puts "Wrong username or password."
  exit 1
end
puts " done."
exit