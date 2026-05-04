# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_zen;

  powerManagement.cpuFreqGovernor = "performance";

  nix.settings.auto-optimise-store = true; 

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d"; 
  };

  nix.settings.cores = 0;
  nix.settings.max-jobs = "auto";

  zramSwap.enable = true;

  # TCP BBR 輻輳制御アルゴリズム
  boot.kernelModules = [ "tcp_bbr" ];
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.core.default_qdisc" = "fq";
    "net.ipv4.tcp_congestion_control" = "bbr";
    "vm.swappiness" = 100;
    "vm.watermark_boost_factor" = 0;
    "vm.watermark_scale_factor" = 125;
    "vm.page-cluster" = 0; 
  };

  # ===== iwd =====
  networking.wireless.iwd.enable = true;
  
  networking.wireless.iwd.settings = {
    Network = {
      EnableIPv6 = true;
    };
    Settings = {
      AutoConnect = true;
    };
  };
  # ===============

  # systemd-networkd
  systemd.network.enable = true;

  services.resolved.enable = false;
  networking.resolvconf.enable = false;

  environment.etc."resolv.conf".text = ''
  nameserver 127.0.0.1
  '';

  # networkd settings
  # 上流wifi管理はnetworkdではなくiwdに任せる

  # wired config
  systemd.network.networks."10-lan" = {
    matchConfig.Name = "enp2s0";
  
    address = [ "192.168.50.1/24" ];
  
    networkConfig = {
      DHCP = "no";
      ConfigureWithoutCarrier = "yes";
    };
  };

  networking.nat = {
    enable = true;
    externalInterface = "wlan0";
    internalInterfaces = [ "enp2s0" ];
  };


  #networking.nameservers = [ "1.1.1.1" "8.8.8.8" ];

  services.dnsmasq = {
    enable = true;
  
    settings = {
      interface = "enp2s0";
      bind-interfaces = true;

      listen-address = "127.0.0.1,192.168.50.1";
  
      # IMPORTANT: avoids early boot race crashes
      dhcp-authoritative = true;
  
      dhcp-range = "192.168.50.100,192.168.50.200,255.255.255.0,12h";
  
      dhcp-option = [
        "option:router,192.168.50.1"
        "option:dns-server,192.168.50.1"
      ];
  
      # upstream DNS
      server = [
        "1.1.1.1"
        "8.8.8.8"
      ];
  
      # prevents weird resolver conflicts
      no-resolv = true;
      cache-size = 1000;
    };
  
    resolveLocalQueries = false;
  };

  # vpn
  services.tailscale = {
    enable = true;
    extraUpFlags = [ "--accept-dns=false" ];
  };

  # nas
  services.nfs.server.enable = true;

  services.nfs.server.exports = ''
    /data 192.168.50.0/24(rw,sync,no_subtree_check)
    /data 100.64.0.0/10(rw,sync,no_subtree_check)
  '';

  services.nfs.server.statdPort = 4000;
  services.nfs.server.lockdPort = 4001;
  services.nfs.server.mountdPort = 4002;


  # networking.hostName = "nixos"; # Define your hostname.

  # Configure network connections interactively with nmcli or nmtui.
  # Don't use NetworkManager!!!!!
  networking.networkmanager.enable = false;

  # Set your time zone.
  # I live in Japan
  time.timeZone = "Asia/Tokyo";


  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  # i18n.defaultLocale = "en_US.UTF-8";
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  #   useXkbConfig = true; # use xkb.options in tty.
  # };

  # Enable the X11 windowing system.
  # I only use Wayland
  services.xserver.enable = false;

  # Gnome settings
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;
  services.gnome.core-apps.enable = true;
  services.gnome.core-developer-tools.enable = false;
  services.gnome.games.enable = false;
  environment.gnome.excludePackages = with pkgs; [ gnome-tour gnome-user-docs ];

  

  # Configure keymap in X11
  services.xserver.xkb.layout = "us";
  # services.xserver.xkb.options = "eurosign:e,caps:escape";

  # Enable CUPS to print documents.
  # I won't use any printers
  services.printing.enable = false;

  # Enable sound.
  # services.pulseaudio.enable = true;
  # OR

  # I only use pipewire
  services.pipewire = {
    enable = true;
    pulse.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  services.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  # users.users.alice = {
  #   isNormalUser = true;
  #   extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
  #   packages = with pkgs; [
  #     tree
  #   ];
  # };

  # User configuration
  users.users.yano = {
    isNormalUser = true;
    description = "Yano";
    extraGroups = [ "wheel" ];
    packages = with pkgs; [
      tree
    ];
    home = "/home/yano";
    shell = pkgs.bash;
  };

  # use firefox
  programs.firefox.enable = true;

  # List packages installed in system profile.
  # You can use https://search.nixos.org/ to find more packages (and options).
  environment.systemPackages = with pkgs; [
    vim 
    wget
    fish
    nano
    neovim

    htop

    git
    usbutils
    
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # my firewall settings
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 2049 4000 4001 4002 ];
    allowedUDPPorts = [ 53 67 68 2049 4000 4001 4002 ];
    checkReversePath = false;
    allowPing = true;
  };


  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "25.11"; # Did you read the comment?

}

