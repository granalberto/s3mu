# s3mu
Massive and recursive uploads to Amazon S3

This script is inspired on https://github.com/DQNEO/Amazon-S3-FastUploader. The main reason to write it was the lack of persistence on the job queue of Amazon::S3::FastUploader.

s3mu uploads as many files as you specify at once. It is intended to be used in case you have many files to upload to Amazon S3, not for just a couple files.

First, a SQLite database is created with every file under directory specified with -l option. Each file has a status: 0 is the file is in the queue to be uploaded; 1 is the file is being uploaded and 2 if the file was already uploaded.

Usage:

$ s3mu -d &lt;dbfile&gt; -l &lt;local_dir_to_upload&gt; -a &lt;remote_base_dir&gt; [-s] -n &lt;number_of_forks&gt; -b &lt;bucket_name&gt;

Options:

-s Activates SSL.

-r Is used if a previously run of the script ended unexpectly (a server reboot, i.e.). Unfinished--

Everything else is auto-explained.

Caveats:

I still need to test how to specify the -a option in case you want to upload files in the root of the bucket. -d '/' is wrong.
