#!/usr/bin/perl

use POSIX;
use HTTP::Date;
use URI::Escape;
require "/home/daumkakao/scripts/log/game/Convert/Convert.pm";
require "/home/daumkakao/scripts/log/game/common.pm";
require "/home/daumkakao/scripts/log/game/Parse/Parse.pm";
require "/home/daumkakao/scripts/log/game/Merge/Parse.pm";

sub log2MidFile {
    my ($src, $dst) = @_;
    &convert($src, $dst);
}

sub parse1 {
    my ($filename) = @_;
    #print $filename,"\n";
    my $date = &getDateFromFileName($filename); #print $date, "\n";
    if (str2time($date)) {
        my $p = Parse->new($filename);
        my @CIds = $p->getAllClientIds(); #print join("::",@CIds),"\n";
        my @Plats = &db_getAllPlatforms(); #print @Plats,"\n";
		#return;
        my @Stses = &db_getAllStates(); #print @Stses,"\n";
        my $db = Database->new("dsymaster.pg.rds.aliyuncs.com:3433", "statistics", "wuyou", "wuyou_123");
        foreach my $cid (@CIds) {
            foreach my $plat (@Plats) {
                my %plat = %{$plat};
                my $pid = $plat{'pid'};
                my $pname = $plat{'pname'};
                my $usrnum = $p->getUserNumberByPlatform($cid, $pname);
                my $oprnum = $p->getOperationTotal($cid, $pname);
				if ($usrnum != 0 || $oprnum != 0) {
                    my $sql = "INSERT INTO slog_summary(date,appid,platform,usrtotal,oprtotal) VALUES('".$date."','".$cid."','".lc($pname)."',".$usrnum.",".$oprnum.")";
                    $db->execute($sql);
                    #print $sql,"\n";
                }
                foreach my $sts (@Stses) {
                    my %sts = %{$sts};
                    my $stsid = $sts{'sid'};
                    my $stsname = $sts{'sname'}; #print $stsid."-".$stsname,"\n";
                    my $stsnum = $p->getOperationNumber($cid, $stsname, $pname);
                    if ($stsnum > 0) {
                        $sql = "INSERT INTO slog_state_summary(date,appid,platform,state,number) VALUES('".$date."','".$cid."','".lc($pname)."','".lc($stsname)."',".$stsnum.")";
                        #print $sql,"\n";
                        $db->execute($sql);
                    }
                }
            }
        }
	
		my %midp = &midParse($filename);
		#my $count = @midp;
		#print $count,"\n";
		foreach my $item (values %midp) {
	    	#my %item = %{$item};
	    	#$devid = $item{'device'};
	    	my %item = %{$item};
	    	my $devid = $item{'device'};
	    	my $client = $item{'client'};
	    	my $platform = $item{'platform'};
	    	my %states = %{$item{'state'}};
	    	while (($sts, $count) = each(%states)) {
				my $sql = "INSERT INTO slog_state_user(date,appid,platform,devid,state,number) VALUES('".$date."','".$client."','".lc($platform)."','".$devid."','".lc(uri_unescape($sts))."',".$count.")";
				#print $sql."\n";
				$db->execute($sql);
	    	}
	    	#print $devid,"\n";
	    	#last;
		}
    } else {
         print "Invalid format of filename(".$filename.")\n";
     }
}

my $str_yesterday = strftime("%Y%m%d", localtime(time-86400)); #Yesterday
my $filename = "statistics.log.".$str_yesterday;
my $source = "/home/daumkakao/log/lighttpd/".$filename;
my $dest = "/home/daumkakao/log/MidFiles/";

#print "out\n";
&log2MidFile($source, $dest);
#print strftime("%H:%M:%S", localtime()),"\n";
&parse1($dest.$filename);
#print strftime("%H:%M:%S", localtime()),"\n";
