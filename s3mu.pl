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
    

if ($resume) {

    $util->file_exists($dbfile) || (warn "Any problem with SQLite file?\n" && exit 1);
    $sqlite->take_one;
    # upload
    exit 0

}

$util->file_exists($dbfile) && die "Problems with SQLite file?\nExiting...\n";
$util->dir_exists($localdir) || die "Problems with local directory?\nExiting...\n";


$sqlite->create_db;
$sqlite->fill_db;
chdir $localdir;


while (my ($data, $nrows) = $sqlite->take_some($nprocs)) {
       
    for my $i (@$data) {
	
	my $pm = Parallel::ForkManager->new($nrows);
	
	$pm->start and next;
	
	my $job = $amazon->upload($amazon->prepare($i->[1]));
	
	if ($job == 1) {
	    
	    $sqlite->set_stat($i->[0], 2);
	} 
	
	else {
	    
	    $sqlite->set_stat($i->[0],0);
	    
	}
	
	$pm->finish;
	
	$pm->wait_all_children;
    }
    
}
       
say 'We are done here!';
