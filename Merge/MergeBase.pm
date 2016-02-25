#!/usr/bin/perl

#中间文件合并的一些基本操作

use File::Copy;

sub merge_ip_array { #合并两个IP数组, 两个参数
    my ($ip1, $ip2) = @_;
    my @result = @$ip1;

    foreach my $ip (@$ip2) {
        if (!grep /^$ip$/, @result) {
            push @result, $ip;
        }
    }

    return @result;
}

sub merge_state_hash { #合并两个状态Hash数组
    my ($hash1, $hash2) = @_;
    my %result = %$hash1;

    my %h1 = %$hash1;
    my %h2 = %$hash2;
    foreach my $key (keys %$hash2) {
        if (exists $h1{$key}) {
            $result{$key} += $h2{$key};
        } else {
            $result{$key} = $h2{$key};
        }
    }

    return %result;
}

1;