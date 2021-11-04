#python scrapper port to ruby
#now on the development branch 
#hello
puts "hello world"
a = [1, 2, 3]
<<<<<<< HEAD
a.map {|x| x**2}
puts "This is the array squared #{a}"
=======
b = a.map {|x| x**2}
puts "This is the array squared #{b}"
c = a.inject {|sum, x| sum + x}
puts "This is the value of the array squared and summed #{c}"
puts "saving "
puts "test"
>>>>>>> develop
