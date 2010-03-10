#!/bin/bash

# ssh-keygen -t rsa

# binaries we need
MYSQLDUMP=/usr/bin/mysqldump
TAR=/bin/tar
RSYNC=/usr/bin/rsync

# password for .dhbackups
#
# format of $HOME/.dhbackups is
#
# IBACKUP_USERNAME=username
# IBACKUP_PASSWORD=password
DHBACKUPS="$HOME/.dhbackups"

if [ ! -r $DHBACKUPS ]; then
	echo "Need $DHBACKUPS file for username and password!"
	exit 1
else
	PERMS=`/bin/ls -l $DHBACKUPS | /usr/bin/awk '{print $1}'`
fi

if [ $PERMS != "-rw-------" ]; then
	echo "Permissions on $DHBACKUPS are wrong!"
	echo "Should be -rw-------, actually is $PERMS"
	exit 2
fi

. $DHBACKUPS
export RSYNC_PASSWORD=$DHBACKUPS_PASSWORD

# today, for tagging the dumpfile
DATE=`/bin/date +%Y-%m-%d`

# place to dump everything
DUMPDIR="$HOME/backup_data_tmp"
DUMPDIR_DATE="$DUMPDIR/$DATE"
DUMPDIR_BK_FOLDER_FILES="$DUMPDIR_DATE/files"
DUMPDIR_BK_FOLDER_DATABASES="$DUMPDIR_DATE/database"

echo $DUMPDIR_BK_FOLDER_FILES

if [ ! -d $DUMPDIR ]; then
	mkdir $DUMPDIR
	mkdir $DUMPDIR_DATE
	mkdir $DUMPDIR_BK_FOLDER_FILES
	mkdir $DUMPDIR_BK_FOLDER_DATABASES
fi

if [ ! -x $MYSQLDUMP ]; then
	echo "Need $MYSQLDUMP!"
	exit 3
fi

if [ ! -x $RSYNC ]; then
	echo "Need $RSYNC!"
	exit 4
fi

cd $DUMPDIR

echo -n "creating tar.gz arcvhive of $HOME/$FOLDER_TO_BACKUP..."
	$TAR czvf $DUMPDIR_BK_FOLDER_FILES/site.tar.gz $HOME/$FOLDER_TO_BACKUP
echo "done!"

echo -n "dumping database to $DUMPDIR_BK_FOLDER_DATABASES/$DATABASE_NAME.sql... "
	$MYSQLDUMP $DATABASE_NAME > $DUMPDIR_BK_FOLDER_DATABASES/$DATABASE_NAME.sql
echo "done!"

if [ -e $DUMPDIR_BK_FOLDER_DATABASES/$DATABASE_NAME.sql ]; then

	echo -n "change directory to $DUMPDIR_BK_FOLDER_DATABASES ..."
	cd $DUMPDIR_BK_FOLDER_DATABASES

	echo -n "creating tar.gz arcvhive of $DUMPDIR_BK_FOLDER_DATABASES/$DATABASE_NAME.sql ..."
	
	$TAR czvf $DATABASE_NAME.tar.gz ./$DATABASE_NAME.sql
	echo "done!"

	echo -n "deleting $DUMPDIR_BK_FOLDER_DATABASES/$DATABASE_NAME.sql ..."
	rm $DATABASE_NAME.sql
	echo "done!"
fi

cd $HOME

$RSYNC -r -v -z -t --delete-after $DUMPDIR/ $DHBACKUPS_USERNAME@$DHBACKUPS_SERVER:~/backup/$FOLDER_TO_BACKUP

echo -n "Cleaning up... "
/bin/rm -rfv $DUMPDIR
echo "done!"