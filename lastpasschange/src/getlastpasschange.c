#include <stdio.h>
#include <shadow.h>

int main(int argc, char *argv[]) {

	if (argc > 1) {
		int lastpw  = 0;
		struct spwd *spwd;
		char *user = argv[1];
		int now     = (int)time(NULL);

		spwd = getspnam(user);

		if (spwd) {
			lastpw = (int) (spwd->sp_lstchg * 86400);
			int diff = (int) (now - lastpw);
			int daysdiff = diff/86400;
			//Days since 01/01/1970
			printf("%ld\n", spwd->sp_lstchg);
			//Timestamp of last pass change
			printf("%d\n", lastpw);
			//Difference of now and last pass change timestamp
			printf("%d\n", diff);
			//Difference in days
			printf("%d\n", daysdiff);
		}
	} else {
		printf("Usage: getlastpasschange <user> \n\n It returns: \n 1. Last change password date on days since 01/01/1970 \n 2. Timestamp of last password change \n 3. Difference between timestamp now and last password change \n 4. Difference in days \n\n ");

	}
	
	return 0;
}
