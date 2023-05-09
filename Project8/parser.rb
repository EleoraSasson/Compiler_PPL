class Parser
  attr_reader :current_command
  def initialize(path_to_vm_file)
    #if path_to_vm_file is a directory, get the vm file in it
    if File.directory?(path_to_vm_file)
      path_to_vm_file = Dir["#{path_to_vm_file}/*.vm"][0]
    end
    @vm_file = File.open(path_to_vm_file, "r")
  end

  def has_more_commands?
    !@vm_file.eof?
  end

  def advance
    @current_command = @vm_file.gets.gsub(/\/\.+|\n|\r/, "")
  end

  def [](index)
    split_command[index]
  end

  def line_number
    @vm_file.lineno
  end

  def file_name
    File.basename(@vm_file.path, ".vm")
  end

  def split_command
    @current_command.split
  end
end
