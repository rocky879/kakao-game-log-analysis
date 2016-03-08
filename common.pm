#!/usr/bin/perl

require "/home/daumkakao/scripts/log/game/Parse/Database.pm";

my $db = Database->new("dsymaster.pg.rds.aliyuncs.com:3433", "statistics", "wuyou", "wuyou_123");

sub getDateFromFileName {
    my ($filename) = @_;
    my @result = $filename =~ /[^\.]+$/g;
    my $count = @result;
    if ($count > 0) {
        return @result[0];
    } else {
        return "";
    }
}

sub db_getAllPlatforms {
    #print "start\n";
    #my $db = Database->new("dsymaster.pg.rds.aliyuncs.com:3433", "statistics", "wuyou", "wuyou_123");
    #print "initend\n";
    my @result = $db->query("SELECT * FROM slog_platform");
    #print @result,"\n";
    return @result;
}

sub db_getAllStates {
    #my $db = Database->new("dsymaster.pg.rds.aliyuncs.com:3433", "statistics", "wuyou", "wuyou_123");
    my @result = $db->query("SELECT * FROM slog_state");
    return @result;
}

sub db_getStateCount {
    my ($date, $cid, $platform, $state) = @_;
    my $result = 0;
    my $sql = "SELECT COALESCE(SUM(number),0) number FROM slog_state_summary WHERE date='".$date."' AND appid='".$cid."' AND platform='".lc($platform)."' AND state='".$state."'";
    my @result = $db->query($sql);
    #print @result,"\n";
    my $count = @result; #print $count,"\n";
    if ($count > 0) {
	my %hash = %{@result[0]};
	#print $hash{'sum'},"\n";
	if (exists $hash{'number'}) {
	    $result = $hash{'number'};
	}
    }
    #print $sql,"\n";
    #print $result,"\n";
    return $result;
}

sub db_HasUser {
    my ($date, $cid, $platform, $devid) = @_;
    my $sql = "SELECT COUNT(*) count FROM slog_state_user WHERE date='".$date."' AND appid='".$cid."' AND platform='".lc($platform)."' AND devid='".$devid."'";
    my @result = $db->query($sql);
    my $count = @result;
    if ($count > 0) {
	my %hash = %{@result[0]};
	if (exists $hash{'count'}) {
	    if ($hash{'count'} ne "0") {
		return true;
	    }
	}
    }

    return false;
}

1;
