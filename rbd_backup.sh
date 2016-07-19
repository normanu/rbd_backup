#!/bin/bash
# rbd incremental backup the snapshot in the "volumes" pool
#
# Usage: rbd_backup.sh <NFS_DIR>

SOURCEPOOL="rbd"
TIMESTAMP=`date "+%Y-%m-%d %H:%M:%S"`

NFS_DIR="$1"
if [[ -z "$NFS_DIR" ]]; then
    echo "$TIMESTAMP   Usage: rbd_backup.sh <NFS_DIR>"
    exit 1
fi

BACKUP_DIR="$NFS_DIR/backup_volume"
LOG_FILE="$BACKUP_DIR/backup.log"
mkdir -p $BACKUP_DIR
touch $LOG_FILE

# list all volumes in the pool
IMAGES=`rbd ls $SOURCEPOOL`
TODAY=`date +%Y%m%d`

for LOCAL_IMAGE in $IMAGES; do

    SNAP_TODAY=`rbd snap ls $LOCAL_IMAGE |grep $TODAY`
    # check if there is a snapshot made today
    if [[ -z "$SNAP_TODAY" ]]; then
        rbd snap create $LOCAL_IMAGE@$TODAY
	else
	echo "$TIMESTAMP   info: image already backed up today" >>$LOG_FILE
    fi

    # check if there is snapshot to backup
    LATEST_SNAP=`rbd snap ls $SOURCEPOOL/$LOCAL_IMAGE |grep -v "SNAPID" |sort -r | head -n 1 |awk '{print $2}'`
    if [[ -z "$LATEST_SNAP" ]]; then
        echo "$TIMESTAMP   info: no snap for $SOURCEPOOL/$LOCAL_IMAGE to backup" >>$LOG_FILE
                continue
    fi

        # the first snapshot backup
        # 1. full export base image
        # 2. export-diff the first snapshot
        IMAGE_DIR="$BACKUP_DIR/$LOCAL_IMAGE"
        if [[ ! -e "$IMAGE_DIR" ]]; then
                mkdir -p "$IMAGE_DIR"
                # full export the image
                echo "$TIMESTAMP   rbd export $SOURCEPOOL/$LOCAL_IMAGE $IMAGE_DIR/${LOCAL_IMAGE}" >>$LOG_FILE
                rbd export $SOURCEPOOL/$LOCAL_IMAGE $IMAGE_DIR/${LOCAL_IMAGE}  >/dev/null 2>&1

                # export-diff the first snapshot
                echo "$TIMESTAMP   rbd export-diff $SOURCEPOOL/$LOCAL_IMAGE@$LATEST_SNAP \
                                      $IMAGE_DIR/${LOCAL_IMAGE}_${LATEST_SNAP}" >>$LOG_FILE
                rbd export-diff $SOURCEPOOL/$LOCAL_IMAGE@$LATEST_SNAP \
                                $IMAGE_DIR/${LOCAL_IMAGE}_${LATEST_SNAP}  >/dev/null 2>&1
                continue
        fi

        # export-diff the snapshot from last one
        LAST_SNAP=`ls $IMAGE_DIR -1 -rt |tail -n 1|awk -F_ '{print $2}'`
        if [[ $LATEST_SNAP == $LAST_SNAP ]]; then
                continue
        fi
        echo "$TIMESTAMP   rbd export-diff --from-snap $LAST_SNAP $SOURCEPOOL/$LOCAL_IMAGE@$LATEST_SNAP \
                                          $IMAGE_DIR/${LAST_SNAP}_${LATEST_SNAP}" >>$LOG_FILE
        rbd export-diff --from-snap $LAST_SNAP $SOURCEPOOL/$LOCAL_IMAGE@$LATEST_SNAP \
                                    $IMAGE_DIR/${LAST_SNAP}_${LATEST_SNAP}  >/dev/null 2>&1

	# Remove old snapshots but leave latest
	OLD_SNAPS=`rbd snap ls $LOCAL_IMAGE|grep -v "SNAPID" |sort -r |tail -n +2 |awk '{print $2}'`
	for DELETE_SNAP in $OLD_SNAPS
	do
		echo "$TIMESTAMP   removing old snapshot $DELETE_SNAP" >>$LOG_FILE
		rbd snap rm $LOCAL_IMAGE@$DELETE_SNAP
	done

done

