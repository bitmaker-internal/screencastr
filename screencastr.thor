require 'thor'
require 'streamio-ffmpeg'
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
    ext = File.extname(out_file)[1..-1]

    `ffmpeg -f lavfi -i anullsrc=channel_layout=stereo:sample_rate=44100 \
    -loop 1 -i assets/1080-GA-Splash.png -f #{ext} -t 5 -r #{options[:framerate]} -pix_fmt yuv420p \
    -vf scale=#{options[:width]}x#{options[:height]} -map 0:a -map 1:v bumper.#{ext}`

    # Can't use invoke, because Thor won't allow the same task to be invoked twice
    begin
      s = Screencastr.new
      s.options = options
      s.concat("bumper.#{ext}", in_file, "bumper-tmp.#{ext}")
      s.concat("bumper-tmp.#{ext}", "bumper.#{ext}", out_file)
    ensure
      File.delete("bumper.#{ext}") if File.exists?("bumper.#{ext}")
      File.delete("bumper-tmp.#{ext}") if File.exists?("bumper-tmp.#{ext}")
    end
  end

  desc "add_watermark IN_FILE OUT_FILE", "Add watermark to video"
  def add_watermark(in_file, out_file)
    video = FFMPEG::Movie.new(in_file)

    ffmpeg_options = {
      watermark: "assets/160-GA-Bitmaker-Glyph-Black.png",
      watermark_filter: { position: "RB", padding_x: 30, padding_y: 30 },
      resolution: "#{options[:width]}x#{options[:height]}",
      frame_rate: options[:framerate]
    }

    video.transcode(out_file, ffmpeg_options)
  end

  desc "transcode IN_FILE OUT_FILE", "Transcode video file to mp4 format"
  def transcode(in_file, out_file)
    video = FFMPEG::Movie.new(in_file)

    ffmpeg_options = {
      resolution: "#{options[:width]}x#{options[:height]}",
      frame_rate: options[:framerate]
    }

    video.transcode(out_file, ffmpeg_options)
  end

  desc "concat FIRST_IN SECOND_IN OUT_FILE", "Concatenate two video files together"
  def concat(first_in, second_in, out_file)
    `ffmpeg -i #{first_in} -i #{second_in} \
    -filter_complex '[0:v] scale=#{options[:width]}x#{options[:height]} [vs0]; \
    [1:v] scale=#{options[:width]}x#{options[:height]} [vs1]; \
    [vs0][0:a][vs1][1:a] concat=n=2:v=1:a=1 [vout][aout]' \
    -r #{options[:framerate]} \
    -map '[vout]' -map '[aout]' #{out_file}`
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
