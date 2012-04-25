Standard protocol lifecycle and packet description
==================================================
The connection to a buddy can be initiated from the buddy or from yourself,
to establish a connection succesfully both ends must be connected to eachother
with two different sockets. This is needed to ensure that we're talking with
the real owner of the id. The id is nothing more than an onion id for a Tor hidden service.
The protocol requires in fact that a Tor session is running with a hidden service
configured to receive connections on the 11109 port.

When we receive an incoming connection from a buddy he has to send a *ping* packet,
this packet contains the address of the presumed connected buddy and a cookie.

Once we receive this ping packet we try connecting on the address contained in the ping.
Once the connection is successful we send a ping packet with our address and a new cookie,
and a pong packet with the received cookie. After this the other end is supposed to send
us a pong packet with our cookie. If everything went right and all cookies were right
the connection has been verified correctly. It obviously can go the other way around.

Once the connection has been verified, both ends send a certain number of packets.

- the *client* packet, that tells what client we are using
- the *version* packet, that tells the version of the client
- the *supports* packet with the supported extensions (this is an extension itself)
- the *profile name* packet, that tells our name (optional)
- the *profile text*, that tells our description (optional)
- if this is a permanent buddy, an *add me* packet
- a *status* packet telling what's our status

After this, the *status* packet is used as a keep alive and must be sent every 120 seconds.

A *remove me* packet can be sent to make the other end remove us from their contact list.

Messages are simply sent to the buddy with a *message* packet.

Packet encoding/decoding
------------------------
The protocol is line based with data torchat-encoded to avoid the presence of line breaks, the
packet **must** end with a `\n`.

Every packet starts with the name of the packet in `this_style`, and if the packet has data
the name is followed by a space and the torchat-encoded string. The packet name can only contain
`[a-z_]`.

The torchat encoding is a simple find and replace of every `\\` into `\\/` and `\n` into `\\n`.

To decode it just replace every `\\n` with `\n` and every `\/` into `\\`.

Usually the packet data is a list of strings separated by spaces unless the item can contain
spaces itself, in that case it's put at the end of the list.

Base packets
------------
In the examples `>` refers to packet sent to the buddy, while `<` refers to packet received
from the buddy.

### Not Implemented

This packet is sent when we receive a packet we don't know about, its only parameter is
the name of the command that we received and is also optional.

```
> supports groupchat
< not_implemented supports
```

### Ping

This packet is used as entry point for the authentication, it contains the address of the sender
and a cookie, which is then used by the other end to pong.

Keep in mind that the ping packet is answerable only when both connections are established, and once
verified it shouldn't be sent anymore and will be ignored.

Despite the name this packet is not used as keepalive.

```
> ping 7acbk6jpofsanyfp 777bc33f-ab25-4f96-baad-135ca2048c3a
< pong 777bc33f-ab25-4f96-baad-135ca2048c3a
```

### Pong

This packet is used as endpoint for the authentication, it contains the cookie that has been
received in the *ping* packet.

Despite the name this packet is not used as keepalive.

```
< ping 7acbk6jpofsanyfp 777bc33f-ab25-4f96-baad-135ca2048c3a
> pong 777bc33f-ab25-4f96-baad-135ca2048c3a
```

### Client

This packet is used to tell the other end what is the name of the client we're using.

The only value of this packet is the client name.

```
> client ruby-torchat
```

### Version

This packet is used to tell the other end what is the version of the client we're using.

The only value of this packet is the version code.

```
> version 0.0.1
```

### Supports

This packet is an extension that has to be included in the standard protocol, it tells the other end
what extensions our client supports.

It's a space separated list of extension names.

```
> supports groupchat broadcast
```

### Status

This packet is used to tell the other end our current status.

The only value of this packet is the status name; currently supported statuses are: available, away, xa.

This packet is also used as keepalive and must be sent at least every 120 seconds, otherwise the
connection will be marked as timed out and the buddy will be disconnected.

```
> status available
```

```
> status away
```

```
> status xa
```

### Add Me

This packet is sent to tell the other end to add us to their buddy list, if the buddy is temporary
this packet **must not** be sent.

```
> add_me
```

### Remove Me

This packet is sent to tell the other end to remove us from their buddy list.

The other end will disconnect us when they received the *remove me* packet.

```
> remove_me
```

### Message

This packet is sent to give the other end a message.

The message must be UTF-8 encoded.

```
> message yo, we are legiun XDXDXD
```

Profile packets
---------------
### Profile Name

This packet tells the other end our name.

It can have no value or our name UTF-8 encoded.

```
> profile_name Anonymous
```

### Profile Text

This packet tells the other end our description, or status message, take it as you wish.

It can have no value or our description UTF-8 encoded.

```
> profile_text Never forgive. Never forget.
```

### Profile Avatar Alpha

This packet contains the alpha channel of the avatar.

This packet **must** be sent even if the avatar has no alpha channel, and the content will
be empty.

Keep in mind that the avatar has to be 64x64.

```
> profile_avatar_alpha
```

### Profile Avatar

This packet contains the rgb channels of the avatar.

Keep in mind that the avatar has to be 64x64.


File transfer packets
---------------------

### Filename

This packet is the entry point of any file transfer, it contains the id of the file transfer,
the size of the file, the size of the blocks and the name of the file that is going to be
transferred.

This packet has to be sent as first to start a file transfer.

```
> filename 92be7d8b-6f10-405b-bde2-a77e71c06afd 4096 10 lol.txt
```

### Filedata

This packet contains a block of data for a given file transfer, it contains the id of the transfer,
the offset of the transfer, an useless md5 of the data and the data.

```
> filedata 92be7d8b-6f10-405b-bde2-a77e71c06afd 0 e09c80c42fda55f9d992e59ca6b3307d aaaaaaaaaa
< filedata_ok 92be7d8b-6f10-405b-bde2-a77e71c06afd 0
```

### Filedata Ok

This packet is sent after every *filedata* packet to tell the other end we received a block,
it contains the id of the file transfer and the offset of the block.

```
< filedata 92be7d8b-6f10-405b-bde2-a77e71c06afd 0 e09c80c42fda55f9d992e59ca6b3307d aaaaaaaaaa
> filedata_ok 92be7d8b-6f10-405b-bde2-a77e71c06afd 0
```

### Filedata Error

This packet is sent after every failing *filedata* packet to tell the other end an error happend
with the transfer of a block, it should be practically impossible but ok.

```
< filedata 92be7d8b-6f10-405b-bde2-a77e71c06afd 0 e29c80c42fda55f9d992e59ca6b3307d aaaaaaaaaa
> filedata_error 92be7d8b-6f10-405b-bde2-a77e71c06afd 0
```

### File Stop Sending

This packet is used to tell the other end we have stopped an inbound file transfer, it contains
the id of the file transfer.

```
> file_stop_sending 92be7d8b-6f10-405b-bde2-a77e71c06afd
```

### File Stop Receiving

This packet is used to tell the other end we have interrupted an outbound file transfer, it contains
the id of the file transfer.

```
> file_stop_receiving 92be7d8b-6f10-405b-bde2-a77e71c06afd
```
