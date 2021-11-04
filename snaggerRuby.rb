#python scrapper port to ruby
#now on the development branch 
#hello
puts "hello world"
a = [1, 2, 3]
b = a.map {|x| x**2}
puts "This is the array squared #{b}"
c = a.inject {|sum, x| sum + x}
puts "This is the value of the array squared and summed #{c}"


## do the same as above with a funcion 
def square(*args)
    puts "here is the array of arguments #{args}"
    args.map{|x| x**2}
end

## do the the same as above with another funtion have user input args
def sum(args)
    puts "this is the array of args you entered: #{args}"
    args.inject{|sum, x| sum + x}
end

a = square(1, 2, 3)
puts "This is the array of args squared #{a}"

puts "enter arguments to sum \n enter q to quit"
a = []
(0...3).each{|x| a << gets.chomp.to_i}
b = sum(a)
puts "this is the is the sum of your arguments: #{b}"