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
    @subroutine_table = SymbolTable.new(parent_node: @symbol_table, scope: "subroutine")
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
    (command == "," ? @symbol_table.duplicate(fast_forward) : @symbol_table.define(kind: command, type: fast_forward, name: fast_forward)) if symbol_table
    (command == "," ? @subroutine_table.duplicate(fast_forward) : @subroutine_table.define(kind: command, type: fast_forward, name: fast_forward)) if !symbol_table
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
    curr_function_type, curr_return_type, curr_func_name = command, fast_forward, fast_forward
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
    @vm_writer.write_function(command_name: @class_name + "." + curr_func_name, var_count: @subroutine_var_count)
    compile_constructor if curr_function_type == "constructor"
    if method == 1
     write_vm("push argument 0")
     write_vm("pop pointer 0")
    end
    compile_statements
    fast_forward #print }
  end

  def compile_constructor
    @vm_writer.write_push(segment: "constant", index: @class_var_count)
    @vm_writer.write_call(command_name: "Memory.alloc", argument_count: 1)
    @vm_writer.write_pop(segment: "pointer", index: 0)
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
    start = @vm_writer.create_label(label: "WHILE", filename: @class_name, line_number: @tokenizer.line_number, position: "START")
    while_end = @vm_writer.create_label(label: "WHILE", filename: @class_name, line_number: @tokenizer.line_number, position: "END")
    @vm_writer.write_label(label_name: start)
    fast_forward(2)
    compile_expression
   write_vm("not")
    @vm_writer.write_if(label_name: while_end)
    fast_forward(2)
    compile_statements
    @vm_writer.write_goto(label_name: start)
    fast_forward
    @vm_writer.write_label(label_name: while_end)
  end

  def compile_if
    else_start = @vm_writer.create_label(label: "ELSE", filename: @class_name, line_number: @tokenizer.line_number, position: "START")
    else_end = @vm_writer.create_label(label: "ELSE", filename: @class_name, line_number: @tokenizer.line_number, position: "END")
    fast_forward(2)
    compile_expression
   write_vm("not")
    @vm_writer.write_if(label_name: else_start)
    fast_forward(2)
    compile_statements
    @vm_writer.write_goto(label_name: else_end)
    @vm_writer.write_label(label_name: else_start)
    fast_forward
    if command == "else"
      fast_forward(2)
      compile_statements
      fast_forward
    end
    @vm_writer.write_label(label_name: else_end)
  end

  def compile_let
    fast_forward
    current_command = command
    if fast_forward == "["
     write_vm("push #{@subroutine_table.kind_of(current_command)} #{@subroutine_table.index_of(current_command)}")
      fast_forward
      compile_expression
      fast_forward
     write_vm("add")
      fast_forward
      compile_expression
     write_vm("pop temp 0\npop pointer 1\npush temp 0\npop that 0")
    else
      fast_forward
      compile_expression
      write_vm("pop #{@subroutine_table.kind_of(current_command)} #{@subroutine_table.index_of(current_command)}")
    end
    fast_forward
  end

  def compile_return
    fast_forward
    if command == "this"
      @vm_writer.write_push(segment: "pointer", index: 0)
      fast_forward
    elsif command != ";"
      compile_expression
    elsif command == ";"
     write_vm("push constant 0")
    end
   write_vm("return")
    fast_forward
  end

  def compile_do
    fast_forward
    compile_subroutine_call(call: true)
    @vm_writer.write_pop(segment: "temp", index: 0)
    fast_forward
  end

  def compile_subroutine_call(end_term: false, call: false, from_identifier: false)
    method = 0
    if from_identifier
      curr_var_name = @previous_command
      curr_type_identifier = command
    else
      curr_var_name = command
      curr_type_identifier = fast_forward
    end
    if @subroutine_table.type_of(curr_var_name) && @subroutine_table.type_of(curr_var_name) != "Array"
     write_vm("push #{@subroutine_table.kind_of(curr_var_name)} #{@subroutine_table.index_of(curr_var_name)}")
      curr_func_name = "#{@subroutine_table.type_of(curr_var_name)}" + "." + fast_forward
      method = 1
      fast_forward
    elsif @subroutine_table.type_of(curr_var_name) == "Array"
     write_vm("push #{@subroutine_table.kind_of(curr_var_name)} #{@subroutine_table.index_of(curr_var_name)}")
      if command == "["
        fast_forward
        compile_expression
        fast_forward
       write_vm("add")
       write_vm("pop pointer 1")
       write_vm("push that 0")
        return
      end
      return
    elsif curr_type_identifier == "."
      curr_func_name = curr_var_name + "." + fast_forward
      fast_forward
    elsif curr_type_identifier == "("
      method = 1
     write_vm("push pointer 0")
      curr_func_name = @class_name + "." + curr_var_name
    else
      raise "no such subroutine"
    end
    c = compile_expression_list
    @vm_writer.write_call(command_name:curr_func_name, argument_count: c + method)
  end

  def compile_expression_list(sub_call: true)
    fast_forward if sub_call
    if command == ")"
      fast_forward
      return 0
    end
    i = 1

    if sub_call
      while command != ")"
        if command == ","
          fast_forward
          i += 1
        else
          compile_expression
        end
      end
      fast_forward
      return i
    else
      compile_expression
      return i
    end
  end

  def compile_expression(expression: true)
    case current_expression_segment
    when "integerConstant"
     write_vm("push constant #{command}")
      fast_forward
      compile_op if command.match(Op)
    when "stringConstant"
      compile_string
      fast_forward
    when "keywordConstant"
      case command
      when "false", "null"
       write_vm("push constant 0")
      when "this"
       write_vm("push pointer 0")
      when "true"
       write_vm("push constant 0\nnot")
      end
      fast_forward
    when "unaryOp"
      compile_op(write_statement: false, unary: true)
    when "identifier"
      curr = command
      @previous_command = curr
      next_command = fast_forward
      if %w{. ( [}.include? next_command
        compile_subroutine_call(end_term: true, from_identifier: true)
      else
        if curr == "this"
         write_vm("push pointer 0")
        else
         write_vm("push #{@subroutine_table.kind_of(curr)} #{@subroutine_table.index_of(curr)}")
        end
      end
      compile_op if command.match(Op)
    when "("
      fast_forward
      compile_expression
      fast_forward
      compile_op if command.match(Op)
    else
      return nil
    end
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

  def compile_string
    str = command[1..-2]
    if str
      len = str.length
     write_vm("push constant #{len}")
     write_vm("call String.new 1")
      i = 0
      while (i < len)
       write_vm("push constant #{@hash[str[i]]}")
       write_vm("call String.appendChar 2")
        i += 1
      end
    else
     write_vm("push constant 0")
     write_vm("call String.new 1")
    end
  end

  def write_unary(curr_command)
    case curr_command
    when "~"
     write_vm("not")
    when "-"
     write_vm("neg")
    else
      raise "no such operator"
    end
  end

  def write_op(curr_command)
    case curr_command
    when "+"
     write_vm("add")
    when "-"
     write_vm("sub")
    when "*"
     write_vm("call Math.multiply 2")
    when "/"
     write_vm("call Math.divide 2")
    when "<"
     write_vm("lt")
    when ">"
     write_vm("gt")
    when "="
     write_vm("eq")
    when "&"
     write_vm("and")
    when "|"
     write_vm("or")
    else
      raise "no such operation"
    end
  end


  def compile_op(write_statement: true, unary: false)
    current_command = command
    fast_forward
    if current_command.match(Op) || current_command.match(Unary)
      compile_expression(expression: false)
      if unary
        write_unary(current_command)
      else
        write_op(current_command)
      end
    end
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
    name = ""
    n.times do
      name = @tokenizer.advance
    end
    return name
  end

  #close the file
  def close
    @vm_file.close
  end

  def write_vm(commandline)
    @vm_writer.write_vm(command_line: commandline)
  end

end