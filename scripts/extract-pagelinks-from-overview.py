#!/usr/bin/env python3
# system modules
import argparse
import sys
import textwrap

# external modules
from lxml import etree


# Options
parser = argparse.ArgumentParser( 
    description = textwrap.dedent("""
        Extract links to single emergency page from the overview page and write
        them to file.
        """)
    )
parser.add_argument("-i","--input",  help = "input html overview file", required = True)
parser.add_argument("-o","--output", help = "output list file", required = False)
args = parser.parse_args()

# open input file
with open(args.input) as f: 
    tree = etree.HTML(f.read())

XPATH = "//table[@class='einsatzverwaltung-reportlist']//a/@href"
links = tree.xpath(XPATH)

# select output file
if not args.output or args.output == "-":
    f = sys.stdout
else:
    f = open(args.output,"w")

# write output
for link in links:
    f.write( link + "\n" )

