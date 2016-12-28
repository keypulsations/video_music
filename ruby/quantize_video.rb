class QuantizeVideo

  def initialize(onset_times=nil, main_beat=nil, path_to_video=nil)
    @extract_scene_segments_command = ""
    @generate_altered_mp4s_command = ""

    @onsets_hsh = {}
    @main_beat = main_beat.to_f
    @path_to_video = path_to_video

    @perfect_beats = []
    num_perfect_beats = (video_duration_seconds.to_f / @main_beat).round + 1
    num_perfect_beats.times do |i|
      @perfect_beats << (@main_beat * i).round(2)
    end

    onset_times = onset_times.split(",").map(&:to_f)
    onset_times.each { |k,_| @onsets_hsh[k] = nil }
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

  def video_duration_seconds
    `ffprobe -i #{@path_to_video} -show_format -v quiet | sed -n 's/duration=//p'`
  end

  def determine_quantization_diffs
    # for each onset time...
    @onsets_hsh.each do |original_onset_time,_|
      quantization_diffs = {}

      # compare the onset time to each perfect beat based on best_approx_beat
      @perfect_beats.each do |perfect_beat|
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
        @onsets_hsh[original_onset_time] = quantized_onset_time
      end
    end
  end

  def dupe_counter_hash
    counter_hash = Hash.new(0)
    @onsets_hsh.each do |_,quantized_onset_time|
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

      @onsets_hsh.each do |original_onset_time,quantized_onset_time|
        if quantized_onset_time == dupe_quantized_onset_time
          quantization_diff = (original_onset_time - quantized_onset_time).abs
          if min_quantization_diff.nil? || quantization_diff < min_quantization_diff
            min_quantization_diff = quantization_diff
            closest_original_onset_time = original_onset_time
          end
        end
      end

      @onsets_hsh.delete_if do |original_onset_time,quantized_onset_time|
        original_onset_time != closest_original_onset_time &&
        quantized_onset_time == dupe_quantized_onset_time
      end
    end
  end

  def set_speed_multiples
    @speed_multiples = []
    @onsets_hsh[0.0] = 0.0
    @onsets_hsh = @onsets_hsh.sort.to_h

    last_onset_pair = nil
    @onsets_hsh.each_with_index do |current_onset_pair,idx|
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
    @onsets_hsh.delete_if { |original_onset_time,_| original_onset_time == 0 }
  end

  def set_speed_multiples_hash
    @speed_multiples_hash = {}
    @onsets_hsh.each_with_index do |onsets_hash,idx|
      original_onset_time = onsets_hash[0]
      @speed_multiples_hash[original_onset_time] = @speed_multiples[idx]
    end
  end

  def write_output_commands
    last_onset = nil
    @speed_multiples_hash.each_with_index do |onset_and_speed_multiple,idx|
      onset = onset_and_speed_multiple[0]
      mult  = onset_and_speed_multiple[1]
      extraction_start_time = extraction_start_time(last_onset, idx)
      duration = duration(onset, last_onset, idx)
      last_onset = onset
      write_extracted_scene_segment(extraction_start_time, duration, idx)
      write_generate_altered_mp4(mult, idx)
    end
  end

  def write_quantized_onsets
    quantized_onset_times_str = ''
    @onsets_hsh.each { |_,v| quantized_onset_times_str << "#{v}," }
    file_path = "/Users/paulosetinsky/magic_music/video_onset_times/quantized_onset_times.txt"
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
    "/Users/paulosetinsky/magic_music/videos/mezzanine_segment_#{segment_idx}.mp4"
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
    command = "ffmpeg -i #{@path_to_video} -ss #{extraction_start_time} -t #{duration} #{file_name} && "
    @extract_scene_segments_command += command
  end

  def write_generate_altered_mp4(mult, segment_idx)
    file_name = mezzanine_segment_file_name(segment_idx)
    segment_idx = stringify_segment_idx(segment_idx)
    command = "ffmpeg -i #{file_name} -filter:v \"setpts=#{(mult)}*PTS\" -an \
      /Users/paulosetinsky/magic_music/videos/output_segment_#{segment_idx}.mp4 && "
    @generate_altered_mp4s_command += command
  end

  def run_output_commands
    extract_segments = @extract_scene_segments_command
    alter_segments   = @generate_altered_mp4s_command

    extract_segments = extract_segments[0,extract_segments.rindex("&&")].strip
    alter_segments   = alter_segments[0,alter_segments.rindex("&&")].strip

    `#{extract_segments} && #{alter_segments} && #{concatenate_segments}`
  end

  def concatenate_segments
    "for f in videos/output_segment_*.mp4; do echo file $PWD/$f; done > videos/file_list.txt && \
    ffmpeg -f concat -safe 0 -i videos/file_list.txt -c copy videos/output.mp4"
  end

end
