require 'thor'
require 'streamio-ffmpeg'
require 'pry'

require_relative 'helpers/file_helpers'
require_relative 'helpers/process_helpers'

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

  class_option :framerate, aliases: "-f", desc: "Specify a framerate for OUT_FILE, (eg. -f 30)", type: :numeric
  class_option :resolution, aliases: "-r", desc: "Specify a resolution for OUT_FILE, (eg. -r 1920x1080)", type: :string

  desc "add_bumpers IN_FILE OUT_FILE", "Add bumpers to video"
  def add_bumpers(in_file, out_file)
    ProcessHelpers.resolution_require_value(options[:resolution])
    ext = File.extname(out_file)[1..-1]

    `ffmpeg -f lavfi -i anullsrc=channel_layout=stereo:sample_rate=44100 \
    -loop 1 -i assets/1080-GA-Splash.png -f #{ext} -t 5 -r 30 -pix_fmt yuv420p \
    -vf scale=#{options[:resolution] || "1920x1080"} -map 0:a -map 1:v bumper.#{ext}`

    # Can't use invoke, because Thor won't allow the same task to be invoked twice
    s = Screencastr.new
    s.options = options
    begin
      s.concat("bumper.#{ext}", in_file, "bumper-tmp.#{ext}")
      s.concat("bumper-tmp.#{ext}", "bumper.#{ext}", out_file)
    ensure
      File.delete("bumper.#{ext}") if File.exists?("bumper.#{ext}")
      File.delete("bumper-tmp.#{ext}") if File.exists?("bumper-tmp.#{ext}")
    end
  end

  desc "add_watermark IN_FILE OUT_FILE", "Add watermark to video"
  def add_watermark(in_file, out_file)
    ProcessHelpers.resolution_require_value(options[:resolution])
    video = FFMPEG::Movie.new(in_file)

    ffmpeg_options = {
      watermark: "assets/160-GA-Bitmaker-Glyph-Black.png",
      watermark_filter: { position: "RB", padding_x: 30, padding_y: 30 },
      resolution: options[:resolution] || "1920x1080",
      frame_rate: options[:framerate] || 30
    }

    video.transcode(out_file, ffmpeg_options)
  end

  desc "transcode IN_FILE OUT_FILE", "Transcode video file to mp4 format"
  def transcode(in_file, out_file)
    ProcessHelpers.resolution_require_value(options[:resolution])
    video = FFMPEG::Movie.new(in_file)

    ffmpeg_options = {
      resolution: options[:resolution] || "1920x1080",
      frame_rate: options[:framerate] || 30
    }

    video.transcode(out_file, ffmpeg_options)
  end

  desc "concat FIRST_IN SECOND_IN OUT_FILE", "Concatenate two video files together"
  def concat(first_in, second_in, out_file)
    ProcessHelpers.resolution_require_value(options[:resolution])

    `ffmpeg -i #{first_in} -i #{second_in} \
    -filter_complex '[0:v] scale=#{options[:resolution] || "1920x1080"} [vs0]; \
    [1:v] scale=#{options[:resolution] || "1920x1080"} [vs1]; \
    [vs0][0:a][vs1][1:a] concat=n=2:v=1:a=1 [vout][aout]' \
    -r #{options[:framerate] || 30} \
    -map '[vout]' -map '[aout]' #{out_file}`
  end

  desc "brand IN_FILE OUT_FILE", "Transcode, watermark, and add bumpers, all in one command"
  def brand(in_file, out_file)
    ProcessHelpers.resolution_require_value(options[:resolution])
    ext = File.extname(out_file)[1..-1]
    invoke :add_watermark, [in_file, "watermarked.#{ext}"]
    begin
      invoke :add_bumpers, ["watermarked.#{ext}", out_file]
    ensure
      File.delete("watermarked.#{ext}") if File.exists?("watermarked.#{ext}")
    end
  end
end
