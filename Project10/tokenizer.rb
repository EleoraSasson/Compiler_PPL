# frozen_string_literal: true

KEYWORDS = /^(class|constructor|method|function|field|static|var|int|char|boolean|void|true|false|null|this|let|do|if|else|while|return)$/
SYMBOLS = /^({|}|\(|\)|\[|\]|\.|\,|\;|\+|\-|\*|\/|\&|\||<|>|=|-|~)$/
INTS = /^\d+$/
STRINGS = /^"[^"\n\r]*"$/
IDENTIFIER = /^[a-zA-Z]+[a-zA-Z_0-9]*$/
class Tokenizer

  def initialize(path_to_jack_file)
    @jack_file = File.open(path_to_jack_file, "r")
    #xml file is path of jack_file with .xml extension
    @xml_file = File.open(path_to_jack_file.gsub(/\.jack$/, ".xml"), "w")
    @current_command = ""
    @commands = []
    @current_index = 0
    write_command
  end

  def has_more_tokens?
    !@jack_file.eof?
  end
  def line_advance
    while has_more_tokens?
      @current_line = @jack_file.gets.strip.gsub(/(\/\/.*)|\r|\n/, "")
      delete_comments
      return @current_line if !@current_line || !@current_line.empty?
    end
  end

  def advance
    if @current_index == @commands.count
      return nil if !line_advance
      @current_index = 0
      split_line
    end
    @current_index += 1
    return @current_command = @commands[@current_index - 1]
  end
  def split_line
    @commands = split_symbols(@current_line)
  end

  def split_symbols(string)
    i = 0
    res = []
    strings = string.split(/(")/)
    while i < strings.length
      if strings[i] == '"'
        if strings[i + 1] != '"'
          res << '"' + strings[i + 1] + '"'
          i += i
        end
        i += 1
      else
        res << strings[i].split(/ |({|}|\(|\)|\[|\]|\.|\,|\;|\+|\-|\*|\/|\&|\||<|>|=|-|~)/)
      end
      i += 1
    end
    return res.flatten.select {|s| !s.empty?}
  end
=begin
  def advance
    while has_more_tokens?
      @current_line = @jack_file.gets.strip.gsub(/(\/\/.*)|\r|\n/, "")
      delete_comments
      return @current_line if !@current_line || !@current_line.empty?
    end
  end
=end

  def delete_comments
    while @current_line.include?("/**")
      while !has_more_tokens? && !@current_line.include?("*/")
        @current_line = @xml_file.gets.strip
      end
      return nil if !has_more_tokens?
      @current_line.gsub!(/\/\*\*.*\*\//, "")
      @current_line.gsub!(/.*\*\//, "")
    end
  end
  def token_type
    if @current_command.match(KEYWORDS)
      return("keyword")
    elsif @current_command.match(SYMBOLS)
      return("symbol")
    elsif @current_command.match(INTS)
      return("integerConstant")
    elsif @current_command.match(STRINGS)
      return("stringConstant")
    elsif @current_command.match(IDENTIFIER)
      return("identifier")
    else
      return nil
    end
  end

  def write_command
    advance until !@current_command.empty?
    @xml_file.write("<#{token_type}> ")
    if @current_command.include? ('"')
      @xml_file.write(@current_command[1..-2])
    elsif @current_command == "<"
      @xml_file.write("&lt;")
    elsif @current_command == ">"
      @xml_file.write("&gt;")
    elsif @current_command == "&"
      @xml_file.write("&amp;")
    else
      @xml_file.write(@current_command)
    end
    @xml_file.write(" </#{token_type}>\n")
  end

  def keyword
    @current_command if token_type == :keyword
  end

  def symbol
    @current_command if token_type == :symbol
  end

  def identifier
    @current_command if token_type == :identifier
  end

  def int_val
    @current_command.to_i if token_type == :integerConstant
  end

  def string_val
    @current_command.gsub(/"/, "") if token_type == :stringConstant
  end
end