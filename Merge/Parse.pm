#!/usr/bin/perl

#中间文件解析, 格式相关
#目前中间文件格式为:
#4921EA5C78F2483BB041AA8A411AE701	201505002	114.82.174.160	iOS	destroy=1&init=1

#package Parse;
use URI::Escape;

sub midParse { #解析中间文件, 参数为中间文件全路径(包含文件名)
    my ($filename) = @_;

    if (-e $filename) { #文件存在
        my %result = ();
        open(FILE, $filename) or die;

        until (!($line = <FILE>)) { #按行读取文件, 直到读到空
            my @array = split(/\t+/, $line); #每行中各项以\t分隔

            my $device = @array[0]; #设备ID
            my $client = @array[1]; #游戏ID
            my $ips = @array[2]; #IP字串, 多个IP以|分隔
            my $platform = @array[3]; #平台
            my $states = @array[4]; #状态字串, key=value格式, 多状态以&分隔

            my $key = join(":", $device, $client); #联合主键

            if (!exists $result{$key}) { #应该不会有重复key项, 生成中间文件时已做处理, 此处以防万一
                $result{$key}{'device'} = $device;
                $result{$key}{'client'} = $client;
                $result{$key}{'platform'} = $platform;

                @array = split(/\|+/, $ips); #以|分隔的IP字串, 解析出来放置数组中
                foreach my $ip (@array) {
                    push (@{$result{$key}{'ip'}}, $ip);
                }

                @array = split(/&+/, $states); #多个状态以&分隔
                foreach my $sts (@array) {
                    my @arr = split(/=+/, $sts); #每个状态字串格式为key=value
		    		my $k = uri_unescape(@arr[0]);
		    		my @tmp = split(/\|+/, $k);
		    		$k = @tmp[0]; #print $k,"\n";
		    		if (exists $result{$key}{'state'}{$k}) {
						$result{$key}{'state'}{$k} += @arr[1];
		    		} else {
                        $result{$key}{'state'}{$k} = @arr[1];
		    		}
                }
            }
        }

        close(FILE);
        return %result;
    }
}

1;
