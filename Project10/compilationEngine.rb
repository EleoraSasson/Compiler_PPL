# frozen_string_literal: true
require_relative 'tokenizer'
BINARY_OPERATORS = %w[+ - * / = | &lt &gt &amp]
UNARY_OPERATORS = %w[- ~]
KEYWORD_CONSTANTS = %w[true false null this]
class CompilationEngine

  def initialize(path_to_jack_file, path_to_xml_file)
    @tokenizer = Tokenizer.new(path_to_jack_file, path_to_xml_file)
    @xml_file = File.open(path_to_xml_file, "w")
    @parsed = []
    @indent = ""
    #compile_class
  end

  def write_non_terminal_start(token)
    @xml_file.puts("#{@indent}<#{token}>" + '\n')
    @parsed.append(token)
    @indent += "    "
  end

  def advance
    token = @tokenizer.advance
    write_terminal(token)
  end
  def compile_class
    write_non_terminal_start("class")
    advance
    advance
    advance
  end

  def compile_class_var_dec

  end

  def compile_subroutine

  end

  def compile_parameter_list

  end

  def compile_subroutine_body

  end

  def compile_var_dec

  end

  def compile_statements

  end

  def compile_do

  end

  def compile_let

  end

  def compile_while

  end

  def compile_return

  end

  def compile_if

  end

  def compile_expression

  end

  def compile_term

  end

  def compile_expression_list

  end

end