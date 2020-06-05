require 'se_open_data/csv/schema'

module SeOpenData
  module CSV
    
    # Defines various Solidarity Economy schemas
    module Schemas

      # Defines the schema versions in order of creation.
      #
      # Note, schema field IDs are used in the code and should not be
      # changed for any given schema (otherwise code may break).
      # They may be changed between versions.
      #
      Versions = [
        SeOpenData::CSV::Schema.new(
          id: :sse_initiatives,
          name: "Solidarity Economy Initiatives",
          version: 1, # FIXME think about this
          description: <<-HERE,

## Geographic coordinates

`Latitude` and `Longitude` are for the exact geolocation of the SSE
initiative, if it is known.

If only a postcode or an address is known, use the `Geo Container *`
fields.

Often, we don't know the exact lat/long of an SSE initiative, but we
know about a geographic container which has a known lat/long.  The
most common example of this is the postcode as a geographic container.

Note that the utility `bin/csv/standard/add-postcode-lat-long.rb` will
populate these 3 fields based on the value of the `Postcode`, so don't
do it manually!  This is used, for example, in the toolchain for
generating the co-ops-uk 2017 RDF.

## Sub-fields

Sometimes a single column can take values that are in fact a list.  So
we need to know the character used to separate the items in the list.
For example, in the legal_form column, we might have an initiative
that is both a 'Cooperative' and a 'Company', the cell would then have
the value "Cooperative;Company"

HERE
          comment: 'Initial version',
          fields: [
            {id: :id,
             header: 'Identifier',
             desc: 'A unique identifier for this initiative',
             comment: '',
            },
            {id: :name,
             header: 'Name',
             desc: '',
             comment: '',
            },
            {id: :description,
             header: 'Description',
             desc: '',
             comment: '',
            },
            {id: :organisational_structure,
             header: 'Organisational Structure',
             desc: '',
             comment: <<-HERE,
This was known as legal_form. The allowed values are taken from the
ESSGLOBAL specification.
HERE
            },
            {id: :primary_activity,
             header: 'Primary Activity',
             desc: '',
             comment: '',
            },
            {id: :activities,
             header: 'Activities',
             desc: '',
             comment: '',
            },
            {id: :street_address,
             header: 'Street Address',
             desc: '',
             comment: '',
            },
            {id: :locality,
             header: 'Locality',
             desc: '',
             comment: '',
            },
            {id: :region,
             header: 'Region',
             desc: '',
             comment: '',
            },
            {id: :postcode,
             header: 'Postcode',
             desc: '',
             comment: '',
            },
            {id: :country_name,
             header: 'Country Name',
             desc: '',
             comment: '',
            },
            {id: :homepage,
             header: 'Website',
             desc: '',
             comment: '',
            },
            {id: :phone,
             header: 'Phone',
             desc: '',
             comment: '',
            },
            {id: :email,
             header: 'Email',
             desc: '',
             comment: '',
            },
            {id: :twitter,
             header: 'Twitter',
             desc: '',
             comment: '',
            },
            {id: :facebook,
             header: 'Facebook',
             desc: '',
             comment: '',
            },
            {id: :companies_house_number,
             header: 'Companies House Number',
             desc: '',
             comment: '',
            },
            {id: :latitude,
             header: 'Latitude',
             desc: '',
             comment: '',
            },
            {id: :longitude,
             header: 'Longitude',
             desc: '',
             comment: '',
            },
            {id: :geocontainer,
             header: 'Geo Container',
             desc: '',
             comment: '',
            },
            {id: :geocontainer_lat,
             header: 'Geo Container Latitude',
             desc: '',
             comment: '',
            },
            {id: :geocontainer_lon,
             header: 'Geo Container Longitude',
             desc: '',
             comment: '',
            },
          ]        
        )
      ]

      # Shortcut alias for the latest schema
      Latest = Versions[-1]
    end
  end
end
