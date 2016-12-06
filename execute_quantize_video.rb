#!/usr/bin/env ruby

load '/Users/paulosetinsky/magic_music/quantize_video.rb'
onset_times   = ARGV[0]
main_beat     = ARGV[1]
path_to_video = ARGV[2]
QuantizeVideo.new(onset_times, main_beat, path_to_video).execute
