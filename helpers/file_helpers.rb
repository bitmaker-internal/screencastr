module FileHelpers
  def self.out_path(in_file, out_name)
    path = File.dirname(in_file)
    return "#{path}/dest/#{out_name}"
  end

  def self.generate_filename(files)
    return files.reduce("") {|acc, f| acc + File.basename(f, ".*") } + ".mp4"
  end
end
