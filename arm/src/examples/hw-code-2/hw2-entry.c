volatile unsigned char * const UART0_PTR = (unsigned char *)0x0101f1000;

void print_uart0 (const char *string) {
  while (*string != '\0') {
    *UART0_PTR = *string;
    string++;
  }
}

int entry () {
  print_uart0("Hello, world!\n");
  return 0;
}
