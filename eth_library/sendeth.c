#include <arpa/inet.h>
#include <linux/if_packet.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/ioctl.h>
#include <sys/socket.h>
#include <net/if.h>
#include <netinet/ether.h>

#define ETH_ALEN 6

#include "sendeth.h"

int ifrindex;
unsigned long int src_mac;

void main(int argc, char *argv[]) {
    return;
}


int socket_open(unsigned char *ifName) {
    int fd = socket(AF_PACKET, SOCK_RAW, IPPROTO_RAW);
    struct ifreq if_idx;
    struct ifreq if_mac;

    // Get MAC address from source and destination
    memset(&if_idx, 0, sizeof(struct ifreq));
    strncpy(if_idx.ifr_name, ifName, IFNAMSIZ-1);
    if (ioctl(fd, SIOCGIFINDEX, &if_idx) < 0)
        perror("SIOCGIFINDEX");
    ifrindex = if_idx.ifr_ifindex;

    memset(&if_mac, 0, sizeof(struct ifreq));
	strncpy(if_mac.ifr_name, ifName, IFNAMSIZ-1);
	if (ioctl(fd, SIOCGIFHWADDR, &if_mac) < 0)
	    perror("SIOCGIFHWADDR");
	memcpy(&src_mac, if_mac.ifr_hwaddr.sa_data, 6);

    return fd;
}

// Get your own MAC address
unsigned long int get_mac_addr(void) {
    return src_mac;
}

int socket_close(int fd) {
    return close(fd);
}

#define BUF_SIZ 1540

int socket_send(int sockfd, unsigned long int src_mac, unsigned long int dest_mac, unsigned int ether_type, const unsigned char *data, int len, unsigned int flags)
{
	char sendbuf[BUF_SIZ];
	struct ether_header *eh = (struct ether_header *) sendbuf;
	int tx_len = 0;
	struct sockaddr_ll socket_address;


	/* Construct the Ethernet header */
	memset(sendbuf, 0, BUF_SIZ);
	/* Ethernet header */
	eh->ether_shost[0] = (src_mac >> 40) & 0xFF;
	eh->ether_shost[1] = (src_mac >> 32) & 0xFF;
	eh->ether_shost[2] = (src_mac >> 24) & 0xFF;
	eh->ether_shost[3] = (src_mac >> 16) & 0xFF;
	eh->ether_shost[4] = (src_mac >> 8) & 0xFF;
	eh->ether_shost[5] = src_mac & 0xFF;
	eh->ether_dhost[0] = (dest_mac >> 40) & 0xFF;
	eh->ether_dhost[1] = (dest_mac >> 32) & 0xFF;
	eh->ether_dhost[2] = (dest_mac >> 24) & 0xFF;
	eh->ether_dhost[3] = (dest_mac >> 16) & 0xFF;
	eh->ether_dhost[4] = (dest_mac >> 8) & 0xFF;
	eh->ether_dhost[5] = dest_mac & 0xFF;
	/* Ethertype field */
	eh->ether_type = htons(ether_type);
	tx_len += sizeof(struct ether_header);

	if (len + sizeof(struct ether_header) > BUF_SIZ)
		len = BUF_SIZ - sizeof(struct ether_header);
	memcpy(sendbuf+sizeof(struct ether_header), data, len);
	tx_len += len;

	/* Index of the network device */
	socket_address.sll_ifindex = ifrindex;
	/* Address length*/
	socket_address.sll_halen = ETH_ALEN;
	/* Destination MAC */
	socket_address.sll_addr[0] = (dest_mac >> 40) & 0xFF;
	socket_address.sll_addr[1] = (dest_mac >> 32) & 0xFF;
	socket_address.sll_addr[2] = (dest_mac >> 24) & 0xFF;
	socket_address.sll_addr[3] = (dest_mac >> 16) & 0xFF;
	socket_address.sll_addr[4] = (dest_mac >> 8) & 0xFF;
	socket_address.sll_addr[5] = dest_mac & 0xFF;

	/* Send packet */
	return sendto(sockfd, sendbuf, tx_len, flags, (struct sockaddr*)&socket_address, sizeof(struct sockaddr_ll));
}
