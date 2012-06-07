Broadcast extension lifecycle and packet description
====================================================
The broadcast protocol is made to share anonymous messages with all the reachable torchat
network.

This feature could be used to spam but users will always be able to disable such a feature.

Packets
-------
Following is a list and description of the packets in the broadcast extension.

### Broadcast Message

This packet is used to send a simple broadcast message, it just contains the message.

A broadcast message can contain *hashtags* which a person can follow/ignore.

When you send a broadcast *message* you send it to every logged in contact you have, on reception
of the *message* the contact will check if the same message has already been sent recently and if
not it will send the same message to every other contact in his contact list and so on.

The check for messages already broadcasted is made by hashing the message itself.

```
> broadcast_message broadcast messages in #torchat rock
```
