#!/usr/bin/env perl

# Copyright 2015 - Alberto Mijares <amijaresp**gmail*com>

use v5.10;
use warnings;
use strict;
use lib 'lib';
use S3mu::SQLite;
use S3mu::AmazonS3;
use S3mu::Utils;
use Getopt::Long;
use File::Spec;
use Parallel::ForkManager;


my $localdir = '';
my $dbfile = '';
my $resume = 0;
my $bucket = '';
my $remotedir = '';
my $ssl = 0;
my $nprocs = 5;

GetOptions (
    'localdir=s' => \$localdir,
    'dbfile=s' => \$dbfile,
    'resume' => \$resume,
    'bucket=s' => \$bucket,
    'amazondir=s' => \$remotedir,
    'ssl' => \$ssl,
    'nprocs=i' => \$nprocs
    );


my $util = new S3mu::Utils;

my $sqlite = new S3mu::SQLite(dbfile => File::Spec->rel2abs($dbfile),
			      localdir => $localdir);

my $amazon = new S3mu::AmazonS3(bucket => $bucket,
				amazondir => $remotedir,
				ssl => $ssl,
				nprocs => $nprocs);

my $pm = Parallel::ForkManager->new($nprocs);
    

if ($resume) {
    
    $util->file_exists($dbfile) || (warn "Any problem with SQLite file?\n" && exit 1);
    while (my $data = $sqlite->take_some($nprocs)) {
	for my $i (@$data) {
	    my $nstat;
	    $pm->start and next;
	    my $job = $amazon->upload($amazon->prepare($i->[1]));
	    $job == 1 ? $nstat = 2 : $nstat = 0;
	    $sqlite->set_stat($i->[0], $nstat);
	    $pm->finish;
	}
	$pm->wait_all_children;
    }
    say 'We are done here!';
    exit 0
}

$util->file_exists($dbfile) && die "Problems with SQLite file?\nExiting...\n";
$util->dir_exists($localdir) || die "Problems with local directory?\nExiting...\n";

$sqlite->create_db;
$sqlite->fill_db;
chdir $localdir;

while (my $data = $sqlite->take_some($nprocs)) {
       
    for my $i (@$data) {

	my $nstat;
	$pm->start and next;
	my $job = $amazon->upload($amazon->prepare($i->[1]));
	$job == 1 ? $nstat = 2 : $nstat = 0;
	$sqlite->set_stat($i->[0], $nstat);
	$pm->finish;
    }

    $pm->wait_all_children;
}
       
say 'We are done here!';
