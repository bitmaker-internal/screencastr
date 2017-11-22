module ProcessHelpers
  def self.resolution_require_value(option)
    if option == "resolution"
      puts "No value provided for option '--resolution'"
      exit
    end
  end
end
