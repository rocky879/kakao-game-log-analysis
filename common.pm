#!/usr/bin/perl

require "/home/daumkakao/scripts/log/game/Parse/Database.pm";

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
    my $db = Database->new("dsymaster.pg.rds.aliyuncs.com:3433", "statistics", "wuyou", "wuyou_123");
    #print "initend\n";
    my @result = $db->query("SELECT * FROM slog_platform");
    #print @result,"\n";
    return @result;
}

sub db_getAllStates {
    my $db = Database->new("dsymaster.pg.rds.aliyuncs.com:3433", "statistics", "wuyou", "wuyou_123");
    my @result = $db->query("SELECT * FROM slog_state");
    return @result;
}

1;
