#python scrapper port to ruby
#now on the development branch 
#hello
puts "hello world"
a = [1, 2, 3]
b = a.map {|x| x**2}
puts "This is the array squared #{b}"
c = a.inject {|sum, x| sum + x}
puts "This is the value of the array squared and summed #{c}"
puts "saving "
