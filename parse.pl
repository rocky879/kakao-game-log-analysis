#!/usr/bin/perl

use POSIX;
use HTTP::Date;
require "/home/daumkakao/scripts/log/game/Convert/Convert.pm";
require "/home/daumkakao/scripts/log/game/common.pm";
require "/home/daumkakao/scripts/log/game/Parse/Parse.pm";

sub log2MidFile {
    my ($src, $dst) = @_;
    &convert($src, $dst);
}

sub parse {
    my ($filename) = @_;
    my $date = &getDateFromFileName($filename); #print $date, "\n";
    if (str2time($date)) {
        my $p = Parse->new($filename);
        my @CIds = $p->getAllClientIds(); #print @CIds,"\n";
        my @Plats = &db_getAllPlatforms();
        my @Stses = &db_getAllStates();
        my $db = Database->new("172.28.3.13", "statistics", "postgres", "asdf1234");
        foreach my $cid (@CIds) {
            foreach my $plat (@Plats) {
                my %plat = %{$plat};
                my $pid = $plat{'pid'};
                my $pname = $plat{'pname'};
                my $usrnum = $p->getUserNumberByPlatform($cid, $pname);
                my $oprnum = $p->getOperationTotal($cid, $pname);
                my $sql = "INSERT INTO slog_summary(date,appid,pid,usrtotal,oprtotal) VALUES('".$date."','".$cid."',".$pid.",".$usrnum.",".$oprnum.")";
                $db->execute($sql);
                #print $sql,"\n";
                foreach my $sts (@Stses) {
                    my %sts = %{$sts};
                    my $stsid = $sts{'sid'};
                    my $stsname = $sts{'sname'};#print $stsname,"\n";
                    my $stsnum = $p->getOperationNumber($cid, $stsname, $pname);
                    if ($stsnum > 0) {
                        $sql = "INSERT INTO slog_state_summary(date,appid,pid,sid,number) VALUES('".$date."','".$cid."',".$pid.",".$stsid.",".$stsnum.")";
                        #print $sql,"\n";
                        $db->execute($sql);
                    }
                }
            }
        }
    } else {
         print "Invalid format of filename(".$filename.")\n";
     }
}

my $str_yesterday = strftime("%Y%m%d", localtime(time-86400)); #Yesterday
my $filename = "statistics.log.".$str_yesterday;
my $source = "/home/daumkakao/log/lighttpd/".$filename;
my $dest = "/home/daumkakao/log/MidFiles/";

&log2MidFile($source, $dest);
&parse($dest.$filename);