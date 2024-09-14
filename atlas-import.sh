#!/bin/bash
#modified version of `mongo-backup.sh` and `mongo-restore.sh` for cloud export and local overwrite
#modified for export from ATLAS to E1 restoration for cloud migration tasking

#todo - update these to container yaml secret/env var import values
LATEST=$(date +%y-%m-%d_%H-%M)
LOG_LOCATION=/backup/logs/restore-${LATEST}.log
ATLAS_SECRET=$(cat /backup/.atlas-secret)
SECRET=$(cat /backup/.secret)
BACKUP_DIR=/backup/atlas
USERNAME=admin #update to secret hosted/env-var/define at runtime.

cleanup_old () {
        #remove oldest snapshots from /backup/mongo-snapshots older than 7 days:
        find /backup/atlas-snapshots/ -name "*.tar.gz" -type f -mtime +7 -delete
        echo "removed older than 7 days snapshots from local dir"

        echo "clearing old logs"
        find /backup/logs/ -name "*.log" -type f -mtime +30 -delete

        #remove oldest snapshots from nas [30 days]
        #find /mnt/nas/mongodump/atlas-snapshots/ -name "*.tar.gz" -type f -mtime +30 -delete
        #echo "removed snaps older than 30 days from nas"
        echo "todo: update target volume for sync service cleanup on DC"
}


import_from_atlas () {
#capture latest data set from Atlas:
mongodump --username wradmin --password $ATLAS_SECRET mongodb+srv://coread-zimmer.gneb3.mongodb.net --out ${BACKUP_DIR}

#remove yesterday's snap in prep for new one:
echo "removing old snap from local"
rm /backup/latest-snapshot/atlas-snap-*.tar.gz

#create fresh tarball with latest mongo-output with date/time:
tar -czf /backup/latest-snapshot/atlas-snap-$(date +%y-%m-%d_%H-%M).tar.gz $BACKUP_DIR

#copy the latest snap tarball to the local backup dir:
echo "duplicating snapshots to archive: /backup/atlas-snapshots"
cp /backup/latest-snapshot/atlas-snap-*.tar.gz /backup/atlas-snapshots/

#purge the latest snapshot only recall folder:
#rm /mnt/nas/mongodump/latest_atlas_snap_only/*

#copy the latest snap tarball to the NAS for storage:
echo "sending tarball to nas"
echo "todo - update to point at target DC volume"
#rsync -av  /backup/latest-snapshot/atlas-snap-*.tar.gz /mnt/nas/mongodump/atlas-snapshots/
#rsync -av  /backup/latest-snapshot/atlas-snap-*.tar.gz /mnt/nas/mongodump/latest_atlas_snap_only/

#get name of latest for check:
TARGET=$(ls /backup/latest-snapshot | grep atlas-snap | awk {'print $1'})

#VALIDATE THAT SYSTEM BACKUP DID OCCUR AND ONLY THEN APPROVE DELETION OF OLDEST FILES:
#if [[ -f /mnt/nas/mongodump/latest_atlas_snap_only/${TARGET} ]]
#then
#        cleanup_old
#        echo "backups captured and confirmed stored on nas"
#else
#        echo "could not validate nas capture of backup, refusing to delete old versions"
#fi
#}

restore_script () {
#use latest restored atlas dump:
#mongorestore -v --username wradmin --password $SECRET --drop /backup/atlas
#restore only target database: coread
mongorestore -v --username $USERNAME --password $SECRET --drop --nsInclude=coread.* /backup/atlas
echo "completed restore"
}

#start runtime and dump to log
echo "$(date)" | tee $LOG_LOCATION
echo "starting sync" | tee $LOG_LOCATION
import_from_atlas 2>&1 | tee $LOG_LOCATION
restore_script 2>&1 | tee $LOG_LOCATION
cleanup_old 2>&1 | tee $LOG_LOCATION

exit 0 #exit clean to avoid stalling container even on failure; can debug separately