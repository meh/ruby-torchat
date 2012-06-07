Latency extension lifecycle and packet description
==================================================
The latency extension is made to check latency between you and your buddies.

Packets
-------
Following is a list and description of the packets in the broadcast extension.

### Latency Ping

This packet is used to ask for the latency between you and the other end.

It just contains an id.

```
> latency_ping 5d928e59-1ad1-4e4d-8f19-e4a885ac7c4a
< latency_pong 5d928e59-1ad1-4e4d-8f19-e4a885ac7c4a

```

### Latency Pong

This packet is used as answer for the latency check.

It just contains the ping id.

```
< latency_ping 5d928e59-1ad1-4e4d-8f19-e4a885ac7c4a 
> latency_pong 5d928e59-1ad1-4e4d-8f19-e4a885ac7c4a
```
