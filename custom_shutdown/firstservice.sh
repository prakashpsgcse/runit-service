#!/bin/bash


echo "First runit service : i am registering trap "

#cont_sv() {
#      echo "First runit service : I received SIGCONT"
#}
#
term_sv() {
      echo "First runit service : I received SIGTERM"
}
#kill_sv() {
#      echo "First runit service :  I received SIGKILL"
#}
#hup_sv() {
#      echo "First runit service :  I received SIGHUP"
#}
##trap UserSig1 SIGUSR1
#trap kill_sv SIGKILL
trap term_sv SIGTERM
#trap cont_sv SIGCONT
#trap hup_sv SIGHUP

while true
do
   echo 1
   sleep 10
done