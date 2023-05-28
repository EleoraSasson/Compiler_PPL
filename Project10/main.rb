=begin
# frozen_string_literal: true
require_relative 'tokenizer'
require_relative 'compilationEngine'
class Main

  puts("Please enter a jack file or a directory containing a jack file")
  path = 'C:\Users\eleor\OneDrive\Bureau\Year 4\Semester 2\Fundamentals\nand2tetris\nand2tetris\projects\10\ArrayTest\Main.jack'
  #path = gets.chomp
  if path.start_with?('"') && path.end_with?('"')
    # remove the double quotes from the input string using gsub and a regular expression
    path = path.gsub(/^"|"$/, '')
  end
  xml_file = File.open(path.gsub(/\.jack$/, ".xml"), "w")
=begin

  tokenizer = Tokenizer.new(path, xml_file)
  tokenizer.write_token_file

  # Create a CompileEngine instance to compile the tokenized input
  compile_engine = CompilationEngine.new(tokenizer, xml_file)

  # Compile the class
  compile_engine.compile_class
  #  compile_engine.write_to_XML_file

=end

require_relative "compilationEngine.rb"
class JackAnalyzer
  def initialize(path)
    path = path[0...-1] if path[-1] == "/"
    @jack_path = File.expand_path(path)
    if path[-5..-1] == ".jack"
      @single_file = true
    else
      @single_file = false
    end
    p @single_file
  end

  def compile
    @single_file ? compile_one(@jack_path) : compile_all
    @compileengine.close
  end

  private
  def compile_one(jack_path)
    xml_path = jack_path.gsub(".jack", ".xml")
    @compileengine = CompileEngine.new(xml_path)
    p "Engine Created"
    @compileengine.set_tokenizer(jack_path)
    p "Tokenizer Created"
    @compileengine.write
    @compileengine.close
  end

  def compile_all
    p "compiling a folder"
    Dir["#{@jack_path}/*.jack"].each do |file|
      p file
      compile_one(file)
    end

  end
end

puts "Please enter a jack file or a directory containing a jack file"
path = 'C:\Users\eleor\OneDrive\Bureau\Year 4\Semester 2\Fundamentals\nand2tetris\nand2tetris\projects\10\ArrayTest\Main.jack'
JackAnalyzer.new(path).compile
