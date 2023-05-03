# frozen_string_literal: true

require_relative 'code_writer'
class VMTranslator

  puts("Enter the path to a vm file, or to a directory containing vm files")
  path = gets.chomp
  #path = 'C:\Users\eleor\OneDrive\Bureau\Year 4\Semester 2\Fundamentals\Homework 1\Project7_lab1\vm files'
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
    #TODO: if vm files need to be translated in only one asm, how do we do it?
    # If path is not a .vm file, assume it is a directory and search for .vm files in it
    files = Dir.entries(path)
    result = []
    if files.empty?
      puts "No .vm files found in directory #{path}"
    else
      files.each do |f|
        if f.end_with?(".vm") && File.file?(File.join(path, f))
          result << File.join(path, f)
        end
      end
      result.each do |vm_file|
        code_writer = CodeWriter.new(vm_file)
        code_writer.create_output
      end
      end
  end
end
