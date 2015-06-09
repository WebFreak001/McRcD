import mcrcd;
import std.stdio;
import std.string;
import std.conv;

void main(string[] args)
{
	auto rcon = new MCRcon();

	string host = "localhost";
	ushort port = 25575;
	string password = "password";

	if(args.length > 1)
	{
		if(args[1].indexOf(':') != -1)
		{
			string[] parts = args[1].split(':');
			if(parts.length > 2)
			{
				writeln("Malformed IP!");
				return;
			}
			else
			{
				host = parts[0];
				try
				{
					port = parse!ushort(parts[1]);
				}
				catch(Exception e)
				{
					writeln("Malformed Port!");
					return;
				}
			}
		}
		else
		{
			host = args[1];
		}
		if(args.length >= 2)
		{
			password = args[2];
		}
	}

	writefln("Attempting to connect to %s:%s...", host, port);
	try
	{
		rcon.connect(host, port);
	}
	catch(Exception e)
	{
		writeln("Couldn't connect!");
		writeln(e);
		return;
	}
	scope(exit) rcon.disconnect();

	writeln("Logging in...");
	rcon.login(password);

	while(true)
	{
		write("> ");
		writeln("  ", (rcon.command(readln().strip())).unformatted);
	}
}
