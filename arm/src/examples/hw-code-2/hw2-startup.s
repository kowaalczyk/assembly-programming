.global _MyApp
_MyApp:
 LDR sp, =stack_top
 BL entry
 B .
