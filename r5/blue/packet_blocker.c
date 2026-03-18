#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/printk.h>
#include <linux/netfilter.h>
#include <linux/netfilter_ipv4.h>
#include <linux/net.h>
#include <linux/ip.h>
#include <linux/tcp.h>
#include <linux/skbuff.h>


#define TARGET_PORT 1999 // change this port number

static int filter_packet(struct sk_buff *sk) {

    struct tcphdr *tcp_header; //  create tcp header struct variable to store tcp header data
    struct iphdr *ip_header; // create ip header struct variable to store ip header data

    if(!sk) {
        return 0; // if can't read from socket buffer, does nothing
    }

    ip_header = ip_hdr(sk); // function ip_hdr() takes ip header from socket buffer struct
    if(ip_header) { // if ip header exists,
        pr_info("packet captured: source IP: %pI4\n", &ip_header->saddr); 
        if(ip_header->protocol == IPPROTO_TCP) { // if tcp protocol
            tcp_header = tcp_hdr(sk); // extract tcp header from the socket buffer

            if(tcp_header) { // if tcp header exists, 
                if(ntohs(tcp_header->dest) == TARGET_PORT) {
                    pr_info("telnet communication has been blocked\n");
                    return 1; // return 1 to block the packet
                }
            }
        }
    }
    return 0; // return 0 to pass the packet.
}

static unsigned int packet_hook_func(void *priv, struct sk_buff *sk, const struct nf_hook_state *state) {
    if(filter_packet(sk)) {
        return NF_DROP; // drop the packet
    }
    else {
        return NF_ACCEPT; // accept the packet to make it continue
    }  
}

static struct nf_hook_ops nho = {
    .hook   = packet_hook_func, // hook function
    .hooknum    = NF_INET_LOCAL_OUT, // NF_INET_LOCAL_OUT macro ensures modules to capture outbound traffics
    .pf     = PF_INET, // PF_INET, same as AF_INET. its ipv4
    .priority   = NF_IP_PRI_FIRST, // NF_IP_PRI_FIRST macro ensures this operation recognized as high priority
};


static int __init telnet_filter_init(void) {
    int res = nf_register_net_hook(&init_net, &nho);
    if(res < 0) {
        pr_err("failed to register netfilter hook\n");
        return res;
    }
    pr_info("telnet blocker loaded\n");
    return 0;
}

static void __exit telnet_filter_exit(void) {
    nf_unregister_net_hook(&init_net, &nho);
    pr_info("telnet blocker unattached\n");
}


module_init(telnet_filter_init);
module_exit(telnet_filter_exit);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Jay");
MODULE_DESCRIPTION("packet capturer");