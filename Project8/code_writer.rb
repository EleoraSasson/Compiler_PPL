class CodeWriter
  #sets the output asm file
  def initialize(path)
    @parser = Parser.new(path)
    @filename = "#{File.dirname(path)}/#{File.basename(path, ".vm")}.asm"
    @file = File.open(@filename, 'w')
    @static_var = File.basename(File.dirname(path)) # useful in declaring static variables
    @function_list = []
  end

  def write_label
    @file.write("// label \n")
    begin
      func_name = @function_list[-1] + "$"
    rescue
      func_name = ''
    end
    label_name_input = @parser.arg1()
    label_name = func_name + label_name_input
      @file.write("(%s)\n" % label_name)
  end

  def write_goto
    @file.write("// goto\n")
    begin
      func_name = @function_list[-1] + "$"
    rescue
      func_name = ''
    end
    label_name_input = @parser.arg1()
    label_name = func_name + label_name_input
    @file.write("(%s)\n" % label_name)
    @file.write("0;JMP\n")
  end

  def write_if_goto
    @file.write("// if-goto\n")
    begin
      func_name = @function_list[-1] + "$"
    rescue
      func_name = ''
    end
    label_name_input = @parser.arg1()
    label_name = func_name + label_name_input
    @file.write("@SP\n")
    @file.write("A=M-1\n")
    @file.write("D=M\n")
    @file.write("@SP\n")    # adjust stack top
    @file.write("M=M-1\n")
    @file.write("@%s\n" % label_name)
    @file.write("D;JNE\n")
  end
  #sets arg1 and arg2, and translates into asm commands accordingly
  def writePushPop
    # no need to pass in command as an argument
    @command = @parser.command_type
    raise 'Invalid command type' unless %w[C_PUSH C_POP].include? @command
    arg1 = @parser.arg1
    arg2 = @parser.arg2

    if @parser.command_type == 'C_PUSH'
      if arg1 == 'constant'
        # e.g. push constant 7
        @file.write("@#{arg2}\n")  #@val
        @file.write("D=A\n")    # D = 7
        @file.write("@SP\n")
        @file.write("A=M\n")
        @file.write("M=D\n")    # M[M[base_address]] = 7
      elsif %w[temp pointer local argument this that].include? arg1
        @file.write("@#{arg2}\n")
        @file.write("D=A\n")
        if arg1 == 'temp'
          @file.write("@5\n")
          @file.write("A=D+A\n")
        elsif arg1 == 'pointer'
          @file.write("@3\n")
          @file.write("A=D+A\n")
        elsif arg1 == 'local'
          @file.write("@LCL\n")
          @file.write("A=D+M\n")
        elsif arg1 == 'argument'
          @file.write("@ARG\n")
          @file.write("A=D+M\n")
        elsif arg1 == 'this'
          @file.write("@THIS\n")
          @file.write("A=D+M\n")
        elsif arg1 == 'that'
          @file.write("@THAT\n")
          @file.write("A=D+M\n")
        end
        @file.write("D=M\n")
        @file.write("@SP\n")
        @file.write("A=M\n")
        @file.write("M=D\n")
      elsif arg1 == 'static'
        # declare a new symbol file.j in "push static j"
        @file.write("@#{@static_var}.#{arg2}\n")
        @file.write("D=M\n")
        # push D's value to the stack
        @file.write("@SP \n")
        @file.write("A=M \n")
        @file.write("M=D \n")
      end
      # increase address of stack top
      @file.write("@SP\n")
      @file.write("M=M+1\n")  # M[base_address] = M[base_address] + 1
    elsif @parser.command_type == 'C_POP'
      # pop the stack value and store it in segment[index]
      # use general purpose RAM[13] to store the value of 'segment_base_address + index'
      @arg2 = arg2.to_s
      @file.write("@#{@arg2}\n")
      @file.write("D=A\n")
      if %w[temp pointer local argument this that].include?(arg1)
        if arg1 == 'local'
          @file.write("@LCL\n")
          @file.write("D=D+M\n")
        elsif arg1 == 'argument'
          @file.write("@ARG\n")
          @file.write("D=D+M\n")
        elsif arg1 == 'this'
          @file.write("@THIS\n")
          @file.write("D=D+M\n")
        elsif arg1 == 'that'
          @file.write("@THAT\n")
          @file.write("D=D+M\n")
        elsif arg1 == 'temp'
          @file.write("@5\n")
          @file.write("D=D+A\n")
        elsif arg1 == 'pointer'
          @file.write("@3\n")
          @file.write("D=D+A\n")
        else
          # Throw an error for unrecognized segment
          raise "Error: Unrecognized memory segment #{arg1}"
        end
        # self.file.write('D=D+M\n')
        @file.write("@13\n") # general purpose register
        @file.write("M=D\n")
        @file.write("@SP\n")
        @file.write("A=M-1\n")
        @file.write("D=M\n") # pop command
        @file.write("@13\n")
        @file.write("A=M\n")
        @file.write("M=D\n") # write to appropriate address
        @file.write("@SP\n")
        @file.write("M=M-1\n") # adjust address of stack top
      elsif arg1 == 'static'
        @file.write("@SP\n")
        @file.write("A=M-1\n")
        @file.write("D=M\n") # pop command
        @file.write("@#{@static_var}.#{@arg2}\n")
        @file.write("M=D\n") # write to appropriate address
        @file.write("@SP\n")
        @file.write("M=M-1\n") # adjust address of stack top
      else
        # Throw an error for unrecognized segment
        raise "Error: Unrecognized memory segment #{arg1}"
      end
    end
  end

  #writes the asm code for an arithmetic command
  def writeArithmetic
    raise "Command must be an arithmetic command" unless @parser.command_type == "C_ARITHMETIC"
    command = @parser.arg1

    if command == "add"
      # stack operation
      @file.write("@SP\n")
      @file.write("AM=M-1\n")
      @file.write("D=M\n")
      @file.write("A=A-1\n")
      @file.write("M=D+M\n")
    elsif command == "sub"
      # stack operation
      @file.write("@SP\n")
      @file.write("AM=M-1\n")
      @file.write("D=M\n")
      @file.write("A=A-1\n")
      @file.write("M=M-D\n")

    elsif command == 'eq'
      # stack operation
      @file.write("@SP\n")
      @file.write("A=M-1\n")
      @file.write("D=M\n")
      @file.write("A=A-1\n")
      @file.write("D=M-D\n")
      @file.write("@IF_TRUE_#{@cmd_index}\n")  # there could be more than one "eq" command
      @file.write("D;JEQ\n")
      @file.write("@SP\n")
      @file.write("A=M-1\n")
      @file.write("A=A-1\n")
      @file.write("M=0\n")
      @file.write("@END_#{@cmd_index}\n")  # there could be more than one "eq" command
      @file.write("0;JMP\n")
      @file.write("(IF_TRUE_#{@cmd_index})\n")
      @file.write("@SP\n")
      @file.write("A=M-1\n")
      @file.write("A=A-1\n")
      @file.write("M=-1\n")
      @file.write("(END_#{@cmd_index})\n")
      @file.write("@SP\n")
      @file.write("M=M-1\n")

    elsif command == 'gt'
      # stack operation
      @file.write("@SP\n")
      @file.write("A=M-1\n")
      @file.write("D=M\n")
      @file.write("A=A-1\n")
      @file.write("D=M-D\n")
      @file.write("@IF_TRUE_#{@cmd_index}\n")  # there could be more than one "gt" command
      @file.write("D;JGT\n")
      @file.write("@SP\n")
      @file.write("A=M-1\n")
      @file.write("A=A-1\n")
      @file.write("M=0\n")
      @file.write("@END_#{@cmd_index}\n")  # there could be more than one "gt" command
      @file.write("0;JMP\n")
      @file.write("(IF_TRUE_#{@cmd_index})\n")
      @file.write("@SP\n")
      @file.write("A=M-1\n")
      @file.write("A=A-1\n")
      @file.write("M=-1\n")
      @file.write("(END_#{@cmd_index})\n")
      @file.write("@SP\n")
      @file.write("M=M-1\n")

    elsif command == 'lt'
      @file.write("@SP\n")
      @file.write("A=M-1\n")
      @file.write("D=M\n")
      @file.write("A=A-1\n")
      @file.write("D=M-D\n")
      @file.write("@IF_TRUE_#{@cmd_index}\n") # there could be more than one "lt" command
      @file.write("D;JLT\n")
      @file.write("@SP\n")
      @file.write("A=M-1\n")
      @file.write("A=A-1\n")
      @file.write("M=0\n")
      @file.write("@END_#{@cmd_index}\n") # there could be more than one "lt" command
      @file.write("0;JMP\n")
      @file.write("(IF_TRUE_#{@cmd_index})\n")
      @file.write("@SP\n")
      @file.write("A=M-1\n")
      @file.write("A=A-1\n")
      @file.write("M=-1\n")
      @file.write("(END_#{@cmd_index})\n")
      @file.write("@SP\n")
      @file.write("M=M-1\n")

    elsif command == 'and'
      @file.write("@SP\n")
      @file.write("AM=M-1\n")
      @file.write("D=M\n")
      @file.write("A=A-1\n")
      @file.write("M=D&M\n")

    elsif command == 'or'
      @file.write("@SP\n")
      @file.write("AM=M-1\n")
      @file.write("D=M\n")
      @file.write("A=A-1\n")
      @file.write("M=D|M\n")

    elsif command == 'neg'
      @file.write("@SP\n")
      @file.write("A=M-1\n")
      @file.write("M=-M\n")

    elsif command == 'not'
      @file.write("@SP\n")
      @file.write("A=M-1\n")
      @file.write("M=!M\n")
    end
  end

  #advances into the vm file and translates the file line by line, until closed
  def create_output
    while @parser.has_more_commands
      @parser.advance
      c_type = @parser.command_type
      if c_type == 'C_PUSH' || c_type == 'C_POP'
        writePushPop
      elsif c_type == 'C_ARITHMETIC'
        writeArithmetic
      elsif c_type == 'C_IF'
        write_if_goto
      elsif c_type == 'C_GOTO'
        write_goto
      elsif c_type == 'C_LABEL'
        write_label
      end
    end
    @file.close
  end
  end

