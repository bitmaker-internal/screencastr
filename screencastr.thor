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

  desc "add_bumpers IN_FILE OUT_FILE", "Add bumpers to video"
  method_option :framerate, aliases: "-f", desc: "Specify a framerate for OUT_FILE, (eg. -f 30)", type: :numeric
  method_option :resolution, aliases: "-r", desc: "Specify a resolution for OUT_FILE, (eg. -r 1920x1080)"
  def add_bumpers(in_file, out_file)
    ProcessHelpers.resolution_require_value(options[:resolution])
    video = FFMPEG::Movie.new(in_file)
  end

  desc "add_watermark IN_FILE OUT_FILE", "Add watermark to video"
  method_option :framerate, aliases: "-f", desc: "Specify a framerate for OUT_FILE, (eg. -f 30)", type: :numeric
  method_option :resolution, aliases: "-r", desc: "Specify a resolution for OUT_FILE, (eg. -r 1920x1080)", type: :string
  def add_watermark(in_file, out_file)
    ProcessHelpers.resolution_require_value(options[:resolution])
    video = FFMPEG::Movie.new(in_file)

    options = {
      watermark: "assets/160-GA-Bitmaker-Glyph-Black.png",
      watermark_filter: { position: "RB", padding_x: 30, padding_y: 30 },
      resolution: options[:resolution] || "1920x1080",
      frame_rate: options[:framerate] || 30
    }

    video.transcode(out_file, options)
  end

  desc "transcode IN_FILE OUT_FILE", "Transcode video file to mp4 format"
  method_option :framerate, aliases: "-f", desc: "Specify a framerate for OUT_FILE, (eg. -f 30)", type: :numeric
  method_option :resolution, aliases: "-r", desc: "Specify a resolution for OUT_FILE, (eg. -r 1920x1080)", type: :string
  def transcode(in_file, out_file)
    ProcessHelpers.resolution_require_value(options[:resolution])
    video = FFMPEG::Movie.new(in_file)

    options = {
      resolution: options[:resolution] || "1920x1080",
      frame_rate: options[:framerate] || 30
    }

    video.transcode(out_file, options)
  end

  desc "concat FIRST_IN SECOND_IN OUT_FILE", "Concatenate two video files together"
  method_option :framerate, aliases: "-f", desc: "Specify a framerate for OUT_FILE, (eg. -f 30)", type: :numeric
  method_option :resolution, aliases: "-r", desc: "Specify a resolution for OUT_FILE, (eg. -r 1920x1080)", type: :string
  def concat(first_in, second_in, out_file)
    ProcessHelpers.resolution_require_value(options[:resolution])

    `ffmpeg -i #{first_in} -i #{second_in} \
    -filter_complex '[0:v] scale=#{options[:resolution] || "1920x1080"} [vs0]; \
    [1:v] scale=#{options[:resolution] || "1920x1080"} [vs1]; \
    [vs0][0:a][vs1][1:a] concat=n=2:v=1:a=1 [vout][aout]' \
    -r #{options[:framerate] || 30} \
    -map '[vout]' -map '[aout]' #{out_file}`
  end
end
