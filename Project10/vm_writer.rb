# frozen_string_literal: true

class VMWriter

  def initialize(vm_path)
    @VMFile = (File.open(vm_path, "w"))
  end

  def write_push(segment:, index:)
    write_vm(command_line: "push #{segment} #{index}")
  end

  def write_pop(segment:, index:)
    write_vm(command_line: "pop #{segment} #{index}")
  end

  def write_arithmetic(command:, unary: false)
    case command
    when "+"
      write_vm(command_line: "add")
    when "-"
      unary ? write_vm(command_line: "neg") : write_vm(command_line: "sub")
    when "="
      write_vm(command_line: "eq")
    when ">"
      write_vm(command_line: "gt")
    when "<"
      write_vm(command_line: "lt")
    when "&"
      write_vm(command_line: "and")
    when "|"
      write_vm(command_line: "or")
    when "~"
      write_vm(command_line: "not")
    else
      raise "not an arithmetic option"
    end
  end

  def create_label(label:, filename:, line_number: nil, position: nil)
    return "#{label}#{position}.#{filename}.#{line_number}"
  end

  def write_label(label_name:)
    write_vm(command_line: "label #{label_name}")
  end

  def write_goto(label_name:)
    write_vm(command_line: "goto #{label_name}")
  end

  def write_if(label_name:)
    write_vm(command_line: "if-goto #{label_name}")
  end

  def write_call(command_name:, argument_count:)
    write_vm(command_line: "call #{command_name} #{argument_count}")
  end

  def write_function(command_name:, var_count:)
    write_vm(command_line: "function #{command_name} #{var_count}")
  end

  def write_return(void: false)
    write_vm(command_line: "return")
    write_vm(command_line: "pop temp 0") if void
  end

  def close
    @VMFile.close
  end

  def write_vm(command_line:, continue: false)
    @VMFile.write(command_line+ "#{continue ? "" : "\n"}")
  end
  
end
