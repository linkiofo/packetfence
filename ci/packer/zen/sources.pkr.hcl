# VirtualBox builds
source "virtualbox-iso" "debian-11" {
  vm_name = "${var.vm_name}"
  disk_size = "100000"
  guest_os_type = "Debian_64"
  hard_drive_interface = "scsi"
  headless = "true"

  # hardware used to **build VM**
  cpus = "2"
  memory = "2048"

  # change hardware configuration before exporting VM
  vboxmanage_post = [
    ["modifyvm", "{{.Name}}", "--cpus", "4"],
    ["modifyvm", "{{.Name}}", "--memory", "12288"],
    ["modifyvm", "{{.Name}}", "--uartmode1", "disconnected"],
    ["storagectl", "{{.Name}}", "--name", "IDE Controller", "--remove"]
  ]
  iso_url = "https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-11.0.0-amd64-netinst.iso"
  iso_checksum = "sha256:ae6d563d2444665316901fe7091059ac34b8f67ba30f9159f7cef7d2fdc5bf8a"
  boot_command = [
    "<esc><wait>",
    "install <wait>",
    "preseed/url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/preseed.cfg <wait>",
    "debian-installer=en_US.UTF-8 <wait>",
    "auto <wait>",
    "locale=en_US.UTF-8 <wait>",
    "kbd-chooser/method=us <wait>",
    "keyboard-configuration/xkb-keymap=us <wait>",
    "netcfg/get_hostname={{ .Name }} <wait>",
    "netcfg/get_domain=vagrantup.com <wait>",
    "fb=false <wait>",
    "debconf/frontend=noninteractive <wait>",
    "console-setup/ask_detect=false <wait>",
    "console-keymaps-at/keymap=us <wait>",
    "grub-installer/bootdev=/dev/sda <wait>",
    "<enter><wait>"
  ]
  boot_wait = "5s"
  http_directory = "files"
  ssh_username = "vagrant"
  ssh_password = "vagrant"
  ssh_timeout = "60m"
  shutdown_command = "sudo poweroff"
  # export
  format = "ova"
  output_directory = "${var.output_vbox_directory}"
}
