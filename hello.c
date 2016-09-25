#include <stdio.h>
#include <time.h>

int main( void )  
{
     time_t second = 1474728477;
     struct tm result;
     gmtime_r(&second, &result);
     printf("%d", result.tm_year);
     return 0;
}