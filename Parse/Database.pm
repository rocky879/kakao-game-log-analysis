#!/usr/bin/perl

package Database;

use DBI;
use Data::Dumper;

sub new {
    my $class = shift();
    my $self = {};
    my $host = shift();
    my @arr = split(/:+/g, $host);
    my $count = @arr;
    if ($count > 1) {
        $host = "host=".@arr[0].";port=".@arr[1];
    } else {
	$host = "host=".$host;
    }
    my $db = shift();
    $self->{"dsn"} = "DBI:Pg:database=".$db.";".$host;
    #$self->{"dsn"} = "DBI:Pg:".$db.":".$host;
    $self->{"user"} = shift();
    $self->{"pwd"} = shift();
    bless $self, $class;
    return $self;
}

sub execute {
    my ($self, $sql) = @_;
    $dbh = DBI->connect($self->{'dsn'}, $self->{'user'}, $self->{'pwd'});
    $sth = $dbh->prepare($sql);
    $sth->execute() or print "sql execute error:$sth->errstr($sql)";
    $sth->finish;
    $dbh->disconnect;
}

sub query {
    my ($self, $sql) = @_;
    $dbh = DBI->connect($self->{'dsn'}, $self->{'user'}, $self->{'pwd'});
    $sth = $dbh->prepare($sql);
    $sth->execute();
    my @result = ();
    while (my $row = $sth->fetchrow_hashref()) {
        push @result, $row;
    }
    $sth->finish;
    $dbh->disconnect;
    return @result;
}

1;
