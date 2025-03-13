#include "lightsss/lightsss.h"
#include <cstdlib>
#include <unistd.h>

pid_t LightSSS::p_pid = -1;
int LightSSS::waitProcess = 0;
std::deque<pid_t> LightSSS::pidSlot = {};
ForkShareMemory LightSSS::forkshm;

ForkShareMemory::ForkShareMemory() {
  if ((key_n = ftok(".", 's') < 0)) {
    perror("Fail to ftok\n");
    FAIL_EXIT
  }

  if ((shm_id = shmget(key_n, 1024, 0666 | IPC_CREAT)) == -1) {
    perror("shmget failed...\n");
    FAIL_EXIT
  }

  void *ret = shmat(shm_id, NULL, 0);
  if (ret == (void *)-1) {
    perror("shmat failed...\n");
    FAIL_EXIT
  } else {
    info = (shinfo *)ret;
  }

  info->flag = false;
  info->notgood = false;
  info->endCycles = 0;
  info->oldest = 0;
}

ForkShareMemory::~ForkShareMemory() {
  if (shmdt(info) == -1) {
    perror("detach error\n");
  }
  shmctl(shm_id, IPC_RMID, NULL);
}

void ForkShareMemory::shwait() {
  while (true) {
    if (info->flag) {
      if (info->notgood) {
        // exit(0);
        break;
      }
      else
        exit(0);
    } else {
      // FORK_PRINTF("parent not dead, I'm sleep: pid: %d\n", getpid());
      sleep(WAIT_INTERVAL);
    }
  }
}

void LightSSS::signal_handler(int signum) {
  FORK_PRINTF("clear processes...\n")
  while (!pidSlot.empty()) {
    pid_t temp = pidSlot.back();
    pidSlot.pop_back();
    kill(temp, SIGKILL);
    waitpid(temp, NULL, 0);
  }
  exit(EXIT_FAILURE); // 退出当前进程
}
void LightSSS::signal_handler_abort(int signum) {
  if(is_child()) exit(EXIT_FAILURE);
  if(pidSlot.empty()) return;
  FORK_PRINTF("handler abort signum: %d, pidSlot size: %ld\n", signum, pidSlot.size());
  forkshm.info->endCycles = -1;
  forkshm.info->oldest = pidSlot.back();

  // only the oldest is wantted, so kill others by parent process.
  // for (auto pid: pidSlot) {
  for (auto pid = pidSlot.begin(); pid != pidSlot.end(); ) {
    if (*pid != forkshm.info->oldest) {
      kill(*pid, SIGKILL);
      waitpid(*pid, NULL, 0);
      pid = pidSlot.erase(pid);
      // slotCnt--;
    }
    else {
      pid++;
    }
  }
  // flush before wake up child.
  fflush(stdout);
  fflush(stderr);

  forkshm.info->notgood = true;
  forkshm.info->flag = true;
  int status = -1;
  // FORK_PRINTF("delete pid: %d\n", pidSlot.back());
  waitpid(pidSlot.back(), &status, 0);

  exit(EXIT_FAILURE); // 退出当前进程
}

int LightSSS::do_fork() {
  if(is_child()) return 0;

  //kill the oldest blocked checkpoint process
  if (slotCnt == SLOT_SIZE) {
    pid_t temp = pidSlot.back();
    pidSlot.pop_back();
    kill(temp, SIGKILL);
    int status = 0;
    waitpid(temp, NULL, 0);
    slotCnt--;
  }
  // fork a new checkpoint process and block it
  if ((pid = fork()) < 0) {
    printf("[%d]Error: could not fork process!\n", getpid());
    return FORK_ERROR;
  }
  // the original process
  else if (pid != 0) {
    slotCnt++;
    pidSlot.push_front(pid);
    return FORK_OK;
  }
  // for the fork child
  waitProcess = 1;
  forkshm.shwait();
  //checkpoint process wakes up
  //start wave dumping
  if (forkshm.info->oldest != getpid()) {
    FORK_PRINTF("Error, non-oldest process should not live. Parent Process should kill the process manually.\n")
    return FORK_ERROR;
  }
  return FORK_CHILD;
}

int LightSSS::wakeup_child(uint64_t cycles) {
  if(pidSlot.empty()) return 0;
  if(is_child()) return 0;
  forkshm.info->endCycles = cycles;
  forkshm.info->oldest = pidSlot.back();

  // only the oldest is wantted, so kill others by parent process.
  for (auto pid: pidSlot) {
    if (pid != forkshm.info->oldest) {
      kill(pid, SIGKILL);
      waitpid(pid, NULL, 0);
      slotCnt--;
      FORK_PRINTF("delete id: %d\n", pid);
    }
  }
  // flush before wake up child.
  fflush(stdout);
  fflush(stderr);

  forkshm.info->notgood = true;
  forkshm.info->flag = true;
  int status = -1;
  // printf("old pid:%d\n", pidSlot.back());
  waitpid(pidSlot.back(), &status, 0);
  return 0;
}

bool LightSSS::is_child() {
  return waitProcess;
}

int LightSSS::do_clear() {
  FORK_PRINTF("clear processes...\n")
  while (!pidSlot.empty()) {
    pid_t temp = pidSlot.back();
    pidSlot.pop_back();
    kill(temp, SIGKILL);
    waitpid(temp, NULL, 0);
    slotCnt--;
  }
  return 0;
}
