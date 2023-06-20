class SymbolTable
  attr_accessor :parent_node, :hash, :previous,
                :static, :field, :var, :argument
  CLASS = /^static|field$/
  SUBROUTINE = /^var|argument$/

  def initialize(parent_node: nil, scope: "class")#()
    @hash = {} #symbol table
    @static = 0 #store the number of static variables
    @field = 0 #store the number of field variables in the class
    @var = 0  #store the number of var variables in the subroutine
    @argument = 0 #store the number of argument variables in the subroutine
    @parent_node = parent_node #symbol table of the enclosing class
    @scope = scope #class or subroutine
    %w(kind type index).each do |func_name| #define the methods for the class to retrieve the kind, type and index of a symbol
      define_singleton_method("#{func_name}_of") do |symbol_name|
        return nil if !search_symbol(symbol_name)
        res = search_symbol(symbol_name)[func_name.to_sym]
        return "this" if res == "field"
        return "local" if res == "var"
        return res
      end
    end
  end

  def duplicate(name)
    define(name: name, type: @type, kind: @kind)
  end
  def define(name:, type:, kind:) #add a new symbol to the symbol table
    @type = type
    @kind = kind
    @hash[name] = {type:type, kind:kind, index: var_count(kind: kind, inc: true),scope: @scope}
  end


  def clean_symbols(copy_field=false) #go through the symbol table and remove all the symbols (that are not static)
    @hash = {}
    @type = nil
    @kind = nil
    @scope = nil
    @static = 0
    @field = 0
    @var = 0
    @argument = 0
    @previous = nil

    if copy_field
      new_parent = SymbolTable.new
      @parent_node.hash.each_key do |k|
        if @parent_node.hash[k][:kind] == "static"
          new_parent.define(name: k, type: @parent_node.hash[k][:type], kind: "static")
        end
      end
      @parent_node = new_parent
    end
  end


  def var_count(kind:, inc: false) #return the number of variables of the given kind already defined in the current scope
    index = self.send(kind)
    self.send("#{kind}=", index + 1) if inc
    return index
  end

  def search_symbol(symbol_name) #search for the symbol in the symbol table
    temp_parent = @parent_node
    temp_hash = @hash
    while !@hash.has_key?(symbol_name) && @parent_node #if the symbol is not in the current symbol table, search in the parent symbol table
      @hash = parent_node.hash
      @parent_node = @parent_node.parent_node
    end
    res = @hash.has_key?(symbol_name) ?  @hash[symbol_name] : nil #return the symbol if it is found, nil otherwise
    @hash = temp_hash #reset data
    @parent_node = temp_parent
    return res
  end
end