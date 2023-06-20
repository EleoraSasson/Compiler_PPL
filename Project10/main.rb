
# frozen_string_literal: true
require_relative 'tokenizer'
require_relative 'compilationEngine'

class Main

  puts("Please enter a jack file or a directory containing a jack file")
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
    #compile_file(path)
    vm_path = path.gsub(".jack", ".vm")
    @compile_engine = CompileEngine.new(vm_path)
    @compile_engine.set_tokenizer(path)
    @compile_engine.write
    @compile_engine.close

  else
    Dir["#{@jack_path}/*.jack"].each do |file|
      vm_path = file.gsub(".jack", ".vm")
      @compile_engine = CompileEngine.new(vm_path)
      @compile_engine.set_tokenizer(file)
      @compile_engine.write
      @compile_engine.close
  end

  end
  end