#!/usr/bin/python3

import sys
f = open(sys.argv[1], "r")
lines = f.readlines()
f.close()
lines = [l.strip() for l in lines]
s = 0
n = len(lines)
for l in lines:
	if (l == ''):
		n -= 1
	else:
		s += int(l)
avg = s/n;
print("average: %f us\n"%avg)
print("average: %f ms\n"%(avg/1000))
print("average: %f s\n"%(avg/1000000))

