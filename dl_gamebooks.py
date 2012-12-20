from bs4 import BeautifulSoup
from bs4 import SoupStrainer
import lxml
import pdb
import socket
import subprocess
from time import clock
import urllib2
import re

# dl_gamebooks allows you to download all gamebooks available for a team in a given year

nflcom_pre = 'http://www.nfl.com'
nflcom_post = "#menu=gameinfo&tab=recap"

def get_gamecenter_links(team, year):
  gc_links = SoupStrainer(href=re.compile("gamecenter"))
	team_url = 'http://www.nfl.com/teams/greenbay%20packers/schedule?team=GB&season=2011&seasonType=REG'
	soup = BeautifulSoup(urllib2.urlopen(team_url).read(), parse_only=gc_links)
	links = soup(href=re.compile("gamecenter"))
	return links

# Cycles through the list of links gleaned by get_gamecenter_links
# and grabs the gamebook link on the gamecenter page.  Then it 
# uses curl to download each gamebook pdf
def download(team, year):
	l = []
	i = 0
	print "getting links: "
	start = clock()
	links = get_gamecenter_links(team,year)
	print clock() - start, "seconds"
	for link in links:
		print "processing", link['href'], "\n"
		start = clock()
		
		filename = re.search("\w+@\w+",link['href'])
		if filename.group():
			out_file = re.sub(r"(\w+)@(\w+)",r"\1_at_\2", filename.group())
			out_file = out_file + ".pdf"
		else:
			out_file = "GB_" + i + ".pdf"
			
		socket.setdefaulttimeout(100)
		full = nflcom_pre + link['href'] + nflcom_post
		gb_pat = re.compile("/liveupdate/gamecenter/\d+/\w+_Gamebook.pdf")
		gc_page_text = urllib2.urlopen(full).read()
		pdf_link = gb_pat.findall(gc_page_text)
		full_dl_link = nflcom_pre + pdf_link[0]
		
		subprocess.Popen(['curl', '-o', out_file, full_dl_link], cwd=r"C:\Users\mjcox\Documents\GB\Game Books\2011")
		print "time: ", clock() - start
		i += 1
	
	return l
	
	
