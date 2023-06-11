# frozen_string_literal: true

class VMWriter

  def initialize(vm_path)
    @VMFile = (File.open(vm_path, "w"))
  end

  def write_push(segment, index)
    @VMFile.puts("push #{segment} #{index}")
  end

  def write_pop(segment, index)
    @VMFile.puts("pop #{segment} #{index}")
  end

  def write_arithmetic(command:, unary: false)
    case command
    when "+"
      @VMFile.puts("add")
    when "-"
      unary ? @VMFile.puts("sub") : @VMFile.puts("neg")
    when "="
      @VMFile.puts("eq")
    when ">"
      @VMFile.puts("gt")
    when "<"
      @VMFile.puts("lt")
    when "&"
      @VMFile.puts("and")
    when "|"
      @VMFile.puts("or")
    when "~"
      @VMFile.puts("not")
    else
      raise "not an arithmetic option"
    end
  end

  def create_label(label, filename, line_number, position)
    return "#{label}#{position}.#{filename}.#{line_number}"
  end


  def write_label(label)
    @VMFile.puts("label #{label}")
  end

  def write_goto(label)
    @VMFile.puts("goto #{label}")
  end

  def write_if(label)
    @VMFile.puts("if-goto #{label}")
  end

  def write_call(name, n_args)
    @VMFile.puts("call #{name} #{n_args}")
  end

  def write_function(name, n_locals)
    @VMFile.puts("function #{name} #{n_locals}")
  end

  def write_return(void)
    @VMFile.puts("return")
    @VMFile.puts("pop temp 0") if void
  end

  def close
    @VMFile.close
  end
end
