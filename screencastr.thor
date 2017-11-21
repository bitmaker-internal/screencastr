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

  desc "add_bumpers VIDEO_PATH", "Add bumpers to video"
  def add_bumpers(video_path)
    video = FFMPEG::Movie.new(video_path)
  end

  desc "add_watermark VIDEO_PATH", "Add watermark to video"
  def add_watermark(video_path)
    video = FFMPEG::Movie.new(video_path)

    options = {
      watermark: "assets/160-GA-Bitmaker-Glyph-Black.png", resolution: video.resolution,
      watermark_filter: { position: "RB", padding_x: 30, padding_y: 30 }
    }

    video.transcode(FileHelpers.out_path(video_path), options)
  end

  desc "transcode VIDEO_PATH", "Transcode video file to mp4 format"
  def transcode(video_path)
    video = FFMPEG::Movie.new(video_path)
    video.transcode(FileHelpers.out_path(video_path))
  end
end
