#!/usr/bin/perl

#原始日志相关操作, 获取各参数方法 格式相关
#目前日志格式如下:
#111.222.199.214 statistics.5dsy.cn - [15/Feb/2016:23:58:45 +0800] "GET /?client_id=201509002&device=7254B59E94C94D2984DF942D56384665&state=init HTTP/1.1" 200 6 "-" "Wuyou iOS/1.8.6"

package Log;

sub new { #初始化日志模块, 唯一参数为一段日志(一般为日志文件中的一行)
    my $class = shift();
    my $self = {};
    $self->{"log"} = shift(); #日志内容
    bless $self, $class;
    return $self;
}

sub output { #测试函数
    my ($self) = @_;
    print $self->{'log'};
}

sub getIp { #获取IP信息
    my ($self) = @_;
    my $log = $self->{'log'};
    @strs = split(/ +/, $log); #日志内容以"空格"分隔, 第一部分为IP
    return @strs[0];
}

sub getTime { #获取时间
    my ($self) = @_;
    my $log = $self->{'log'};
    #$pattern = "\[(.+?)\]";
    @arr = $log =~ /\[(.*)\]/g; #时间被包含在一对中括号里[]
    return @arr[0];
}

sub getInfoes { #获取主要信息字串, 测试用
    my ($self) = @_;
    my $log = $self->{'log'};
    @arr = $log =~ /\"(.+?)\"/g; #该信息包含在第一个引号中""
    return @arr[0];
}

sub getClientId { #获取客户端ID(区分游戏)
    my ($self) = @_;
    my $log = $self->{'log'};
    @arr = $log =~ /\"(.+?)\"/g; #获取主要信息, 第一个引号中""
    @str = @arr[0] =~ /\/\?(.*) /g; #主要信息的k=v字串在/?与空格之间
    @params = split(/&/, @str[0]); #以&分隔各个k=v块
    foreach $str (@params) {
        @tmps = split(/=/, $str);
        $key = @tmps[0];
        $val = @tmps[1];
        if ($key eq "client_id") { #找出key为client_id的value
            return $val;
        }
    }
}

sub getDevice { #获取设备ID
    my ($self) = @_;
    my $log = $self->{'log'};
    @arr = $log =~ /\"(.+?)\"/g; #获取主要信息, 第一个引号中""
    @str = @arr[0] =~ /\/\?(.*) /g; #主要信息的k=v字串在/?与空格之间
    @params = split(/&/, @str[0]); #以&分隔各个k=v块
    foreach $str (@params) {
        @tmps = split(/=/, $str);
        $key = @tmps[0];
        $val = @tmps[1];
        if ($key eq "device") { #找出key为device的value
            return $val;
        }
    }
}

sub getState { #获取状态名称
    my ($self) = @_;
    my $log = $self->{'log'};
    @arr = $log =~ /\"(.+?)\"/g; #获取主要信息, 第一个引号中""
    @str = @arr[0] =~ /\/\?(.*) /g; #主要信息的k=v字串在/?与空格之间
    @params = split(/&/, @str[0]); #以&分隔各个k=v块
    foreach $str (@params) {
        @tmps = split(/=/, $str);
        $key = @tmps[0];
        $val = @tmps[1];
        if ($key eq "state") { #找出key为state的value
            return $val;
        }
    }
}

sub getPlatform { #获取所属平台
    my ($self) = @_;
    my $log = $self->{'log'};
    @arr = $log =~ /\"Wuyou (.*)\//g; #该信息在Wuyou 与/之间
    return @arr[0];
}

1;