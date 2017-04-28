#!/bin/bash -

MY_NETWORK="129.16.23.0/24"

# Replace the ip address here with the ip address for your computer. You can use the programs "/sbin/ifconfig", or "/sbin/ip addr show". 
MY_HOST="129.16.23.12"

# Network interfaces
IN=em1
OUT=em1

# Path to iptables, "/sbin/iptables"
IPTABLES="sudo /usr/bin/iptables"

########################
### DON'T TOUCH THIS ###
########################
# Explanation: Changing these rules may freeze your machine, because the nfs connection to your home directory will be lost.

# Flushing all chains and setting default policy
$IPTABLES -P INPUT ACCEPT
$IPTABLES -P FORWARD ACCEPT
$IPTABLES -P OUTPUT ACCEPT
$IPTABLES -F

# delete chain CTH if it exists
$IPTABLES -L CTH &>/dev/null
if [ $? -eq 0 ]; then
    $IPTABLES -X CTH
fi

# Make sure NFS works (allow traffic to Chalmers), or your machine may hang until restarted
$IPTABLES -N CTH
$IPTABLES -A CTH -s 129.16.226.60 -m state --state ESTABLISHED,RELATED -m comment --comment "NFS server" -j ACCEPT
$IPTABLES -A CTH -s 129.16.20.0/22 -m comment --comment "Ignore CSE networks (including rooms 4220/4225)" -j RETURN
$IPTABLES -A CTH -m state --state ESTABLISHED,RELATED -m comment --comment "Allow the rest to Chalmers" -j ACCEPT

$IPTABLES -A INPUT -i $IN -s 129.16.0.0/16 -m comment --comment "Allow NFS traffic" -j CTH
$IPTABLES -A OUTPUT -o $OUT -d 129.16.0.0/16 -j ACCEPT

# reset counters to zero
$IPTABLES -Z

# Block malformed packets
$IPTABLES -A INPUT -p tcp --tcp-flags FIN,PSH,URG FIN,PSH,URG -m comment --comment "Block XMAS packets" -j DROP
$IPTABLES -A INPUT -p tcp --tcp-flags ALL NONE -m comment --comment "Block NULL packets" -j DROP

##################
### START HERE ###
##################

# Requirement 1: Set default policy to drop
$IPTABLES -P INPUT DROP
$IPTABLES -P FORWARD DROP
$IPTABLES -P OUTPUT DROP

# Requirement 2: Allow all fraffic from loopback
$IPTABLES -I INPUT 1 -i lo -j ACCEPT
$IPTABLES -I OUTPUT 1 -o lo -j ACCEPT

# Requirement 3: Allow outgoing from ethernet inteface
$IPTABLES -A OUTPUT -o $OUT -j ACCEPT

# Requirement 4: Protection against spoofed packets
$IPTABLES -I INPUT 1 -i $IN -s 10.0.0.8/8 -j DROP
$IPTABLES -I INPUT 1 -i $IN -s 172.16.0.0/12 -j DROP
$IPTABLES -I INPUT 1 -i $IN -s 192.168.0.0/16 -j DROP
$IPTABLES -I INPUT 1 -i $IN -s 169.254.0.0/16 -j DROP

# Requirement 5: Allow established connections (Stateful inspection)
$IPTABLES -A INPUT -i $IN -m state --state ESTABLISHED,RELATED -j ACCEPT

# Requirement 6: Limit ping flood
$IPTABLES -I INPUT 1 -i $IN -p icmp --icmp-type echo-request -m limit --limit 1/s -j ACCEPT
$IPTABLES -I INPUT 2 -i $IN -p icmp -j DROP

# Requirement 7: Application specific
$IPTABLES -A INPUT -i $IN -p tcp --dport 22 -j ACCEPT
$IPTABLES -A INPUT -i $IN -p sctp --dport 22 -j ACCEPT
$IPTABLES -A INPUT -i $IN -p udp --dport 22 -j ACCEPT
$IPTABLES -A INPUT -i $IN -p tcp --dport 8080 -j ACCEPT
$IPTABLES -A INPUT -i $IN -p udp --dport 8080 -j ACCEPT
$IPTABLES -A INPUT -i $IN -p tcp --dport 111 -j ACCEPT

# Requirement 8: Logg all other packets
$IPTABLES -A INPUT -j LOG
$IPTABLES -A OUTPUT -j LOG

echo "Done!"
