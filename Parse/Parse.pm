#!/usr/bin/perl

#分析中间文件, 从中取得所需值

package Parse;
use URI::Escape;

sub new { #构造参数唯一参数为中间文件名称(或全路径)
    my $class = shift();
    my $self = {};
    my $filename = shift();
    $self->{'filename'} = $filename;
    bless $self, $class;
    return $self;
}

sub getUserNumber { #获取某款游戏的用户数量, 参数为游戏client_id
    my ($self, $client_id) = @_;
    my $filename = $self->{'filename'};
    if (-e $filename) {
        open(FILE, "<", $filename);
        my $total = 0;
        until(!($line=<FILE>)) {
            my @array = split(/\t+/, $line);
            if ($client_id eq @array[1]) { #第二项为ClientID
                $total++;
            }
        }
        close(FILE);
        return $total;
    } else {
        print "file not exist!\n";
        return -1;
    }
}

sub getUserNumberByPlatform { #获取某款游戏在Android或IOS下的用户数量, 第一个参数为游戏client_id, 第二个参数为平台字串
    my ($self, $client_id, $platform) = @_;
    my $filename = $self->{'filename'};
    if (-e $filename) {
        open(FILE, "<", $filename);
        my $total = 0;
        until(!($line=<FILE>)) {
            my @array = split(/\t+/, $line);
            if ($client_id eq @array[1]) { #第二项为ClientID
                my $plat = @array[3]; #第四项为平台字串
                if ("\L$platform\E" eq "\L$plat\E") { #转为小写字母后比较
                    $total++;
                }
            }
        }
        close(FILE);
        return $total;
    } else {
        print "file not exist!\n";
        return -1;
    }
}

sub getAllClientIds {
    my ($self) = @_;
    my $filename = $self->{'filename'};
    my @result = ();
    if (-e $filename) { #print $filename,"\n";
        open(FILE, "<", $filename);
        until(!($line=<FILE>)) {
            my @array = split(/\t+/g, $line); #print join("|", @array),"\n";
	    my $count = @array;
	    if ($count != 5) {
		next;
	    }
            my $id = @array[1];
            if (!grep /^$id$/, @result) {
                push @result, $id;
            }
        }
        close(FILE);
    }

    return @result;
}

#包内调用
sub getKeyInKvPair { #从格式(key=value)的字串中取出key值
    my ($kvstring) = @_;
    my @array = split(/=+/, $kvstring);
    return @array[0];
}

#包内调用
sub getValueInKvPair { #从格式(key=value)的字串中取出value值
    my ($kvstring) = @_;
    my @array = split(/=+/, $kvstring);
    return @array[1];
}

#包内调用
sub getOperationTotalInString { #解析操作字串,获取操作总数
    my ($string) = @_;
    my @array = split(/&+/, $string);
    my $total = 0;
    foreach $kv (@array) {
        my $num = &getValueInKvPair($kv);
        $total += $num;
    }
    return $total;
}

#包内调用
sub getOperationInString { #解析操作字串,获取某操作的数量, 参数为操作名称
    my ($string, $operation) = @_;
    my @array = split(/&+/, $string);
    my $total = 0;
    foreach $kv (@array) {
        my $key = &getKeyInKvPair($kv);
		$key = lc(uri_unescape($key)); #url解码并转为小写
		my @tmp = split(/\|+/, $key); #认为|后为参数
		$key = @tmp[0]; #只取|前内容
        if ($key eq lc($operation)) {
            my $num = &getValueInKvPair($kv);
            $total += $num;
        }
    }
    return $total;
}

#包内调用
sub getOperationTotalInLine { #获取一行信息中操作总数
    my ($line, $client_id, $platform) = @_;
    #print $client_id,"\n";
    my @array = split(/\t+/, $line);
    if ($client_id eq @array[1]) { #第二项为ClientID
        my $plat = @array[3]; #第四项为平台字串
        if ("\L$platform\E" eq "\L$plat\E") { #转为小写字母后比较
            my $str_opr = @array[4]; #第五项为操作字串
            my $num = &getOperationTotalInString($str_opr);
            return $num;
        }
    }
    return 0;
}

#包内调用
sub getOperationInLine { #获取一行信息中某种操作的数量, 参数2为游戏client_id, 参数3为操作名称
    my ($line, $client_id, $operation, $platform) = @_;
    my @array = split(/\t+/, $line);
    #print $line;
    #print $platform,"\n";
    #print $operation,"\n";
    if ($client_id eq @array[1]) { #第二项为ClientID
        my $plat = @array[3]; #第四项为平台字串
        if ("\L$platform\E" eq "\L$plat\E") { #转为小写字母后比较
            my $str_opr = @array[4]; #第五项为操作字串
            my $num = &getOperationInString($str_opr, $operation);
            #print $num,"\n";
            return $num;
        }
    }
    return 0;
}

#包内调用
sub getOperationTotalByUserInLine { #按用户获取一行信息中操作总数, 参数2为游戏client_id, 参数3为用户信息
    my ($line, $client_id, $user) = @_;
    my @array = split(/\t+/, $line);
    if ($client_id eq @array[1] && $user eq @array[0]) { #第二项为ClientID, 第一项为用户信息
        my $str_opr = @array[4]; #第五项为操作字串
        my $num = &getOperationTotalInString($str_opr);
        return $num;
    } else {
        return 0;
    }
}

#包内调用
sub getOperationByUserInLine { #获取一行信息中某种操作的数量, 参数2为游戏client_id, 参数3为操作名称, 参数4为用户信息
    my ($line, $client_id, $operation, $user) = @_;
    my @array = split(/\t+/, $line);
    if ($client_id eq @array[1] && $user eq @array[0]) { #第二项为ClientID, 第一项为用户信息
        my $str_opr = @array[4]; #第五项为操作字串
        my $num = &getOperationInString($str_opr, $operation);
        return $num;
    } else {
        return 0;
    }
}

sub getOperationTotal { #获取某一游戏在Android或IOS平台上的操作总数, 参数1为游戏的client_id, 参数2为平台字串
    my ($self, $client_id, $platform) = @_;
    my $filename = $self->{'filename'};
    if (-e $filename) {
        my $total = 0;
        open(FILE, "<", $filename);
        until(!($line = <FILE>)) {
            my $num = &getOperationTotalInLine($line, $client_id, $platform);
            $total += $num;
        }
        close(FILE);
        return $total;
    } else {
        return -1;
    }
}

sub getOperationNumber { #获取某一游戏在Android或IOS平台上某个操作的数量, 参数1为游戏的client_id, 参数2为操作名称, 参数3为平台字串
    my ($self, $client_id, $operation, $platform) = @_; #print $platform,"\n";

    #print $line;
    #print $platform,"\n";
    #print $operation,"\n";

    my $filename = $self->{'filename'};
    if (-e $filename) {
        my $total = 0;
        open(FILE, "<", $filename);
        until(!($line=<FILE>)) {
            my $num = &getOperationInLine($line, $client_id, $operation, $platform);
            $total += $num;
        }
        close(FILE);
        #print $total,"\n";
        return $total;
    } else {
        return -1;
    }
}

sub getOperationTotalByUser { #获取某一用户在玩某一游戏时的操作总数, 参数1为游戏client_id, 参数2为用户信息(目前按DeviceID)
    my ($self, $client_id, $user) = @_;
    my $filename = $self->{'filename'};
    if (-e $filename) {
        my $total = 0;
        open(FILE, "<", $filename);
        until(!($line=<FILE>)) {
            my $num = &getOperationTotalByUserInLine($line, $client_id, $user);
            $total += $num;
        }
        close(FILE);
    } else {
        return -1;
    }
}

sub getOperationNumberByUser { #获取某一用户在玩某一游戏时某种操作的数量, 参数1为游戏client_id, 参数2为操作名称, 参数3为用户信息(目前按DeviceID)
    my ($self, $client_id, $operation, $user) = @_;
    my $filename = $self->{'filename'};
    if (-e $filename) {
        my $total = 0;
        open(FILE, "<", $filename);
        until(!($line=<FILE>)) {
            my $num = &getOperationByUserInLine($line, $client_id, $operation, $user);
            $total += $num;
        }
        close(FILE);
    } else {
        return -1;
    }
}

1;
