# frozen_string_literal: true

class SymbolTable

  STATIC, FIELD, ARG, VAR, NONE = "static", "field", "argument", "var", "none"
  def initialize
    @class_table = {}
    @subroutine_table = {}
    @class_count = 0
    @subroutine_count = 0
  end

  def start_subroutine
    @subroutine_table = {}
    @subroutine_count = 0
  end

  def define
    case @parser[1]
    when STATIC, FIELD
      @class_table[@parser[2]] = [@parser[1], @parser[3], @class_count]
      @class_count += 1
    when ARG, VAR
      @subroutine_table[@parser[2]] = [@parser[1], @parser[3], @subroutine_count]
      @subroutine_count += 1
    end
  end


  def var_count(kind)
    case kind
    when STATIC, FIELD
      @class_count
    when ARG, VAR
      @subroutine_count
    end

    def kind_of(name)
      if @subroutine_table[name]
        @subroutine_table[name][0]
      elsif @class_table[name]
        @class_table[name][0]
      else
        NONE
      end
    end

    def type_of(name)
    end
    if @subroutine_table[name]
      @subroutine_table[name][1]
    elsif @class_table[name]
      @class_table[name][1]
    else
      NONE
    end

    def index_of(name)
      if @subroutine_table[name]
        @subroutine_table[name][2]
      elsif @class_table[name]
        @class_table[name][2]
      else
        NONE
      end
    end
  end
end

