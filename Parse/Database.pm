#!/usr/bin/perl

package Database;

use DBI;
use Data::Dumper;

sub new {
    my $class = shift();
    my $self = {};
    my $host = shift();
    my $db = shift();
    $self->{"dsn"} = "DBI:Pg:database=".$db.";host=".$host;
    $self->{"user"} = shift();
    $self->{"pwd"} = shift();
    bless $self, $class;
    return $self;
}

sub execute {
    my ($self, $sql) = @_;
    $dbh = DBI->connect($self->{'dsn'}, $self->{'user'}, $self->{'pwd'});
    $sth = $dbh->prepare($sql);
    $sth->execute();
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