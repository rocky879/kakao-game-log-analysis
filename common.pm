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
    my $db = Database->new("172.28.3.13", "statistics", "postgres", "asdf1234");
    $db->query("SELECT * FROM slog_platform");
}

sub db_getAllStates {
    my $db = Database->new("172.28.3.13", "statistics", "postgres", "asdf1234");
    $db->query("SELECT * FROM slog_state");
}

1;