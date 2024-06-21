#!/opt/homebrew/bin/python

import sys
import json
import subprocess

data = json.load(sys.stdin)

for d in data:
    returned_value = subprocess.call("curl -O "+d['s3Url'], shell=True)
    print (returned_value)

