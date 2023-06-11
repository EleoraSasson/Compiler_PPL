require_relative "Tokenizer.rb"
require_relative 'symbol_table'
require_relative 'vm_writer'
class CompileEngine

  Integer = /^\d+$/
  String = /^\"[^"]*\"$/
  Keyword = /^true|false|null|this$/
  Identifier = /^[a-zA-Z]+[a-zA-Z_0-9]*$/
  Unary = /^-|~$/
  Op = /^\+|\-|\*|\/|\&|\||<|>|=$/
  Sub = /^\(|\[|\.$/

  def initialize(vm_file)
    @hash = {}  # hash table for symbol table
    @vm_file = File.open(vm_file, "w")
    @symbol_table = SymbolTable.new()
    @subroutine_table = SymbolTable.new(parent_node= @symbol_table, scope= "subroutine")
    @vm_writer = VMWriter.new(vm_file)
    create_ascii
  end

  def create_ascii
    @hash = {}

    (' '..'~').each do |char|
      @hash[char] = char.ord
    end
  end


  def set_tokenizer(jack_file_path)
    @tokenizer = Tokenizer.new(jack_file_path)
  end

  def write
    @class_name = fast_forward(2)
    fast_forward(2)
    compile_classVarDec until @tokenizer.command_segment != "classVarDec"
    @class_var_count = @symbol_table.var_count(kind: "field")
    compile_subroutineDec until @tokenizer.command_segment != "subroutineDec"
    fast_forward #print }
  end

  #todo: if there is a bug, prob here
  #   (command == "," ? @class_table.dup(fastforward) : @class_table.define(kind: command, type: fastforward, name: fastforward)) if classtable
  #         (command == "," ? @subroutine_table.dup(fastforward) : @subroutine_table.define(kind: command, type: fastforward, name: fastforward)) if !classtable
  #
  def write_class_table(symbol_table = true)
    # define(name: name, type: @type, kind: @kind)
    name = fast_forward
    (command == "," ? @symbol_table.define(name: name, type: @type, kind: @kind) : @symbol_table.define(kind: command, type: fast_forward, name: fast_forward)) if symbol_table
    (command == "," ? @subroutine_table.define(name: name, type: @type, kind: @kind) : @subroutine_table.define(kind: command, type: fast_forward, name: fast_forward)) if !symbol_table
    fast_forward
  end

  def compile_classVarDec(symbol_table: true)
    write_class_table(symbol_table) while command != ";"
    fast_forward
  end

  def compile_parameter_list
    return if command == ")"
    if command == ","
      fast_forward
    else
      @subroutine_table.define(kind: "argument", type: command , name: fast_forward)
      fast_forward
    end
  end

  def compile_subroutineDec
    method = 0
    curr_function_type, curr_funcname = command, fast_forward, fast_forward
    if curr_function_type == "function"
      @subroutine_table.clean_symbols(true)
    else
      @subroutine_table.clean_symbols
      @subroutine_table.parent_node = @symbol_table
    end
    method = 1 if curr_function_type == "method"
    fast_forward(2)
    if method == 1
      @subroutine_table.define(name: "this", type: @class_name, kind: "argument")
    end
    compile_parameter_list while command != ")"
    fast_forward #print ")"
    fast_forward #print "{"
    compile_classVarDec(symbol_table: false) while @tokenizer.command_segment == "varDec"
    @subroutine_var_count = @subroutine_table.var_count(kind: "var")
    @vm_writer.write_function(@class_name + "." + curr_funcname, @subroutine_var_count)
    compile_constructor if curr_function_type == "constructor"
    if method == 1
      @vm_writer.puts("push argument 0")
      @vm_writer.puts("pop pointer 0")
    end
    compile_statements
    fast_forward #print }
  end

  def compile_constructor
    @vm_writer.write_push("constant", @class_var_count)
    @vm_writer.write_call("Memory.alloc", 1)
    @vm_writer.write_pop("pointer", 0)
  end


  def compile_statements
    if @tokenizer.command_segment == "statements" # just in case that the subroutine doesn't have a statement
      compile_statement until @tokenizer.command_segment != "statements"
    end
  end

  def compile_statement
    case command
    when "while"
      compile_while
    when "if"
      compile_if
    when "let"
      compile_let
    when "do"
      compile_do
    when "return"
      compile_return
    end
  end

  def compile_while
    start = @vm_writer.create_label("WHILE", @class_name, @tokenizer.line_number, "START")
    while_end = @vm_writer.create_label("WHILE", @class_name, @tokenizer.line_number, "END")
    @vm_writer.write_label(start)
    fast_forward(2)
    compile_expression
    @vm_writer.puts("not")
    @vm_writer.write_if(while_end)
    fast_forward(2)
    compile_statements
    @vm_writer.write_goto(start)
    fast_forward
    @vm_writer.write_label(while_end)
  end

  def compile_if
    else_start = @vm_writer.create_label("ELSE", @class_name, @tokenizer.line_number, "START")
    else_end = @vm_writer.create_label("ELSE", @class_name, @tokenizer.line_number, "END")
    fast_forward(2)
    compile_expression
    @vm_writer.puts("not")
    @vm_writer.write_if(else_start)
    fast_forward(2)
    compile_statements
    @vm_writer.write_goto(else_end)
    @vm_writer.write_label(else_start)
    fast_forward
    if command == "else"
      fast_forward(2)
      compile_statements
      fast_forward
    end
    @vm_writer.write_label(else_end)
  end

  #todo: if bug change to ccomand
  def compile_let
    fast_forward
    if fast_forward == "["
      @vm_writer.puts("push #{@subroutine_table.kind_of(command)} #{@subroutine_table.index_of(command)}")
      fast_forward
      compile_expression
      fast_forward
      @vm_writer.puts("add")
      fast_forward
      compile_expression
      @vm_writer.puts("pop temp 0\n
                       pop pointer 1\n
                       push temp 0\n
                       pop that 0")
    else
      fast_forward
      compile_expression
      @vm_writer.puts("pop #{@subroutine_table.kind_of(command)} #{@subroutine_table.index_of(ccomand)}")
    end
    fast_forward
  end

  def compile_return
    fast_forward
    if command == "this"
      @vm_writer.write_push("pointer", 0)
      fast_forward
    elsif command != ";"
      compile_expression
    elsif command == ";"
      @vm_writer.puts("push constant 0")
    end
    @vm_writer.puts("return")
    fast_forward
  end

  def compile_do
    fast_forward
    compile_subroutine_call
    @vm_writer.write_pop("temp", 0)
    fast_forward
  end

  def compile_subroutine_call(from_identifier: false)
    method = 0
    if from_identifier
      curr_var_name = @previous_command
      curr_type_identifier = command
    else
      curr_var_name = command
      curr_type_identifier = fast_forward
    end
    if @subroutine_table.type_of(curr_var_name) && @subroutine_table.type_of(curr_var_name) != "Array"
      @vm_writer.puts("push #{@subroutine_table.kind_of(curr_var_name)} #{@subroutine_table.index_of(curr_var_name)}")
      curr_funcname = "#{@subroutine_table.type_of(curr_var_name)}" + "." + fast_forward
      method = 1
      fast_forward
    elsif @subroutine_table.type_of(curr_var_name) == "Array"
      @vm_writer.puts("push #{@subroutine_table.kind_of(curr_var_name)} #{@subroutine_table.index_of(curr_var_name)}")
      if command == "["
        fast_forward
        compile_expression
        fast_forward
        @vm_writer.puts("add")
        @vm_writer.puts("pop pointer 1")
        @vm_writer.puts("push that 0")
        return
      end
      return
    elsif curr_type_identifier == "."
      curr_funcname = curr_var_name + "." + fast_forward
      fast_forward
    elsif curr_type_identifier == "("
      method = 1
      @vm_writer.puts("push pointer 0")
      curr_funcname = @class_name + "." + curr_var_name
    else
      raise "no such subroutine"
    end
    c = compile_expression_list
    @vm_writer.write_call(curr_funcname, c + method)
  end

  def compile_expression_list(sub_call: true)
    fast_forward #print "("
    write_labels(statement: "expressionList") if sub_call
    if sub_call
      (command == "," ? fast_forward : compile_expression) until command == ")"
    else
      compile_expression
    end
    write_labels(start: false, statement: "expressionList") if sub_call
    fast_forward #print ")" 
  end

  def compile_expression(expression: true)
    @previous_command = current_command
    write_labels(statement: "expression") if expression
    write_labels(statement: "term")
    case current_expression_segment
    when "integerConstant", "stringConstant", "keywordConstant"
      fast_forward
      compile_op
    when "unaryOp"
      compile_op(write_statement: false, unary: true)
    when "identifier"
      fast_forward
      command.match(Op) ? compile_op : compile_subroutine_call
    when "("
      compile_expression_list(sub_call: false)
      compile_op
    else
      return nil
    end
    write_labels(start: false, statement: "expression") if expression
  end

  def current_expression_segment
    if command.match(Integer)
      return "integerConstant"
    elsif command.match(String)
      return "stringConstant"
    elsif command.match(Keyword)
      return "keywordConstant"
    elsif command.match(Identifier)
      return "identifier"
    elsif command.match(Unary)
      # has some logic flaw here: if symbol is "-", the program will always
      # recognize it as a "Unary", but sometimes it can be an Op
      return "unaryOp"
    elsif command.match(Op)
      return "Op"
    elsif command == "("
      return "("
    end
  end

  def compile_op(write_statement: true, unary: false)
    write_labels(start: false, statement: "term") if write_statement
    if command.match(Op) || command.match(Unary)
      fast_forward
      compile_expression(expression: false)
    end
    write_labels(start: false, statement: "term") if unary
  end

  # return the current command
  def command
    @tokenizer.current_command
  end

  # write tags that will take several lines, start: true will print "<tag>", else "</tag>"
  def write_labels(start: true, statement:)
    @vm_file.write("<#{start ? "" : "/"}#{statement}>\n")
  end

  # fast_forward is to print the simple "<tag> name </tag>" lines
  def fast_forward(n=1)
    n.times do
      @tokenizer.write_command
      @tokenizer.advance
    end
  end

  #close the file
  def close
    @vm_file.close
  end
end