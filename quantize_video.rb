a = [6.44, 9.84, 13.08, 16.44, 19.8, 23.12, 29.8, 34.76, 38.12, 43.12, 49.72, 53.04, 56.4, 59.76, 63.08, 66.44, 73.16, 76.48, 78.48, 82.28, 86.56, 89.76, 93.16]
b = [3.4, 6.8, 10.2, 13.6, 17, 20.4, 23.8, 27.2, 30.6, 34, 37.4, 40.8, 44.2, 47.6, 51, 54.4, 57.8, 61.2, 64.6, 68, 71.4, 74.8, 78.2, 81.6, 85, 88.4, 91.8]

onsets_hsh = {}
a.each { |num| onsets_hsh[num] = nil }

onsets_hsh.each do |k,v|
  diffs = {}

  b.each do |comparison|
    diff = (comparison - k)
    sign = diff > 0 ? 1 : -1
    diffs[diff.abs] = sign
  end

  min = diffs.min_by { |i,j| i }
  key = min[0]
  val = min[1]

  if diffs[key]
    onsets_hsh[k] = k + (key * val)
  end
end

h = Hash.new(0)
onsets_hsh.each  { |k,v| h[v] += 1 }
dupes = h.select { |k,v| v > 1 }

dupes.each do |k,v|
  min = nil
  min_key = nil

  onsets_hsh.select do |i,j|
    if j == k
      diff = (i - j).abs
      if !min || diff < min
        min = diff
        min_key = i
      end
    end
  end

  onsets_hsh = onsets_hsh.delete_if { |i,j| i != min_key && k == j }
end

onsets_hsh[0] = 0
onsets_hsh = onsets_hsh.sort.to_h

last_hsh = nil
speed_multiples = []
onsets_hsh.each_with_index do |hsh,i|
  if last_hsh && i > 0
    diff_a = (hsh[0] - last_hsh[0]).round(2)
    diff_b = (hsh[1] - last_hsh[1]).round(2)
    speed_mult = (diff_b - diff_a).round(2)
    speed_multiples << speed_mult
  end
  last_hsh = hsh
end

onsets_hsh.delete_if { |k,_| k == 0 }
speed_multiples_hsh = {}
onsets_hsh.each_with_index { |k,i| speed_multiples_hsh[k[0]] = speed_multiples[i] }

timestamp = Time.now.to_i
last_mult = nil
speed_multiples_hsh.each_with_index do |k,i|
  mult = k[1]

  duration =
    if i > 0
      k[0] - last_mult[0]
    else
      k[0]
    end

  duration = duration.round(2)

  extraction_start_time =
    if i > 0
      if last_mult[0] < 10
        "00:00:0#{last_mult[0]}"
      elsif last_mult[0] < 60
        "00:00:#{last_mult[0]}"
      else
        mm = (last_mult[0] / 60).truncate
        ss = (last_mult[0] % 60).round(2)
        "00:0#{mm}:#{ss}"
      end
    else
      "00:00:00"
    end

  mezzanine_segment_file_name = "./videos/mezzanine_segment_#{i}.mp4"
  last_mult = k

  # puts extraction_start_time
  # puts duration
  # puts duration
  # puts mezzanine_segment_file_name
  # puts ''

  # `ffmpeg -i ./videos/humanflight.mp4 -ss #{extraction_start_time} -t #{duration} #{mezzanine_segment_file_name}`
  # `ffmpeg -i #{mezzanine_segment_file_name} -filter:v \"setpts=#{mult}*PTS\" -an ./videos/output_segment_#{i}.mp4`

  puts "ffmpeg -i #{mezzanine_segment_file_name} -filter:v \"setpts=#{mult}*PTS\" -an ./videos/output_segment_#{i}.mp4"
end

# `ffmpeg -f concat -safe 0 -i <(for f in ./videos/output_segment_*.mp4; do echo "file '$PWD/$f'"; done) -c copy ./videos/output.mp4`
