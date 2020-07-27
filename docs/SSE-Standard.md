# Description of Standard 

This file describes the standard information needed to translate a dataset into linked data using the SSE open-data repository.

Here we describe the fields in the intermediary step before the data is transformed into RDF format (using definitions from [the SSE vocabulary](https://vocabs.solidarityeconomy.coop/essglobal/V2a/html-content/essglobal.html#H4)). The translation of datasets (csv format) to linked data is a two step process: 

1. Transform the original format to a standard format (defined below)
2. Transform the standard format to linked data and upload it to a triple-store

The resulting data files look something like: 

Original_Data.csv --(step 1)--> Standard_Format.csv --(step 2)--> RDF 


It is important to note that in the original data file fields do not have to map directly to the standard fields (although it is recommended). They can be composed by multiple fields, one field could describe two other fields, etc...

For example one could have the following fields in the Original_Data.csv: street address 1, street address 2. They would be merged into Street Address. Conversely one could have a field which maps to two fields in Standard_Format.csv: Country Street Address. This would be separated into two fields: Country, Street Address. More complex mappings and translations are also possible but it is recommended that a straightforward mapping is used (e.g. Country in Original_Data.csv maps directly to Country in Standard_Format.csv) since the margin for error increases with complexity.

# Field Definitions

In this section the fields which we currently populate are defined in the following format:
<hr/>

## Name of Field
    
    Required: is the field strictly required?
    Description: short explanation and description of the field
    Type: the type of the field (e.g. boolean, text, numbers or enumerated values)
    Validation: what is deemed as valid data to be passed to the field

<hr/>

### The following fields are described: 

"Identifier",
"Name",
"Description",
"Organisational Structure",
"Primary Activity",
"Activities",
"Street Address",
"Locality",
"Region",
"Postcode",
"Country Name",
"Website",
"Phone",
"Email",
"Twitter",
"Facebook",
"Companies House Number"

## Identifier

    Required: Yes
    Description: A unique identifier used to identify organizations (initiatives*) within a dataset. The uniqueness must be guaranteed within the passed dataset! (i.e. one must guarantee uniqueness within the passed Original_Data.csv file and the Standard.csv file). The identifier will be used to create a URL address for the organization. (e.g. if Company XYZ passes an initiative with an id of IDENTITY, the resulting URL could be: data.solidarityeconomy.coop/XYZ/IDENTITY). These IDs must remain constant within the passed Original_Dataset.csv files
    Type: Text
    Validation: There must be no white spaces or special characters (only english alpha-numerals) and the ID must be shorter than 15 characters
<hr/>

## Name
    
    Required: No
    Description: The name of the organization. It is recommended that names are bellow 10 words (or 90) so that they fit more neatly into text boxes
    Type: Text
    Validation: (Non strict) below 90 characters

<hr/>

## Description

    Required: No
    Description: A free-form description of the organization
    Type: Text
    Validation: None
    
<hr/>

## Organisational Structure

    Required: No
    Description: The structure of the organization in the context of the SSE vocabulary. Valid values for this field can be found at https://vocabs.solidarityeconomy.coop/essglobal/V2a/html-content/essglobal.html#H6.1 . One should use the Definition instead of the Label for an organisational structure (i.e. for https://vocabs.solidarityeconomy.coop/essglobal/V2a/html-content/essglobal.html#organisational-structure-OS100 one should use Multi-stakeholder co-operative instead of OS100)
    Type: Enumerated
    Validation: only definition values at https://vocabs.solidarityeconomy.coop/essglobal/V2a/html-content/essglobal.html#H6.1 . IMPORTANT! Make sure you remove the . at the end. i.e do not use "Multi-stakeholder co-operative." but instead use "Multi-stakeholder co-operative" 
    
<hr/>

## Primary Activity

    Required: No
    Description: The primary economic activity of the organization in the context of the SSE vocabulary. Valid values for this field can be found at https://vocabs.solidarityeconomy.coop/essglobal/V2a/html-content/essglobal.html#H5.1 . One should use the Definition instead of the Label for an organisational structure (i.e. for https://w3id.solidarityeconomy.coop/essglobal/V2a/standard/activities-mofidied/AM10 one should use Arts, Media, Culture & Leisure instead of AM10).
    Type: Enumerated
    Validation: only definition values at https://vocabs.solidarityeconomy.coop/essglobal/V2a/html-content/essglobal.html#H5.1 . IMPORTANT! Make sure you remove the . at the end. i.e do not use "Arts, Media, Culture & Leisure." but instead use "Arts, Media, Culture & Leisure". Only one activity can be placed in this field.
    
<hr/>

## Activities

    Required: No
    Description: Economic activities of the organization in the context of the SSE vocabulary. Values should be defined the same way as in the Primary Activity field. In this field, multiple economic activities of an organization can be defined.
    Type: Enumerated
    Validation: only definition values at https://vocabs.solidarityeconomy.coop/essglobal/V2a/html-content/essglobal.html#H5.1 . IMPORTANT! Make sure you remove the . at the end. i.e do not use "Arts, Media, Culture & Leisure." but instead use "Arts, Media, Culture & Leisure". Multiple activities can be placed here but must be separated with the ";" character (e.g. a valid entry with multiple activities is: "Arts, Media, Culture & Leisure;Campaigning, Activism & Advocacy;Community & Collective Spaces")
    
<hr/>

## Street Address

    Required: No
    Description: The street address of an organization (i.e. Address by omitting City, State, Postcode, and Country and leave in only the Street Address)
    Type: Text
    Validation: None
    
<hr/>

## Locality

    Required: No
    Description: The city of the organization.
    Type: Text
    Validation: None
    
<hr/>

## Region

    Required: No
    Description: The State of the organization
    Type: Text
    Validation: None
    
<hr/>

## Postcode

    Required: No
    Description: The postcode of the organization
    Type: Text
    Validation: None
    
<hr/>

## Country Name

    Required: No
    Description: The country of the organization. One should use the ISO-3166 Official State Name field at https://en.wikipedia.org/wiki/List_of_ISO_3166_country_codes . Although this value is not strictly enumerated currently, it is recommended that a standard country format is used
    Type: Text
    Validation: (Non-Strict) use only official state names at https://en.wikipedia.org/wiki/List_of_ISO_3166_country_codes 
    
<hr/>

## Website

    Required: No
    Description: The website of the organization.
    Type: URL
    Validation: Must be a valid URL (example validator check https://regexr.com/39nr7)
    
<hr/>

## Phone

    Required: No
    Description: The phone of the organization.
    Type: Numbers
    Validation: Must be a valid telephone number (example validator check https://regexr.com/3c53v)
    
<hr/>

## Email

    Required: No
    Description: The email of the organization.
    Type: Text
    Validation: Must be a valid email address (example validator check https://regexr.com/3e48o)
    
<hr/>

## Twitter

    Required: No
    Description: The twitter handle of the organization.
    Type: Numbers
    Validation: Must be a valid twitter handle (no spaces or special characters) the value will be added to the end of twitter.com/ e.g. if DSamardzhiev is entered you would get https://twitter.com/DSamardzhiev)
    
<hr/>

## Facebook

    Required: No
    Description: The facebook handle of the organization.
    Type: Numbers
    Validation: Must be a valid facebook handle (no spaces or special characters) the value will be added to the end of facebook.com/ e.g. if DSamardzhiev is entered you would get https://facebook.com/DSamardzhiev)
    
<hr/>

## Companies House Number

    Required: No
    Description: The UK Companies House number of an organization. 
    Type: Numbers
    Validation: Must be 8 numbers with a leading zero (https://completeformations.co.uk/companyfaqs/uk_company_setup/company_numbers.html)
    
<hr/>


### **For all the fields: special emoji characters (or encoded emoji) are invalid and the text must be utf-8  compliant**

<hr/>

<i>
Definitions: 

initiative - an initiative (or organization) refers to an individual entry in the Original_Data.csv file. 
</i>
