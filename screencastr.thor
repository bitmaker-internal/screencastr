require 'thor'
require 'streamio-ffmpeg'
require 'pry'

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
  end

  desc "transcode VIDEO_PATH", "Transcode video file to mp4 format"
  def transcode(video_path)
    video = FFMPEG::Movie.new(video_path)
    path_array = video_path.split('/')
    filename = path_array.pop.split('.').first
    path = path_array.join('/')
    video.transcode("#{path}/#{filename}.mp4")
  end
end
