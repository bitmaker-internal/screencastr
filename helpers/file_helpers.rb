module FileHelpers
  def self.out_path(in_path)
    path = File.dirname(in_path)
    filename = File.basename(in_path, ".*")
    return "#{path}/#{filename}.mp4"
  end
end
