#!/bin/bash
DB=dp
BACKUP_FILENAME="`date +%Y-%m-%d`_dp_production.gz"
mysqldump -ce -h localhost -u root -pDP2012omg $DB | gzip > /mnt/sites/dp/respaldos/$BACKUP_FILENAME
#uuencode $BACKUP_FILENAME | mail -s "daily backup for `date`" avillagran@dportales.cl

echo -e "\n====\n== Backed up $DB to $BACKUP_FILENAME on `date` \n====\n"