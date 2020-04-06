require 'csv'

csv_opts = {}
csv_opts.merge!(headers: true)
csv_in = ::CSV.new(ARGF.read, csv_opts)
csv_out = ::CSV.new($stdout)
headers = nil
i = 0
csv_in.each do |row|
    unless headers
        headers = row.headers
        headers.push("Id")
        csv_out << headers
    end
    row['Id'] = i
    i+=1
    csv_out << row
end