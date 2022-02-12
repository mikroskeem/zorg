# Zorg

- shellcheck pass
- no docs yet (!!!), this is a collection of scripts i threw together in one weekend pretty much
    - not production quality, but runs in production on my box with syncoid
- pretty much `./backup_all.sh rpool/data/stuff`
  - `.../stuff/*` will be turned into borg repos
  - nested datasets are not supported (e.g `rpool/data/stuff/x/y`)
- generate `~/.ssh/backup_key_ed25519` (or configure `ZORG_SSH_KEY` envvar)
  - `ssh-keygen -N "" -C "" -t ed25519 -f ~/.ssh/backup_key_ed25519` there you go
- ignored.txt can do something like
  ```
  autosnap_.*
  syncoid_.*
  ```
  to skip unwanted snapshots made by various tools

GPL-3.0 also

## Trivia

- Yes, it works on macOS

## TODO

- [ ] mount credentials into ramfs to prevent risking with swapping raw credentials on disk
    - needs more fiddling with user & mount namespaces, doable
- [ ] mechanism to delete zfs snapshots after being backed up into borg repo
- [ ] restore zfs snapshots from borg repository
- [ ] support for nested datasets
- [ ] support for multiple repository & credentials directories
    - currently assumes that whole script dir is for one dataset set
- [ ] more credential management solutions
    - sops
    - vault
    - custom? (need a spec)
- [ ] support for one big monster borg repo (?)
    - \+ potentially better dedup gains?
    - \- gigantic single point of failure

