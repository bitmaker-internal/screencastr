require 'thor'
require 'pry'

require_relative 'helpers/file_helpers'

class Screencastr < Thor
  # Flow
  # 1. Open video
  # 2. Transcode video down to preset settings (Fast 1080p30 in Handbrake)
    # a. Can potentially use HandbrakeCLI (installed via `brew install handbrake`)
  # 3. Add watermark to video
  # 4. Encode bumper to same settings as video
  # 5. Concat bumper to beginning and end of video
  # 6. Upload video to S3
    # a. Will need a naming scheme to match the location properly

  class_option :framerate, aliases: "-f", desc: "Specify a framerate for OUT_FILE. Default: 30", type: :numeric, default: 30
  class_option :width, aliases: "-w", desc: "Specify the width in pixels for OUT_FILE. Default: 1920", type: :numeric, default: 1920
  class_option :height, aliases: "-h", desc: "Specify the height in pixels for OUT_FILE. Default: 1080", type: :numeric, default: 1080

  desc "add_bumpers IN_FILE OUT_FILE", "Add bumpers to video"
  def add_bumpers(in_file, out_file)
    ext = File.extname(out_file)[1..-1] # extension without the dot

    unless File.exist?("bumper.#{ext}")
      `ffmpeg -f lavfi -i anullsrc=channel_layout=stereo:sample_rate=44100 \
      -loop 1 -i assets/1080-GA-Splash.png -f #{ext} -t 5 -r #{options[:framerate]} -pix_fmt yuv420p \
      -vf scale=#{options[:width]}x#{options[:height]} -map 0:a -map 1:v bumper.#{ext}`
    end

    invoke :concat, ["bumper.#{ext}", in_file, "bumper.#{ext}", out_file]
  end

  desc "add_watermark IN_FILE OUT_FILE", "Add watermark to video"
  def add_watermark(in_file, out_file)
    `ffmpeg -y -i #{in_file} -i assets/160-GA-Bitmaker-Glyph-Black.png \
    -filter_complex 'scale=#{options[:width]}:#{options[:height]}:force_original_aspect_ratio=decrease,\
    pad=#{options[:width]}:#{options[:height]}:(ow-iw)/2:(oh-ih)/2,\
    overlay=x=main_w-overlay_w-30:y=main_h-overlay_h-30' \
    -r #{options[:framerate]} #{out_file}`
  end

  desc "transcode IN_FILE OUT_FILE", "Transcode video file to mp4 format"
  def transcode(in_file, out_file)
    `ffmpeg -y -i #{in_file} -r #{options[:framerate]} \
    -vf 'scale=#{options[:width]}:#{options[:height]}:force_original_aspect_ratio=decrease,\
    pad=#{options[:width]}:#{options[:height]}:(ow-iw)/2:(oh-ih)/2' #{out_file}`
  end

  desc "concat FIRST_IN SECOND_IN ... NTH_IN OUT_FILE", "Concatenate an arbitrary number of files together"
  def concat(*in_files, out_file)
    if in_files.length <= 1
      puts "concat requires at least 2 inputs"
      exit
    end

    inputs = []
    scale_filters = []
    streams = []

    in_files.each_with_index do |in_file, index|
      inputs << "-i #{in_file}"
      scale_filters << "[#{index}:v] scale=#{options[:width]}:#{options[:height]}:force_original_aspect_ratio=decrease,\
      pad=#{options[:width]}:#{options[:height]}:(ow-iw)/2:(oh-ih)/2 [vs#{index}];"
      streams << "[vs#{index}][#{index}:a]"
    end

    `ffmpeg #{inputs.join(" ")} -filter_complex '#{scale_filters.join(" ")}\
    #{streams.join} concat=n=#{streams.length}:v=1:a=1 [vout][aout]' \
    -r #{options[:framerate]} -map '[vout]' -map '[aout]' #{out_file}`
  end

  desc "brand IN_FILE OUT_FILE", "Transcode, watermark, and add bumpers, all in one command"
  def brand(in_file, out_file)
    ext = File.extname(out_file)[1..-1]
    invoke :add_watermark, [in_file, "watermarked.#{ext}"]
    begin
      invoke :add_bumpers, ["watermarked.#{ext}", out_file]
    ensure
      File.delete("watermarked.#{ext}") if File.exists?("watermarked.#{ext}")
    end
  end
end
