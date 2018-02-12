require 'listen'

class Monitor

  def initialize(screencastr)
    @screencastr = screencastr
    monitor
  end

  def monitor
    monitor_dir = "#{Dir.pwd}/uploads/pending"
    puts "Monitoring #{monitor_dir}"

    listener = Listen.to(monitor_dir) do |modified, added, removed|
      brand_and_upload(added) if added.any?
      puts "File Modified: #{modified}" if modified.any?
      puts "File Removed: #{removed}" if removed.any?
    end
    listener.start
    sleep
  end

  def brand_and_upload(files)
    files.each do |file_path|
      file_extension = File.extname(file_path)
      return unless file_extension == '.mov'

      file_dirname   = File.dirname(file_path)
      file_basename  = File.basename(file_path, file_extension)
      new_file_name  = file_basename + '.mp4'
      destination    = File.join([Dir.pwd, 'uploads', 'processing', new_file_name])

      puts "Branding File"
      puts "Source: #{file_path}"
      puts "Destination: #{destination}"

      @screencastr.brand(file_path, destination)

      upload(destination)
    end
  end

  def upload(file_path)
    file_basename  = File.basename(file_path)
    s3_destination = File.join('to-be-filed', file_basename)

    puts "Uploading File"
    puts "Source: #{file_path}"
    puts "Destination: #{s3_destination}"

    @screencastr.upload(file_path, s3_destination)
  end

end
