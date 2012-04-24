Groupchat Redundancy extension lifecycle and packet description
===============================================================

### Groupchat Echo Message

This packet is used to implement redundancy (requires autodrop_user to be disabled, and a 'redundacy extention' to be implemented), it is sent to every participant and contains the id of the groupchat, and the message. It also has the 'claimed' address of the sender.

```
> groupchat_echoed_message 6f012391-883d-4f4f-8d54-52c4227b3ac9 jdurifleoskgiege Hi guise
```