#!/bin/bash

set -efu -o pipefail

cd testserver

if [ ! -f server.jar ]; then
	wget https://piston-data.mojang.com/v1/objects/8dd1a28015f51b1803213892b50b7b4fc76e594d/server.jar
fi

rm -rf world versions logs libraries
java -Xmx1024M -Xms1024M -jar server.jar nogui &

sleep 20
echo "stop" | dub --root=../examples/repl -- localhost foobar123
# for some reason stopping vanilla server with rcon enabled takes AGES
sleep 120

if kill -0 $! 2>/dev/null; then
	echo "Stop command didn't stop the server!"
	kill $!
	exit 1
fi

cd ..
