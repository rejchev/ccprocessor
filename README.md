<h1 align="center">Color Chat Processor</h1>
<div align="center">

[![Build](https://github.com/rejchev/ccprocessor/actions/workflows/build.yml/badge.svg)](https://github.com/rejchev/ccprocessor/actions/workflows/build.yml)
[![Discord](https://img.shields.io/discord/1159851636156530800?logo=discord&logoColor=%23959da5&color=%235865F2)](https://discord.gg/kPtqX2NhYZ)
[![Downloads](https://img.shields.io/github/downloads/rejchev/ccprocessor/total?color=%2332c955)]()
[![LICENSE](https://img.shields.io/github/license/rejchev/ccprocessor)](LICENSE)
</div>

## About

### Description
The chat handler makes the hidden features of the standard in-game chat available.<br>
Its functionality and fixes for all known bugs make this handler the best of its kind.

### Real-Time Color Processing
RTCP is one of the features of the chat processor, which allows you to replace abbreviations with colors when sending a message

![RTCP](./.github/images/rtcp.gif)

### Flexible Localization
For a long time of development, it was decided to support flexible localization. <br>
This approach allows you to preserve the language affiliation and form a message in the language of the player's platform. <br>

<b>For example `ServerLang: "en"`

- What the RU-player sees <br>
![RU-Client](./.github/images/ru-client.png)

- What the EN-player sees at same time <br>
![EN-Client](./.github/images/en-client.png)

### Extended Radio
The handler also deals with the radio channel. <br>
You can edit already boring radio commands. <br>
![Radio](./.github/images/radio.png)

### And more other...

## Game support
---------
- [x] Counter-Strike: Global Offensive
- [x] Counter-Strike: Source (Open Beta)
- [x] Team Fortress 2
- [x] Left 4 Dead 2

## Requirements:
-------------
- Sourcemod 1.12 [ [Windows](http://sourcemod.net/latest.php?os=windows&version=1.12) | [Linux](http://sourcemod.net/latest.php?os=linux&version=1.12) ]

## Handlers
Handlers intercept and expand the engine’s message channels by virtualizing the logical channel.

| Engine channel | Package | Virtualization | Virtual Channels |
| :------------: | :-------: | :--------------: | :-------------------: |
|  `SayText2`  |  `ccp-saytext2.smx` | `Yes` |`STA` = Public chat<br>`STP` = Team chat<br>`CN` = Name Change |
|  `TextMsg`   | `ccp-textmsg.smx`  | `Yes` | `TM` = Server chat |
|  `SayText`   | `ccp-saytext.smx`  | `Yes` | `ST` = Server chat |
|  `RadioText` | `ccp-radiomsg.smx` |  `Yes` | `RT` = Radio chat  |

## License
[GNU Public License v3](https://github.com/rejchev/ccprocessor/blob/main/LICENSE)
