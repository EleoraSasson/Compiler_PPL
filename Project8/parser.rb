# defining constants to be used in the program
C_ARITHMETIC ="C_ARITHMETIC"
C_PUSH = "C_PUSH"
C_POP = "C_POP"
C_LABEL = "C_LABEL"
C_GOTO = "C_GOTO"
C_IF = "C_IF"
C_FUNCTION = "C_FUNCTION"
C_CALL = "C_CALL"
C_RETURN = "C_RETURN"
S_COMMAND = "S_COMMAND"
S_ARG1 = "S_ARG1"
S_ARG2 = "S_ARG2"

class Parser
  #opens the vm file in reading mode
  def initialize(filename)
    @vm_file = File.open(filename, "r")
    @raw_lines = @vm_file.readlines  # rawlines is an array of strings (lines of the file)
    @clean_lines = []
    @raw_lines.each do |line|
      next if line[0..1] == "//" || line == "\n"     # skips empty or comment lines
      line = line.split("//").first if line.include?("//")     # if the line contains a comment, keep the part without the comment
      line.delete!(" ")    #delete spaces on the line
      l = []
      line.each_char { |ch| l << ch unless ['', "\n"].include?(ch) }    # l is an array of char that holds the clean version of the line
      @clean_lines << l.join('')    # adds the line to cleanline
    end
    @cmd_index = -1
    @command = nil
    @total_commands = @clean_lines.length
  end

  #checks if the vmf has more commands left
  def has_more_commands
    @cmd_index < @total_commands -1
  end

  #reads the next command and sets command to the current command
  def advance
    if has_more_commands
      @cmd_index += 1
      @command = @clean_lines[@cmd_index]
    end
  end

  # returns the command type of the line
  def command_type
    if %w[add sub neg eq gt lt and or not].include?(@command)
      return C_ARITHMETIC
    elsif @command.include?('push')
      return C_PUSH
    elsif @command.include?('pop')
      return C_POP
    elsif @command.include?('label')  #for next project
      return C_LABEL
    elsif @command.include?('push')
      return C_GOTO
    elsif @command.include?('label')
      return C_LABEL
    elsif @command.include?('if')
      return C_IF
    elsif @command.include?('goto')
      return C_GOTO
    elsif @command.include?('function')
      return C_FUNCTION
    elsif @command.include?('call')
      return C_CALL
    elsif @command.include?('return')
      return C_RETURN
    else
      raise "Unrecognized command type"
    end
  end

  #if arithmetic, returns the command
  # if push or pop, returns memory location (pushpointer8 will return pointer)
  def arg1
    if %w[add sub neg eq gt lt and or not].include?(@command)
      return @command
    elsif @command.include?('push')
      s = @command.split('push')[1]
      s.each_char.with_index do |ch, ind|
        if ch.match?(/\d/)
          return s[0...ind]
        end
      end
    elsif @command.include?('pop')
      # pop segment index
      s = @command.split('pop')[1]
      s.each_char.with_index do |ch, ind|
        if ch.match?(/\d/)
          return s[0...ind]
        end
      end
    elsif @command.include?('label')
      # label symbol
      return @command.split('label')[1]
    elsif @command.include?('if_goto')
      return @command.split('if_goto')[1]
    elsif @command.include?('goto')
      return @command.split('goto')[1]
    elsif @command.include?('function')
      return @command.split('function')[1].gsub(/\d+$/, '')
    elsif @command.include?('call')
      return @command.split('call')[1]
    elsif @command.include?('return')
      return @command.split('return')[1]
    else
      raise "Unrecognized command type when trying to obtain arg1"
    end
  end

  #in case of push, pop, returns the numeric value (pushpointer8 will return 8)
  def arg2
    @command.each_char.with_index do |ch, ind|
      if ch.match?(/\d/)
        return @command[ind..-1]
      end
    end
  end
end