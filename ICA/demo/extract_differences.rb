require 'csv'

csv_opts = {headers: true}

csv_in = ::CSV.new(File.read(ARGV[0]), csv_opts)
csv_urls = ::CSV.new(File.read(ARGV[1]),csv_opts)
csv_out = "results.csv"
id_header_std = '﻿Contact ID'
url_prefix = "https://w3id.solidarityeconomy.coop/ICA/"

url_array = []
headers = false
csv_urls.each {|row|
    unless headers
        headers = row.headers
    end
    url_array.push row[headers[0]]
}

headers = false
rows_to_add = []
csv_in.each{ |row|
    unless headers
        headers = row.headers
    end

    if !url_array.include? "#{url_prefix}#{row[id_header_std]}"
        rows_to_add.push row
    end

}

h = false
CSV.open(csv_out, "w") do |csv|
    unless h
        csv << headers
        h = true
    end

    rows_to_add.each {|r|
        csv << r
    }
end
