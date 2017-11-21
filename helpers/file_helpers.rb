module FileHelpers
  def self.out_path(in_path)
    path = File.dirname(in_path)
    filename = File.basename(in_path, ".*")
    return "#{path}/#{filename}.mp4"
  end

  def self.concat_out_path(first_in, second_in)
    path = File.dirname(first_in)
    first_filename = File.basename(first_in, ".*")
    second_filename = File.basename(second_in, ".*")

    return "#{path}/#{first_filename + second_filename}.mp4"
  end
end
