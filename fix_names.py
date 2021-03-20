import sys
import pdb

lines = open('template.args', 'r').readlines()
saving = []
for line in lines:
    if line.startswith('description:'):
        line = 'description: '+sys.argv[1]+'\n'
    saving.append(line)
open('template.args', 'w').writelines(saving)
