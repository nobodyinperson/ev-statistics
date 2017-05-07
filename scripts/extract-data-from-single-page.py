#!/usr/bin/env python3
# system modules
import argparse
import sys
import csv
import re
import textwrap
import logging

# external modules
from lxml import etree

logging.basicConfig(level = logging.INFO)

# Options
parser = argparse.ArgumentParser( 
    description = textwrap.dedent("""
        Extract data from a single emergency page and write csv output to file.
        """)
    )
parser.add_argument("-i","--input",  help = "input html file", required = True)
parser.add_argument("-o","--output", help = "output csv file", required = False)
args = parser.parse_args()

# csv dialect
csv.register_dialect( "custom", 
    delimiter = "|", 
    lineterminator = "\r\n",  
    skipinitialspace = True,
    quotechar = "'",
    )

# open input file
with open(args.input) as f: 
    tree = etree.HTML(f.read())

# xpath to the useful content
xpath_content = "//div[@class='post-content']//text()"
# xpath to the header fields in the content (e.g. bold headlines)
xpath_header = "//div[@class='post-content']//strong/text()|//div[@class='post-content']//h3/text()"

# find content and headers
content = tree.xpath( xpath_content )
headers = tree.xpath( xpath_header  )

data = {} # start with empty dict
current_header = "unknown"
for line in content: # loop over all content lines
    # remove preceding and trailing whitespace
    line = line.replace(csv.get_dialect("custom").delimiter," ") # replace delim
    line = re.sub(string=line,pattern="^\s+",repl="")
    line = re.sub(string=line,pattern="\s+$",repl="")
    if line in headers: # this is a header line
        # remove filthy characters
        line = re.sub(string=line.lower(),pattern="[^a-z0-9_.-]+",repl="")
        current_header = line
    else: # this is content
        try:             data[current_header] += line # append
        except KeyError: data[current_header] =  line # initialise

logging.debug("data:\n{}".format(data))

# select output file
if not args.output or args.output == "-":
    output_file = sys.stdout
else:
    output_file = open(args.output,"w")

# write output
writer = csv.DictWriter( # a CSV writer
    output_file, # write to this file
    fieldnames = data.keys(), # these header fields
    dialect = "custom", # custom dialect
    )
writer.writeheader() # write header
writer.writerow( data ) # write data
