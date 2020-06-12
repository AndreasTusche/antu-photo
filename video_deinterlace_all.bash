#!/bin/bash

myid=$( date +%Y%m%d%H%M%S )
workorder=$( mktemp ./workorder_${myid}_XXX.bash )

echo "#!/bin/bash" >$workorder
echo "n=\$1" >> $workorder

for file in "/Users/andreas/Movies/iMovie-Mediathek.imovielibrary/"*"/Original Media/"[12][09]*".mov"; do
	echo -n "echo -n \"[ \$(( ++i )) / \$n ] \"; " >> $workorder
	echo "./video_deinterlace.bash \"$file\"" >> $workorder
done

n=$( wc -l $workorder )
chmod u+x $workorder
echo "Starting $workorder to convert $n videos."
t0=$(date +%s%N)

$workorder $n

t1=$(date +%s%N)
dt=$( bc -l <<< "scale=3;($t1 - $t0) / 1000000000" )
echo "Finished $workorder to convert $n videos in $dt seconds."
rm $workorder
