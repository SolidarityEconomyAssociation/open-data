# Mapping new CSV schemas to the standard CSV schema

Whenever a new data source is added, perhaps because of a new project
or an existing project's schema changes, there needs to be a mapping
created to the standard CSV schema.



## An example

There are three CSV files supplied from Co-ops UK. The names of these
seem to vary, but are typically something like
`open_data_administrative_areas.csv`, `open_data_economic.csv`, etc.

The headings of these files are as follows.

### Co-Ops UK data

#### Administrative areas

- CUK Organisation ID
- Registered Name
- Area Type
- Area Name

#### Economic

- CUK Organisation ID
- Registered Name
- Turnover
- Profit before tax
- Member/Shareholder Funds
- Memberships
- Employees
- GVA
- Is Most Recent?
- Year End Date
- Economic Year

#### Organisations

- CUK Organisation ID
- Registered Number
- Registrar
- Registered Name
- Trading Name
- Legal Form
- Registered Street
- Registered City
- Registered State/Province
- Registered Postcode
- UK Nation
- SIC Code
- SIC section
- SIC code  - level 2
- SIC code  - level 2 description
- SIC code  - level 3
- SIC code  - level 3 description
- SIC code  - level 4
- SIC code  - level 4 description
- SIC code  - level 5
- SIC code  - level 5 description
- Sector - Simplified, High Level
- Ownership Classification
- Registered Status
- Incorporation Date
- Dissolved Date

#### Outlets

- CUK Organisation ID
- Registered Name
- Outlet Name
- Street
- City
- State/Province
- Postcode
- Description
- Phone
- Website

### SEA open-data standard.csv

The output needs to be the standard open-data CSV schema, which is
normally in a file `standard.csv` and has headers as follows.

- Identifier
- Name
- Description
- Organisational Structure
- Primary Activity
- Activities
- Street Address
- Locality
- Region
- Postcode
- Country Name
- Website
- Phone
- Email
- Twitter
- Facebook
- Companies House Number
- Latitude
- Longitude
- Geo Container
- Geo Container Latitude
- Geo Container Longitude

### The process

In this example, taken from a real-life case which may now be
superseded, a makefile is used to coordinate the script
invocations. Configuration comes from makefiles `common.mk` and
deployment configuration from `editions/final.mk` (defined by the
`edition=final` parameter).

    $ cd co-ops-uk/2019-06/
    $ make -f csv.mk edition=final
	
The output is:

	mkdir -p generated-data/final/csv/
	ruby -I /home/example/open-data/tools/se_open_data/lib  co-ops-uk-outlets-converter.rb co-ops-uk-csv-data/open_data_outlets.csv > generated-data/final/csv/outlets.csv
	ruby -I /home/example/open-data/tools/se_open_data/lib  co-ops-uk-orgs-converter.rb co-ops-uk-csv-data/open_data_organisations.csv > generated-data/final/csv/organisations.csv
	ruby -I /home/example/open-data/tools/se_open_data/lib  ../../tools/se_open_data/bin/csv/merge-with-headers.rb generated-data/final/csv/outlets.csv generated-data/final/csv/organisations.csv > generated-data/final/csv/merged.csv
	ruby -I /home/example/open-data/tools/se_open_data/lib  ../../tools/se_open_data/bin/csv/standard/fix-duplicates.rb generated-data/final/csv/merged.csv > generated-data/final/csv/fixed-dups.csv
	ruby -I /home/example/open-data/tools/se_open_data/lib  ../../tools/se_open_data/bin/csv/standard/remove-duplicates.rb generated-data/final/csv/fixed-dups.csv > generated-data/final/csv/de-duplicated.csv 2> generated-data/final/csv/ignored-duplicates.csv
	Ignored duplicates have been written to generated-data/final/csv/ignored-duplicates.csv
	Total ignored: 0 generated-data/final/csv/ignored-duplicates.csv
	ruby -I /home/example/open-data/tools/se_open_data/lib  ../../tools/se_open_data/bin/csv/standard/add-postcode-lat-long.rb --postcodeunit-cache postcode_lat_lng.json  --postcode-global-cache os_postcode_cache.json generated-data/final/csv/de-duplicated.csv > generated-data/final/standard.csv
	Fetching geodata...  (100%)
	SAVING NEW CACHE
	ruby -I /home/example/open-data/tools/se_open_data/lib  ../../tools/se_open_data/bin/csv/standard/make-uri-name-postcode.rb --uri-prefix https://w3id.org/coops-uk/2019/ generated-data/final/standard.csv > generated-data/final/csv/uri-name-postcode.csv

(Note, at the time of writing, if `postcode_lat_lng.json` or
`os_postcode_cache.json` is missing the last step will fail - these
files need to exist)

As you can see, the makefile `csv.mk` controls a pipeline of processes
that converts just *two* of the CSV files from Coop UK's Open Data set
into a single CSV file in 'standard' format.  The 'standard' format
means that the column headings are as defined above, as expected by
the next step of the process.

    $ head -1 generated-data/final/standard.csv 
    Identifier,Name,Description,Legal Forms,Street Address,Locality,Region,Postcode,Country Name,Website,Companies House Number,Latitude,Longitude,Geo Container,Geo Container Latitude,Geo Container Longitide

A number of intermediate CSV files are generated, but the final product is the `standard.csv`:

    $ find generated-data/final
	generated-data/final
	generated-data/final/csv
	generated-data/final/csv/de-duplicated.csv
	generated-data/final/csv/fixed-dups.csv
	generated-data/final/csv/ignored-duplicates.csv
	generated-data/final/csv/merged.csv
	generated-data/final/csv/organisations.csv
	generated-data/final/csv/outlets.csv
	generated-data/final/csv/uri-name-postcode.csv
	generated-data/final/standard.csv

There are two scripts used to generate the csv.

- `co-ops-uk-outlets-converter.rb` reads `open_data_outlets.csv` and
  writes transformed data to `outlets.csv`
- `co-ops-uk-orgs-converter.rb` reads `open_data_organisations.csv`
  and writes transformed data to `organisations.csv`
- `merge-with-headers.rb` reads `outlets.csv` and `organisations.csv`
  and writes a concatenated list in `merged.csv`
- `fix-duplicates.rb` reads `merged.csv`, ensures duplicate ID fields
  are rewritten to unique values, and writes `fixed-dups.csv`
- `remove-duplicates.rb` reads `fixed-dups.csv` and separates unique
  rows into `de-duplicated.csv` and duplicates (those with fields from
  {SeOpenData::CSV::Standard::V1::UniqueKeys} matching an earlier
  row) into `ignored-duplicates.csv`
- `add-postcode-lat-long.rb` reads `postcode_lat_lng.json` (containing
  a cached UK postcode index) and `de-duplicated.csv` and writes
  `standard.csv` with the `geocontainer*` fields added.
- `make-uri-name-postcode.rb` reads `os_postcode_cache.json` (another
  cached UK postcode index) and `standard.csv` and writes a CSV
  version of the index with inititive names to `uri-name-postcode.csv`
   

### co-ops-uk-orgs-converter.rb

This class is adapted from the project `co-ops-uk/2019-06/`, in the
file `co-ops-uk-orgs-converter.rb`. It has since been supeceded, but
is the example referenced in `row_reader.rb`, and I shall use it as a
semi-concrete example case.

That script is one step in the process above. The others include
utility scripts included in `bin/csv`, which call methods of
{SeOpenData::CSV}.

An instance of this class is created by {SeOpenData::CSV.convert} for
each input row of the CSV, and passed a hash of field data parsed from
it. The data values are keyed by the CSV header fields on the first
line.

If the method `pre_flight_checks` is implemented, it will be called
first for each row.

{SeOpenData::CSV::RowReader} supplies common methods such as
{SeOpenData::CSV::RowReader#postcode_normalized #postcode_normalized}
and {SeOpenData::CSV::RowReader#add_comment #add_comment}.

Then the output data row is generated by calling the methods matching the
keys of `OutputStandard::Headers` in turn.


```
require 'se_open_data'

# This is the CSV standard that we're converting into:
OutputStandard = SeOpenData::CSV::Standard::V1

class CoopsUkOrgsReader < SeOpenData::CSV::RowReader

  # This hash is primarily used as a parameter to the constructor for SeOpenData::CSV::RowReader.
  #
  # It defines method names (keys) that this class should implement
  # as simple accessors for the row hash. For example:
  # 
  #     # Given an instance:
  #     reader = CoopsUkOrgsReader.new(fields)
  #
  #     # Then this will print the value of fields["Trading Name"]
  #     puts reader.name 
  #
  # 
  # Note, the method names typically match field IDs in OutputStandard::Headers,
  # but may not. For example, they may be added for other methods to access data fields
  # conveniently.
  #
  # This class must implement methods for all of the keys not listed here,
  # too. These will typically be the ones which need more complicated logic to 
  # transform. See {#companies_house_number} and {#legal_forms} for example.
  InputHeaders = {
    # These symbols match symbols in OutputStandard::Headers.
    name: "Trading Name",
    street_address: "Registered Street",
    locality: "Registered City",
    region: "Registered State/Province",
    postcode: "Registered Postcode",
    country_name: "UK Nation",
    id: "CUK Organisation ID",

    # These symbold don't match symbold in OutputStandard::Headers.
    # But CSV::RowReader creates method using these symbol names to read that colm from the row:
    registrar: "Registrar",
    registered_number: "Registered Number"
  }
  
  def initialize(row)
    # Let CSV::RowReader provide methods for accessing columns described by InputHeaders, above:
    super(row, InputHeaders)
  end
  
  # Some columns in the output are not simple copies of input columns:
  # Here are the methods for generating those output columns:
  # (So all method names below should aldo appear as keys in the output_headers Hash)
  def companies_house_number
    # Registered number with Companies House
    registrar == "Companies House" ? registered_number : nil
  end
  
  def legal_forms
    # Return a list of strings, separated by OutputStandard::SubFieldSeparator.
    # Each item in the list is a prefLabel taken from essglobal/standard/legal-form.skos.
    # See lib/se_open_data/essglobal/legal_form.rb
    [
      "Cooperative", 
      registrar == "Companies House" ? "Company" : nil
    ].compact.join(OutputStandard::SubFieldSeparator)
  end
end
```

The script `co-ops-uk-orgs-converter.rb` concludes with this loop,
which calls {SeOpenData::CSV.convert} on the input data (via
`ARGF.read`), supplying the output header definitions
(`OutputStandard::Headers`), the above converter class, an output
stream (`$stdout`) and supplimental keyword options for the `CSV`
parser class, such as the encoding.

```
# Convert to CSV with OutputStandard::Headers.
# OutputStandard::Headers is a Hash of <symbol, headerString>
# The values for each header <symbol, string> in OutputStandard::Headers are taken from either:
#   Looking up row[inputHeaderString] in the input CSV, where inputHeaderString = CoopsUkOrgsReader::InputHeaders[symbol], or
#   The return value of the method in CoopsUkOrgsReader whose name is symbol, or
#   Empty if neither of the above apply.
 
SeOpenData::CSV.convert(
  # Output:
  $stdout, OutputStandard::Headers,
  # Input:
  ARGF.read, CoopsUkOrgsReader, encoding: "ISO-8859-1"
)
```
