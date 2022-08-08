#!/opt/homebrew/bin/python

import sys
import json

data = json.load(sys.stdin)

for d in data:
    print("curl -O "+d['s3Url']+"\n")

