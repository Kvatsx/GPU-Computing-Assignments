/*
 * @Author: Kaustav Vats 
 * @Roll-Number: 2016048 
 */

 #include <iostream>
 #include <stdio.h>

using namespace std;

__global__ void matchPattern_GPU(unsigned int *text, unsigned int *words, int *matches, int nwords, int length) {

    // __shared__ int sm_matches[nwords];
    __shared__ unsigned int sm_text[blockDim.x+1][blockDim.y];
    
    int col = blockIdx.x*blockDim.x + threadIdx.x;
    int row = blockIdx.y*blockDim.y + threadIdx.y;

    int total_threads = gridDim.x*gridDim.y*blockDim.x*blockDim.y;
    int index = row*gridDim.x + col;

    sm_text[col][row] = text[index];

    unsigned int word;
    while ( index < length ) {
        for (int offset=0; offset<4; offset++)
        {
            if (offset==0) {
                word = text[index];
                // cout << "wd:" << word << endl;
            }
            else {
                word = (text[l]>>(8*offset)) + (text[l+1]<<(32-8*offset)); 
            }

            for (int w=0; w<nwords; w++){
                // sm_matches[w] += (word==words[w]);
                matches[w] += (word==words[w]);
            } 
            // cout << "word : " << offset << word << endl;           
        }
        index += total_threads;
    }
}

int main() {
    
}
