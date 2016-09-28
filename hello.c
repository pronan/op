#include <stdio.h>
#include <time.h>

int main( void )  
{
     time_t second = 1474728477;
     struct tm result;
     localtime_r(&second, &result);
     printf("%d\n", result.tm_hour);
     printf("%d", (int)mktime(&result));
     return 0;
}