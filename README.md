# Backup script for Volumes in RBD pool

This script is made to create incremental backups of the volumes in the rbd ceph pool.
When you have big volumes and a slow connection it is difficult to backup these offsite.
With this script you will only have to backup the main version and all the diffs to the main backup.

## Howto

Put the script in a folder make it executable by typing

`chmod +x rbd_backup.sh`

You use the script by point a destination folder for the backups,

_Example:_
`./rbd_backup.sh /backup`

I advise you to run the script in a cronjob to run everyday.
It is configured to run once a day as it uses the date as diff filename.

### TODO

- Make a script to merge the diffs on both sides and check if of and onsite versions are the same.

