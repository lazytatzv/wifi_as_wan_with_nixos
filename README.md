# このrepoについて

NixOSでWifi as WANを簡単に導入するためのrepo.

Eduroam等の802.1X認証が要求される状況で、通信状況の改善を目的とする.

## Why NixOS

`configuration.nix`で殆どの設定を管理することができ、かつ環境再現性が非常に高いため.

## CAUTION

ネットワークの規約違反になる可能性があるので、利用する際はよく確認することと、自己責任でお願いします.

## Example Topology

Eduroam <--wifi--> NixOS <--Ethernet--> Router <--Wifi/Ether--> Other PCs

## Mechanism



## Usage

必要なもの

- PC(wifi&etherのNIC付き)
- LANケーブル
- ルータ(家庭用で良い)

### Introduction

1. NixOS Installation

以下のサイトを参考に、NixOSを実機にインストールする.

(NixOS Installation Guide)[https://nixos.wiki/wiki/NixOS_Installation_Guide]

2. Clone this repo

```bash
git clone https://github.com/lazytatzv/wifi_as_wan_with_nixos.git

```

3. Install

```bash
sudo chmod +x install.sh

./install.sh
```




