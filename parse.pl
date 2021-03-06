#!/usr/bin/perl

use POSIX;
use HTTP::Date;
use URI::Escape;
require "/home/daumkakao/scripts/log/game/Convert/Convert.pm";
require "/home/daumkakao/scripts/log/game/common.pm";
require "/home/daumkakao/scripts/log/game/Parse/Parse.pm";
require "/home/daumkakao/scripts/log/game/Merge/Parse.pm";

my $db = Database->new("dsymaster.pg.rds.aliyuncs.com:3433", "statistics", "wuyou", "wuyou_123");

sub log2MidFile {
    my ($src, $dst) = @_;
    &convert($src, $dst);
}

sub pre_parse {
    my ($pre_file, $filename) = @_;
    my $date = &getDateFromFileName($filename);
    if (str2time($date)) {
	if (!-e $pre_file) {
	    return;
	}

	my $prep = Parse->new($pre_file);
	my $p = Parse->new($filename);
	my @CIds = $p->getAllClientIds();
	my @Plats = &db_getAllPlatforms();
	foreach my $cid (@CIds) {
	    foreach my $plat (@Plats) {
		my %plat = %{$plat};
		my $pid = $plat{'pid'};
		my $pname = $plat{'pname'};
		my @users_now = $p->getAllUsersByPlatform($cid, $pname);
		my @users_pre = $prep->getAllUsersByPlatform($cid, $pname);
		my $num_new = 0;
		my $num_old = 0;
		foreach my $u (@users_now) {
		    if (grep /^$u$/, @users_pre) {
			$num_old++;
		    } else {
			$num_new++;
		    }
		}
		my $sql = "UPDATE slog_summary SET old_pre_1=".$num_old.",new_pre_1=".$num_new." WHERE date='".$date."' AND appid='".$cid."' AND platform='".lc($pname)."'";
		$db->execute($sql);
	    }
	}
    }
}

sub cont_parse {
    my ($files, $filename) = @_;
    my @files = @{$files};
    my $count = @files; print $count,"\n";

    my $col = "";    
    if ($count == 2) {
	$col = "num_cont_3";
    } elsif ($count == 6) {
	$col = "num_cont_7";
    } else {
        return;
    }

    my $date = &getDateFromFileName($filename);
    if (str2time($date)) {
        my $p = Parse->new($filename);
        my @CIds = $p->getAllClientIds();
        my @Plats = &db_getAllPlatforms();
        foreach my $cid (@CIds) {
            foreach my $plat (@Plats) {
                my %plat = %{$plat};
                my $pid = $plat{'pid'};
                my $pname = $plat{'pname'};
                my @users_now = $p->getAllUsersByPlatform($cid, $pname);

                my $result = 0;
                foreach my $u (@users_now) {
		    my $num = 0;
                    foreach my $f (@files) {
			if (!-e $f) {
			    return; #只要有一个文件不存在即返回，不再往下执行
			}
                        #my $pre = Parse->new($f);
                        #my @pusers = $pre->getAllUsersByPlatform($cid, $pname);
			
                        #if (grep /^$u$/, @pusers) {
                        #    $num++;
                        #} else {
			#    last;
			#}

			open(FILE, $f);
			until (!(my $line=<FILE>)) {
			    if ($line =~ /^$u/g) {
				my @tmps = split(/\t+/, $line);
				my $len = @tmp;
				if ($len != 5) {
				    next;
				}
				if (@tmps[1] eq $cid && lc(@tmps[3]) eq lc($pname)) {
				    $num++;
				    last;
				}
			   }
			}
			close(FILE);
			
			#if(&db_HasUser($date, $cid, $platform, $u)) {
			#    $num++;
			#}
                    }
		    if ($num >= $count) {
			$result++;
		    }
                }
                my $sql = "UPDATE slog_summary SET ".$col."=".$result." WHERE date='".$date."' AND appid='".$cid."' AND platform='".lc($pname)."'";
                $db->execute($sql);
            }
        }
    }
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
        #my $db = Database->new("dsymaster.pg.rds.aliyuncs.com:3433", "statistics", "wuyou", "wuyou_123");
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

sub summary {
    my ($filename) = @_;
    my $date = &getDateFromFileName($filename);
    my $p = Parse->new($filename); #print $filename,"\n";
    my @CIds = $p->getAllClientIds();
    my @Plats = &db_getAllPlatforms();
    foreach my $cid (@CIds) {
	foreach my $plat (@Plats) {
	    my %plat = %{$plat};
	    my $pname = $plat{'pname'};
	    my $init_count = &db_getStateCount($date, $cid, $pname, 'init');
	    my $enter_rate = 0;
	    my $login_count = &db_getStateCount($date, $cid, $pname, 'login');
	    if ($login_count != 0 && $init_count != 0) {
	        $enter_rate = sprintf("%.4f", $login_count/$init_count);
	    }
	    my $pay_rate = 0;
	    my $pay_count = &db_getStateCount($date, $cid, $pname, 'pay');
	    my $prepare_count = &db_getStateCount($date, $cid, $pname, 'pay_prepare');
	    if ($pay_count != 0 && $prepare_count != 0) {
		$pay_rate = sprintf("%.4f", $pay_count/$prepare_count);
	    }
	    #print $cid,"\t",$pname,"\t",$init_count,"\n";
	    #print $cid,"\n";
	    if ($init_count != 0 || $enter_rate != 0 || $pay_rate != 0) {
	        my $sql = "INSERT INTO slog_result(date,appid,platform,open_count,enter_rate,pay_rate) VALUES('".$date."','".$cid."','".lc($pname)."',";
	        $sql .= $init_count.",".$enter_rate.",".$pay_rate.")";
	        $db->execute($sql);
	    }
	}
    }
    #my $count = &db_getStateCount('20160303', '201505002', 'ios', 'init');
    #print $count,"\n";
}

sub parse_pre {
    my ($filename) = @_;
    my $date = &getDateFromFileName($filename); #print $date,"\n";
    my $date_before = strftime("%Y%m%d", localtime(str2time($date)-86400)); #print $date_before,"\n";

	my $p = Parse->new($filename);
	my @CIds = $p->getAllClientIds();
	my @Plats = &db_getAllPlatforms();
	foreach my $cid (@CIds) {
	    foreach my $plat (@Plats) {
	        my %plat = %{$plat};
	        my $pname = $plat{'pname'};
	        my $format = "SELECT DISTINCT devid FROM slog_state_user WHERE date='%s' AND appid='%s' AND platform='%s'";
	        my $sql1 = sprintf($format, $date, $cid, lc($pname));
	        my $sql2 = sprintf($format, $date_before, $cid, lc($pname));
	        my $sql = "SELECT COUNT(*) count FROM (".$sql1.") a INNER JOIN (".$sql2.") b ON a.devid=b.devid";
	        my @res = $db->query($sql);
	        my %hash = %{@res[0]};
	        #print $hash{'count'},"\n";
	        my $count = $hash{'count'};

	        $format = "UPDATE slog_summary SET old_pre_1=%d,new_pre_1=usrtotal-%d WHERE date='%s' AND appid='%s' AND platform='%s'";
	        $sql = sprintf($format, $count, $count, $date, $cid, lc($pname));
	        #print $sql,"\n";
	        $db->execute($sql);
	    }
	}
}

sub parse_cont_3 {
    my ($filename) = @_;
    my $date = &getDateFromFileName($filename); #print $date,"\n";
    my $date_before1 = strftime("%Y%m%d", localtime(str2time($date)-86400)); #print $date_before,"\n";
    my $date_before2 = strftime("%Y%m%d", localtime(str2time($date)-86400*2)); #print $date_before,"\n";

	my $p = Parse->new($filename);
	my @CIds = $p->getAllClientIds();
	my @Plats = &db_getAllPlatforms();
	foreach my $cid (@CIds) {
	    foreach my $plat (@Plats) {
	        my %plat = %{$plat};
	        my $pname = $plat{'pname'};
	        my $format = "SELECT DISTINCT devid FROM slog_state_user WHERE date='%s' AND appid='%s' AND platform='%s'";
	        my $sql1 = sprintf($format, $date, $cid, lc($pname));
	        my $sql2 = sprintf($format, $date_before1, $cid, lc($pname));
	        my $sql3 = sprintf($format, $date_before2, $cid, lc($pname));
	        my $sql = "SELECT COUNT(*) count FROM ((".$sql1.") a INNER JOIN (".$sql2.") b ON a.devid=b.devid) INNER JOIN (".$sql3.") c ON a.devid=c.devid";
	        my @res = $db->query($sql);
	        my %hash = %{@res[0]};
	        #print $hash{'count'},"\n";
	        my $count = $hash{'count'};

	        $format = "UPDATE slog_summary SET num_cont_3=%d WHERE date='%s' AND appid='%s' AND platform='%s'";
	        $sql = sprintf($format, $count, $date, $cid, lc($pname));
	        #print $sql,"\n";
	        $db->execute($sql);
	    }
	}
}

my $str_yesterday = strftime("%Y%m%d", localtime(time-86400)); #Yesterday
my $filename = "statistics.log.".$str_yesterday;
my $str_yesterday_before = strftime("%Y%m%d", localtime(time-86400*2)); #The day before yesterday
my $pre_file = "statistics.log.".$str_yesterday_before;
my $source = "/home/daumkakao/log/lighttpd/".$filename;
my $dest = "/home/daumkakao/log/MidFiles/";

my @_3days_files = ();
my @_7days_files = ();
for ($i=0; $i<2; $i++) {
    my $name = "statistics.log.".strftime("%Y%m%d", localtime(time-86400*($i+2)));
    push @_3days_files, ($dest.$name);
}
for ($i=0; $i<6; $i++) {
    my $name = "statistics.log.".strftime("%Y%m%d", localtime(time-86400*($i+2)));
    push @_7days_files, ($dest.$name);
}
#print join("\n", @_3days_files),"\n\n";
#print join("\n", @_7days_files),"\n";

#print "out\n";
&log2MidFile($source, $dest);
#print strftime("%H:%M:%S", localtime()),"\n";
&parse1($dest.$filename);
#print strftime("%H:%M:%S", localtime()),"\n";
&summary($dest.$filename);
&parse_pre($dest.$filename);
&parse_cont_3($dest.$filename);
#&db_getStateCount('20160303','201505001','ios','init');
#&pre_parse($dest.$pre_file, $dest.$filename);
#cont_parse(\@_3days_files, $dest.$filename);
#print strftime("%H:%M:%S", localtime()),"\n";
#cont_parse(\@_7days_files, $dest.$filename);
#print strftime("%H:%M:%S", localtime()),"\n";
