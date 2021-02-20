#!/bin/bash


echo "Second runit service : i am registering trap "

cont_sv() {
      echo "Second runit service : I received SIGCONT"
}

term_sv() {
      echo "Second runit service : I received SIGTERM"
}

hup_sv() {
      echo "Second runit service :  I received SIGHUP"
}
#trap UserSig1 SIGUSR1
trap term_sv SIGTERM
#trap cont_sv SIGCONT
#trap cont_sv SIGHUP

while true
do
   echo 2
   sleep 10
done