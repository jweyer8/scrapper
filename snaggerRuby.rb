require 'nokogiri'
require 'httparty'
require 'spreadsheet'

#get input from user
#get location 
#get desired price max/min
#get number of beds
def userInput()
    info = [:state, :city, :max_price, :min_price, :beds].zip(ARGV.cycle).to_h
    if info[:state].nil? 
        puts "Enter state: "
        info.merge!(state: gets.chomp.downcase[0..1])
    end
    if info[:city].nil?
        puts "Enter city: "
        info.merge!(city: gets.chomp.gsub(' ','-').gsub(' ','').downcase)
    end
    if info[:max_price].nil?
        puts "Enter max price: "
        info.merge!(max_price: gets.chomp.match(/\d+/)[0].to_i)
    end
    if info[:min_price].nil?
        puts "Enter min price: "
        info.merge!(min_price: gets.chomp.match(/\d+/)[0].to_i)
    end
    if info[:beds].nil?
        puts "Enter number of beds: "
        info.merge!(beds: gets.chomp.match(/\d+/)[0].to_i)
    end
end


#get correct HTML data based off user input
#use HTTParty to scrape the data from the url that is based off user input
#apartmentlist.com will be used as the main website
#spefic url will be based off what the user enters for desired location
#Nokogiri is used to parse the raw HTML that HTTParty scraped
def getHTML(base_url)
    begin 
        input = userInput()
        input = {state: 'wa', city: 'maple-valley', max_price: 2000, min_price: 1000, beds: 1}
        unparsed_page = HTTParty.get(base_url + '/' + input[:state] +  '/' + input[:city])
        parsed_page = Nokogiri::HTML(unparsed_page) 
        #raise a StandardError if web page doesn't exist (404 Error)
        raise StandardError.new unless parsed_page.xpath("//h1[starts-with(text(), 'Uh oh, we can') and contains(text(), 'find that page')]").empty? 
    rescue SocketError => bad_url
        puts "Invalid input\nTry again:"
        retry
    rescue StandardError => unknown_state 
        #retry getting user input if 404 error
        puts "Invalid city or state"
        puts "#{unknown_state.message}"
        retry 
    end
    listings(parsed_page, base_url, input)
end


#get viable floor plans 
#apartmentlist.com provides multiple floorplans for each apartment listing 
#this function looks at each floor plan and determines if it is valid based off user input
#if floor plan is valid it will be added to the array of valid appartments 
def plans(floor_plan_listings, input)
    floor_plans = []
    #go through all of the floor plans for the apartment and add to valid floor plan array if it's a fit
    floor_plan_listings.each_with_index do |floor_plan_listing, i|
        begin
            num_bed = floor_plan_listing.css("div:nth-of-type(1)").text.match(/(\d+)|Studio/)[0]
            price = floor_plan_listing.css("div:nth-of-type(2)").text.match(/(\$\d+,*\d+)|Ask/)[0].gsub(',','').gsub('$','')
            footage = floor_plan_listing.css("div:nth-of-type(3)").text.match(/\d+/)[0]
        #some floor plans don't provide some of the above data
        #if this data isn't prodived .text will be an invalid method call
        #rescue will catch this error and the plan will not be added to valid list
        #*** may want to change this control flow to allow for floor plans with missing info to the valid array
        #*** if above is desired add ensure block and neseccary code
        rescue NoMethodError
        else
            price == "Ask" ? price = -1 : price = price.to_i           # sometimes apartment price isn't provided and "Ask" is privided for price. change this to -1 for comparison sake
            num_bed == "Studio" ? num_bed = 0 : num_bed = num_bed.to_i # convert studio to 0 bed for comparison sake
            #add if the floor plan fits user inputs
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


#get valid listings 
#go through all listings on the page add add them to the valid appartment data structure if it's a fit
#each valid appartment will be added to an array of hashes 
#each hash provides a link, address, and valid floor plans for the apartment
def listings(parsed_page, base_url, input)
    apartment_listings = parsed_page.css("div[class*='-ListingCard']") #target all listings
    apartments = []
    #loop through all the listings on the page
    apartment_listings.each do |apartment_listing|
        floor_plan_listings = apartment_listing.css("div[class*='-Floorplans']>div")
        floor_plans = plans(floor_plan_listings, input)
        #unless there are no valid floor plans for the givin listing add the appartment to the valid array
        #see plans() function above
        unless floor_plans.empty?
            apartments << {
                name: apartment_listing.css('a').text,
                link: base_url + apartment_listing.css('a')[0].attributes['href'].value.to_s,
                address: apartment_listing.css('span').text,
                plans: floor_plans.map(&:dup)
            }
        end
        floor_plans.clear
    end
    apartments
end


#port data to an excel block for easy viewing
#see spreadsheet gem
def createXLS(apartments)
    #creat new excel object
    book = Spreadsheet::Workbook.new
    sheet = book.create_worksheet(name: 'First Sheet')
    #initate formats for excel cells
    format_full_border = Spreadsheet::Format.new :horizontal_align => :center, :weight => :bold, :border => :thin, :pattern_fg_color => :Silver, :pattern => 1
    format_bottom_border_bold = Spreadsheet::Format.new :horizontal_align => :center, :weight => :bold, :bottom => :thin, :top => :thin, :pattern_fg_color => :Silver, :pattern => 1
    format_bottom_border = Spreadsheet::Format.new :bottom => :thin, :horizontal_align => :right
    format_bold = Spreadsheet::Format.new :horizontal_align => :center, :weight => :bold
    format_blue = Spreadsheet::Format.new :color => :blue
    format_right = Spreadsheet::Format.new :horizontal_align => :right
    #write data to excel for every apartment scrapped
    apartments.each_with_index do |apartment, i|
        indx = i*10 #10 rows between each apartment data
        #formating
        #merge lambda fro easier merging of certain cells
        #takes in a 2d array [[row], [{start column, end column}]]
        add_merge = -> (row_col) {sheet.merge_cells(row_col[0], row_col[1][:start], row_col[0], row_col[1][:stop])}
        merges = [ [indx, {start: 0, stop: 5}], [indx+1, {start: 1, stop: 5}], [indx+2, {start: 1, stop: 5}], [indx+3, {start: 0, stop: 5}], [indx+4, {start: 0, stop: 1}], [indx+4, {start: 2, stop: 3}], [indx+4, {start: 4, stop: 5}]]
        merges.each(&add_merge)
        sheet.row(indx+2).set_format(1, format_blue)
        #format across 5 columns
        (0..5).each {|x| sheet.row(indx).set_format(x, format_full_border)}
        (0..5).each {|x| sheet.row(indx+3).set_format(x, format_bottom_border_bold)}
        (0..5).each {|x| sheet.row(indx+4).set_format(x, format_bold)}
        #entering data into cells
        sheet.row(indx).push(apartment[:name])
        sheet.row(indx+1).push("address", apartment[:address])
        sheet.row(indx+2).push("Link", "#{Spreadsheet::Link.new apartment[:link]}") #create hyperling
        sheet.row(indx+3).push("Floor Plans")
        sheet.row(indx+4).push("# Bedrooms", "","Price", "", "Sqrf")
        #for every valid floor plan listing within apartment write data
        #inludes price, number of beds, and square footage
        apartment[:plans].each_with_index do |plan, j|
            indx2 = indx+5+j
            [ [indx2, {start: 0, stop: 1}], [indx2, {start: 2, stop: 3}], [indx2, {start: 4, stop: 5}]].each(&add_merge)
            (0..5).each {|x| sheet.row(indx2).set_format(x, format_right)}
            sheet.row(indx2).push(plan[:num_bed], "", plan[:price], "", plan[:footage])
            if j+1 == apartment[:plans].length then (0..5).each {|x| sheet.row(indx2).set_format(x, format_bottom_border)} end
        end   
    end
     book.write "/Users/jweyer/Desktop/apartments.xls"
end


##########MAIN###############
 base_url = 'https://www.apartmentlist.com'
 apartments = getHTML(base_url)
 puts `clear`
#  puts apartments
 createXLS(apartments)



