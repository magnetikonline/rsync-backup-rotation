# Rsync backup rotation
Automate incremental backups when using Rsync via a module `post-xfer exec` script and `--link-dest`. Backups are numbered in directories from `001..REVISION` with the script dropping the oldest directory after `REVISION` count has been reached.

## Install

### Target server
Place `rsyncd-rotation.sh` somewhere on your server and set executable for user(s) running the receiving `rsyncd`. Adjust the `REVISION=XX` value at top of script to set the backup retention count desired.

Next, configure target Rsync module(s) to execute rsyncd-rotation.sh *after* a successful Rsync run via `rsyncd.conf`, either `/etc/rsyncd.conf` for root or if rsyncd over SSH, via `~/rsyncd.conf`.

As an example, how I typically configure Rsync modules on the target:

```ini
list = false
log file = /var/log/rsyncd/00default.log
read only = false
use chroot = false


[modulename]
log file = /var/log/rsyncd/modulename.log
path = /target/path/to/backup/to
post-xfer exec = /path/to/rsyncd-rotation.sh
```

Breaking this down:
- Setting `use chroot = false` (usually) required if not running `rsyncd` under root user.
- Before validating module login credentials, everything logged to `/var/log/rsyncd/00default.log`
- Module name defined in `[modulename]`
- Validated login module logging to `/var/log/rsyncd/modulename.log`
- Backup location on the target defined in `path = /target/path/to/backup/to`. Backups laid out in the form of `/target/path/to/backup/to/001` to `/target/path/to/backup/to/REVISION`.
- The `post-xfer exec = /path/to/rsyncd-rotation.sh` setting tells `rsyncd` to execute rotation script *after* transmission is complete, adjust path to suit.

We are now done with the target server.

### Source server
To start an incremental backup from the source server you will run `rsync` like the following (more than likely via crontab), flavour `rsync` commandline to suit:

```shell
rsync -a --delete --link-dest=../001 /backup/from targethost::modulename/000

# or over an encrypted SSH connection
rsync -a -e "ssh -l targetuser" --delete --link-dest=../001 /backup/from targethost::modulename/000
```
The *critical* command line options are:
- Backup is hard-linked against the previous incremental with `--link-dest=.../001`, where source files have not changed between runs for disk space savings.
- The current backup is placed into a `/target/path/to/backup/to/000` directory with `targethost::modulename/000`. After the Rsync completes, target server will execute `rsyncd-rotation.sh` and increase this directory along with all existing incrementals by one position, dropping the oldest if `REVISION` has been reached.

## All done
You should now have automated, space saving and easy to manage incremental backups running under Rsync. Enjoy!
