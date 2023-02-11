
// Open and close a raw socket, get MAC address
int socket_open(uint8_t *ifname);
int socket_close(int);
unsigned long int get_mac_addr(void);
int get_ifrindex(void);

// Send data to the socket
int socket_send(int sockfd, unsigned long int src_mac, unsigned long int dest_mac, unsigned int ether_type, uint8_t *data, int len, unsigned int flags);
