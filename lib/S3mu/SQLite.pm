# Copyright 2015 - Alberto Mijares <amijaresp**gmail*com>

package S3mu::SQLite;
use Moo;
use DBI;
use File::Find;


has dbfile => (
    is => 'ro'
    );

has localdir => (
    is => 'ro'
    );


my @list;

sub open {

    my $self = shift;

    my $datafile = $self->dbfile;

    my $dbh = DBI->connect("dbi:SQLite:dbname=$datafile","","");

    return $dbh;
 }

sub create_db {

    my $self = shift;

    my $dbh = $self->open;
    
    $dbh->do('CREATE TABLE queue (path TEXT, stat INT DEFAULT 0)');

    $dbh->disconnect;

    warn "Database file created\n";

}


sub gather_files {

    -f && push @list, $File::Find::name;
}


sub fill_db {

    my $self = shift;

    my $dir = $self->localdir;

    my $dbh = $self->open;

    my $wd = $ENV{PWD};

    my $sth = $dbh->prepare("INSERT INTO queue (path) VALUES(?)");

    chdir $dir;

    find(\&gather_files, '.');

    warn "Files gathered\n";

    $dbh->begin_work;
    
    for (@list) {
	$sth->execute($_);
    }

    $dbh->commit;

    $dbh->disconnect;

    warn "Database filled\n";

    undef @list;
}


sub take_one {

    my $self = shift;

    my $dbh = $self->open;

    my $file = $dbh->selectrow_arrayref
	("SELECT rowid,path FROM queue WHERE stat = 0 LIMIT 1") || 
	die "No more files to upload\n";;

    $dbh->do("UPDATE queue SET stat = 1 WHERE rowid = $file->[0]");
    
    $dbh->disconnect;

    warn "Working with $file->[1]\n";

    return $file;
    
}


sub take_some {

    my $self = shift;

    my $n = shift;

    my $dbh = $self->open;

    my $sth = $dbh->prepare("SELECT rowid, path FROM queue WHERE stat = 0 LIMIT ?");

    $sth->execute($n);

    my $data = $sth->fetchall_arrayref;

    my $nrows = $sth->rows;

    die "No more files to upload\n" if ($nrows < 1);

    my $updater = $dbh->prepare("UPDATE queue SET stat = 1 WHERE rowid = ?");

    for my $res (@$data) { 

	$updater->execute($res->[0]);

    }
    
    $dbh->disconnect;

    return $data, $nrows;    
}


sub set_stat {

    my $self = shift;

    my $rowid = shift;

    my $stat = shift;
    
    my $dbh = $self->open;

    my $sth = $dbh->prepare("UPDATE queue SET stat = ? WHERE rowid = ?");
       
    $sth->execute($stat, $rowid);

    $dbh->disconnect;
}


1;
