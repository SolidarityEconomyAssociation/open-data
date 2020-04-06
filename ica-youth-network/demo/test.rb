f = File.open("a.txt").read;
ok_pattern = "/\".+\"\,"
f.each_line do |line|
    line.encode!('UTF-8', 'UTF-8', :invalid => :replace)
    line.delete!("\xEF\xBB\xBF")
    line = line.sub('"','').sub(/.*\K\"/, '').gsub("'","").
        gsub("\"\"","$$").gsub("\"","").gsub("$$","\"")
        if(ok_pattern.match?(line))
            puts line
        else
            line.sub!(/.*\K\"/, '')
            strm = ","+line.split(',')[-2] +","+ line.split(',')[-1]
            line.insert(line.index(strm),"\"")
            puts line
        end
        # if string matches \".+\"\, then its good
        # if it doesn't match it, try to fix it
end

# remove all single quotes not followed by a quote 
# replace ' with empty
# replace double quotes with single quote
# make sure to place quote before the last two commas