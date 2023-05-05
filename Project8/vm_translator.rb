# frozen_string_literal: true

require_relative 'code_writer'
class VMTranslator

  puts("Enter the path to a vm file, or to a directory containing vm files")
  #path = gets.chomp
  path = 'C:\Users\eleor\OneDrive\Bureau\Year 4\Semester 2\Fundamentals\nand2tetris\nand2tetris\projects\08\FunctionCalls\StaticsTest\Class1.vm'
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


=begin
def compile
  if @single_file
    puts "Translating single file: #{@vm_path}"
    translate(@vm_path)
  else
    puts "Translating all files in directory: #{@vm_path}"
    translate_all
  end
end

def translate(vm_path)
  @writer.set_file_name(vm_path)
  @writer.create_output(vm_path, @single_file)
  end

  def translate_all
    #translates all the vm files in the directory
    Dir.entries(@vm_path).each do |file|
      if file.end_with?(".vm") && File.file?(File.join(@vm_path, file))
        translate(File.join(@vm_path, file))
      end
    end
  end

 #end of class VMTranslator
  VMTranslator.new.compile
end
=end

=begin

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
=end
=begin
      asm_files = Dir.entries(path).select { |f| f.end_with?(".asm") && File.file?(File.join(path, f)) }

      if asm_files.empty?
        puts "No .asm files found in directory #{path}"
      else
        # Create the output file
        output_file = File.join(path, "#{File.basename(path)}.asm")
        File.open(output_file, "w") do |f|
          asm_files.each do |asm_file|
            File.open(File.join(path, asm_file), "r") do |asm|
              asm.each_line do |line|
                f.puts line
              end
            end
          end
        end
      end
=end
