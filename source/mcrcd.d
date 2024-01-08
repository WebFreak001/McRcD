module mcrcd;

import std.string;
import std.socket;
import std.bitmanip;
import core.time;

/// Response for Rcon packets.
struct MCRconResponse
{
	///
	this(ubyte[] _data, int _responseID = -1)
	{
		data = _data;
		responseID = _responseID;
	}

	/// Response ID for packets. `-1` on login error.
	int responseID;

	/// Automatically removes all § codes from text.
	@property string unformatted() const
	{
		string raw = text.idup;
		size_t index;
		while((index = raw.indexOf('§')) != -1)
		{
			if(index < raw.length - 2)
				raw = raw[0 .. index] ~ raw[index + 3 .. $];
			else if(index < raw.length - 1)
				raw = raw[0 .. index] ~ raw[index + 2 .. $];
			else
				break;
		}
		return raw;
	}

	union
	{
		ubyte[] data; /// Raw data containing response.
		char[] text; /// ditto
	}
}

unittest
{
	MCRconResponse res;
	res.text = "foo§".dup;
	assert(res.unformatted == "foo");
	res.text = "foo§f".dup;
	assert(res.unformatted == "foo");
}

///
enum MCRconPacket : int
{
	Command = 2, ///
	Login = 3 ///
}

/// Rcon class for connections.
class MCRcon
{
private:
	Socket _socket;
public:
	/// Connects to `host:port` and creates a new socket.
	void connect(string host, short port)
	{
		assert(!isConnected, "Still connected!");
		_socket = new TcpSocket();
		_socket.connect(new InternetAddress(host, port));
	}

	/// Disconnects from the server.
	void disconnect()
	{
		_socket.close();
		_socket = null;
	}

	/// Returns if still connected to the server.
	@property bool isConnected()
	{
		return _socket !is null && _socket.isAlive();
	}

	/// Sends a packet containing `data` with `packetID` as ID and returns the data synchronously.
	MCRconResponse send(MCRconPacket packetID, string data)
	{
		enforce(isConnected, "Cannot send data without being connected");
		ubyte[] payload = cast(ubyte[])[0, 0, 0, 0] ~ cast(ubyte[])nativeToLittleEndian(cast(int)packetID) ~ cast(ubyte[])data ~ cast(ubyte[])[0, 0];
		enforce(_socket.send(cast(ubyte[])nativeToLittleEndian(cast(int)payload.length) ~ payload) != Socket.ERROR, "Couldn't send packet! " ~ _socket.getErrorText());

		MCRconResponse response;

		while(true)
		{
			ubyte[4] recv = new ubyte[4];
			enforce(_socket.receive(recv) > 0, "Couldn't receive packet! " ~ _socket.getErrorText());
			int packLength = littleEndianToNative!int(recv);

			ubyte[] packet = new ubyte[packLength];
			enforce(_socket.receive(packet) > 0, "Couldn't receive packet! " ~ _socket.getErrorText());

			response.responseID = littleEndianToNative!int(packet[0 .. 4]);
			int packetType = littleEndianToNative!int(packet[4 .. 8]);
			response.data ~= packet[8 .. $ - 2];
			enforce(packet[$ - 2 .. $] == cast(ubyte[])[0, 0], "Invalid padding");
			enforce(response.responseID != -1, "Login failed");

			auto sockIn = new SocketSet(1);
			sockIn.add(_socket);

			if(Socket.select(sockIn, new SocketSet(0), new SocketSet(0), 0.msecs) == 0)
				return response;
		}
	}

	/// Shorthand for `send(MCRconPacket.Command, command)`
	auto command(string command)
	{
		return send(MCRconPacket.Command, command);
	}

	/// Shorthand for `send(MCRconPacket.Login, password)`
	auto login(string password)
	{
		return send(MCRconPacket.Login, password);
	}
}
