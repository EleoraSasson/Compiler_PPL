# frozen_string_literal: true

require_relative 'code_writer'
class VMTranslator

  puts("Enter the path to a vm file, or to a directory containing vm files")
  path = gets.chomp
  #path = 'C:\Users\eleor\OneDrive\Bureau\Year 4\Semester 2\Fundamentals\nand2tetris\nand2tetris\projects\08\FunctionCalls\FibonacciElement\Sys.vm'
  #path = path.gsub(/\0/, '')
  if path.start_with?('"') && path.end_with?('"')
    # remove the double quotes from the input string using gsub and a regular expression
    path = path.gsub(/^"|"$/, '')
  end
  #if the path ends by .vm, then create a instance of codewriter and call create_output
  if path.end_with?(".vm")
    code_writer = CodeWriter.new(path)
    code_writer.create_output
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
      end
  end
end
