Groupchat extension lifecycle and packet description
====================================================
The person that starts the groupchat starts it by inviting the first person
to it, the *invite* packet has a cookie inside that will also be the id of the
groupchat throughout its lifecycle, it also contains a list of modes for the groupchat.

After the *invite* packet a *participants* packet is sent to the invited person,
this packet has inside the list of ids of the current groupchat.

After receiving the *participants* packet the invited starts connections to all the
participants and sends them a packet asking them if they're really participating
in the groupchat. The contacts that aren't in his buddy list are added as temporary
buddies. If any of the participants are in his blocked list, a *leave* packet will be
sent, refusing to join the groupchat, otherwise a a *participants* packet is sent back
with the current participants in the groupchat, on receiving that packet the invitor will
send back a *participants* packet with possible new participants, this packet sending back
and forth will end when the invitor sends an empty *participants* packet, at that point
a *join* packet will be sent.

After the *join* packet an *invited* packet will be sent to the already present participants,
in this way they'll know who invited that person and that that person is going to join the
groupchat.

The messaging in the groupchat is simply sent to every other participant from the sender
of the message.

To exit the groupchat a *leave* packet is sent to every participant present in the groupchat.

When a participant disconnects it's seen as leaving the groupchat.

When there are no more participants in a groupchat that groupchat is destroyed.

Packets
-------
Following is a list and description of the packets in the groupchat extension.

In the examples `>` refers to packet sent to the buddy, while `<` refers to packet received
from the buddy.

### Groupchat Invite

This packet is used to invite someone to a groupchat, it contains the id of the groupchat
and a list of modes.

The modes will be useful in implementing extensions to the groupchat protocol, for example in
the implementation of redundancy and permanent groupchats.

```
> groupchat_invite 6f012391-883d-4f4f-8d54-52c4227b3ac9
```

```
> groupchat_invite 6f012391-883d-4f4f-8d54-52c4227b3ac9 noredundancy
```

### Groupchat Participants

This packet is used to tell the invited person the current participants, it contains the
groupchat id and a space separated list of ids. The should not contain the id of the person
sending the packet.

```
> groupchat_participants 6f012391-883d-4f4f-8d54-52c4227b3ac9 bgboqr35plm637wp
```

### Groupchat Is Participating

This packet is sent to ask someone if he's participating in a groupchat, it contains the id of
the groupchat.

```
> groupchat_is_participating 6f012391-883d-4f4f-8d54-52c4227b3ac9
< groupchat_participating
```

### Groupchat Participating

This packet is sent as answer to the *is_participating* packet and is used to answer that we
are participating, it contains the id of the groupchat.


```
< groupchat_is_participating 6f012391-883d-4f4f-8d54-52c4227b3ac9
> groupchat_participating 6f012391-883d-4f4f-8d54-52c4227b3ac9
```

### Groupchat Not Participating

This packet is sent as answer to the *is_participating* packet and is used to answer that we
are not participating, it contains the id of the groupchat.

```
< groupchat_is_participating 6f012391-883d-4f4f-8d54-52c4227b3ac9
> groupchat_not_participating 6f012391-883d-4f4f-8d54-52c4227b3ac9
```

### Groupchat Join

This packet is sent in answer to the invitor if accepting to join the groupchat, it contains
the id of the groupchat.

```
< groupchat_invite 6f012391-883d-4f4f-8d54-52c4227b3ac9
< groupchat_participants 6f012391-883d-4f4f-8d54-52c4227b3ac9 bgboqr35plm637wp
> groupchat_join 6f012391-883d-4f4f-8d54-52c4227b3ac9
```

### Groupchat Leave

This packet is sent in answer to the invitor if refusing to join the groupchat or as packet to
tell everyone that you're leaving the groupchat, it contains the id and an optional reason for
leaving.

```
< groupchat_invite 6f012391-883d-4f4f-8d54-52c4227b3ac9
< groupchat_participants 6f012391-883d-4f4f-8d54-52c4227b3ac9 bgboqr35plm637wp
> groupchat_leave 6f012391-883d-4f4f-8d54-52c4227b3ac9
```

```
> groupchat_leave 6f012391-883d-4f4f-8d54-52c4227b3ac9 I'm a bad person, and so are you
```

### Groupchat Invited

This packet is sent by the invitor to every participant of the groupchat if the invited accepts to
join the groupchat, it contains the id of the groupchat and the id of the invited.

```
> groupchat_invited 6f012391-883d-4f4f-8d54-52c4227b3ac9 4dlrnr744xsibjcd
```

### Groupchat Message

This packet is used to send a message to the groupchat, it is sent to every participant and contains
the id of the groupchat and the message.

```
> groupchat_message 6f012391-883d-4f4f-8d54-52c4227b3ac9 Hi guise
```
