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

  def create_ascii #create a hash table for ascii characters
    @hash = {}
    (' '..'~').each do |char|
      @hash[char] = char.ord
    end
  end
  def set_tokenizer(jack_file_path)
    @tokenizer = Tokenizer.new(jack_file_path)
  end

  def write #write the vm code
    @class_name = fast_forward(2) #print class name
    fast_forward(2) #print {
    compile_classVarDec until @tokenizer.command_segment != "classVarDec"  #compile field and static var
    @class_var_count = @symbol_table.var_count(kind: "field")  #count the number of field var
    compile_subroutineDec until @tokenizer.command_segment != "subroutineDec" #compile constructor, function and method
    fast_forward #print }
  end

  def write_class_table(symbol_table = true)  #if symbol_table is true, write the symbol table, else write the subroutine table
    (command == "," ? @symbol_table.duplicate(fast_forward) : @symbol_table.define(kind: command, type: fast_forward, name: fast_forward)) if symbol_table #define the class var
    (command == "," ? @subroutine_table.duplicate(fast_forward) : @subroutine_table.define(kind: command, type: fast_forward, name: fast_forward)) if !symbol_table #define the subroutine var
    fast_forward #print ;
  end

  def compile_classVarDec(symbol_table: true) #compile and process class variable declarations, updating the symbol table accordingly, until a semicolon is encountered
    write_class_table(symbol_table) while command != ";"
    fast_forward
  end

  def compile_parameter_list
    return if command == ")" #if there is no parameter
    if command == "," #if there is more than one parameter
      fast_forward #print ","
    else
      @subroutine_table.define(kind: "argument", type: command , name: fast_forward) #define the parameter
      fast_forward #print ","
    end
  end

  def compile_subroutineDec #compiles constructor, function and method
    method = 0 #method is 1 if the function is a method
    curr_function_type, curr_return_type, curr_func_name = command, fast_forward, fast_forward
    if curr_function_type == "function" #clean the subroutine table
      @subroutine_table.clean_symbols(true)
    else #clean the subroutine table and set the parent node to the class table
      @subroutine_table.clean_symbols
      @subroutine_table.parent_node = @symbol_table
    end
    method = 1 if curr_function_type == "method" #if the function is a method, define "this" as an argument
    fast_forward(2)
    if method == 1
      @subroutine_table.define(name: "this", type: @class_name, kind: "argument")
    end
    compile_parameter_list while command != ")"
    fast_forward #print ")"
    fast_forward #print "{"
    compile_classVarDec(symbol_table: false) while @tokenizer.command_segment == "varDec" #compile the subroutine var
    @subroutine_var_count = @subroutine_table.var_count(kind: "var") #count the number of subroutine var
    @vm_writer.write_function(command_name: @class_name + "." + curr_func_name, var_count: @subroutine_var_count) #write the function name and the number of subroutine var
    compile_constructor if curr_function_type == "constructor" #if the function is a constructor, compile the constructor
    if method ==
     write_vm("push argument 0") #if the function is a method, push the first argument to the stack bc it is the object that the method is called on
     write_vm("pop pointer 0") #pop the object to the pointer 0
    end
    compile_statements
    fast_forward #print }
  end

  def compile_constructor
    @vm_writer.write_push(segment: "constant", index: @class_var_count) #push the number of field var to the stack
    @vm_writer.write_call(command_name: "Memory.alloc", argument_count: 1) #call the Memory.alloc function to allocate memory for the object
    @vm_writer.write_pop(segment: "pointer", index: 0) #pop the object to the pointer 0 bc the constructor returns the object
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
    start = @vm_writer.create_label(label: "WHILE", filename: @class_name, line_number: @tokenizer.line_number, position: "START") #create a label for the while loop
    while_end = @vm_writer.create_label(label: "WHILE", filename: @class_name, line_number: @tokenizer.line_number, position: "END") #create a label for the end of the while loop
    @vm_writer.write_label(label_name: start)
    fast_forward(2) #print (
    compile_expression
   write_vm("not") #write the condition
    @vm_writer.write_if(label_name: while_end) #if the condition is false, jump to the end of the while loop
    fast_forward(2) #print )
    compile_statements
    @vm_writer.write_goto(label_name: start) #jump to the start of the while loop
    fast_forward #print }
    @vm_writer.write_label(label_name: while_end) #write the end of the while loop
  end

  def compile_if
    else_start = @vm_writer.create_label(label: "ELSE", filename: @class_name, line_number: @tokenizer.line_number, position: "START")
    else_end = @vm_writer.create_label(label: "ELSE", filename: @class_name, line_number: @tokenizer.line_number, position: "END")
    fast_forward(2) #print (
    compile_expression
   write_vm("not") #write the condition
    @vm_writer.write_if(label_name: else_start) #if the condition is false, jump to the else statement
    fast_forward(2)
    compile_statements
    @vm_writer.write_goto(label_name: else_end) #jump to the end of the if statement
    @vm_writer.write_label(label_name: else_start) #write the else statement
    fast_forward #print }
    if command == "else"
      fast_forward(2) #print {
      compile_statements
      fast_forward #print }
    end
    @vm_writer.write_label(label_name: else_end) #write the end of the else statement
  end

  def compile_let
    fast_forward #print varName
    current_command = command
    if fast_forward == "["
     write_vm("push #{@subroutine_table.kind_of(current_command)} #{@subroutine_table.index_of(current_command)}")
      fast_forward #print [. if it is an array:
      compile_expression #compile the expression inside the []
      fast_forward #print ]
     write_vm("add")
      fast_forward
      compile_expression
     write_vm("pop temp 0\npop pointer 1\npush temp 0\npop that 0") #pop the expression to that bc the expression is an array
    else
      fast_forward #print =
      compile_expression #compile the expression after =
      write_vm("pop #{@subroutine_table.kind_of(current_command)} #{@subroutine_table.index_of(current_command)}")
    end
    fast_forward
  end

  def compile_return
    fast_forward
    if command == "this" #if the return value is this, push the pointer 0 to the stack
      @vm_writer.write_push(segment: "pointer", index: 0)
      fast_forward
    elsif command != ";" #if the return value is not ;, compile the expression
      compile_expression
    elsif command == ";" #if the return value is ;, push 0 to the stack
     write_vm("push constant 0")
    end
   write_vm("return")
    fast_forward
  end

  def compile_do #compile the subroutine call and pop the return value to temp 0
    fast_forward #print subroutineName
    compile_subroutine_call(call: true)
    @vm_writer.write_pop(segment: "temp", index: 0)
    fast_forward
  end

  #if the call is made from an identifier, pushes the base address onto the stack
  # If the call is for a method of an object or variable, constructs the fully qualified method name
  # It increments the method variable to account for the implicit this parameter.
  # if array, handles array element access, if function, construct function name
  #
  def compile_subroutine_call(end_term: false, call: false, from_identifier: false) #compile the subroutine call
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
       write_vm("add") #add the expression to the base address
       write_vm("pop pointer 1") #pop the expression to pointer 1 bc the expression is an array
       write_vm("push that 0")
        return
      end
      return
    elsif curr_type_identifier == "." #if the subroutine call is a method
      curr_func_name = curr_var_name + "." + fast_forward #construct the function name
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

  def compile_expression_list(sub_call: true) #compile the expression list by determining the number of expressions and generating code for each expression
    fast_forward if sub_call
    if command == ")"
      fast_forward
      return 0
    end
    i = 1
    if sub_call #if the expression list is a subroutine call
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

  def compile_expression(expression: true) #handles single expressions (int, str, const...)
    case current_expression_segment
    when "integerConstant"
     write_vm("push constant #{command}") #push the integer constant to the stack
      fast_forward
      compile_op if command.match(Op) #if the next command is an operator, compile the operator
    when "stringConstant"
      compile_string
      fast_forward
    when "keywordConstant"
      case command
      when "false", "null" #if the keyword is false or null, push 0 to the stack
       write_vm("push constant 0")
      when "this" #if the keyword is this, push the pointer 0 to the stack
       write_vm("push pointer 0")
      when "true"
       write_vm("push constant 0\nnot")
      end
      fast_forward
    when "unaryOp"
      compile_op(write_statement: false, unary: true)
    when "identifier"
      curr = command #save the current command
      @previous_command = curr #save the previous command
      next_command = fast_forward
      if %w{. ( [}.include? next_command #if the next command is a ., (, or [, compile the subroutine call
        compile_subroutine_call(end_term: true, from_identifier: true)
      else
        if curr == "this" #if the current command is this, push the pointer 0 to the stack
         write_vm("push pointer 0")
        else
         write_vm("push #{@subroutine_table.kind_of(curr)} #{@subroutine_table.index_of(curr)}") #push the current command
        end
      end
      compile_op if command.match(Op)
    when "(" #if the current command is a (, compile the expression inside the parentheses
      fast_forward
      compile_expression
      fast_forward
      compile_op if command.match(Op)
    else
      return nil
    end
  end

  def current_expression_segment #determines the type of the current expression
    if command.match(Integer)
      return "integerConstant"
    elsif command.match(String)
      return "stringConstant"
    elsif command.match(Keyword)
      return "keywordConstant"
    elsif command.match(Identifier)
      return "identifier"
    elsif command.match(Unary)
      return "unaryOp"
    elsif command.match(Op)
      return "Op"
    elsif command == "("
      return "("
    end
  end

  def compile_string
    str = command[1..-2] #remove the quotes from the string
    if str
      len = str.length #get the length of the string
     write_vm("push constant #{len}") #push the length of the string to the stack (make some space)
     write_vm("call String.new 1") #call the string constructor
      i = 0
      while (i < len) #loop through the string and append each character to the string
       write_vm("push constant #{@hash[str[i]]}")
       write_vm("call String.appendChar 2")
        i += 1
      end
    else #if the string is empty, push an empty string to the stack
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
    if current_command.match(Op) || current_command.match(Unary) #if the current command is an operator or a unary operator, compile the expression
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

  def fast_forward(n=1) #fast forward n times
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