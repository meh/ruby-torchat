Typing notice extension lifecycle and packet description
========================================================
This is a simple extension to support typing notice.

They're simply packets sent to the buddy you're talking to to tell them your current
typing status.

Packets
-------
Following is a list and description of the packets in the groupchat extension.

In the examples `>` refers to packet sent to the buddy, while `<` refers to packet received
from the buddy.

### Typing Start

This packet is used to tell the other end we started typing.

```
> typing_start
```

### Typing Thinking

This packet is used to tell the other end we stopped typing momentarily to think.

This packet can be not sent at all, it's just a fancy addition because BitlBee supports it.

```
> typing_thinking
```

### Typing Stop

This packet is used to tell the other end we stopped typing.

This packet can avoid being sent if the message is sent.

```
> typing_stop
```
