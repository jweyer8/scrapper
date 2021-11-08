require 'nokogiri'
require 'httparty'
require 'byebug'


#get input from user
#get location 
#get desired price max/min
#get number of beds
def userInput()
    info = {}
    puts "Enter state: "
    info.merge!(state: gets.chomp.downcase[0..1])
    puts "Enter city: "
    info.merge!(city: gets.chomp.gsub(' ','-').gsub(' ','').downcase)
    puts "Enter max price: "
    info.merge!(max_price: gets.chomp.match(/\d+/)[0].to_i)
    puts "Enter min price: "
    info.merge!(min_price: gets.chomp.match(/\d+/)[0].to_i)
    puts "Enter number of beds: "
    info.merge!(beds: gets.chomp.match(/\d+/)[0].to_i)
end



#get correct HTML data based off user input
def getHTML(base_url)
    begin 
        input = userInput()
        puts "#{base_url + '/' + input[:state] +  '/' + input[:city]}"
        unparsed_page = HTTParty.get(base_url + '/' + input[:state] +  '/' + input[:city])
        parsed_page = Nokogiri::HTML(unparsed_page) 
        raise StandardError.new unless parsed_page.xpath("//h1[starts-with(text(), 'Uh oh, we can') and contains(text(), 'find that page')]").empty? 
    rescue SocketError => bad_url
        puts "Invalid input\nTry again:"
        retry
    rescue StandardError => unknown_state
        puts "Invalid city or state"
        puts "#{unknown_state.message}"
        retry 
    end
    listings(parsed_page, base_url, input)
end

#get viable plans 
def plans(floor_plan_listings, input)
    floor_plans = []
    floor_plan_listings.each_with_index do |floor_plan_listing, i|
        begin
            num_bed = floor_plan_listing.css("div:nth-of-type(1)").text.match(/(\d+)|Studio/)[0]
            price = floor_plan_listing.css("div:nth-of-type(2)").text.match(/(\$\d+,*\d+)|Ask/)[0].gsub(',','').gsub('$','')
            footage = floor_plan_listing.css("div:nth-of-type(3)").text.match(/\d+/)[0]
        rescue NoMethodError
        else
            price == "Ask" ? price = -1 : price = price.to_i
            num_bed == "Studio" ? num_bed = 0 : num_bed = num_bed.to_i
            if num_bed == input[:beds] && price <= input[:max_price] && (price >= input[:min_price] || price == -1)
                floor_plans << {
                    num_bed: num_bed,
                    price: price,
                    footage: footage
                }  
            end
        end
    end
    floor_plans
end

#get listings 
def listings(parsed_page, base_url, input)
    apartment_listings = parsed_page.css("div[class*='-ListingCard']")
    apartments = []
    floor_plans = []
    apartment_listings.each do |apartment_listing|
        floor_plan_listings = apartment_listing.css("div[class*='-Floorplans']>div")
        floor_plans = plans(floor_plan_listings, input)
        unless floor_plans.empty?
            apartments << {
                link: base_url + apartment_listing.css('a')[0].attributes['href'].value.to_s,
                address: apartment_listing.css('span').text,
                plans: floor_plans.map(&:dup)
            }
        end
        floor_plans.clear
    end
    apartments
end


##########MAIN###############
 base_url = 'https://www.apartmentlist.com'
 apartments = getHTML(base_url)
 puts `clear`
 puts "#{apartments}"

