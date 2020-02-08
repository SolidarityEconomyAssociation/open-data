# This makefile fragment sets up the things that are common to all editions of the data being generated.
# 
# Makefile fragments to define specific editions go in this directory:
EDITIONS_DIR := editions/

# Everything produced for an edition goes here:
TOP_OUTPUT_DIR := generated-data/$(edition)/

# This is CSV file that is generated by the csv.mk makefile, and is the input to generating Linked Data:
STANDARD_CSV := $(TOP_OUTPUT_DIR)standard.csv

# This has been worked out for the dotcoop dataset
# TODO - sort out this hack
#SAMEAS_CSV := ../../dotcoop/domains2018-04-24/generated-data/experimental/sameas.csv
#SAMEAS_HEADERS := "cuk uri","dot uri"

# bin directory for se_open_data scripts.
# If the bin derectory is on your PATH, you don't this:
SE_OPEN_DATA_BIN_DIR := ../../tools/se_open_data/bin/

# lib directory for se_open_data library.
# This is unnecessary if the library is installed as a gem (not yet possible as at April 2018)
SE_OPEN_DATA_LIB_DIR := $(abspath ../../tools/se_open_data/lib/)

# Any CSS files in CSS_SRC_DIR will be deployed to the DEPLOYMENT_SERVER
CSS_SRC_DIR := css/

# A sample of Identifiers (from 'Identifiers' column in STANDARD_CSV)
# to be used to test the deployment:
TEST_INITIATIVE_IDENTIFIERS := R000001 R013429/BD234AA R013429/BH205RQ/2
