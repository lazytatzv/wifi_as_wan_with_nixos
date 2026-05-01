# WiFi as WAN with NixOS

NixOSを利用して、Wi-Fi接続（特にEduroam等の802.1X認証環境）をイーサネット経由で他のデバイスに共有するためのプロジェクトです。

通信環境が不安定な場所で、高感度なアンテナを持つPCを「中継機」として動作させ、ルーター等を通じて安定した通信環境を構築することを目的としています。

> [!CAUTION]
> 本設定は研究・実験用途を目的としています。利用するネットワークの規約（ネットワークポリシー）を遵守し、自己責任で利用してください。

## Example Topology

```text
Eduroam (802.1X) <---[Wi-Fi]---> NixOS (Gateway) <---[Ethernet]---> Router <---[Wi-Fi/Ether]---> Clients
```

## Mechanism

この設定では、NixOSをルーター（ゲートウェイ）として動作させるために以下のコンポーネントを組み合わせています。

- **iwd (iNet Wireless Daemon)**: Wi-Fi接続を管理します。802.1X認証（Eduroam等）に強く、安定した接続を提供します。
- **systemd-networkd**: ネットワークインターフェース（Wi-Fi, Ethernet）の構成を管理します。
- **IP Forwarding & NAT**: `net.ipv4.ip_forward`を有効にし、Wi-Fi側からイーサネット側へパケットを転送します。
- **dnsmasq**: イーサネット側に接続されたルーターやPCに対し、DHCP（IPアドレス割り当て）とDNSキャッシュサーバー機能を提供します。

## Prerequisites

導入前に以下の点を確認してください。

1. **ハードウェア**: Wi-Fiチップと有線LANポート（NIC）を搭載したPC。
2. **インターフェース名**: 
   - `configuration.nix` 内で `wlan0`（Wi-Fi）と `enp2s0`（有線LAN）がハードコードされています。
   - `ip link` コマンドで自身の環境のインターフェース名を確認し、必要に応じて書き換えてください。
3. **NixOS**: インストール済みの環境であること。

## Usage

### 1. リポジトリのクローン

```bash
git clone https://github.com/lazytatzv/wifi_as_wan_with_nixos.git
cd wifi_as_wan_with_nixos
```

### 2. インターフェース名の調整

`configuration.nix` を開き、以下の箇所をご自身の環境に合わせて編集してください。

- `networking.nat.externalInterface = "wlan0";`
- `networking.nat.internalInterfaces = [ "enp2s0" ];`
- 各 `systemd.network.networks` セクションの `matchConfig.Name`

### 3. 設定の適用

`install.sh` を実行して、設定ファイルを `/etc/nixos/` に配置し、システムを更新します。

```bash
chmod +x install.sh
./install.sh
sudo nixos-rebuild switch
```

### 4. Wi-Fiへの接続

`iwctl` を使用して、上流のWi-Fi（Eduroam等）に接続します。

```bash
iwctl
[iwd]# station wlan0 connect <SSID>
```

#### Eduroam (802.1X) の設定について

EduroamなどのWPA2-Enterpriseネットワークに接続する場合、`/var/lib/iwd/<SSID>.8021x`（例: `eduroam.8021x`）を作成して設定を記述します。本リポジトリに [eduroam.8021x.example](./eduroam.8021x.example) を用意しています。

**PEAP + MSCHAPV2 の場合 (一般的):**

```ini
[Security]
EAP-Method=PEAP
EAP-Identity=your_id@example.ac.jp
EAP-PEAP-Phase2-Method=MSCHAPV2
EAP-PEAP-Phase2-Identity=your_id@example.ac.jp
EAP-PEAP-Phase2-Password=your_password
# 必要に応じてCA証明書のパスを指定
# EAP-PEAP-CACert=/etc/ssl/certs/ca-certificates.crt
```

**TTLS + PAP の場合:**

```ini
[Security]
EAP-Method=TTLS
EAP-Identity=your_id@example.ac.jp
EAP-TTLS-Phase2-Method=PAP
EAP-TTLS-Phase2-Identity=your_id@example.ac.jp
EAP-TTLS-Phase2-Password=your_password
# 必要に応じてCA証明書のパスを指定
# EAP-TTLS-CACert=/etc/ssl/certs/ca-certificates.crt

[Settings]
AutoConnect=true
```

※ ファイル作成後、`sudo chmod 600 /var/lib/iwd/eduroam.8021x` で権限を適切に設定し、`sudo systemctl restart iwd` を実行して設定を読み込ませてください。

## Customization

- **IPアドレス体系**: デフォルトでは有線LAN側に `192.168.50.1/24` を割り当てています。既存のネットワークと重複する場合は変更してください。
- **DNS**: `dnsmasq` の設定で `1.1.1.1` と `8.8.8.8` を上流DNSとして指定しています。




