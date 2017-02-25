| Towers of Hanoi, adapted from: http://strobotics.com/hanoi.htm

5 value disks
variable sa
variable sb
variable sc

: save sc ! sb ! sa ! to disks ;
: get sa @ sb @ sc @ ;
: get2 get swap ;
: hanoi
	save disks 0;drop
	disks get
	disks 1- get2 hanoi save
	cr ." move a ring from " sa ? ." to " sb ?
	disks 1- get2 rot hanoi
;

." Tower of Hanoi, with " disks . ." rings: " 
disks 1 2 3 hanoi cr bye
