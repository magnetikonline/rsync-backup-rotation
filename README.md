# Rsync backup rotation
Automate incremental backups when using Rsync via a module `post-xfer exec` script and the mighty handy `--link-dest`. Backups are numbered in directories from `001..REVISION` with the script dropping the oldest directory after `REVISION` count is reached on the target server.

## Install

### Target server
Place `rsyncd-rotation.sh` somewhere on your server and ensure it is executable for the user running under `rsyncd`. Configure the `REVISION=XX` bash variable at the top of the script to control the backup retention count desired.

Next, configure your target Rsync module(s) to execute rsyncd-rotation.sh after a successful Rsync process in your `rsyncd.conf` file, either `/etc/rsyncd.conf` for root or if using rsyncd over SSH, in `~/rsyncd.conf`.

As an example and how I typically configure modules on the target:

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

To break this down:
- The setting `use chroot = false` is vital if not running the module as root on target server.
- Before validating module, everything is logged to `/var/log/rsyncd/00default.log`
- Module name defined in `[modulename]`
- Module logging is to `/var/log/rsyncd/modulename.log`
- Backup location on the target is defined in `path = /target/path/to/backup/to`. Our backups will be in the form of `/target/path/to/backup/to/001` to `/target/path/to/backup/to/REVISION`.
- The `post-xfer exec = /path/to/rsyncd-rotation.sh` setting tells `rsyncd` to execute our rotation script after transmission is complete, adjust path to suit.

We are now done with the target server.

### Source server
To run an incremental backup from the source server you will do something like the following (more than likely from a crontab), flavour your rsync command to suit:

```shell
rsync -a --delete --link-dest=../001 /backup/from targethost::modulename/000

# or via an SSH connection (better)
rsync -a -e "ssh -l targetuser" --delete --link-dest=../001 /backup/from targethost::modulename/000
```
The *critical* command line options are:
- Backup is hard-linked against the previous incremental using `--link-dest=.../001` where source files have not changed (massive disk space savings - vital).
- The current backup is placed into a **000** directory under the root of the **modulename** path with `targethost::modulename/000`. After the Rsync completes, the target server will execute `rsyncd-rotation.sh` and increase this directory along with all existing incrementals by one position and dropping the oldest if `REVISION` has been reached.

## All done
You should now have automated, space saving (via hard links) and easy to manage incremental backups running under Rsync. Enjoy!
