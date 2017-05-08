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
        Browse HTML code for an xpath.
        """)
    )
parser.add_argument("-i","--input",  
    help = "input html file. Defaults to STDIN.", required = False)
parser.add_argument("-o","--output", help = 
    "output list file. Defaults to STDOUT.",required = False)
parser.add_argument("-x","--xpath", help = "the xpath to search for", 
    required = True)
args = parser.parse_args()

# select output file
if not args.input or args.input == "-":
    f = sys.stdin
else:
    f = open(args.input,"r")
# read input file
with open(args.input) as f: 
    tree = etree.HTML(f.read())

links = tree.xpath( args.xpath )

# select output file
if not args.output or args.output == "-":
    f = sys.stdout
else:
    f = open(args.output,"w")

# write output
for link in links:
    f.write( link + "\n" )

