# McRcD
A tiny Minecraft Rcon library for D.

## Usage

```D

import mcrcd;
import std.stdio;

// Interactive Rcon console
void main(string[] args)
{
	auto rcon = new MCRcon();

	try
	{
		// Will connect to localhost:25575 or throw an exception if an error occurs
		rcon.connect("localhost", 25575);
	}
	catch(Exception e)
	{
		writeln("Couldn't connect!");
		writeln(e);
		return;
	}
	scope(exit) rcon.disconnect();

	// Login to Rcon
	rcon.login("password");

	while(true)
	{
		write("> ");
		MCRconResponse response = rcon.command(readln().strip());
		// MCRconResponse.unformatted automatically removes all text formatting/color codes (§code)
		writeln("  ", response.unformatted);
	}
}

```

## [Documentation](http://mcrcd.webfreak.org/)
generated using [MaterialDoc](https://github.com/WebFreak001/MaterialDoc)
