#!/usr/bin/env bash

set -e

MODULE_DEST="/etc/nixos/wifi-as-wan.nix"

echo "wifi-as-wan.nix を ${MODULE_DEST} にコピーします..."
sudo cp ./wifi-as-wan.nix "${MODULE_DEST}"

echo "--------------------------------------------------"
echo "配置が完了しました。"
echo "ご自身の /etc/nixos/configuration.nix を編集し、以下を追加してください："
echo ""
echo "  imports = [
    ./hardware-configuration.nix
    ./wifi-as-wan.nix
  ];"
echo ""
echo "  services.wifi-as-wan = {"
echo "    enable = true;"
echo "    externalInterface = \"wlan0\";  # Wi-Fi"
echo "    internalInterface = \"enp2s0\"; # 有線LAN"
echo "  };
"
echo ""
echo "その後、'sudo nixos-rebuild switch' を実行して設定を適用してください。"
echo "--------------------------------------------------"