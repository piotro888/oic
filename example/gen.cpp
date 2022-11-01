#include <bits/stdc++.h>
#include <sys/time.h>

using namespace std;

int rrand(int l, int u) {
    return (rand()%(u-l+1))+l;
}

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(nullptr);

    struct timeval time;
    gettimeofday(&time, nullptr);
    srand(time.tv_sec+time.tv_usec);

    

}