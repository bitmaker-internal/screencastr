# Screencastr

This is a Thor task that uses [`ffmpeg`](https://www.ffmpeg.org/) to transcode screencasts and upload them to S3 automatically.

Ideally this task will kick off automatically when a new video file is dropped into a watched folder.

This project uses the [`streamio-ffmpeg`](https://github.com/streamio/streamio-ffmpeg) Ruby gem which wraps the ffmpeg library.

## Prerequisites

You'll need to install the following cli tools on the system that you're running this task on:

- ffmpeg (`brew install ffmpeg`)
- HandbrakeCLI (optionally) (`brew install handbrake`)


## Transcoding Flow

The process will be something like the following when done:

1. Open video
2. Transcode video down to preset settings (Fast 1080p30 in Handbrake)
  - Can potentially use [HandbrakeCLI](https://handbrake.fr/docs/en/latest/cli/cli-guide.html) (installed via `brew install handbrake`)
3. Add watermark to video
4. Encode bumper to same settings as video
5. Concat bumper to beginning and end of video
6. Upload video to S3
  - Will need a naming scheme to match the location properly
