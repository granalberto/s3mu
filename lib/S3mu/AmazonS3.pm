# Copyright 2015 - Alberto Mijares <amijaresp**gmail*com>

package S3mu::AmazonS3;
use Moo;
use Amazon::S3;
use Amazon::S3::FastUploader::File;


has bucket => (
    is => 'ro'
    );

has amazondir => (
    is => 'ro'
    );

has ssl => (
    is => 'ro'
    );

has nprocs => (
    is => 'ro'
    );

sub prepare {

    my $self = shift;
    my $localfile = shift;
    my $bucket_name = $self->bucket;
    my $target_dir = $self->amazondir;
    my $secure = $self->ssl;
    my $nprocs = $self->nprocs;

    my $config = {
        aws_access_key_id => $ENV{AWS_ACCESS_KEY_ID},
        aws_secret_access_key => $ENV{AWS_SECRET_ACCESS_KEY},
        secure => $secure,
        encrypt => 0,
        retry => 5,
        process => $nprocs,
        verbose => 0,
     };

    my $s3 = Amazon::S3->new($config);

    my $bucket = $s3->bucket($bucket_name) or die 'cannot get bucket';

    my $file = Amazon::S3::FastUploader::File->new({
            s3         => $s3,
            local_path => $localfile,
            target_dir => $target_dir,
            bucket     => $bucket,
            config     => $config
						   });

    return $file;

}


sub upload {
    my $self = shift;
    my $file = shift;

    $file->upload;
}


1;
