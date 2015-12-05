# Copyright 2015 - Alberto Mijares <amijaresp**gmail*com>

package S3mu::Utils;
use Moo;

sub file_exists {

    my $self = shift;
    my $file = shift;
    return 0 unless $file;
    return 0 unless -f $file;
    return 0 unless -r $file;
    return 1;
}


sub dir_exists {

    my $self = shift;
    my $dir = shift;
    return 0 unless $dir;
    return 0 unless -d $dir;
    return 0 unless -r $dir;
    return 1;
}


1;

