# WiFi as WAN with NixOS

NixOSを利用して、Wi-Fi接続（特にEduroam等の802.1X認証環境）をイーサネット経由で他のデバイスに共有するためのNixOSモジュールです。

通信環境が不安定な場所で、高感度なアンテナを持つPCを「中継機」として動作させ、ルーター等を通じて安定した通信環境を構築することを目的としています。

> [!CAUTION]
> 本設定は研究・実験用途を目的としています。利用するネットワークの規約（ネットワークポリシー）を遵守し、自己責任で利用してください。

## Example Topology

```text
Eduroam (802.1X) <---[Wi-Fi]---> NixOS (Gateway) <---[Ethernet]---> Router <---[Wi-Fi/Ether]---> Clients
```

## Mechanism

このモジュールでは、NixOSをルーター（ゲートウェイ）として動作させるために以下のコンポーネントを組み合わせています。

- **iwd (iNet Wireless Daemon)**: Wi-Fi接続を管理します。802.1X認証（Eduroam等）に強く、安定した接続を提供します。
- **systemd-networkd**: ネットワークインターフェース（Wi-Fi, Ethernet）の構成を管理します。
- **IP Forwarding & NAT**: `net.ipv4.ip_forward`を有効にし、Wi-Fi側からイーサネット側へパケットを転送します。
- **dnsmasq**: イーサネット側に接続されたルーターやPCに対し、DHCP（IPアドレス割り当て）とDNSキャッシュサーバー機能を提供します。

## Prerequisites

導入前に以下の点を確認してください。

1. **ハードウェア**: Wi-Fiチップと有線LANポート（NIC）を搭載したPC。
2. **インターフェース名**: `ip link` コマンドで自身の環境のインターフェース名（`wlan0` 等のWi-Fiと、`enp2s0` 等の有線LAN）を確認してください。
3. **NixOS**: インストール済みの環境であること。

## ⚠️ Important Notes & Limitations (重要なお知らせ)

このモジュールはルーターとしてのパフォーマンスと安定性を最優先するため、以下の点に注意してください。

1. **NetworkManager 等との競合について:**
   本モジュールは `systemd-networkd` と `iwd` を直接使用してルーティングを管理するため、**NetworkManagerやsystemd-resolvedとの共存はできません**。
   これらがユーザー設定で有効になっている場合、システム破壊を防ぐためにビルド時にエラー（Assertion Failed）を出して停止します。

   **解決策は2つあります:**
   - **手動で無効化する (推奨・安全):** ご自身の `configuration.nix` で `networking.networkmanager.enable = false;` 等を追記してください。
   - **自動で強制無効化する (簡単):** このモジュールのオプション `services.wifi-as-wan.autoDisableConflicts = true;` を設定すると、競合するサービスを `mkForce` を用いて自動で強制無効化します。

2. **nftables の有効化:**
   パフォーマンス向上のため、デフォルトのファイアウォールバックエンドとして `nftables` を使用します。
3. **カーネルパラメータの変更:**
   BBR、CAKE（キューイング）、IPスプーフィング対策など、ルーター向けの強力な `sysctl` チューニングが適用されます。

## Usage

### 1. リポジトリの取得とモジュールの配置

```bash
git clone https://github.com/lazytatzv/wifi_as_wan_with_nixos.git
cd wifi_as_wan_with_nixos

# モジュールファイルを /etc/nixos に配置
chmod +x install.sh
./install.sh
```

### 2. configuration.nix の編集

ご自身の `/etc/nixos/configuration.nix` を開き、以下の設定を追加してください。

```nix
  imports = [
    ./hardware-configuration.nix
    ./wifi-as-wan.nix # モジュールをインポート
  ];

  services.wifi-as-wan = {
    enable = true;
    externalInterface = "wlan0";  # 確認したWi-Fiインターフェース名に変更
    internalInterface = "enp2s0"; # 確認した有線LANインターフェース名に変更
  };
```

### 3. 設定の適用

```bash
sudo nixos-rebuild switch
```

### 4. Wi-Fiへの接続

`iwctl` を使用して、上流のWi-Fi（Eduroam等）に接続します。

```bash
iwctl
[iwd]# station wlan0 connect <SSID>
```

#### Eduroam (802.1X) の設定について

EduroamなどのWPA2-Enterpriseネットワークに接続する場合、`/var/lib/iwd/<SSID>.8021x`（例: `eduroam.8021x`）を作成して設定を記述します。本リポジトリに [`eduroam.8021x.example`](https://github.com/lazytatzv/wifi_as_wan_with_nixos/blob/main/eduroam.8021x.example) を用意しています。

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

## Customization Options

`services.wifi-as-wan` で利用可能なオプションは以下の通りです。

- `enable` (bool): モジュールを有効化するかどうか。
- `externalInterface` (string): インターネット側（上流）のWi-Fiインターフェース名。デフォルト `"wlan0"`。
- `internalInterface` (string): LAN側（下流）の有線インターフェース名。デフォルト `"enp2s0"`。
- `internalIp` (string): LAN側インターフェースのIPアドレス。デフォルト `"192.168.50.1"`。
- `internalPrefixLength` (int): LAN側のサブネットマスク長。デフォルト `24`。
- `dhcpRange` (string): クライアントへ割り当てるIPの範囲。デフォルト `"192.168.50.100,192.168.50.200,255.255.255.0,12h"`。
- `upstreamDns` (list of string): dnsmasqが使用する上流DNS。デフォルト `["1.1.1.1" "8.8.8.8"]`。