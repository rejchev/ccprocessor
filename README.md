<h1 align="center">Color Chat Processor</h1>
<p align="center">
    <a href="#license"><img src="https://img.shields.io/github/license/rejchev/ccprocessor" /></a>
    <a href="#requirements"><img src="https://img.shields.io/badge/sourcemod-v.1.11-blue" /></a>
    <a href="https://discord.gg/cFZ97Mzrjy" target="_blank"><img src="https://img.shields.io/discord/494942123548868609" /></a>
</p>

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
- Sourcemod 1.11 
    - [Windows](http://sourcemod.net/latest.php?os=windows&version=1.11)
    - [Linux](http://sourcemod.net/latest.php?os=linux&version=1.11)

## Handlers
Handler Name | Message identifier | Package | Virtualization |
:------------: | :------------------: | :-------: | :--------------: |
|  `SayText2`  | `STA` = Public chat <br> `STP` = Team chat <br> `CN` = Name Change  | `ccp-saytext2.smx` | `Yes` |
|  `TextMsg`   | `TM` = Server chat | `ccp-textmsg.smx`  | `Yes` |
|  `SayText`   | `ST` = Server chat | `ccp-saytext.smx`  | `Yes` |
|  `RadioText` | `RT` = Radio chat  | `ccp-radiomsg.smx` |  `Yes` |
    
## [Supported Modules](https://github.com/rejchev/ccp-modules)

## License
[GNU Public License v3](https://github.com/rejchev/ccprocessor/blob/main/LICENSE)
