#!/usr/bin/env ruby

load '/Users/paulosetinsky/video_music/ruby/video_quantizer.rb'
onset_times   = ARGV[0]
path_to_video = ARGV[1]
path_to_song = ARGV[2]
song_tempo    = ARGV[3]

VideoQuantizer.new(onset_times, path_to_video, path_to_song, song_tempo).execute
