import mcrcd;
import std.algorithm;
import std.conv;
import std.stdio;
import std.string;

void main(string[] args)
{
	auto rcon = new MCRcon();

	string host = "localhost";
	ushort port = 25575;
	string password = "password";

	if (args.length > 1)
	{
		auto parts = args[1].findSplit(":");
		if (parts[2].length)
		{
			host = parts[0];
			try
			{
				port = parse!ushort(parts[2]);
			}
			catch (ConvException e)
			{
				stderr.writeln("Malformed Port!");
				return;
			}
		}
		else
		{
			host = parts[0];
		}

		if (args.length >= 2)
		{
			password = args[2];
		}
	}

	stderr.writefln("Attempting to connect to %s:%s...", host, port);
	try
	{
		rcon.connect(host, port);
	}
	catch (Exception e)
	{
		stderr.writeln("Couldn't connect!");
		stderr.writeln(e);
		return;
	}
	scope (exit)
		rcon.disconnect();

	stderr.writeln("Logging in...");
	rcon.login(password);

	while (true)
	{
		write("> ");
		string line = readln();
		if (!line.length)
			break;
		if (!line.chomp.length)
			continue;
		writeln("  ", (rcon.command(line.chomp())).text);
	}
}
