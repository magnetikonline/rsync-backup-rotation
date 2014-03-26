# Rsync backup rotation
Automate incremental backups when using Rsync via a module `post-xfer exec` script and `--link-dest`. Backups are numbered in directories from `001..REVISION_COUNT` with the script dropping the oldest directory once `REVISION_COUNT` limit has been reached.

## Install

### Target server
Place `rsyncd-rotation.sh` somewhere on your server and set executable for the user/group running the receiving `rsyncd`. Adjust the `REVISION_COUNT=XX` variable at top of script to the backup retention count desired.

Next, configure target Rsync module(s) to execute `rsyncd-rotation.sh` *after* a successful Rsync run via `rsyncd.conf` - either `/etc/rsyncd.conf` for daemon mode or `~/rsyncd.conf` if via SSH.

As an example, how I typically configure Rsync modules on the target:

```ini
list = false
log file = /var/log/rsyncd/00default.log
log format = %i %f [%l]
read only = false
transfer logging = true
use chroot = false


[modulename]
log file = /var/log/rsyncd/modulename.log
path = /target/path/to/backup
post-xfer exec = /path/to/rsyncd-rotation.sh
```

Breaking this down:
- Before validating module login credentials, everything is logged to `/var/log/rsyncd/00default.log`
- Increasing the level of transfer logging to include filename and bytes moved via `log format`
- Setting `use chroot = false` (usually) required if not running `rsyncd` under root
- Module name defined in `[modulename]`
- Validated login module logging to `/var/log/rsyncd/modulename.log`
- Backup location on the target defined in `path = /target/path/to/backup`. Backups laid out in the form of `/target/path/to/backup/001` to `/target/path/to/backup/REVISION_COUNT`.
- The `post-xfer exec = /path/to/rsyncd-rotation.sh` setting tells `rsyncd` to execute the rotation script *after* transmission is complete, adjust path to suit.

We are now done with the target server for configuration.

### Source server
To start an incremental backup from the source server run `rsync` like the following, flavour your `rsync` command line to suit:

```sh
$ rsync \
	-a --delete \
	--link-dest=../001 \
	/backup/from targethost::modulename/000

# or over an encrypted SSH connection
$ rsync \
	-a -e "ssh -l targetuser" --delete \
	--link-dest=../001 \
	/backup/from targethost::modulename/000
```

The *critical* command line options are:
- Backup is hard-linked against the previous incremental with `--link-dest=.../001`, where source files have not changed between runs for disk space savings.
- The current backup is placed into a `/target/path/to/backup/000` directory with `targethost::modulename/000`. After the Rsync completes, target server will execute `rsyncd-rotation.sh` and increase this directory along with all existing incrementals by one position, dropping the oldest if `REVISION_COUNT` has been reached.

## All done
You should now have automated, space saving and easy to manage incremental backups running under Rsync. Enjoy!
