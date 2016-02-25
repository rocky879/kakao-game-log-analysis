#!/usr/bin/perl

#一些基本操作函数

use File::Basename qw<basename dirname>;

#去除字串左侧空格
sub ltrim {
    my $s = shift;
    $s =~ s/^\s+//;
    return $s;
}

#去除字串右侧空格
sub rtrim {
    my $s = shift;
    $s =~ s/\s+$//;
    return $s;
}

#去除字串两侧空格
sub trim {
    my $s = shift;
    $s =~ s/^\s+|\s+$//g;
    return $s;
}

#从路径中获取文件名,如果为目录则返回空字串
sub get_file_name {
    my ($path) = @_;
    if ($path =~ /(.*)\/$|(.*)\\$/g) { #以/或\结尾则认为是目录
        return "";
    } else {
        return basename $path;
    }
}

1;