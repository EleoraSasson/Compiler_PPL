require_relative 'parser'
class CodeWriter

  @@jump_number = 0

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
    label_name_input = @parser.arg1
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
    label_name_input = @parser.arg1
    label_name = func_name + label_name_input
    @file.write("(%s)\n" % label_name)
    @file.write("0;JMP\n")
  end

  def write_if_goto
    @file.write("// if-goto\n")
    func_name = @function_list.empty? ? '' : @function_list[-1] + "$"
    label_name_input = @parser.arg1
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
  def writePushPop (index)
    # no need to pass in command as an argument
    @command = @parser.command_type
    raise 'Invalid command type' unless %w[C_PUSH C_POP].include? @command
    arg1 = @parser.arg1
    #arg2 = @parser.arg2

    if @parser.command_type == 'C_PUSH'
      if arg1 == 'constant'
        # e.g. push constant 7
        @file.write("@" + index + "\n" + "D=A\n" + "@SP\n" + "A=M\n" + "M=D\n" + "@SP\n" + "M=M+1\n")
      elsif arg1 == 'local'
        @file.write(pushTemplate("LCL", index, false))
      elsif arg1 == 'argument'
        @file.write(pushTemplate("ARG", index, false))
      elsif arg1 == 'this'
        @file.write(pushTemplate("THIS", index, false))
      elsif arg1 == 'that'
        @file.write(pushTemplate("THAT", index, false))
      elsif arg1 == 'temp'
        @file.write(pushTemplate("R5", index.to_i+5, false))
      elsif arg1 == 'pointer' && index.to_i == 0
        @file.write(pushTemplate("THIS", index, true))
      elsif arg1 == 'pointer' && index.to_i == 1
        @file.write(pushTemplate("THAT", index, true))
      elsif arg1 == 'static'
        @file.write(pushTemplate((16+index.to_i).to_s, index, false))
      end
      # increase address of stack top
    elsif @parser.command_type == 'C_POP'
      if arg1 == 'constant'
        # e.g. push constant 7
        @file.write("@" + index + "\n" + "D=A\n" + "@SP\n" + "A=M\n" + "M=D\n" + "@SP\n" + "M=M+1\n")
      elsif arg1 == 'local'
        @file.write(popTemplate("LCL", index, false))
      elsif arg1 == 'argument'
        @file.write(popTemplate("ARG", index, false))
      elsif arg1 == 'this'
        @file.write(popTemplate("THIS", index, false))
      elsif arg1 == 'that'
        @file.write(popTemplate("THAT", index, false))
      elsif arg1 == 'temp'
        @file.write(popTemplate("R5", index.to_i+5, false))
      elsif arg1 == 'pointer' && index.to_i == 0
        @file.write(popTemplate("THIS", index, true))
      elsif arg1 == 'pointer' && index.to_i == 1
        @file.write(popTemplate("THAT", index, true))
      elsif arg1 == 'static'
        @file.write(popTemplate((16+index.to_i).to_s, index, false))
      end
    else
        # Throw an error for unrecognized segment
        raise "Error: Unrecognized memory segment #{arg1}"
      end
    end

  def pushTemplate(segment, index, is_direct)
    has_pointer = (is_direct) ? "" : "@#{index}\nA=D+A\nD=M\n"
    "@" + segment + "\n" + "D=M\n"+ has_pointer + "@SP\n" + "A=M\n" + "M=D\n" + "@SP\n" + "M=M+1\n";
  end

  def popTemplate(segment, index, is_direct)
  # When it is a pointer R13 will store the address of THIS or THAT
  # When it is a static R13 will store the index address
  has_pointer = (is_direct) ? "D=A\n" : "D=M\n@#{index}\nD=D+A\n"
  "@" + segment + "\n" + has_pointer + "@R13\nM=D\n" + "@SP\n" + "AM=M-1\n" + "D=M\n" + "@R13\nA=M\nM=D\n"
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
      @file.write("M=M+D\n")
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
      @file.write("AM=M-1\n")
      @file.write("D=M\n")
      @file.write("A=A-1\n")
      @file.write("D=M-D\n")
      @file.write("@FALSE")
      @file.write(@@jump_number)
      @file.write("\n")
      @file.write("D;")
      @file.write("JNE\n")
      @file.write("@SP\n")
      @file.write("A=M-1\n")
      @file.write("M=-1\n")
      @file.write("@CONTINUE")
      @file.write(@@jump_number)
      @file.write("\n0;JMP\n")
      @file.write("(FALSE")
      @file.write(@@jump_number)
      @file.write(")\n")
      @file.write("@SP\n")
      @file.write("A=M-1\n")
      @file.write("M=0\n")
      @file.write("(CONTINUE")
      @file.write(@@jump_number)
      @file.write(")\n")
      @@jump_number+=1

    elsif command == 'gt'
      # stack operation
      @file.write("@SP\n")
      @file.write("AM=M-1\n")
      @file.write("D=M\n")
      @file.write("A=A-1\n")
      @file.write("D=M-D\n")
      @file.write("@FALSE")
      @file.write(@@jump_number)
      @file.write("\n")
      @file.write("D;")
      @file.write("JLE\n")
      @file.write("@SP\n")
      @file.write("A=M-1\n")
      @file.write("M=-1\n")
      @file.write("@CONTINUE")
      @file.write(@@jump_number)
      @file.write("\n0;JMP\n")
      @file.write("(FALSE")
      @file.write(@@jump_number)
      @file.write(")\n")
      @file.write("@SP\n")
      @file.write("A=M-1\n")
      @file.write("M=0\n")
      @file.write("(CONTINUE")
      @file.write(@@jump_number)
      @file.write(")\n")
      @@jump_number+=1

    elsif command == 'lt'
      @file.write("@SP\n")
      @file.write("AM=M-1\n")
      @file.write("D=M\n")
      @file.write("A=A-1\n")
      @file.write("D=M-D\n")
      @file.write("@FALSE")
      @file.write(@@jump_number)
      @file.write("\n")
      @file.write("D;")
      @file.write("JGE\n")
      @file.write("@SP\n")
      @file.write("A=M-1\n")
      @file.write("M=-1\n")
      @file.write("@CONTINUE")
      @file.write(@@jump_number)
      @file.write("\n0;JMP\n")
      @file.write("(FALSE")
      @file.write(@@jump_number)
      @file.write(")\n")
      @file.write("@SP\n")
      @file.write("A=M-1\n")
      @file.write("M=0\n")
      @file.write("(CONTINUE")
      @file.write(@@jump_number)
      @file.write(")\n")
      @@jump_number+=1

    elsif command == 'and'
      @file.write("@SP\n")
      @file.write("AM=M-1\n")
      @file.write("D=M\n")
      @file.write("A=A-1\n")
      @file.write("M=M&D\n")

    elsif command == 'or'
      @file.write("@SP\n")
      @file.write("AM=M-1\n")
      @file.write("D=M\n")
      @file.write("A=A-1\n")
      @file.write("M=D|M\n")

    elsif command == 'neg'
      @file.write("D=0\n")
      @file.write("@SP\n")
      @file.write("A=M-1\n")
      @file.write("M=D-M\n")

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
        writePushPop(@parser.arg2)
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