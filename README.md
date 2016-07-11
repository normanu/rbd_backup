# Backup script for Volumes in RBD pool

This script is made to incremental backups of the volumes in my rbd ceph pool.
When you have big volumes and a slow connection it is difficult to backup these offsite.
With this script you will only have to backup the main version and all the diffs.


## TODO

- Make a script to merge the diffs on both sides and check if of and onsite versions are the same.

