import glob
import os
from os.path import join
import re
import subprocess

base_dir = r"C:\Users\mjcox\Documents\GB\Game Books\\"
# convert gamebook from pdf to text
def convert(year):
  gb_dir = base_dir + str(year) 
	for root, dirs, files in os.walk(gb_dir):
		for name in files:
			subprocess.Popen(['pdftotext', '-layout', join(root, name)])
				

# get the field position from game book
def get_fp(year):
	fp_data=[]
	dir = base_dir + str(year) + r"\*.txt"
	txt_gamebooks = glob.glob(dir)
	
	pat = re.compile(r"\((\d+)\) Average (\w+) (\d+)")
	for gb in txt_gamebooks:
		file = open(gb).read()
		fp = re.findall(pat,file)
		fp_data.append(fp)
	
	return fp_data
	
# Need to clean up the analysis section... quick and dirty atm bc I'm running out the door
def f(x): return x[1] == 'GB'
def nf(x): return x[1] != 'GB'
def mf(x): return int(x[2])

def analyze_fp(year):
	i = 0
	p = []
	np = []
	fp = get_fp(year)
	for x in fp:
		p.extend(map(mf, filter(f,x)))
		np.extend(map(mf, filter(nf,x)))
		i+=1
		
	avg_p = sum(p)/float(i)
	avg_np = sum(np)/float(i)
	
	return avg_p, avg_np
