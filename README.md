HOW-TO GENERATE THE APPSTREAM INFO
-----------------------------------
In order to generate appstream metainfo it's needed a working chroot environment.
The metadata_builder.sh needs some basic info to work the variables $REPO must point to the repo's path and $SUITE to the target suite (xenial, bbionic...)

The process is automated and only needs to adjust $REPO and $SUITE and a valid asgen.conf at the repo's path.

However the manual steps are:

* A valid chroot

	Chroot must have /proc, /sys...

    * ``` sudo cp /proc/mounts /path/to/the/chroot/etc/mtab ```
 
    * ``` sudo mount -t proc /proc /path/to/the/chroot/proc/ ```
 
    * ``` sudo mount -t sysfs /sys/ /path/to/the/chroot/sys/ ```
 
    * ``` sudo mount -o bind /dev/pts /path/to/the/chroot/dev/pts ```
 
    * ``` sudo mount -o bind /dev /path/to/the/chroot/dev/ ```

	Also the repo's path mounted at /srv

    * ``` sudo mount --bind /path/to/the/repo /path/to/the/chroot/srv/ ```

* Access the chroot

``` sudo chroot /path/to/the/chroot ```

* Change the working directory to the one with the asgen.conf file (inside chroot)

``` cd /srv/ 
#Optionally delete generated data (recommended)
appstream-generator cleanup 
appstream-generator remove-found xenial
appstream-generator process $suite --force #$suite must be a valid suite (bionic,xenial...)
```

* Check the process results at /path/to/the/mirror/export
The directory tree is:
    * ./data -> Valid data (dep-11 folder of the repo)
    * ./html -> Html report with hints, errors and valid data
    * ./hints -> Detected hints in json format
    * ./media -> Folder with icons and images


