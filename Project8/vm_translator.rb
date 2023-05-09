require_relative 'code_writer'

class VMTranslator
  def initialize(path)
    path = path[0...-1] if path[-1] == "/"
    @vm_path = File.expand_path(path)
    if path[-3..-1] == ".vm"
      file_name = path.split("/")[-1][0..-4]
      @asm_path = "#{@vm_path[0..-4]}.asm"
      @single_file = true
    else
      #check if there is only one vm file in the directory
      if Dir["#{@vm_path}/*.vm"].length == 1
        @asm_path = "#{@vm_path}/#{@vm_path.split("/")[-1]}.asm"
        @single_file = true
      else
        @asm_path = "#{@vm_path}/#{@vm_path.split("/")[-1]}.asm"
        @single_file = false
      end
    end
    @writer = CodeWriter.new(@asm_path, @single_file)
  end
  def compile
    @single_file ? translate(@vm_path) : translate_all
    @writer.close
  end

  private
  def translate(vm_path)
    @writer.set_file_name(vm_path)
    @writer.write
  end

  def translate_all
    Dir["#{@vm_path}/*.vm"].each {|file| translate(file)}
  end
end

puts("Please enter a vm file or a directory containing a vm file")
=begin
path = gets.chomp
if path.start_with?('"') && path.end_with?('"')
  # remove the double quotes from the input string using gsub and a regular expression
  path = path.gsub(/^"|"$/, '')
end
=end
path = 'C:\Users\eleor\OneDrive\Bureau\Year 4\Semester 2\Fundamentals\nand2tetris\nand2tetris\projects\08\FunctionCalls\SimpleFunction'
# Create a new VMTranslator object and call the compile method
translator = VMTranslator.new(path)
translator.compile
