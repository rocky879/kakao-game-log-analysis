#!/usr/bin/perl

#将原始日志文件转换为中间文件

my $pwd = $ENV{'PWD'}; #当前路径

require $pwd."/Convert/Common.pm";
require $pwd."/Convert/Log.pm";

use File::Basename qw<basename>;

sub parse { #解析原始日志文件, 唯一参数为文件名称(包括路径)
    my ($filename) = @_;
    my %result = (); #结果为哈希数组

    if (!-e $filename) { #若文件不存在
        return %result;
    }

    open(FILE, "<", $filename) or die; #打开文件
    until(!($line=<FILE>)) { #按行读取文件, 直到读到空
        my $log = Log->new(trim($line)); #去除两侧空格
        my $ip = $log->getIp();
        my $dev = $log->getDevice();
        my $state = $log->getState();
        my $client = $log->getClientId();
        my $platform = $log->getPlatform();
        my $key = $dev."|".$client; #以设备ID和游戏ID联合作为唯一标识

        if (exists $result{$key}) { #相同标识的对象已经存在
            if (exists $result{$key}{'state'}{$state}) { #该状态已存在, 在原来计数上+1
                $result{$key}{'state'}{$state}++;
            } else { #该状态不存在, 新增状态, 并计数为1
                $result{$key}{'state'}{$state} = 1;
            }

            if (!grep /$ip$/, @{$result{$key}{'ip'}}) { #IP记录为数组, 判断IP是否已经存在, 该处为不存在时处理
                push @{$result{$key}{'ip'}}, $ip; #将IP加入到当前IP数组中
            }
        } else { #该标识对象不存在, 则在结果中新增该标识对象, 并赋值
            my @arr = (trim($ip)); #去除IP两侧空格, 并将其置于数组中
            $result{$key}{'ip'} = \@arr;
            $result{$key}{'dev'} = $dev;
            $result{$key}{'client'} = $client;
            $result{$key}{'platform'} = $platform;
            $result{$key}{'state'}{$state} = 1; #状态计数初始化为1
        }
    }

    close(FILE); #关闭文件

    return %result;
}

sub toMidFile { #将解析结果写入中间文件, 参数1为原始日志文件解析结果, 参数2为中间文件所在路径(包含文件名)
    my ($res, $output) = @_;
    my %result = %{$res}; #传入结果为哈希数组, 强转
    my $content = ""; #需写入中间文件的内容, 初始化为空
    while (($key, $value) = each(%result)) { #遍历传入的解析结果
        my %item = %{$value}; #每一项均为一个哈希数组

        $content .= $item{'dev'}."\t"; #设备ID
        $content .= $item{'client'}."\t"; #游戏ID
        $content .= join("|", @{$item{'ip'}})."\t"; #IP数组以"|"分隔显示
        $content .= $item{'platform'}."\t"; #平台

        %stses = %{$item{'state'}}; #状态信息为哈希数组
        my $str = ""; #状态显示字串, 格式为key=value格式, 且以&分隔
        while (($sts, $count) = each(%stses)) { #遍历状态信息
            if ($str ne "") {
                $str .= "&";
            }

            $str .= $sts."=".$count;
        }

        $content .= $str;
        $content .= "\n"; #行末加换行
    }

    if (-e $output) { #若已存在所要生成的文件, 先删除
        unlink $output;
    }

    open(OUTFILE, ">", $output) or die;
    print OUTFILE ($content);
    close(OUTFILE);
}

sub convert { #将日志文件转为中间文件, 参数1为原始日志文件路径(含文件名), 参数2为中间文件存放路径(文件名不变)
    my ($filename, $path) = @_;

    if (-e $filename) { #原始日志文件存在
        my %result = &parse($filename); #解析原始日志文件
        if (!-d $path) { #所示路径不存在, 则创建
            mkdir $path;
        }

        my $dest = $path.(basename $filename); #目的路径上添加文件名
        &toMidFile(\%result, $dest);
    }
}

1;