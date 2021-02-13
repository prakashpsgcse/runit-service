#Init System 
-> first prcess in booting process [after BIOS]

-> daemon process

-> continues running until the system is shut down

-> started by kernal during booting process

-> Assigned PID 1 

-> this should start all process/service/daemons 

-> ex: boot screen , N/W process etc

###Examples 
-> systemd

-> launchd

-> runit 
# runit-service
-> cross platform Unix init system [service supervision]
-> service supervision --managing services/logging
-> runsv command, which manages each process
-> runs on GNU/Linux, *BSD, MacOSX, Solaris
-> Automatic starting of services when the system starts
-> Automatic monitoring and restarting of services if they terminate
-> runit componets are brokern into small units 
-> runsvdir, runsv, chpst, svlogd, and sv
-> To start runit manually 

**sv** controls and manages services monitored by runsv.
**runsv** starts and monitors a service and optionally an appendant log service.
**runsvdir** starts and monitors a collection of runsv processes.
**runsvchdir** changes the services directory of runsvdir (i.e. switches the “runlevel”).
**svlogd** is runit’s service logging daemon.
**chpst** runs a program with a changed process state (e.g. set the user id of a program, or renice a program)
**utmpset** modifies the user accounting database utmp to indicate that the user on the terminal line logged out.
```shell
runsvdir -P /etc/service
```
-> to check runit is running 
```shell
ps -ef | grep runsvdir
```

####Dir Structure
-> core dir is **/etc/sv** 
-> this contain one dir for each process and **run** script to start process
   ```shell
   /etc/sv/{service-name}
   -------------------------------
   /etc/sv/kafka
   /etc/sv/zookeeper
```
###runsvdir
-> starts runsv process for each subdir in /etc/service or link
-> restart runsv process if it terminates 
-> every 5 sec it checks delta in dir and starts if new folder or sends TERM to runsv if folder is removed
-> If the log argument is given to runsvdir, all output to standard error is redirected to this log
-> -H Handle TERM the same as HUP, i.e. send a TERM signal to each runsv(8) process, then exit with 111.
-> If runsvdir receives a TERM signal, it exits with 0 immediately, unless -H is specified in which case TERM is treated like HUP. 
-> If runsvdir receives a HUP signal, it sends a TERM signal to each runsv(8) process it is monitoring and then exits with 111.

#First runit Service
-> create folder and run file 
```shell
#!/bin/sh
echo "i am first runit sample service"
echo date 
df -h
----------------
chmod +x run
```

-> link dir to runsvdir 
```shell
ln -s /etc/sv/firstrunitservice /etc/service/firstrunitservice
```

-> check status 
```shell
sv status firstrunitservice
```
-> in dir ther is folder cretaed "supervise"
```shell
[root@localhost firstrunitservice]# ls
run  supervise
[root@localhost firstrunitservice]# ls supervise/
control  lock  ok  pid  stat  status
[root@localhost firstrunitservice]# ls -l supervise/
total 8
prw-------. 1 root root  0 Jan 10 14:32 control
-rw-------. 1 root root  0 Jan 10 14:32 lock
prw-------. 1 root root  0 Jan 10 14:32 ok
-rw-r--r--. 1 root root  0 Jan 10 14:49 pid
-rw-r--r--. 1 root root  5 Jan 10 14:49 stat
-rw-r--r--. 1 root root 20 Jan 10 14:49 status

```

###Logs
-> to check logs of each services/process
-> run log service inside each service/process
-> log file name  will be **current** 
```shell
 /etc/sv/{service-name}/log
 ----------------------------
 /etc/sv/kafka/log
 [root@localhost firstrunitservice]# cat log/run 
#!/bin/sh
exec svlogd -t /var/log/firstrunit
OR
exec svlogd -t .
--------------------------------------
[root@localhost firstrunitservice]# tail -10 log/current 
2021-01-10_11:24:30.45830 Filesystem               Size  Used Avail Use% Mounted on
2021-01-10_11:24:30.45834 devtmpfs                 3.9G     0  3.9G   0% /dev
2021-01-10_11:24:30.45836 tmpfs                    3.9G  197M  3.7G   5% /dev/shm
2021-01-10_11:24:30.45836 tmpfs                    3.9G  9.8M  3.9G   1% /run
2021-01-10_11:24:30.45837 tmpfs                    3.9G     0  3.9G   0% /sys/fs/cgroup
2021-01-10_11:24:30.45837 /dev/mapper/centos-root   50G  5.7G   45G  12% /
2021-01-10_11:24:30.45838 /dev/sda1               1014M  155M  860M  16% /boot
2021-01-10_11:24:30.45839 /dev/mapper/centos-home  174G  4.7G  170G   3% /home
2021-01-10_11:24:30.45839 tmpfs                    797M   40K  797M   1% /run/user/1000
2021-01-10_11:24:30.45863 i am done..................................................

```
-> **-t** timestamp [man svlogd]

-> When you kill runsvdir only that process is killed 
-> services will be active and running 
-> when you kill service log service associated to that is not killed
-> to kill or send TERM signal to all runsv process send SIGHUP
HUP (Hang up)
```shell
kill -1 {runsvdir pid}
```
-> this will kill all runsv process including log service
-> seperate svlogd for service
-> we can directly send SIGNALS to runsv 
```shell
sv {signal} {service-name}
--------------------------------------

```
#RUNIT Stages
-> runit performs the system's booting, running and shutting down in three stages
####Stage 1
-> runs /etc/runit/1 file 
-> sys init tasks/one time tasks are done 
-> 
####Stage 2
-> starts after stage 1
-> runs /etc/runit/2
-> start runsvdir here 
-> this should not end before system halt 
-> automatically restarted if it crashes 
-> This keeps running (if all goes well) until system reboot or halt.
-> 
#### Stage 3
-> tasks during reboot/shutdown/halts are done 
-> runs /etc/runit/3
-> if stage 2 return without any error this runs 
-> tasks to cleanly bring down the machine.
-> Stops all runsv services etc 
```shell
echo 'Waiting for services to stop...'
sv -w196 force-stop /etc/service/*
sv exit /etc/service/*
```

##sample stages 
These are working examples for Debian sarge
http://smarden.org/runit/debian/3

https://paulgorman.org/technical/runit.txt.html


#RUNIT Signals
-> If runsvdir receives a TERM signal, it exits with 0 immediately.
-> If runsvdir receives a HUP signal, it sends a TERM signal to each runsv(8) process it is monitoring and then exits with 111
-> When I run 
```shell
docker kill 40ed444ca8c2 --signal SIGCONT
docker kill 40ed444ca8c2 --signal SIGTERM
docker kill 40ed444ca8c2 --signal SIGKILL
```
  this will not run runlevel3

-> we need stopit file in runit folder for executing /etc/runit/3 file 
-> only SIGCONT is executing runlevel 3 [SIGKILL/SIGTERM/SIGHUP is not executing runlrvl 3]

```shell
[root@localhost runit-service]# docker logs -f 40ed444ca8c2
- runit: $Id: 25da3b86f7bed4038b8a039d2f8e8c9bbcf0822b $: booting.
- runit: enter stage: /etc/runit/1
i am /etc/runit/1 file 
date
1:i amg oing to stop  
- runit: leave stage: /etc/runit/1
- runit: enter stage: /etc/runit/2
i am /etc/runit/2 file 
- runit: leave stage: /etc/runit/2
- runit: enter stage: /etc/runit/3
i am /etc/runit/3 file 
date
1:i amg going to stop: shutdown completed   
- runit: leave stage: /etc/runit/3
- runit: sending KILL signal to all processes...
- runit: power off...
- runit: system halt.
```

###TRAP with runit 

