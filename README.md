# Rsync backup rotation
Automate incremental [Rsync](https://rsync.samba.org/) backups via a module `post-xfer exec` script and the `--link-dest` option.

Incremental backups are stored using hard-links between identical files, providing very efficient storage using nothing more than the Linux file system.

Backup runs are numbered in directories from `001 -> REVISION_COUNT`, with the script dropping directories which exceed `REVISION_COUNT`.

- [Installation](#installation)
	- [Target server](#target-server)
	- [Source server](#source-server)
- [All done](#all-done)

## Installation

### Target server
- Place `rsyncd-rotation.sh` somewhere usable and set executable for the run-as user of _receiving_ `rsyncd` process.
- Adjust [`REVISION_COUNT`](rsyncd-rotation.sh#L3) constant to the incremental retention count desired.
- Configure target Rsync module(s) to execute `rsyncd-rotation.sh` *after* a successful run via:
	- `/etc/rsyncd.conf` if running daemon mode, or...
	- `~/rsyncd.conf` if via SSH.

As an example, how I typically configure target modules:

```ini
list = false
log file = /var/log/rsyncd/00default.log
log format = %i %f [%l]
read only = false
transfer logging = true
use chroot = false


[MODULE_NAME]
log file = /var/log/rsyncd/MODULE_NAME.log
path = /target/path/to/backup
post-xfer exec = /path/to/rsyncd-rotation.sh
```

Breaking this down:
- Before validating user/module, everything is logged to `/var/log/rsyncd/00default.log`.
- Increasing the level of transfer logging to include filename and bytes moved via `log format`.
- Setting `use chroot = false` (usually) required if not running `rsyncd` under root.
- Validated module logging to `/var/log/rsyncd/MODULE_NAME.log`.
- Backup location on the target defined in `path = /target/path/to/backup`. Incremental backup runs stored in the form of `/target/path/to/backup/001` to `/target/path/to/backup/REVISION_COUNT`.
- Stanza `post-xfer exec = /path/to/rsyncd-rotation.sh` instructs `rsyncd` to execute rotation script *after* file transfer is complete.

We are now done with target server configuration.

### Source server
To start an incremental backup execute `rsync` in a method like below:

```sh
$ rsync \
	-a \
	--delete \
	--link-dest=../001 \
	/backup/from/path TARGET_HOST::MODULE_NAME/000

# or over an encrypted SSH connection
$ rsync \
	-a \
	-e "ssh -l TARGET_USER" \
	--delete \
	--link-dest=../001 \
	/backup/from.path TARGET_HOST::MODULE_NAME/000
```

The *critical* command line components are:
- Current backup is hard-linked against previous incremental with the `--link-dest=.../001` argument where files are identical between source and incremental.
- Backup is placed into a `/target/path/to/backup/000` directory via the `TARGET_HOST::MODULE_NAME/000` destination set.

Once Rsync completes, `rsyncd-rotation.sh` is executed to increase all incremental directories by one, dropping any that exceed set `REVISION_COUNT`.

## All done
You should now have automated, space saving and easy to manage incremental backups running under Rsync. Enjoy!
