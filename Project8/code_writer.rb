require_relative 'parser'

class CodeWriter
  def initialize(path_to_asm_file, single_file)
    @asm_file = File.open(path_to_asm_file, "w")
    @function_count = 1
    write_bootstrap if !single_file
  end

  def set_file_name(path_to_vm_file)
    @parser = Parser.new(path_to_vm_file)
  end

  def write
    while @parser.has_more_commands?
      if !@parser.advance.empty?
        translate
      end
    end
  end

  def translate
    case @parser[0]
    when "add","sub","eq","gt","lt","and","or","neg","not"
      write_arithmetic
    when "push"
      write_push
    when "pop"
      write_pop
    when "label"
      write_label
    when "goto","if-goto"
      write_goto
    when "call"
      write_call
    when "function"
      write_function
    when "return"
      write_return
    end
  end

  def write_arithmetic
    case @parser[0]
    when "add"
      arithmetic(calc: "+")
    when "sub"
      arithmetic(calc: "-")
    when "eq"
      arithmetic(calc: "-", jump_type: "JEQ")
    when "gt"
      arithmetic(calc: "-", jump_type: "JGT")
    when "lt"
      arithmetic(calc: "-", jump_type: "JLT")
    when "and"
      arithmetic(calc: "&")
    when "or"
      arithmetic(calc: "|")
    when "neg"
      arithmetic(calc: "-", unary: true)
    when "not"
      arithmetic(calc: "!", unary: true)
    end
  end

  #function to write push command in assembly
  def write_push
    # Check the segment
    case @parser[1]
      # If 'constant', push the constant value onto the stack.
    when "constant"
      push_stack(constant:@parser[2])
      # If 'static', load the static variable into the A register and push its value onto the stack.
    when "static"
      load_static
      push_stack
      # For all other segments, load the segment's base address into the A register, add the offset to the address, and push the value stored at the resulting memory address onto the stack.
    else
      load_memory
      push_stack
    end
  end

  #function to write pop command in assembly
  def write_pop
    # Pop the top value off the stack and store it in the D register.
    pop_stack
    # Check the segment
    if @parser[1] == "static"
      # If the segment is 'static', load the static variable into the A register and set the M register to the value in the D register.
      load_static(pop: true)
    else
      # Otherwise, store the address of the target memory location in register 13 (R13), load the value in the D register into the M register at the memory address pointed to by R13, and then increment the R13 register.
      write_file(string: "@13\nM=D")
      load_memory(save_from_r13: true)
    end
  end

  #function to write the label line in assembly
  def write_label
    write_file(string: "(#{@parser[1]})")
  end

  #function to write a goto/if goto line in assembly
  def write_goto
    if @parser[0] == "if-goto"
      pop_stack
      jump = true
    end
    write_file(string: "@#{@parser[1]}")
    write_file(string: "#{jump ? "D;JNE" : "0;JMP"}")
  end

  #function to write a function declaration line in assembly
  # initialize the functions local variables
  def write_function
    write_file(string: "(#{@parser[1]})")
    @parser[2].to_i.times do
      write_file(string: "@0\nD=A")
      push_stack
    end
    @function_name = @parser[1]
  end

  # function to write a function call line into hack assembly, and initialize the funcs arguments
  def write_call(init: false)
    @argument_count = init ? 0 : @parser[2]
    function_init
    write_file(string: "@#{init ? "Sys.init" : @parser[1]}\n0;JMP")
    write_file(string: "(RETURN#{@function_count - 1})", comment: "return address of #{init ? "Sys.init" : @parser[1]}")
  end

  #function to write a function return statement line into hack assembly
  def write_return
    write_file(string: "@5\nD=A\n@LCL\nA=M-D\nD=M\n@15\nM=D")
    pop_stack
    write_file(string: "@ARG\nA=M\nM=D\nD=A+1\n@SP\nM=D")
    %w[THAT THIS ARG LCL].each do |register|
      write_file(string: "@LCL\nAM=M-1\nD=M\n@#{register}\nM=D")
    end
    write_file(string: "@15\nA=M", comment: "going back to the return address of #{@parser[1]}")
    write_file(string: "0;JMP")
  end

  #helper function for write call that initializes the functions local variables
  def function_init
    write_file(string: "@RETURN#{@function_count}\nD=A")
    push_stack
    %w[LCL ARG THIS THAT].each do |register|
      write_file(string: "@#{register}\nD=M")
      push_stack
    end
    write_file(string: "@#{@argument_count.to_i + 5}\nD=A\n@SP\nD=M-D\n@ARG\nM=D\n@SP\nD=M\n@LCL\nM=D")
    @function_count += 1
  end

  # helper function for write_push and write_pop. It loads/stores the value of the statics variables

  def load_static(pop: false)
    write_file(string: "@#{@parser.file_name.upcase}.#{@parser[2]}")
    # If pop is true, store the value in D to the memory location. Otherwise, load the value into D
    write_file(string: "#{pop ? "M=D" : "D=M"}")
  end

  # Loads a variable from memory into the D register or stores the value in D to a memory location
  def load_memory(pop: false, save_from_r13: false)
    symbol_hash = Hash["local", "LCL", "argument", "ARG", "this", "THIS", "that", "THAT",
                       "pointer", "THIS", "temp", "5"]
    # Load the memory index into D
    write_file(string: "@#{@parser[2]}")
    write_file(string: "D=A")
    # Load the base address of the memory segment into A
    write_file(string: "@#{symbol_hash[@parser[1]]}")
    # Compute the memory address by adding the index to the base address
    write_file(string: "#{(@parser[1] == "temp" || @parser[1] == "pointer") ? "AD=A+D" : "AD=M+D"}")
    # If save_from_r13 is true, store the value in the D register to the memory location pointed to by R13
    # and then store the value in the R13 register to the memory location pointed to by A.
    # Otherwise, load the value into D
    write_file(string: "#{save_from_r13 ? "@14\nM=D\n@13\nD=M\n@14\nA=M\nM=D" : "D=M"}")
  end


  def push_stack(constant: nil)
    # Pushes a constant value onto the stack
    write_file(string: "@#{constant}\nD=A") if constant
    write_file(string: "@SP\nA=M\nM=D\n@SP\nM=M+1")
  end

  def pop_stack(save_to_d: true)
    # Pops a value off the stack
    # If save_to_d is true, the value popped will be saved in the D register
    write_file(string: "@SP\nM=M-1\nA=M#{save_to_d ? "\nD=M" : ""}")
  end

  def jump(jump_type)
    # Implements a jump instruction based on the provided jump type
    write_file(string: "@TRUE_JUMP", set_file_name: true, label: "@")
    write_file(string: "D; #{jump_type}\nD=0")
    write_file(string: "@FALSE_NO_JUMP", set_file_name: true, label: "@")
    write_file(string: "0;JMP")
    write_file(string: "(TRUE_JUMP", set_file_name: true, label: "(")
    write_file(string: "D=-1")
    write_file(string: "(FALSE_NO_JUMP", set_file_name: true, label: "(")
  end

  def arithmetic(calc:, jump_type: nil, unary: false)
    # Performs an arithmetic operation on the two topmost values on the stack
    # The operation is specified by the operator
    # If jump_type is provided, the result of the operation will be used as a boolean and the code will jump based on the jump type
    # If unary is true, the operation will only use one operand from the stack
    pop_stack
    pop_stack(save_to_d: false) if !unary
    write_file(string: "D=#{unary ? "" : "M"}#{calc}D")
    jump(jump_type) if jump_type
    push_stack
  end

  def write_bootstrap
    write_file(string: "@256\nD=A\n@SP\nM=D")
    write_call(init: true)
  end

  def close
    @asm_file.close
  end

  def write_file(string:"", set_line_number: false, comment: "", set_file_name: false, label: "")
    line_number = set_line_number ? @parser.line_number : ""
    if !set_file_name
      @asm_file.write("#{string}#{line_number}#{comment == "" ? "\n" : "//#{comment}\n"}")
    elsif label == "@"
      @asm_file.write("#{string}.#{@parser.file_name.upcase}.#{@parser.line_number}#{comment == "" ? "\n" : "//#{comment}\n"}")
    else
      @asm_file.write("#{string}.#{@parser.file_name.upcase}.#{@parser.line_number}#{comment == "" ? ")\n" : ")//#{comment}\n"}")
    end
  end
end

