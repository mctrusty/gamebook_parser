 #!/usr/bin/perl -w

use strict;
use Benchmark;
#use Data::Dumper;

my $grammar = do {
  use Regexp::Grammars;
	qr{
		<logfile: parselog>

		<Play>. <Timeout>?
		
		<rule: Play>
			<PlayInfo> <Pass> 
			|<PlayInfo> <Run>
			|<PlayInfo> <Punt> 
		
		<rule: PlayInfo>
			<Downdist><Time><Formation>?
		
		<rule: FumblePlay>
			 <Fumble> <F1>

		<rule: F1>
			<Player> <PlayGain> <FumblePlay>
			| <Player> <PlayGain>
			
		<rule: Downdist>
			<down=(\d+)>-<dist=(\d+)>-<territory=(\w+)>\s<yard=(\d+)>
			
		<rule: Time>
			\(<MATCH= ((?:\d+)?\:\d+)>\)
			|(?:\d+)?\:\d+
			
		<rule: Formation>
			\(<MATCH=(No Huddle|No Huddle, Shotgun|Shotgun)>\)
		
		<rule: Player>
			(\w+\.\w+)
			
		<rule: Pass>
			<QB= Player> pass <Depth> <Dir> to <Receiver= Player> <PlayGain>
			| <Incomplete>
			| <Sack>
			| <Scramble>
			| <Aborted>
		
		<rule: Incomplete>
			<QB= Player> pass incomplete <Depth> <Dir> to <Player> 
			
		<rule: Sack>
			<QB= Player> sacked <PlayGain>
			
		<rule: Scramble>
			<QB= Player> scrambles <Dir> <Posn> <PlayGain>
		
		<rule: Aborted>
			<QB= Player> FUMBLES (Aborted) at <Dir> <Posn>
			| <QB= Player> Aborted. <Center= Player> FUMBLES at <Territory=(\w+)> <Yard= (\d+)>
			
		<rule: Run>
			<Player> <Dir> <Posn> <PlayGain>
		
		<rule: Fumble>
			FUMBLES \(<Player>\) <Recovered>
			| FUMBLES and recovers at <Territory = (\w+)> <Yard= (\d+)>
			| FUMBLES \(<Player>\) touched at <Territory = (\w+)> <Yard= (\d+)> <Recovered>
			| <Player> MUFFS catch touched at <Territory = (\w+)> <Yard= (\d+)> <Recovered>
		
		<rule: Recovered>
			RECOVERED by <Team = (\w+)>-<Player> at <RecTerritory = (\w+)> <RecYard= (\d+)>\.
		
		<rule: Punt>
			<Player> punts <Dist=(\d+)> yards to <Territory=(\w+)> <Posn= (\d+)>, Center - <Center=Player> (<DownedPunt>|<ReturnedPunt>)
		
		<rule: DownedPunt>
			, downed by <Team=(\w+)>-<Gunner=Player>
		
		<rule: ReturnedPunt>
			\. <Returner=Player> <PlayGain>
			
		<rule: KO>
			#Onside...
			
		<rule: Depth>
			short|deep
			
		<rule: Dir>
			left|right|middle|up
			
		<rule: Posn>
			end|guard|tackle|the <MATCH=(middle)>
		
		<rule: Penalty>
			PENALTY on <Team=(\w+)>-<Player>, <Actual=(\w+(?:\s+\w+)*)>, <Yards=(\d+)> yards, enforced at <Territory=(\w+)> <Posn=(\w+)>
			
		<rule: PlayGain>
			(to|pushed ob at|at) <newTerritory=(\w+)> <newYard=(\d+)> for <gain= ((?:-?\d+) yards|yard|no gain)> <Tacklers>\.
			| for <gain=(\d+)> yards,? <TD>
		
		<rule: TD>
			<Res=(TOUCHDOWN NULLIFIED)> by Penalty.  <Penalty>
			|	<Res=(TOUCHDOWN)>
			
		<rule: Tacklers>
			\(<[Player]>+ % ;\)
			
		<rule: Timeout>
			Timeout #\d by \w+ at <Time>
	}x;
};
#open and parse gamebook
{	
  my $t0 = Benchmark->new;
  
  local $/;
  foreach (split /\n(?!\s{15,})/, <>)
  {
	s/\n\s{15,}/ /g;
	if (m/Fourth Quarter/ .. m/END OF QUARTER/){
		print "$_\n";
		if ($_ =~ $grammar){
			procPlayInfo($/{Play}{PlayInfo});
			procPlay($/{Play});
			print "Timeout\n" if $/{Timeout};
		}
		else{
			print "no play\n";
			
		}
	}
	else {
		#print "$_\n";
	}
  }
	my $t1 = Benchmark->new;
	my $td = timediff($t1, $t0);
	print "the code took:",timestr($td),"\n";
}

sub procPlayInfo{
	my (%info) = %{$_[0]};	
	print "down: $info{Downdist}{down}\n";
	print "dist: $info{Downdist}{dist}\n";
	print "time: $info{Time}\n";
	print "formation: $info{Formation}\n" if $info{Formation};
}

sub procPlay{
	my (%play) = %{$_[0]};
	procCompletePass($play{Pass}) if $play{Pass}{QB}; 			#QB value should only exist if the play is a completed pass;
	procIncompletePass($play{Pass}{Incomplete}) if $play{Pass}{Incomplete};
	procScramble($play{Pass}{Scramble}) if $play{Pass}{Scramble};
	procSack($play{Pass}{Sack}) if $play{Pass}{Sack};
	procAborted($play{Pass}{Aborted}) if $play{Pass}{Aborted};
	procRunPlay($play{Run}) if $play{Run};
	procPunt($play{Punt}) if $play{Punt};
	procFumblePlay($play{FumblePlay}) if $play{FumblePlay};
}

sub procFumblePlay{
	my (%fumblePlay) = %{$_[0]};
	print "FumbleRooski\n" if $fumblePlay{Fumble};
}


sub procCompletePass{
	#<QB= Player> pass <Depth> <Dir> to <Receiver= Player> (to|pushed ob at) <PlayGain> <Tacklers>
	my (%hash) = %{$_[0]};
	print "Complete Pass\n";
	print "QB= $hash{'QB'}\n";
	print "Depth = $hash{'Depth'}\n";
	print "Dir = $hash{'Dir'}\n";
	print "Receiver = $hash{'Receiver'}\n";
	procPlayGain($hash{'PlayGain'});
}

sub procIncompletePass{
	my (%hash) = %{$_[0]};
	print "Incomplete Pass\n";
	print "$hash{'Depth'}\n";
	print "$hash{'Dir'}\n";
	print "Intended Receiver: $hash{'Player'}\n";
}

sub procSack{
	my (%sack) = %{$_[0]};
	print "$sack{'QB'} Sacked\n";
	procPlayGain($sack{'PlayGain'});
}

sub procScramble{
	my (%scram) = %{$_[0]};
	print "$scram{'QB'} scramble\n";
	procPlayGain($scram{'PlayGain'});
}

sub procAborted{
	my (%abort) = %{$_[0]};
	print "Aborted\n";
}

#pre: accepts a hash containing Run Play information
#post: prints out information pertaining to a run play
sub procRunPlay{
	my (%hash) = %{$_[0]};
	print "Player: $hash{'Player'}\n";
	print "Run\n";
	print "Dir: $hash{'Dir'}\n";
	print "Posn: $hash{'Posn'}\n";
	procPlayGain($hash{'PlayGain'});
}

sub procPunt{
	my (%punt) = %{$_[0]};
	print "Punter: $punt{'Player'}\n";
	print "Distance: $punt{'Dist'}\n";
	print "Territory: $punt{'Territory'}\n";
	print "Posn: $punt{'Posn'}\n";
	if ($punt{'DownedPunt'}){
		print "Downed by $punt{'DownedPunt'}{'Team'} - $punt{'DownedPunt'}{'Gunner'}\n";
	}
	if ($punt{'ReturnedPunt'}){
		print "Returned by $punt{'ReturnedPunt'}{'Returner'}\n";
		procPlayGain($punt{'ReturnedPunt'}{'PlayGain'});
	}
}

#pre: accepts a hash containing PlayGain information from the grammar
#post: prints out information relating to the play gain
sub procPlayGain{
	my (%playinfo) = %{$_[0]};
	print "Gain: $playinfo{'gain'}\n";
	if ($playinfo{'TD'}){		
		print "TOUCHDOWN\n";
	}
	else {
		print "Territory: $playinfo{'newTerritory'}\tPosn: $playinfo{'newYard'}\n";
	}
	
	if ($playinfo{'TD'}{'Penalty'}){
		print "NULLIFIED\nPenalty: $playinfo{'TD'}{'Penalty'}{'Actual'}\n";
	}

}

sub procPenalty{
	my (%penalty) = %{$_[0]};
	#PENALTY on <Team=(\w+)>-<Player>, <Actual=(\w+(?:\s+\w+)*)>, <Yards=(\d+)> yards, enforced at <Territory=(\w+)> <Posn=(\w+)>
	print "Penalty:\n";
	print "$penalty{Team}, $penalty{player}\n";
	print "$penalty{Actual}\n";

}

sub procTacklers{
	my (%tacklers) = %{$_[0]};
	#print "pass, tackler: $/{Play}{Pass}{Tacklers}{Player}[0]\n" if $/{Play}{Pass}{Tacklers};
}
