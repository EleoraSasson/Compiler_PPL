
# frozen_string_literal: true
require_relative 'tokenizer'
require_relative 'compilationEngine'

class Main
  def compile_file(jack_path)
    xml_path = jack_path.gsub(".jack", ".xml")
    @compile_engine = CompileEngine.new(xml_path)
    p "Engine Created"
    @compile_engine.set_tokenizer(jack_path)
    p "Tokenizer Created"
    @compile_engine.write
    @compile_engine.close
  end

  puts("Please enter a jack file or a directory containing a jack file")
  #path = 'C:\Users\eleor\OneDrive\Bureau\Year 4\Semester 2\Fundamentals\nand2tetris\nand2tetris\projects\10\ArrayTest\Main.jack'
  path = gets.chomp
  if path.start_with?('"') && path.end_with?('"')
    # remove the double quotes from the input string using gsub and a regular expression
    path = path.gsub(/^"|"$/, '')
  end
  path = path[0...-1] if path[-1] == "/"
  @jack_path = File.expand_path(path)
  if path[-5..-1] == ".jack"
    @single_file = true
  else
    @single_file = false
  end

  if @single_file == true
    #compile_file(@jack_path)
    xml_path = path.gsub(".jack", ".xml")
    @compile_engine = CompileEngine.new(xml_path)
    @compile_engine.set_tokenizer(path)
    @compile_engine.write
    @compile_engine.close
  else
    Dir["#{@jack_path}/*.jack"].each do |file|
      xml_path = file.gsub(".jack", ".xml")
      @compile_engine = CompileEngine.new(xml_path)
      @compile_engine.set_tokenizer(file)
      @compile_engine.write
      @compile_engine.close
  end

  end
  end