set pagination off
set confirm off
target extended-remote localhost:3333
monitor halt
load
monitor resume 0x00001000
detach
quit
