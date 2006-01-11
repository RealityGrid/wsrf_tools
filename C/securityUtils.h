#define MAX_LEN 256

struct security_info {
  char   caCertsPath[MAX_LEN]; 
  char   myKeyCertFile[MAX_LEN];
  char   userDN[MAX_LEN];
};

int getSecurityConfig(struct security_info *sec);
