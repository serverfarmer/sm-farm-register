# Overview

`sm-farm-register` is a Server Farmer management extension responsible for registering new managed hosts in the farm, and generating dedicated ssh keys for them.

# Scripts

`add-managed-host.sh` - tries to connect to the added server for a few times using ssh, then creates dedicated ssh keys for `root` and `backup` users, and executes `add-backup-host.sh` script from `sm-backup-collector` extension (if installed on the same management host)

`add-dedicated-key.sh` - generates new ssh dedicated key for given user and uploads it to managed host
