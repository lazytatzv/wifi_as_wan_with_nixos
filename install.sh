#!/usr/bin/env bash

set -e

CONFIG_DEST="/etc/nixos/configuration.nix"
BACKUP_DEST="/etc/nixos/configuration.nix.bak"

if [ -f "$CONFIG_DEST" ]; then
    echo "既存の configuration.nix を ${BACKUP_DEST} にバックアップします..."
    sudo cp "$CONFIG_DEST" "$BACKUP_DEST"
fi

echo "新しい configuration.nix を ${CONFIG_DEST} に配置します..."
sudo cp ./configuration.nix "$CONFIG_DEST"

echo "--------------------------------------------------"
echo "配置が完了しました。"
echo "1. configuration.nix 内のインターフェース名が正しいか確認してください。"
echo "2. 'sudo nixos-rebuild switch' を実行して設定を適用してください。"
echo "--------------------------------------------------"
