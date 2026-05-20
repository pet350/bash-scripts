#! /bin/bash
## Simple script to reclaim RAM being used for Buffers and Cache 

# To free pagecache:
         echo 1 > /proc/sys/vm/drop_caches
# To free dentries and inodes:
         echo 2 > /proc/sys/vm/drop_caches
# To free pagecache, dentries and inodes:
         echo 3 > /proc/sys/vm/drop_caches
sync && sysctl -w vm.drop_caches=3
