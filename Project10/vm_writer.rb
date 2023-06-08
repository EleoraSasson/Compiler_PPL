# frozen_string_literal: true

class VMWriter

  def initialize
    @VMFile = (File.open("path", "w"))
  end

  def write_push(segment, index)
    @VMFile.puts("push #{segment} #{index}")
  end

  def write_pop(segment, index)
    @VMFile.puts("pop #{segment} #{index}")
  end

  def write_arithmetic(command)
    @VMFile.puts(command)
  end


  def write_label(label)
    @VMFile.puts("label #{label}")
  end

  def write_goto(label)
    @VMFile.puts("goto #{label}")
  end

  def write_if(label)
    @file.puts("if-goto #{label}")
  end

  def write_call(name, n_args)
    @file.puts("call #{name} #{n_args}")
  end

  def write_function(name, n_locals)
    @file.puts("function #{name} #{n_locals}")
  end

  def write_return
    @file.puts("return")
  end

  def close
    @file.close
  end
end
