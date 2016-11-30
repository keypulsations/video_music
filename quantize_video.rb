class QuantizeVideo

  def initialize(onset_times, best_approx_beat, video_duration_seconds)
    @onsets_hsh = {}
    @perfect_beat = []

    num_perfect_beats =
      (video_duration_seconds.to_f / best_approx_beat).round + 1

    num_perfect_beats.times do |i|
      @perfect_beat << (best_approx_beat * i).round(2)
    end

    onset_times.each { |num| @onsets_hsh[num] = nil }
  end

  def execute
    determine_quantization_diffs
    remove_dupe_quantized_onset_times
    set_speed_multiples
    remove_zero_onset_time
    set_speed_multiples_hash
    create_outputs
  end

  def determine_quantization_diffs
    # for each onset time...
    @onsets_hsh.each do |original_onset_time,_|
      quantization_diffs = {}

      # compare each onset time to each perfect beat based on best_approx_beat
      @perfect_beat.each do |perfect_beat|
        quantization_diff = (perfect_beat - original_onset_time).abs
        sign = quantization_diff > 0 ? 1 : -1
        quantization_diffs[quantization_diff] = sign
      end

      # find closest perfect beat to onset time
      smallest_quantization_diff_with_sign =
        quantization_diffs.min_by { |diff,sign| diff }

      smallest_quantization_diff_abs = smallest_quantization_diff_with_sign[0]
      sign = smallest_quantization_diff_with_sign[1]

      quantized_onset_time =
        original_onset_time + (smallest_quantization_diff_abs * sign)

      if quantization_diffs[smallest_quantization_diff_abs]
        @onsets_hsh[original_onset_time] = quantized_onset_time
      end
    end
  end

  def dupe_counter_hash
    counter_hash = Hash.new(0)
    @onsets_hsh.each do |original_onset_time,quantized_onset_time|
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

      @onsets_hsh.select do |original_onset_time,quantized_onset_time|
        if quantized_onset_time == dupe_quantized_onset_time
          quantization_diff = (original_onset_time - quantized_onset_time).abs
          if !min_quantization_diff || quantization_diff < min_quantization_diff
            min_quantization_diff = quantization_diff
            closest_original_onset_time = original_onset_time
          end
        end
      end

      @onsets_hsh =
        @onsets_hsh.delete_if do |original_onset_time,quantized_onset_time|
          original_onset_time != closest_original_onset_time &&
          quantized_onset_time == dupe_quantized_onset_time
        end
    end
  end

  def set_speed_multiples
    @speed_multiples = []
    @onsets_hsh[0] = 0
    @onsets_hsh = @onsets_hsh.sort.to_h

    last_onsets_hash = nil
    @onsets_hsh.each_with_index do |onsets_hash,idx|
      if last_onsets_hash && idx > 0

        original_onset_time_ratio  = (onsets_hash[0] - last_onsets_hash[0])
        original_onset_time_ratio  = original_onset_time_ratio.round(2)

        quantized_onset_time_ratio = (onsets_hash[1] - last_onsets_hash[1])
        quantized_onset_time_ratio = quantized_onset_time_ratio.round(2)

        speed_mult =
          (quantized_onset_time_ratio - original_onset_time_ratio).round(2)

        @speed_multiples << speed_mult
      end
      last_onsets_hash = onsets_hash
    end
  end

  def remove_zero_onset_time
    @onsets_hsh.delete_if { |original_onset_time,_| original_onset_time == 0 }
  end

  def set_speed_multiples_hash
    @speed_multiples_hash = {}
    @onsets_hsh.each_with_index do |onsets_hash,idx|
      original_onset_time = onsets_hash[0]
      speed_multiples_hash[original_onset_time] = @speed_multiples[idx]
    end
  end


  def create_outputs
    last_onset_and_speed_multiple = nil
    @speed_multiples_hash.each_with_index do |onset_and_speed_multiple,idx|
      onset = onset_and_speed_multiple[0]
      mult = onset_and_speed_multiple[1]

      last_onset_and_speed_multiple = onset_and_speed_multiple

      extraction_start_time = extraction_start_time(onset, idx)
      duration = duration(onset, last_onset_and_speed_multiple)

      mezzanine_segment_file_name =
        "./videos/mezzanine_segment_#{idx}.mp4"

      extract_scene_segment(extraction_start_time, duration, segment_idx)
      mezzanine_segment_file_name =
        "./videos/mezzanine_segment_#{segment_idx}.mp4"

      generate_altered_mp4(mezzanine_segment_file_name, idx)
      concatenate_segments
    end
  end

  def duration(onset, last_onset, idx)
    dur = onset[0]

    if idx > 0
      dur -= last_onset[0]
    end

    dur.round(2)
  end

  def extraction_start_time(onset,idx)
    if idx > 0
      if onset < 10
        "00:00:0#{last_mult[0]}"
      elsif onset < 60
        "00:00:#{last_mult[0]}"
      else
        mm = (onset / 60).truncate
        ss = (onset % 60).round(2)
        "00:0#{mm}:#{ss}"
      end
    else
      "00:00:00"
    end
  end

  def mezzanine_segment_file_name(idx)
    "./videos/mezzanine_segment_#{segment_idx}.mp4"
  end

  def extract_scene_segment(extraction_start_time, duration, segment_idx)
    mezzanine_segment_file_name = mezzanine_segment_file_name(segment_idx)

    `ffmpeg -i ./videos/humanflight.mp4 -ss #{extraction_start_time} -t \
    #{duration} #{mezzanine_segment_file_name}`
  end

  def generate_altered_mp4(mezzanine_segment_file_name, segment_idx)
    mezzanine_segment_file_name = mezzanine_segment_file_name(segment_idx)

    `ffmpeg -i #{mezzanine_segment_file_name} -filter:v \"setpts=#{(1.0-mult).\
      round(2)}*PTS\" -an ./videos/output_segment_#{segment_idx}.mp4`
  end

  def concatenate_segments
    `ffmpeg -f concat -safe 0 -i <(for f in ./videos/output_segment_*.mp4; \
    do echo "file '$PWD/$f'"; done) -c copy ./videos/output.mp4`
  end

end
