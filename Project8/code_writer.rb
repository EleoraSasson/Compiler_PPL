require_relative 'parser'
class CodeWriter

  @@jump_number = 0
  @@label_count = 0

  #sets the output asm file
  def initialize(path)
    @parser = Parser.new(path)
    @filename = "#{File.dirname(path)}/#{File.basename(path, ".vm")}.asm"
    @file = File.open(path, 'w')
    @static_var = File.basename(File.dirname(path)) # useful in declaring static variables
    @function_list = []
    #write_bootstrap
  end
=begin
  def set_file_name(path)
    @parser = Parser.new(path)
  end
=end
  def write_bootstrap
    # bootstrap code
    @file.write("@256\n")
    @file.write("D=A\n")
    @file.write("@SP\n")
    @file.write("M=D\n")
    ## call Sys.init : call Sys.init 0
    # push return-address
    sys_init_ret_add = "return-address-sysinit"
   @file.write("@%s\n" % sys_init_ret_add)
   @file.write("D=A\n")
   @file.write("@SP\n")
   @file.write("A=M\n")
   @file.write("M=D\n")
   @file.write("@SP\n")
   @file.write("M=M+1\n")
    # push LCL
   @file.write("@LCL\n")
   @file.write("D=M\n")
   @file.write("@SP\n")
   @file.write("A=M\n")
   @file.write("M=D\n")
   @file.write("@SP\n")
   @file.write("M=M+1\n")
    # push ARG
   @file.write("@ARG\n")
   @file.write("D=M\n")
   @file.write("@SP\n")
   @file.write("A=M\n")
   @file.write("M=D\n")
   @file.write("@SP\n")
   @file.write("M=M+1\n")
    # push THIS
   @file.write("@THIS\n")
   @file.write("D=M\n")
   @file.write("@SP\n")
   @file.write("A=M\n")
   @file.write("M=D\n")
   @file.write("@SP\n")
   @file.write("M=M+1\n")
    # push THAT
   @file.write("@THAT\n")
   @file.write("D=M\n")
   @file.write("@SP\n")
   @file.write("A=M\n")
   @file.write("M=D\n")
   @file.write("@SP\n")
   @file.write("M=M+1\n")
    # ARG = SP - n - 5
   @file.write("@SP\n")
   @file.write("D=M\n")
   @file.write("@5\n")
   @file.write("D=D-A\n")
   @file.write("@ARG\n")
   @file.write("M=D\n")
    # LCL = SP
   @file.write("@SP\n")
   @file.write("D=M\n")
   @file.write("@LCL\n")
   @file.write("M=D\n")
   @file.write("@Sys.init\n")
   @file.write("0;JMP\n")
    # declare a label for the return-address
   @file.write("(%s)\n" % sys_init_ret_add)
  end
  def write_init
    @file.write("// init\n")
    # initially set the SP address to 256 (the address for the stack)
    @file.write("@256\n")
    @file.write("D=A\n")
    @file.write("@SP\n")
    @file.write("M=D\n")
    # set the local address to 300
    @file.write("@300\n")
    @file.write("D=A\n")
    @file.write("@LCL\n")
    @file.write("M=D\n")
    # set the argument address to 400
    @file.write("@400\n")
    @file.write("D=A\n")
    @file.write("@ARG\n")
    @file.write("M=D\n")
    # set the this address to 3000
    @file.write("@3000\n")
    @file.write("D=A\n")
    @file.write("@THIS\n")
    @file.write("M=D\n")
    # set the that address to 3010
    @file.write("@3010\n")
    @file.write("D=A\n")
    @file.write("@THAT\n")
    @file.write("M=D\n")
  end

  def write_label
    @file.write("// label\n")
    # check if label was declared within function; if so, label should carry function name
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
    #check about brackets
    @file.write("@")
    @file.write("%s\n" % @parser.arg1)
    @file.write("0;JMP\n")
  end

  def write_if_goto
    @file.write("// if-goto\n")
    # check if 'if-goto' was declared within function; if so, label should carry function name
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

  def write_call
    func_name = @parser.arg1()
    num_args = @parser.arg2()
    #@file.write("// call #{func_name} #{num_args}\n")
    # push return-address (using label declared below)
    #@file.write("// call : push return-address\n")
    s = "RETURN_ADDRESS_#{@cmd_index}"  # there could be more than one return_addresses in the entire code
    @file.write("@#{s}\n")
    @file.write("D=A\n")
    @file.write("@SP\n")
    @file.write("A=M\n")
    @file.write("M=D\n")
    @file.write("@SP\n")
    @file.write("M=M+1\n")
    # push LCL
    #@file.write("// call : push LCL\n")
    @file.write("@LCL\n")
    @file.write("D=M\n")
    @file.write("@SP\n")
    @file.write("A=M\n")
    @file.write("M=D\n")
    @file.write("@SP\n")
    @file.write("M=M+1\n")
    # push ARG
    #@file.write("// call : push ARG\n")
    @file.write("@ARG\n")
    @file.write("D=M\n")
    @file.write("@SP\n")
    @file.write("A=M\n")
    @file.write("M=D\n")
    @file.write("@SP\n")
    @file.write("M=M+1\n")
    # push THIS
    #@file.write("// call : push THIS\n")
    @file.write("@THIS\n")
    @file.write("D=M\n")
    @file.write("@SP\n")
    @file.write("A=M\n")
    @file.write("M=D\n")
    @file.write("@SP\n")
    @file.write("M=M+1\n")
    # push THAT
    #@file.write("// call : push THAT\n")
    @file.write("@THAT\n")
    @file.write("D=M\n")
    @file.write("@SP\n")
    @file.write("A=M\n")
    @file.write("M=D\n")
    @file.write("@SP\n")
    @file.write("M=M+1\n")
    # ARG = SP - n - 5
    #@file.write("// call : ARG = SP - n - 5\n")
    @file.write("@SP\n")
    @file.write("D=M\n")
    @file.write("@#{num_args}\n")
    @file.write("D=D-A\n")
    @file.write("@5\n")
    @file.write("D=D-A\n")
    @file.write("@ARG\n")
    @file.write("M=D\n")
    # LCL = SP
    #@file.write("// call : LCL = SP\n")
    @file.write("@SP\n")
    @file.write("D=M\n")
    @file.write("@LCL\n")
    @file.write("M=D\n")
    # goto f
    #@file.write("// call : goto f\n")
    @file.write("@#{func_name}\n")
    @file.write("0;JMP\n")
    # declare a label for the return-address
    @file.write("// call : declare label for return-address\n")
    @file.write("(#{s})\n")

  end

  #for bootstrapping


  #assembly code for "return"
  def write_return
    @file.write("// return\n")
    # func_name = function_list.pop()
    ## FRAME = LCL : store FRAME in a temp variable
    @file.write("@LCL\n")
    @file.write("D=M\n")
    @file.write("@13\n")     # address of the temp variable FRAME
    @file.write("M=D\n")
    ## RET = *(FRAME - 5) : store return address in another temp variable
    @file.write("@13\n")
    @file.write("D=M\n")
    @file.write("@5\n")
    @file.write("D=D-A\n")
    @file.write("A=D\n")
    @file.write("D=M\n")    # D now equals *(FRAME - 5)
    @file.write("@14\n")     # address of the temp variable RET
    @file.write("M=D\n")
    ## *ARG = pop()
    @file.write("@SP\n")
    @file.write("A=M-1\n")
    @file.write("D=M\n")
    @file.write("@ARG\n")
    @file.write("A=M\n")
    @file.write("M=D\n")
    @file.write("@SP\n")
    @file.write("M=M-1\n")
    ## SP = ARG + 1
    @file.write("@ARG\n")
    @file.write("D=M+1\n")
    @file.write("@SP\n")
    @file.write("M=D\n")
    ## THAT = *(FRAME - 1)
    @file.write("@13\n")
    @file.write("A=M-1\n")
    @file.write("D=M\n")
    @file.write("@THAT\n")
    @file.write("M=D\n")
    ## THIS = *(FRAME - 2)
    @file.write("@13\n")
    @file.write("D=M\n")
    @file.write("@2\n")
    @file.write("A=D-A\n")
    @file.write("D=M\n")
    @file.write("@THIS\n")
    @file.write("M=D\n")
    ## ARG = *(FRAME - 3)
    @file.write("@13\n")
    @file.write("D=M\n")
    @file.write("@3\n")
    @file.write("A=D-A\n")
    @file.write("D=M\n")
    @file.write("@ARG\n")
    @file.write("M=D\n")
    ## LCL = *(FRAME - 4)
    @file.write("@13\n")
    @file.write("D=M\n")
    @file.write("@4\n")
    @file.write("A=D-A\n")
    @file.write("D=M\n")
    @file.write("@LCL\n")
    @file.write("M=D\n")
    ## goto RET
    @file.write("@14\n")     # address of RET
    @file.write("A=M\n")    # address = RET
    @file.write("0;JMP\n")

  end

  def write_function
    func_name = @parser.arg1()
    @function_list.append(func_name)
    num_locals = @parser.arg2()
    @file.write("// function %s %s\n" % [func_name, num_locals])
    @file.write("(%s)\n" % func_name)
    @file.write("@%s\n"  % num_locals)
    @file.write("D=A\n")
    @file.write("@13\n")
    @file.write("M=D\n")
    @file.write("(LOOP_%s)\n" % func_name)
    @file.write("@13\n")
    @file.write("D=M\n")
    @file.write("@END_%s\n" % func_name)
    @file.write("D;JEQ\n")
    # start logic for code to carry out while D != 0
    @file.write("@SP\n")
    @file.write("A=M\n")
    @file.write("M=0\n")    # M[M[base_address]] = 7
    @file.write("@SP\n")
    @file.write("M=M+1\n")  # M[base_address] = M[base_address] + 1
    @file.write("@13\n")
    @file.write("M=M-1\n")
    # end logic for code to carry out while D != 0
    @file.write("@LOOP_%s\n" % func_name)
    @file.write("0;JMP\n")
    @file.write("(END_%s)\n" % func_name)
  end

  #sets arg1 and arg2, and translates into asm commands accordingly
  def writePushPop 
    # no need to pass in command as an argument
    @command = @parser.command_type
    raise 'Invalid command type' unless %w[C_PUSH C_POP].include? @command
    arg1 = @parser.arg1
    arg2 = @parser.arg2

    if @parser.command_type == 'C_PUSH'
      # stack operation
      if arg1 == "constant"
        @file.write("@%s\n" % arg2)
        @file.write("D=A\n")    # D = 7
        @file.write("@SP\n")
        @file.write("A=M\n")
        @file.write("M=D\n")    # M[M[base_address]] = 7
      elsif %w[temp pointer local argument this that].include?(arg1)
        @file.write("@%s\n" % arg2)
        @file.write("D=A\n")
        if arg1 == "temp"
          @file.write("@5\n")
          @file.write("A=D+A\n")
        elsif arg1 == "pointer"
          @file.write("@3\n")
          @file.write("A=D+A\n")
        elsif arg1 == "local"
          @file.write("@LCL\n")
          @file.write("A=D+M\n")
        elsif arg1 == "argument"
          @file.write("@ARG\n")
          @file.write("A=D+M\n")
        elsif arg1 == "this"
          @file.write("@THIS\n")
          @file.write("A=D+M\n")
        elsif arg1 == "that"
          @file.write("@THAT\n")
          @file.write("A=D+M\n")
        end
          @file.write("D=M\n")
          @file.write("@SP\n")
          @file.write("A=M\n")
          @file.write("M=D\n")    # M[M[base_address]] = 7
      elsif arg1 == "static"
        @file.write(@static_var + arg2 + "\n")
        @file.write("D=M\n")
        @file.write("@SP\n")
        @file.write("A=M\n")
        @file.write("M=D\n")    # M[M[base_address]] = 7
      end
      @file.write("@SP\n")
      @file.write("M=M+1\n")  # M[base_address] = M[base_address] + 1

    elsif @parser.command_type == 'C_POP'  #TODO: why pop doesnt have constant
      @file.write("@%s\n" % arg2)
      @file.write("D=A\n")
      if %w[temp pointer local argument this that].include?(arg1)
        if arg1 == "local"
          @file.write("@LCL\n")
        @file.write("D=D+M\n")
        elsif arg1 == "argument"
          @file.write("@ARG\n")
        @file.write("D=D+M\n")
        elsif arg1 == "this"
          @file.write("@THIS\n")
        @file.write("D=D+M\n")
        elsif arg1 == "that"
          @file.write("@THAT\n")
        @file.write("D=D+M\n")
        elsif arg1 == "temp"
          @file.write("@5\n")
        @file.write("D=D+A\n")
        elsif arg1 == "pointer"
          @file.write("@3\n")
          @file.write("D=D+A\n")
        end
        @file.write("@13\n")
        @file.write("M=D\n")
        @file.write("@SP\n")
        @file.write("A=M-1\n")
        @file.write("D=M\n")
        @file.write("@13\n")
        @file.write("A=M\n")
        @file.write("M=D\n")
        @file.write("@SP\n")
        @file.write("M=M-1\n")
      elsif arg1 == "static"
        @file.write("@SP\n")
        @file.write("A=M-1\n")
        @file.write("D=M\n")
        @file.write(@static_var + arg2 + "\n")  #TODO: self is file
        @file.write("M=D\n")
        @file.write("@SP\n")
        @file.write("M=M-1\n")
      end
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
    write_bootstrap
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
      elsif c_type == 'C_FUNCTION'
        write_function
      elsif c_type == 'C_CALL'
        write_call
      elsif c_type == 'C_RETURN'
        write_return
      end
    end
    @file.close
  end

end