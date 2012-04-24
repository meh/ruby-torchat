Groupchat Redundancy extension lifecycle and packet description
===============================================================

Groupchat Redundancy extention is there to deal with the unreliable nature of torchat direct connections.
It will be standard in jtorchat, for reliable groupchatting.

Model
----

model for groupchat redundancy:

	1. It will try direct message sending for everyone in the group
  	#daux (Direct): normal msg from me
	2. If one member is partially disconnected from others, everyone that is still connected to that user will tell other unconnected users that they got it from that user.
	The message will display number of users that claims to have received that message out of the total list.
	#daux (8 of 10): I'm partially disconnected from 2 users

To implement this, three simple rules is needed:

	1. Everyone needs the same grouplist/memberlist
	2. On direct reception of message from the original speaker, first display message in groupchat with "(Direct)" tag, and then relay on the message for the benefit of any disconnected users.
	3. If received 'relayed' message, wait for any other copy of the message to arrive from other members, then depending of users you received a copy of. Display a 'trust' ratio. e.g. "(8 of 10)", which means, 8 members out of 10 members said they received that particular message from that speaker.

Why this approach, why not symmetric encryption, or asymmetric encryption:

	1. symmetric encryption will not prevent spoofing as everyone has the same key. As for snoopers outside the group, just make sure everyone has the same memberlist. 
	2. asymmetric encryption is harder to implement and requires more CPU cycles. However we will implement this eventually as an optional addon for those that requires it. KISS applies here, we want to keep it simple, and bugfree.


Packets
----

### Groupchat Echo Message

This packet is used to implement redundancy (requires autodrop_user to be disabled, and a 'redundacy extention' to be implemented), it is sent to every participant and contains the id of the groupchat, and the message. It also has the 'claimed' address of the sender.

```
> groupchat_echoed_message 6f012391-883d-4f4f-8d54-52c4227b3ac9 jdurifleoskgiege Hi guise
```