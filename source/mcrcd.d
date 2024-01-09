module mcrcd;

import core.time;
import std.algorithm;
import std.bitmanip;
import std.exception : enforce;
import std.socket;
import std.string;

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
		ptrdiff_t index = raw.length;
		while ((index = raw.lastIndexOf('§', index)) != -1)
			raw = raw[0 .. index] ~ raw[min($, index + 3) .. $];
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
	res.text = "§ffoo".dup;
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
	void connect(scope const(char)[] host, short port)
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
	MCRconResponse send(MCRconPacket packetID, scope const(char)[] data, int maxResponseSize = 64 * 1024)
	{
		enforce(isConnected, "Cannot send data without being connected");
		ubyte[] payload = new ubyte[14 + data.length];
		payload[0 .. 4] = nativeToLittleEndian(cast(uint) payload.length - 4);
		// 4..8 is requestID, which is 0 for all our requests
		payload[8 .. 12] = nativeToLittleEndian(cast(int) packetID);
		payload[12 .. $ - 2] = cast(const(ubyte)[]) data;
		enforce(_socket.send(payload[]) != Socket.ERROR, "Couldn't send payload! "
				~ _socket.getErrorText());

		MCRconResponse response;

		ubyte[4] recv;
		enforce(_socket.receive(recv[]) == 4, "Couldn't receive packet! "
				~ _socket.getErrorText());
		uint packLength = littleEndianToNative!uint(recv);

		enforce(packLength <= maxResponseSize, "Response larger than maximum response size");

		ubyte[] packet = new ubyte[packLength];
		size_t filled;
		while (filled < packet.length)
		{
			auto len = _socket.receive(packet[filled .. $]);
			if (len == 0)
				throw new Exception("remote side has closed the connection");
			else if (len == -1)
				throw new Exception(
					"Socket error trying to receive response: "
						~ _socket.getErrorText());
			else
				filled += len;
		}

		response.responseID = littleEndianToNative!int(packet[0 .. 4]);
		int packetType = littleEndianToNative!int(packet[4 .. 8]);
		response.data ~= packet[8 .. $ - 2];
		enforce(packet[$ - 2 .. $] == cast(ubyte[])[0, 0], "Invalid padding");
		enforce(response.responseID != -1, "Login failed");

		return response;
	}

	/// Shorthand for `send(MCRconPacket.Command, command)`
	auto command(scope const(char)[] command)
	{
		return send(MCRconPacket.Command, command);
	}

	/// Shorthand for `send(MCRconPacket.Login, password)`
	auto login(scope const(char)[] password)
	{
		return send(MCRconPacket.Login, password);
	}
}
