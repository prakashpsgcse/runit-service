# Init System 
-> first prcess in booting process [after BIOS]  
-> daemon process  
-> continues running until the system is shut down  
-> started by kernal during booting process  
-> Assigned PID 1  
-> this should start all process/service/daemons  
-> ex: boot screen , N/W process etc

### Examples 
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
## Runit Components
_**sv**_ controls and manages services monitored by runsv.  
_**runsv**_ starts and monitors a service and optionally an appendant log service.  
_**runsvdir**_ starts and monitors a collection of runsv processes.  
_**runsvchdir**_ changes the services directory of runsvdir (i.e. switches the “runlevel”).  
_**svlogd**_ is runit’s service logging daemon.  
_**chpst**_ runs a program with a changed process state (e.g. set the user id of a program, or renice a program)  
_**utmpset**_ modifies the user accounting database utmp to indicate that the user on the terminal line logged out.  

### Starting runsvdir
```shell
runsvdir -P /etc/service
```
-> to check runit is running 
```shell
ps -ef | grep runsvdir
```

#### Dir Structure
-> core dir is **/etc/sv**  
-> this contain one dir for each process and **run** script to start process
   ```shell
   /etc/sv/{service-name}
   -------------------------------
   /etc/sv/kafka
   /etc/sv/zookeeper
```
### runsvdir
-> starts runsv process for each subdir in /etc/service or link  
-> restart runsv process if it terminates  
-> every 5 sec it checks delta in dir and starts if new folder or sends TERM to runsv if folder is removed  
-> If the log argument is given to runsvdir, all output to standard error is redirected to this log  
-> -H Handle TERM the same as HUP, i.e. send a TERM signal to each runsv(8) process, then exit with 111. 
-> If runsvdir receives a TERM signal, it exits with 0 immediately, unless -H is specified in which case TERM is treated like HUP.  
-> If runsvdir receives a HUP signal, it sends a TERM signal to each runsv(8) process it is monitoring and then exits with 111.  

# First runit Service
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

### Logs
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
## Terminating runsvdir
-> When you kill runsvdir only that process is killed   
-> services will be active and running  
-> when you kill service log service associated to that is not killed  
-> to kill or send TERM signal to all runsv process send SIGHUP to runsvdir
```shell
kill -1 {runsvdir pid}
```
-> this will kill all runsv process including log service  
-> seperate svlogd for service  
-> we can directly send SIGNALS to runsv  
## Terminating service/runsv
```shell
sv {signal} {service-name}
--------------------------------------
```
# RUNIT Stages
-> runit performs the system's booting, running and shutting down in 3 stages
### Stage 1
-> this executed when sys starts
-> runs /etc/runit/1 file 
-> sys init tasks/one time tasks are done 

### Stage 2
-> starts after stage 1  
-> runs /etc/runit/2  
-> start runsvdir here  
-> this should not end before system halt  
-> automatically restarted if it crashes  
-> This keeps running (if all goes well) until system reboot or halt.  
-> TRAPS can be handled in this stage  

### Stage 3
-> executed when you kill/shutdown   
-> tasks during reboot/shutdown/halts are done  
-> runs /etc/runit/3  [only if you have stopit file and SIGCONT]  
-> if stage 2 return without any error this runs  
-> tasks to cleanly bring down the machine.  
-> Stops all runsv services etc  [we have to do]
```shell
echo 'Waiting for services to stop...'
sv -w196 force-stop /etc/service/*
sv exit /etc/service/*
```

## sample stages 
These are working examples for Debian sarge  
http://smarden.org/runit/debian/3


# RUNIT Signals
-> If runsvdir receives a TERM signal, it exits with 0 immediately.  
-> If runsvdir receives a HUP signal, it sends a TERM signal to each runsv process it is monitoring and then exits with 111  
-> When I run 
```shell
docker kill 40ed444ca8c2 --signal SIGCONT
docker kill 40ed444ca8c2 --signal SIGTERM
docker kill 40ed444ca8c2 --signal SIGKILL
```
  this will not run runlevel 3

-> we need stopit file in runit folder for executing /etc/runit/3 file  
-> only SIGCONT is executing runlevel 3 [SIGTERM/SIGHUP is not executing runlrvl 3]

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

###T RAP
-> SIGKILL & SIGSTOP cannot be TRAPPED  
-> Docker stop command will send SIGTERM  
-> Docker kill command will send SIGKILL  

## Runit gracefull shutdown
### Method 1:
1. When SIGTERM/SIGKILL/SIGHUP received from docker/kubernetes convert it to SIGHUP and send it to runsvdir  
2. Automatically When runsvdir receives a HUP signal, it sends a TERM signal to each runsv  

-> How do you make sure you will catch/trap these signals ?  
-> most of the time SIGTERM/SIGHUP is received by runit-init (process ID 1 )  

Not able to TRAP SIGTERM from docker????
### Method 2
1. In DockerFile use SIGCONT as stop signal   
2. Add /etc/runit/stop. this will execute /etc/runit/3  
3. In /etc/runit/3  file stop all services using sv stop  


## SV commands 
### up
If the service is not running, start it. If the service stops, restart it.
### down
If the service is running, send it the TERM signal, and the CONT signal.  
If ./run exits, start ./finish if it exists  
After it stops, do not restart service.  
## once
If the service is not running, start it. Do not restart it if it stop
## start
Same as up, but wait up to 7 seconds for the command to take effect.  
Then report the status or timeout.  
If the script ./check exists in the service directory, sv runs this script to check whether the service is up and available; it’s considered to be available if ./check exits with 0.  
## stop
Same as down, but wait up to 7 seconds for the service to become down.  
Then report the status or timeout.  
## force-stop
Same as down, but wait up to 7 seconds for the service to become down.  
Then report the status, and on timeout send the service the kill command.  


## Docker zombie reaping problem Issue: 
 -> When we kill or force stop service runsv process dies and actual process is not  
 -> In Init sys process without parent will be adopted by PID 1 

ex :  
 -> I killed 2 process first/second service  
 -> Only runsv process killed and script is not stopped  
 -> runit process adopted orphan process

```shell
/etc/sv/secondrunitservice # pstree
-+= 00001 root runit 
 |-+- 00015 root sh /opt/test/SecondService.sh 
 | \--- 00108 root sleep 10 
 |-+- 00014 root sh /opt/test/firstservice.sh 
 | \--- 00109 root sleep 10 
 \-+= 00009 root runsvdir /etc/service 
   |--- 00011 root runsv firstrunitservice 
   \--- 00010 root runsv secondrunitservice 
/etc/sv/secondrunitservice # sv start firstrunitservice
ok: run: firstrunitservice: (pid 118) 0s
/etc/sv/secondrunitservice # pstree
-+= 00001 root runit 
 |-+- 00015 root sh /opt/test/SecondService.sh 
 | \--- 00115 root sleep 10 
 |-+- 00014 root sh /opt/test/firstservice.sh 
 | \--- 00116 root sleep 10 
 \-+= 00009 root runsvdir /etc/service 
   |-+- 00011 root runsv firstrunitservice 
   | \-+- 00118 root /bin/sh ./run 
   |   \-+- 00119 root sh /opt/test/firstservice.sh 
   |     \--- 00120 root sleep 10 
   \--- 00010 root runsv secondrunitservice
```

# Unix Process Basics 
-> for any command Unix/Linux creates/starts process   
-> Can be foreground / Background  
-> Daemons are system-related background processes  
-> Tracked with PID [process id-5 digit]  
-> alone with PID parent PID [PPID]  also assigned from who created that  
-> a parent process can create an independently executing child process  
-> each process has parent except PID 1 or Init process .bcoz started by kernal  
-> process can wait() for child prcesss to complete  
-> The parent process may then issue a wait system call which suspends the execution of the parent process while the child executes  
-> After child terminates with exit code , parent will resume [only for wait()]  
-> when child process terminated/killed SIGCHLD sent to parent  
-> Using this parent can retrive exit status of child  
-> Parent updates process table [removed entry -> reaped]  
-> process ends via exit, all of the memory and resources associated with it are deallocated  
-> the process's entry in the process table remains .Its parent process responsibility to call wait() and get the exit code of child and remove Child entry from PTABLE  
-> ps cmd OP with Z in STAT field is zombie process  

## Zombie and Orphan Processes

### Zombie Process
-> if parent is not waiting on child [just to update status] is Zombie  Processes   
-> if a wait is not performed then the terminated child remains in a "zombie" state  
-> No one is there to remove its state from P-Table  
-> processes that stay zombies for a long time are generally an error and cause a resource leak  
-> As long as a zombie is not removed from the system via a wait, it will consume a slot in the kernel process table, and if this table fills, it will not be possible to create further processes.  
### Orphan Processes
-> parent is killed before child its called Orphan Processes  
-> This process is not dead , it will be executing  
-> Thease process will be Adapted by PID 1 (INIT PROCESS)  
-> Then INIT will wait() on this process and remove it from P-TABLE  
-> The action of calling waitpid() on a child process in order to eliminate its zombie, is called "reaping"  

## Running INIT process in docker will avoid Zombie/Orphan 
