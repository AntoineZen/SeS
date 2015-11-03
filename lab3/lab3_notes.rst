
LAB3: Kernel configuration
==========================

Question 1
----------

The goal here is to have a running Linux kernel with the following options:
 
 - Enabled randmom generator
 - Enabled TCP Syn Cookie protection
 - Randomize_va-Space option
 - Write protected kernel text sections
 - Filtered access to /dev/mem
 - Strip assembler-generated symbols
 - Enable --fstack-protector option
 - Restrict unprivileged access to kernel (dmesg)
 - Enable SELinux
 - Disable IPv6

To obtain the menu to confiure the kernel, first naviagte to the buildroot root, then run the command from the Makefile::

    cd ~/workspace/xu3/buildroot
    make linux-xconfig

after the right options have been disabled, just type::

    make

Once the compilation is ended, copy the fresh kernel to the uSD-Card: ::

	sudo cp ~/workspace/xu3/buildroot/output/images/uImage /media/<users>/bootfs/


The uSD-Card can then be inserted into the Odroid and the system can be booted. After the boot, we can verify that we are running the fresh kernel using the 'uname' command: ::
                                                                    
	# uname -a                                                                                
	Linux odroidxu3 3.10.63 #1 SMP PREEMPT Tue Oct 27 08:55:42 CET 2015 armv7l GNU/Linux    

The date & time in the command output should match with kernel compilation time.  
             

Question 2
----------

The goal here is to check that the new kernel is resitent to 'syn-cookie' attack. It is posible to disable the syn-cookie attack protection at run time using the following command::

	# sysctl -w net.ipv4.tcp_syncookies=0
	net.ipv4.tcp_syncookies = 0

We can monitor what append with netstat:

	watch -n2 netstat -atn

the *-a* options tels netstat that we want to show etablished connection and non-etablished connections. The *-t* options tell that we want to see TCP connections. The *-n* options tells that we want to see the addresses in numerical format. The *watch -n2* enable to update the nestat command every two seconds.



On the host machine, we need to temporary change the IP address to be in the same net as
the Odroid. This can be archived using the following command::

	$ sudo ifconfig eth0 192.168.0.12 netmask 255.255.255.0 up


We can check that this is effective using a *ping" command ::

	$ ping 192.168.1.11

The IP address was configured in the previous Lab, using "/etc/network/interfaces".

To make the attack, open scapy in root mode:

	$ sudo scapy

This open an IPython shell with the current namespace populated with Scapy objects. This is convenient to build attacks. First we need to define our syn-coockies packet:p

	In [1]: p = IP(dst='192.168.0.11', id=1111, ttl=99)/TCP(sport=RandShort(), dport=22, seq=12345, ack=1000, window=1000, flags='S')/'HaX0r SVP'



Also we need to block the TCP reset that will be placed by the Host Linux when he receive the SYN/ACK from the Odroid::

 	$ sudo iptables -A OUTPUT -p tcp -s 192.168.0.12 --tcp-flags RST RST -j DROP


Question 3
----------

1) TODO

2) 
The drivers are located here:

	antoine@antoine-vb-64:~/workspace/xu3/buildroot/output/build/linux-eiafr-5/drivers$ find . -name *rtl8192cu*
	./net/wireless/rtl8192cu_v40
	./net/wireless/rtl8192cu_v40/hal/rtl8192c/usb/rtl8192cu_xmit.o
	./net/wireless/rtl8192cu_v40/hal/rtl8192c/usb/rtl8192cu_recv.o
	./net/wireless/rtl8192cu_v40/hal/rtl8192c/usb/.rtl8192cu_recv.o.cmd
	./net/wireless/rtl8192cu_v40/hal/rtl8192c/usb/.rtl8192cu_xmit.o.cmd
	./net/wireless/rtl8192cu_v40/hal/rtl8192c/usb/rtl8192cu_recv.c
	./net/wireless/rtl8192cu_v40/hal/rtl8192c/usb/rtl8192cu_xmit.c
	./net/wireless/rtl8192cu_v40/hal/rtl8192c/usb/.rtl8192cu_led.o.cmd
	./net/wireless/rtl8192cu_v40/hal/rtl8192c/usb/rtl8192cu_led.o
	./net/wireless/rtl8192cu_v40/hal/rtl8192c/usb/rtl8192cu_led.c
	./net/wireless/rtlwifi/rtl8192cu

in ~/workspace/xu3/buildroot/output/build/linux-eiafr-5/drivers/net/wireless/Kconfig uncomment line 284

	source "drivers/net/wireless/rtlwifi/Kconfig"

in ~/workspace/xu3/buildroot/output/build/linux-eiafr-5/drivers/net/wireless/Makefile, uncomment line 27

	obj-$(CONFIG_RTLWIFI)       += rtlwifi/

Then we need to reconfigure the kernel build system to build the module driver:

$ cd ~/workspace/xu3/buildroot
make linux-xconfig

Enable it in "Drivers / Network device support / Wireless LAN" opttion "Realtek 8192C USB WiFi"

Type "make to build the image"

We need to copy the new kernel and RootFS to the uSDCard. For this we have a new install script that place only the kernel and RootFS. The file is "4_copy_kernel_rootfs.hs"

Then we do on the Odroid the command to activate the kernel module driver:

	modprobe rtl8192cu

it complain that the firmware file is missing.

Just copy all rtwifi firmeare from the host PC to the uSD card:

	sudo cp -r /lib/firmware/rtlwifi /media/antoine/e3409f1a-2196-4d11-97c8-36c81d0fd6af/lib/firmware/

We can then install The kernel module::

	TODO

4)

Config files for WiFi.

/etc/wpa.supplicant.conf::

	ctrl_interface=/var/run/wpa_supplicant
	ap_scan=1

	network={
	  key_mgmt=WPA-PSK
	  ssid="SeS"
	  scan_ssid=1
	  proto=RSN
	  pairwise=CCMP
	  group=CCMP
	  psk="A*/1deGr"
	}


5)
/etc/network/interfaces

auto wlan0
pre-up wpa_supplicatn -B -iwlan0


Then we need to restart the newtork using

	# /etc/init.d/S40network restart

It complain that the inferface might already be used:

	Successfully initialized wpa_supplicant
	ctrl_iface exists and seems to be in use - cannot override it
	Delete '/var/run/wpa_supplicant/wlan0' manually if it is not used anymore
	Failed to initialize control interface '/var/run/wpa_supplicant'.
	You may have another wpa_supplicant process already running or the file was
	left by an unclean termination of wpa_supplicant in which case you will need
	to manually remove this file before starting wpa_supplicant again.


So we need to delete the file mentioned

	# rm /var/run/wpa_supplicant/wlan0

We can restart the network again:

	# /etc/init.d/S40network restart

And this time, we get an IP addrress:

	Stopping network...[  754.271642] [c4] smsc95xx 1-1.1:1.0 eth0: hardware isn't capable of remote wakeup
	ifdown: interface wlan0 not configured
	Starting network...
	[  754.372258] [c4] smsc95xx 1-1.1:1.0 eth0: hardware isn't capable of remote wakeup
	Successfully initialized wpa_supplicant
	udhcpc (v1.22.1) started
	Sending discover...
	[  757.430149] [c0] wlan0: deauthenticating from 20:aa:4b:c5:17:35 by local choice (reason=2)
	[  757.456276] [c0] cfg80211: Calling CRDA to update world regulatory domain
	[  757.463107] [c0] wlan0: authenticate with 20:aa:4b:c5:17:35
	[  757.480052] [c0] wlan0: send auth to 20:aa:4b:c5:17:35 (try 1/3)
	[  757.487129] [c0] wlan0: authenticated
	[  757.493669] [c2] wlan0: associate with 20:aa:4b:c5:17:35 (try 1/3)
	[  757.503521] [c0] wlan0: RX AssocResp from 20:aa:4b:c5:17:35 (capab=0x431 status=0 aid=1)
	[  757.510210] [c0] rtlwifi:addbareq_rx():<100-1> sta is NULL
	[  757.516130] [c0] wlan0: associated
	Sending discover...
	Sending select for 192.168.1.105...
	Sending select for 192.168.1.105...
	Sending select for 192.168.1.105...
	Lease of 192.168.1.105 obtained, lease time 86400
	deleting routers
	adding dns 192.168.1.1


