# frozen_string_literal: true
require_relative 'tokenizer'
class Main

  puts("Please enter a jack file or a directory containing a jack file")
  #path = 'C:\Users\eleor\OneDrive\Bureau\Year 4\Semester 2\Fundamentals\nand2tetris\nand2tetris\projects\10\ArrayTest\Main.jack'
  path = gets.chomp
  if path.start_with?('"') && path.end_with?('"')
    # remove the double quotes from the input string using gsub and a regular expression
    path = path.gsub(/^"|"$/, '')
  end
  @token = Tokenizer.new(path)
  @token.write_token_file
end
