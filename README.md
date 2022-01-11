# Rsync backup rotation

Enable automated incremental [Rsync](https://rsync.samba.org/) backups with a module `post-xfer exec` script and the `--link-dest` option.

Incremental backups are stored using hard-links between identical files, providing very efficient storage using nothing more than the Linux file system.

Backup runs are numbered in directories from `001 -> REVISION_COUNT`, with script automatically truncating directories beyond `REVISION_COUNT`.

- [Installation](#installation)
	- [Target server](#target-server)
		- [Optional arguments](#optional-arguments)
	- [Source server](#source-server)
	- [All done](#all-done)
- [Tests](#tests)

## Installation

### Target server

- Place [`rsyncd-rotation.sh`](rsyncd-rotation.sh) somewhere usable and set executable for the run-as user of _receiving_ `rsyncd` process.
- Configure target Rsync module(s) to execute `rsyncd-rotation.sh` *after* a successful run via:
	- `/etc/rsyncd.conf` if running daemon mode, or...
	- `~/rsyncd.conf` if via SSH.

An example target module config:

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

- Before validating user/module, everything logged to `/var/log/rsyncd/00default.log`.
- Increasing the level of transfer logging to include filename and bytes moved via `log format`.
- Setting `use chroot = false` (usually) required if not running `rsyncd` under root.
- Validated module logging to `/var/log/rsyncd/MODULE_NAME.log`.
- Backup location for the target defined in `path = /target/path/to/backup`.
	- Incremental backups stored at `/target/path/to/backup/001` to `/target/path/to/backup/REVISION_COUNT`.
- Finally, stanza `post-xfer exec = /path/to/rsyncd-rotation.sh` instructs `rsyncd` to execute rotation script *after* file transfer is complete.

#### Optional arguments

In addition `rsyncd-rotation.sh` accepts arguments:

- Logging of key script events to file via the `-l LOG_FILE` option, handy for debugging correct operation.
- Adjustment of backup retention count from [default](rsyncd-rotation.sh#L3) of `25` via the `-r RETENTION_COUNT` option. Given count must be `2` or greater.

Example use:

```ini
[MODULE_NAME]
log file = /var/log/rsyncd/MODULE_NAME.log
path = /target/path/to/backup
post-xfer exec = /path/to/rsyncd-rotation.sh -l /path/to/file.log -r 6
```

### Source server

To perform a backup execute `rsync` in a method like below:

```sh
# to an rsync listening daemon (unencrypted)
$ rsync \
	--archive \
	--delete \
	--link-dest "../001" \
	/backup/from/path TARGET_HOST::MODULE_NAME/000

# or over an encrypted SSH connection
$ rsync \
	--archive \
	--delete \
	--link-dest "../001" \
	--rsh "ssh -l TARGET_USER" \
	/backup/from.path TARGET_HOST::MODULE_NAME/000
```

The *critical* command line components are:

- Current backup is hard-linked against previous incremental with the `--link-dest "../001"` argument where files are identical between source and incremental.
- Backup is placed into a `/target/path/to/backup/000` directory via the `TARGET_HOST::MODULE_NAME/000` destination set.

Once Rsync completes, `rsyncd-rotation.sh` is executed to increase all incremental directories by one, dropping any that exceed set `REVISION_COUNT`.

### All done

You should now have automated, space saving and easy to manage incremental backups running under Rsync. Enjoy!

## Tests

Small test suite for `rsyncd-rotation.sh` provided by [`test/test.sh`](test/test.sh).
