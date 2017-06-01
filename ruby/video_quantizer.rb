require 'pry'
require 'csv'

class VideoQuantizer

  MINUTE_SECONDS = 60.0

  attr_accessor :extract_scene_segments_command, :generate_altered_mp4s_command,
                :onsets_hash, :perfect_beats, :path_to_video, :speed_multiples,
                :speed_multiples_hash, :path_to_song, :path

  def initialize(onset_times, path_to_video, path_to_song, song_tempo=140)
    main_beat = song_tempo.to_f/MINUTE_SECONDS

    @extract_scene_segments_command = ""
    @generate_altered_mp4s_command = ""
    @onsets_hash = {}
    @path_to_video = path_to_video
    @path_to_song = path_to_song
    @perfect_beats = []
    @path = `pwd`.gsub("\n","")

    num_perfect_beats = (video_duration_seconds / main_beat).round + 2
    num_perfect_beats.times do |i|
      perfect_beats << (main_beat * i).round(2)
    end

    onset_times = onset_times.split(",").map(&:to_f)
    onset_times.each { |k,_| onsets_hash[k] = nil }
  end

  def execute
    determine_quantization_diffs
    remove_dupe_quantized_onset_times
    set_speed_multiples
    remove_zero_onset_time
    set_speed_multiples_hash
    write_output_commands
    write_quantized_onsets
    run_output_commands
  end

private

  def video_duration_seconds
    `ffprobe -i #{path_to_video} -show_format -v quiet | sed -n 's/duration=//p'`.to_f
  end

  def determine_quantization_diffs
    # for each onset time...
    onsets_hash.each do |original_onset_time,_|
      quantization_diffs = {}

      # compare the onset time to each perfect beat based on best_approx_beat
      perfect_beats.each do |perfect_beat|
        quantization_diff = (perfect_beat - original_onset_time)
        sign = quantization_diff > 0 ? 1 : -1
        quantization_diffs[quantization_diff.abs] = sign
      end

      # find closest perfect beat to onset time
      smallest_quantization_diff_with_sign = quantization_diffs.min_by { |diff,sign| diff }
      smallest_quantization_diff = smallest_quantization_diff_with_sign[0]
      sign = smallest_quantization_diff_with_sign[1]

      quantized_onset_time = original_onset_time + (smallest_quantization_diff * sign)

      if quantization_diffs[smallest_quantization_diff]
        onsets_hash[original_onset_time] = quantized_onset_time
      end
    end
  end

  def dupe_counter_hash
    counter_hash = Hash.new(0)
    onsets_hash.each do |_,quantized_onset_time|
      counter_hash[quantized_onset_time] += 1
    end
    counter_hash
  end

  def dupe_quantized_onset_times
    dupe_counter_hash.select { |quantized_onset_time,count| count > 1 }
  end

  def remove_dupe_quantized_onset_times
    dupe_quantized_onset_times.each do |dupe_quantized_onset_time,_|

      min_quantization_diff = nil
      closest_original_onset_time = nil

      onsets_hash.each do |original_onset_time,quantized_onset_time|
        if quantized_onset_time == dupe_quantized_onset_time
          quantization_diff = (original_onset_time - quantized_onset_time).abs
          if min_quantization_diff.nil? || quantization_diff < min_quantization_diff
            min_quantization_diff = quantization_diff
            closest_original_onset_time = original_onset_time
          end
        end
      end

      onsets_hash.delete_if do |original_onset_time,quantized_onset_time|
        original_onset_time != closest_original_onset_time &&
          quantized_onset_time == dupe_quantized_onset_time
      end
    end
  end

  def set_speed_multiples
    onsets_hash = self.onsets_hash

    @speed_multiples = []
    onsets_hash[0.0] = 0.0
    onsets_hash = onsets_hash.sort.to_h

    last_onset_pair = nil
    onsets_hash.each_with_index do |current_onset_pair,idx|
      if idx > 0
        current_original_onset = current_onset_pair[0]
        last_original_onset = last_onset_pair[0]
        current_quantized_onset = current_onset_pair[1]
        last_quantized_onset = last_onset_pair[1]

        original_segment_duration  = (current_original_onset - last_original_onset)
        quantized_segment_duration = (current_quantized_onset - last_quantized_onset)

        speed_mult = (quantized_segment_duration / original_segment_duration)
        @speed_multiples << speed_mult
      end
      last_onset_pair = current_onset_pair
    end
  end

  def remove_zero_onset_time
    onsets_hash.delete_if { |original_onset_time,_| original_onset_time == 0 }
  end

  def set_speed_multiples_hash
    @speed_multiples_hash = {}
    onsets_hash.each_with_index do |onsets_hash,idx|
      original_onset_time = onsets_hash[0]
      @speed_multiples_hash[original_onset_time] = speed_multiples[idx]
    end
  end

  def write_output_commands
    last_onset = nil
    last_idx = nil

    speed_multiples_hash.each_with_index do |onset_and_speed_multiple,idx|
      onset = onset_and_speed_multiple[0]
      mult  = onset_and_speed_multiple[1]
      extraction_start_time = extraction_start_time(last_onset, idx)
      duration = duration(onset, last_onset, idx)

      last_onset = onset
      last_idx = idx

      write_extracted_scene_segment(extraction_start_time, duration, idx)
      write_generate_altered_mp4(mult, idx)
    end

    current_idx = last_idx + 1
    last_segment_start_time = extraction_start_time(last_onset, current_idx)
    write_extracted_scene_segment(last_segment_start_time, video_duration_seconds - last_onset, current_idx)

    # mult can be 1 here because we do not need to alter the speed for the last segment
    write_generate_altered_mp4(1, last_idx + 1)
  end

  def write_quantized_onsets
    quantized_onset_times_str = ''
    onsets_hash.each { |_,v| quantized_onset_times_str << "#{v}," }
    file_path = "video_onset_times/quantized_onset_times.txt"
    quantized_onset_times_str = quantized_onset_times_str.chomp(',')
    File.open(file_path, 'w') { |file| file.write(quantized_onset_times_str) }
  end

  def duration(onset, last_onset=nil, idx)
    dur = onset

    if idx > 0
      dur -= last_onset
    end

    dur
  end

  def extraction_start_time(last_onset,idx)
    if idx > 0
      if last_onset < 10
        "00:00:0#{last_onset}"
      elsif last_onset < 60
        "00:00:#{last_onset}"
      else
        mm = (last_onset / 60).truncate
        ss = (last_onset % 60)
        "00:0#{mm}:#{ss}"
      end
    else
      "00:00:00"
    end
  end

  def mezzanine_segment_file_name(segment_idx)
    segment_idx = stringify_segment_idx(segment_idx)
    "#{path}/videos/mezzanine_segment_#{segment_idx}.mp4".gsub("\n","")
  end

  def stringify_segment_idx(segment_idx)
    if segment_idx < 10
      "0" + segment_idx.to_s
    else
      segment_idx.to_s
    end
  end

  def write_extracted_scene_segment(extraction_start_time, duration, segment_idx)
    file_name = mezzanine_segment_file_name(segment_idx)
    command = "ffmpeg -i #{path_to_video} -ss #{extraction_start_time} -t #{duration} #{file_name} && "
    self.extract_scene_segments_command += command
  end

  def write_generate_altered_mp4(mult, segment_idx)
    file_name = mezzanine_segment_file_name(segment_idx)
    output_segment_path = "#{path}/videos/output_segment_#{segment_idx}.mp4".gsub("\n","")
    segment_idx = stringify_segment_idx(segment_idx)
    command = "ffmpeg -i #{file_name} -filter:v \"setpts=#{(mult)}*PTS\" -an \ #{output_segment_path} && "
    self.generate_altered_mp4s_command += command
  end

  def run_output_commands
    extract_segments = extract_scene_segments_command
    alter_segments   = generate_altered_mp4s_command

    extract_segments = extract_segments[0,extract_segments.rindex("&&")].strip
    alter_segments   = alter_segments[0,alter_segments.rindex("&&")].strip

    if `#{get_song_beats}`
    `#{chop_song} &&
     #{extract_segments} &&
     #{alter_segments} &&
     #{concatenate_segments} &&
     #{add_song} &&
     #{play_video}`
    end

  end

  def concatenate_segments
    "for f in videos/output_segment_*.mp4; do echo file $PWD/$f; done > videos/file_list.txt && \
    ffmpeg -f concat -safe 0 -i videos/file_list.txt -c copy videos/output.mp4"
  end

  def add_song
    "ffmpeg -i videos/output.mp4 -i #{path_to_chopped_song} -c:v copy -map 0:v:0 -map 1:a:0 -shortest videos/output_with_music.mp4"
  end

  def play_video
    "ffplay -i -autoexit -showmode 0 videos/output_with_music.mp4"
  end

  def get_song_beats
    "#{path}/librosa/examples/beat_tracker.py #{path_to_song} #{beat_output_csv_path}"
  end

  def beat_output_csv_path
    path_to_song.gsub('.mp3', '_beats.csv')
  end

  def song_beat_first_onset
    `touch #{beat_output_csv_path}`
    csv = CSV.open(beat_output_csv_path)
    beat_onsets = []
    csv.each { |v| beat_onsets << v }
    beat_onsets = beat_onsets.flatten.map(&:to_f)
    durations = []

    beat_onsets.each_with_index do |beat_onset, index|
      if index > 0
        durations << (beat_onsets[index] - beat_onsets[index-1]).round(3)
      end
    end

    freq = durations.inject(Hash.new(0)) { |h,v| h[v] += 1; h }
    mode = durations.max_by { |v| freq[v] }

    first_beat_onset_index = durations.index(mode)

    beat_onsets[first_beat_onset_index]
  end

  def chop_song
    "ffmpeg -ss #{song_beat_first_onset} -i #{path_to_song} -acodec copy #{path_to_chopped_song}"
  end

  def path_to_chopped_song
    path_to_song.gsub('.mp3', '_chopped.mp3')
  end

end
