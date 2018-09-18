# Screencastr

This is a Thor CLI that uses [`ffmpeg`](https://www.ffmpeg.org/) to transcode screencasts and upload them to S3 automatically.

Ideally this task will kick off automatically when a new video file is dropped into a watched folder.

## Prerequisites

You'll need to install the following CLI tools on the system that you're running this task on:

+ ffmpeg (`brew install ffmpeg`)

You'll also need to configure the following environment variables:

+ `AWS_ACCESS_KEY_ID` : Your access key ID for AWS
+ `AWS_SECRET_ACCESS_KEY` : Your secret access key for AWS
+ `AWS_REGION` : The AWS region, should probably be `us-east-1`
+ `BITMAKER_S3_BUCKET` : Optional, otherwise the bucket is set to `bitmakerhq`

## Instructions/Commands

Run `bundle install` to install the requirements.

Screencastr uses Thor as a task runner. To see the commands available, run

```
thor -T
```

Screencastr is capable of transcoding video formats, watermarking videos, adding a branded intro/outro, concatenating two or more videos together, and uploading videos to S3.

The more common workflow is:
+ `thor screencastr:concat` (optional; use if you have multiple pieces of video)
+ `thor screencastr:brand` (adds watermark, bumpers, etc.)
+ `thor screencastr:upload` (actually uploads the video)

### `thor screencastr:concat`

Used to combine two or more videos together into a single output video. When calling it, give it any number of input files, followed by an output file at the end. A typical use case where we're combining two videos on the Desktop into one output looks something like this:

```
thor screencastr:concat ~/Desktop/part1.mov ~/Desktop/part2.mov ~/Desktop/output.mp4
```

**Note** that `concat` does not brand the video or upload the video to S3. You can run `brand` after the fact for that.

### `thor screencastr:brand`

Used to convert a video to typically a 1080p mp4 file, brand it with a watermark and intro/outro, and optionally upload it to S3.

Run `thor screencastr:brand IN_FILE OUT_FILE`, where `IN_FILE` is the file you'd like to brand (as well as its filepath), and `OUT_FILE` is what you will save the output as. Screencastr will attempt to convert to whatever file extension is attached to `OUT_FILE`, but currently only mp4 has been tested. A typical use case, where we're branding/converting a file on the Desktop, and saving the new file to the Desktop, looks like this:

```
thor screencastr:brand ~/Desktop/example.mov ~/Desktop/example.mp4
```

If you add the `-u` flag to `brand`, the file will be uploaded to S3 as well. Screencastr will ask you for the course and cohort if you elect to upload the file this way, to determine where it should be saved on S3, and will spit out a URL at the end. Here's that same example as above, but with the upload flag:

```
thor screencastr:brand -u ~/Desktop/example.mov ~/Desktop/example.mp4
```

### `thor screencastr:upload`

Used to upload a given video to AWS in a specific place. For example, for the August 2018 web dev cohort:

    thor screencastr:upload path/to/video lessons/web-development/2018-08-team-bender/w1d1-os-and-git-fundamentals.mp4

This will place the video in the given folder. Please specify the correct folder for your screencasts.

## Transcoding Flow

The process will be something like the following when done:

1. Open video
2. Transcode video down to preset settings
3. Add watermark to video
4. Encode bumper to same settings as video
  - Optionally, only if bumper video doesn't already exist on file system
5. Concat bumper to beginning and end of video
6. Upload video to S3
  - Will need a naming scheme to match the location properly

## Super Stretch Ideas

- Package this so that it's simple for less technical people to run locally on their machines
  - No clue what that would entail
  - Maybe a rudimentary Electron app???
