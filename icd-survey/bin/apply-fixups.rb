#!/usr/bin/env ruby
# coding: utf-8

# This amends certain entries of the data input to set values defined
# manually, when that is needed. It is only useful

require 'csv'

def read_csv(file)
  CSV.read(file, headers:true)
end

survey_data = read_csv(ARGV[0])

puts survey_data[0].headers.join(",")
survey_data.each do |row|
  unless row.header_row?
    case row['ICAID']&.to_i
    when 103
      # unused currently
      expect = <<HERE.strip 
General information JCCU (official name: Japanese Consumers' Cooperative Union) is the union of national co-operatives based on the Consumers' Co-operative Livelihood Law (commonly known as the Coop Law). Fulfills the following functions:

●Formulation of co-op national policies.

●Representation of co-op's views at national and international levels.

●Planning, development and supply of CO･OP Brand Products.

●Procurement and distribution of products including national brand products and imports.

●Other business operations including catalog and online sales.

●Coordination of member activities at national level.

●Guidance of member co-op management and staff education through correspondence courses and seminars.

The Japanese Consumer Co-operative is the largest consumer union in Japan.

Co-op is engaged in varieties of businesses and any of those is a need-driven one. The main objective is to improve the welfare of its members. Therefore they perform social and cultural activities going far beyond their economic operations.

Governance Consumers' cooperatives utilize the cooperative principle of democratic member control, or one member/one vote. Most consumers' cooperatives have a board of directors elected by and from the membership. The board is usually responsible for hiring management and ensuring that the cooperative meets its goals, both fiscal and otherwise. Democratic functions, such as petitioning or recall of board members, may be codified in the bylaws or organizing document of the cooperative. Most consumers' cooperatives hold regular membership meetings (often once a year). HistoryThe history of Japanese Consumers' Co-operative dates back in the 1919. Japanese Co-operative Society was initiated during the era of Taisho democracy. In 1919, the ""Katei Kobai (purchasing) union"" was established in Tokyo. During the following year, 1920, the ""Kyoueki-sha Kobai union"" was established, in Osaka, and in 1921 the ""Limited responsibility Kobe Kobai union"" was also established in Kobe. This gives the starting history of the regional purchasing co-op. By entering the Showa period (1926), the strengthened economic control and the staffs' compulsory military drafts by war almost suffocated co-op. After the end of the war in 1945, in the severe food shortage and exceptional inflation, co-ops were established once again across the country. In 1947, about three million people became members nationwide. In 1948, the law for consumers' cooperative union was enacted and in 1951, Japan Consumers' Cooperative Union was established. During 1950s, co-ops for regional labors and institutional co-ops were established across the country. During the years of steep economic growth in 1960s, the consumers' movement against price inflations and harmful food additives was promoted. Co-op led the movement. Between the end of 1960s and 1970s, community residents as its members organized citizen's co-ops. These citizen's co-ops built up the non-store business such as joint purchasing and individual deliveries. Japanese co-ops are in a new developing period now. Today, Co-ops are an integral part of communities with 37% of all households in Japan belonging to a Co-op.( Source:  ""History"" , Japanese Consumers' Co-operative Union ( JCCU) website, Date of Access: May 23th 2016,

http://jccu.coop/eng/aboutus/history.php

“For a Better Tomorrow” http://jccu.coop/eng/public/pdf/better_2012.pdf,

“Facts&Figures 2014” http://jccu.coop/eng/public/pdf/ff_2014.pdf)
HERE
      warn "fixup 103"      
      row['Description'] = <<HERE.strip
General information JCCU (official name: Japanese Consumers' Cooperative Union) is the union of national co-operatives based on the Consumers' Co-operative Livelihood Law (commonly known as the Coop Law). Fulfills the following functions:

- Formulation of co-op national policies.
- Representation of co-op's views at national and international levels.
- Planning, development and supply of CO-OP Brand Products.
- Procurement and distribution of products including national brand products and imports.
- Other business operations including catalog and online sales.
- Coordination of member activities at national level.
- Guidance of member co-op management and staff education through correspondence courses and seminars.

The Japanese Consumer Co-operative is the largest consumer union in Japan.

Co-op is engaged in varieties of businesses and any of those is a need-driven one. The main objective is to improve the welfare of its members. Therefore they perform social and cultural activities going far beyond their economic operations.

Governance Consumers' cooperatives utilize the cooperative principle of democratic member control, or one member/one vote. Most consumers' cooperatives have a board of directors elected by and from the membership. The board is usually responsible for hiring management and ensuring that the cooperative meets its goals, both fiscal and otherwise. Democratic functions, such as petitioning or recall of board members, may be codified in the bylaws or organizing document of the cooperative. Most consumers' cooperatives hold regular membership meetings (often once a year).

...
HERE

    when 105
      # unused currently
      expect = <<HERE.strip
Throughout Japan, about 390,000 fishers (cooperative members) are engaged in fishery production activities, while conserving and fostering fishery resources, under the banner of mutually-supporting collaboration. These fishers join hands to organize JFs.
JFs serve as a core organization in fishing villages, protecting fishing grounds, fostering marine resources and marketing seafood. They also supply fishing materials and other daily commodities that are indispensable to cooperative members.
There are 1,057 (as of February 1, 2010) JFs along Japanese coastal areas.

JF Zengyoren is designed to protect the fishery management and lives of JF members, foster rich marine resources, contribute to the creation of enriched communities, and improve the social and economic status of cooperative members. It works in collaboration with JF (Japan Fisheries Cooperatives) and federation of JF. Toward its goals, it is stepping up activities to preserve, and hand down to future generations the blessings of the beautiful and blue seas.
The JF Zengyoren consists mainly of prefectural JF federations of fisheries cooperative associations, as well as about 1,057 fisheries cooperative associations engaged in coastal fishing activities throughout the nation.

The JF Group is active in the areas of supply business, marketing business and guidance services.

?The JF supply business provides all the necessary materials and commodities for fishing and dairy life.

?The JF marketing business provides a stable supply of seafood and quality processed foods for consumers, under the motto of ""safe and reliable seafood"".

?The JF guidance service aims to improve the fishing industry's status and reinforce the organizational development of the JF Group.

( Source: National Federation of Fisheries Co-operatives Associations (JF ZENGYOREN) website, Outline of JF ZENGYOREN, http://www.zengyoren.or.jp/, Date of Access: December 6th 2010)",,35.689304 139.765874
650,,National Federation of Fishers Cooperatives Ltd. (FISHCOPFED),http://www.fishcopfed.in,The National Federation of Fishers Co-operatives Ltd. (FISHCOPFED) is engaged mainly in welfare and promotional activities. It provides capacity building training to poor members/fishers of the country besides networking of PFCs and providing support for domestic and export marketing of fish.,,28.6138954 77.2090057
106,,National Federation of Forest Owners' Co-operative Associations (ZENMORI-REN),http://www.zenmori.org/,"Based on the spirit of cooperative association, the aim is for members to collaborate to promote business, to improve the economic and social status of the members, to promote conservation of forest resources and forest productivity.
HERE
      warn "fixup 105"
      row['Description'] = <<HERE.strip
Throughout Japan, about 390,000 fishers (cooperative members) are engaged in fishery production activities, while conserving and fostering fishery resources, under the banner of mutually-supporting collaboration. These fishers join hands to organize JFs.
JFs serve as a core organization in fishing villages, protecting fishing grounds, fostering marine resources and marketing seafood. They also supply fishing materials and other daily commodities that are indispensable to cooperative members.
There are 1,057 (as of February 1, 2010) JFs along Japanese coastal areas.

JF Zengyoren is designed to protect the fishery management and lives of JF members, foster rich marine resources, contribute to the creation of enriched communities, and improve the social and economic status of cooperative members. It works in collaboration with JF (Japan Fisheries Cooperatives) and federation of JF. Toward its goals, it is stepping up activities to preserve, and hand down to future generations the blessings of the beautiful and blue seas.
The JF Zengyoren consists mainly of prefectural JF federations of fisheries cooperative associations, as well as about 1,057 fisheries cooperative associations engaged in coastal fishing activities throughout the nation.

The JF Group is active in the areas of supply business, marketing business and guidance services.

The JF supply business provides all the necessary materials and commodities for fishing and dairy life.

The JF marketing business provides a stable supply of seafood and quality processed foods for consumers, under the motto of "safe and reliable seafood".

The JF guidance service aims to improve the fishing industry's status and reinforce the organizational development of the JF Group.

( Source: National Federation of Fisheries Co-operatives Associations (JF ZENGYOREN) website, Outline of JF ZENGYOREN, http://www.zengyoren.or.jp/, Date of Access: December 6th 2010)
HERE

    end
  end
  puts row.to_csv
end



