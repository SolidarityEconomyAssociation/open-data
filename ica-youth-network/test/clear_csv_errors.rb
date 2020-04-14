require 'csv'


text=File.open(ARGV[0]).read
error_detected = false
headers = nil
csv_out = ::CSV.new($stdout)
count = 0
text.each_line do |line|
    if !headers # if there's an error in the headers there's an error in the file
        headers = line
        if line.include? "\""
            error_detected = true
        end
    end
    if error_detected
        line.encode!('UTF-8', 'UTF-8', :invalid => :replace)
        line.delete!("\xEF\xBB\xBF")
        line = line.sub('"','').sub(/.*\K\"/, '').gsub("'","").
        gsub("\"\"","replaceMeWithQuote").gsub("\"","").gsub("replaceMeWithQuote","\"")
        $stdout.print(line) 
            # line = line.sub(/.*\K\"/, '')
            # strm = ","+line.split(',')[-2] +","+ line.split(',')[-1]
            # line.insert(line.index(strm),"\"")
    else
        $stdout.print(line)
    end
        
end

# remove all single quotes not followed by a quote 
# replace ' with empty
# replace double quotes with single quote
# make sure to place quote before the last two commas