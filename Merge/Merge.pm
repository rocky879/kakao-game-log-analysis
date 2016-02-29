#!/usr/bin/perl

#合并中间文件操作

my $pwd = $ENV{'PWD'}; #当前路径

require "/home/daumkakao/scripts/log/game/Merge/Parse.pm";
require "/home/daumkakao/scripts/log/game/Merge/MergeBase.pm";

use File::Basename qw<dirname>;
use File::Path qw(mkpath);

sub merge2files { #合并两个中间文件, 前两个参数为中间文件全路径(包含文件名), 第三个参数为结果全路径(包含文件名)
    my ($file1, $file2, $dest) = @_;

    #print $file1, "\n";
    #print $file2, "\n";

    #解析两个中间文件
    my %result1 = midParse($file1); #print %result1, "\n";
    my %result2 = midParse($file2);

    my %result = %result1; #将第一个文件解析结果先直接赋值给合并结果
    foreach my $key (keys %result2) { #遍历第二个文件解析结果
        if (exists $result{$key}) { #如果第二个的某项存在于合并结果中
            #print $result{$key}{'ip'}[0], "\n";
            my @arr_ip_merge = merge_ip_array($result1{$key}{'ip'}, $result2{$key}{'ip'}); #合并两个IP数组
            $result{$key}{'ip'} = (); #清空原IP数组
            foreach my $ip (@arr_ip_merge) { #将合并后的IP数组逐一放入结果的IP数组中
                push (@{$result{$key}{'ip'}}, $ip);
            }
            #print @arr_ip_merge, "\n";

            my %hash_merge = merge_state_hash($result{$key}{'state'}, $result{$key}{'state'}); #合并状态哈希
            $result{$key}{'state'} = (); #清空原状态哈希
            while (($k, $v) = each(%hash_merge)) { #将合并后的状态哈希逐一放入结果的状态哈希中
                $result{$key}{'state'}{$k} = $v;
            }
        } else {
            $result{$key} = $result2{$key};
        }
    }

    my $content = ""; #写入合并后的中间文件的内容

    while (($k, $v) = each(%result)) { #遍历上面的合并结果
        my %hash = %{$v}; #结果中每个value均为哈希
        #print $hash{'ip'}[0], "\n";

        $content .= $hash{'device'}."\t"; #设备ID
        $content .= $hash{'client'}."\t"; #游戏ID
        $content .= join("|", @{$hash{'ip'}})."\t"; #IP数组以"|"分隔显示
        $content .= $hash{'platform'}."\t"; #平台

        %stses = %{$hash{'state'}}; #状态信息为哈希数组
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

    #if (-e $dest) { #若已存在所要生成的文件, 先删除
        #unlink $dest;
    #}

    my $dir = dirname $dest;
    if (!-d $dir) {
        #mkpath($dir, 1, 0755);
        #system("mkdir -p ".$dir);
        mkpath $dir;
    }

    #print (dirname $dest);
    #print "\n";
    open(OUTFILE, ">".$dest) or die;
    print OUTFILE ($content);
    close(OUTFILE);
}

sub merge2folders { #合并两个中间文件的文件夹, 前两个参数为需合并的文件夹路径, 第三个参数为目标文件夹
    #合并原则为同名文件合并, 不同名的直接复制的目标文件夹
    my ($folder1, $folder2, $dest) = @_;

    if (!($folder1 =~ /\/$/g)) { #判断文件夹路径是否以/结尾, 不是的话加上
        $folder1 .= "/";
    }
    if (!($folder2 =~ /\/$/g)) { #同上
        $folder2 .= "/";
    }

    my @filelist = ();
    chdir $folder1;
    for my $file (glob("*")) { #将folder1中的文件完全复制到目标文件夹中
        copy($folder1.$file, $dest);
        push @filelist, $file; #将文件名放在一个数组中, 用于之后比较
    }

    chdir $folder2;
    for my $file (glob("*")) {
        if (grep /^$file$/, @filelist) { #存在与folder1中的同名文件, 合并
            merge2files($folder1.$file, $folder2.$file, $dest.$file);
        } else { #同名文件不存在于folder1中, 直接复制到目标文件夹
            copy($folder2.$file, $dest);
        }
    }
}

sub merge_folders { #合并N个文件夹, 第一个参数为文件夹路径数组, 第二个参数为目标文件夹
    my ($folders, $dest) = @_;
    my @folders = @{$folders};
    my $count = @folders; #文件夹数量

    if ($count == 1) { #只有一个文件夹, 直接将该文件夹中所有文件复制到目标文件夹
        my $folder = @folders[0];
        chdir $folder;
        for my $file (glob("*")) {
            copy($folder.$file, $dest);
        }
    } elsif ($count > 1) {
        my $idx = 0;
        my $folder1 = @folders[0];
        while ($idx <= $count-2) {
            if ($idx > 0) { #非第一次合并, folder1为目标文件夹, 即之前合并结果
                $folder1 = $dest;
            }

            my $folder2 = @folders[$idx+1];
            merge2folders($folder1, $folder2, $dest);
            $idx++;
        }
    } else {
        die;
    }
}

1;