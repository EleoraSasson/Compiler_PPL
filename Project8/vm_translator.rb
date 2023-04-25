# frozen_string_literal: true

class VMTranslator

  puts("Enter the path to a vm file, or to a directory containing vm files")
  path = gets.chomp

  if path.end_with?(".vm")
    # If path is a .vm file, create a CodeWriter instance and call create_output on it
    code_writer = CodeWriter.new(path)
    code_writer.create_output
=begin
  else
    # If path is not a .vm file, assume it is a directory and search for .vm files in it
    vm_files = Dir.glob(File.join(path, "*.vm"))
    if vm_files.empty?
      puts "No .vm files found in directory #{path}"
    else
      vm_files.each do |vm_file|
        code_writer = CodeWriter.new(vm_file)
        code_writer.create_output
      end
=end
    #end
  end
end
