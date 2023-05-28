require_relative 'tokenizer'

class CompilationEngine
  def initialize(tokenizer, output_file)
    @tokenizer = tokenizer
    @output_file = output_file
    @indent_level = 0
    @output = []
    compile_class
    write_output
  end

  def compile_class
    eat('class')
    class_name = eat(:identifier)
    eat('{')

    while %w[static field].include? peek
      compile_class_var_dec
    end

    while %w[constructor function method].include? peek
      compile_subroutine_dec
    end

    eat('}')
  end

  def compile_class_var_dec
    eat(%w[static field]) # Discard the variable kind
    eat_type # Discard the variable type

    loop do
      eat(:identifier)

      break if peek != ','

      eat(',')
    end

    eat(';')
  end


  def compile_subroutine_dec
    subroutine_kind = eat(%w[constructor function method])
    return_type = eat(%w[void type])

    if subroutine_kind == 'method'
      eat('this')
    end

    subroutine_name = eat(:identifier)

    eat('(')
    compile_parameter_list
    eat(')')

    compile_subroutine_body(subroutine_name, subroutine_kind, return_type)
  end

  def compile_parameter_list
    return if peek == ')'

    type = eat_type
    name = eat(:identifier)

    while peek == ','
      eat(',')
      type = eat_type
      name = eat(:identifier)
    end
  end

  def compile_subroutine_body(subroutine_name, subroutine_kind, return_type)
    eat('{')

    while peek == 'var'
      compile_var_dec
    end

    compile_statements

    eat('}')
  end

  def compile_var_dec
    eat('var')

    while peek == ','
      eat(',')
      name = eat(:identifier)
    end

    eat(';')
  end

  def compile_statements
    while %w[let if while do return].include? peek
      case peek
      when 'let'
        compile_let
      when 'if'
        compile_if
      when 'while'
        compile_while
      when 'do'
        compile_do
      when 'return'
        compile_return
      end
    end
  end

  def compile_let
    eat('let')

    eat('=')

    compile_expression

    eat(';')
  end

  def compile_if
    eat('if')

    eat('(')

    compile_expression

    eat(')')

    eat('{')

    compile_statements

    eat('}')

    if peek == 'else'
      eat('else')

      eat('{')

      compile_statements

      eat('}')
    end
  end

  def compile_while
    eat('while')

    eat('(')

    compile_expression

    eat(')')

    eat('{')

    compile_statements

    eat('}')
  end

  def compile_do
    eat('do')

    compile_subroutine_call

    eat(';')
  end

  def compile_return
    eat('return')

    if peek != ';'
      compile_expression
    end

    eat(';')
  end

  def compile_expression
    compile_term

    while %w[+ - * / & | < > =].include? peek
      op = eat(%w[+ - * / & | < > =])

      compile_term
    end
  end

  def compile_term
    case peek
    when :integerConstant
      eat(:integerConstant)
    when :stringConstant
      eat(:stringConstant)
    when :keywordConstant
      eat(%w[true false null this])
    when :identifier
      eat(:identifier)

      if peek == '['
        eat('[')
        compile_expression
        eat(']')
      elsif peek == '(' || peek == '.'
        compile_subroutine_call
      end
    when '-'
      eat('-')
      compile_term
    when '~'
      eat('~')
      compile_term
    when '('
      eat('(')
      compile_expression
      eat(')')
    end
  end

  def compile_subroutine_call
    eat(:identifier)

    if peek == '.'
      eat('.')
      eat(:identifier)
    end

    eat('(')

    compile_expression_list

    eat(')')
  end

  def compile_expression_list
    return if peek == ')'

    compile_expression

    while peek == ','
      eat(',')
      compile_expression
    end
  end

  def eat(expected_token)
    token = @tokenizer.advance

    if expected_token.is_a?(Array)
      raise "Expected one of #{expected_token}, got #{token}" unless expected_token.include?(token)
    else
      raise "Expected #{expected_token}, got #{token}" unless token == expected_token
    end

    add_to_output(token)
    token
  end

  def peek
    @tokenizer.peek
  end

  def eat_type
    eat(%w[int char boolean] + [:identifier])
  end

  def add_to_output(token)
    @output << "#{'  ' * @indent_level}#{token}"
  end

  def write_output
    File.open(@output_file, 'w') do |file|
      file.puts @output
    end
  end
end
