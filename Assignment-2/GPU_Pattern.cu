/*
 * @Author: Kaustav Vats 
 * @Roll-Number: 2016048 
 * @Ref:- CPU Code by TA
 */

 #include <iostream>
 #include <stdlib.h>
 #include <stdio.h>
 #include <string.h>
 #include <math.h>
 #include <ctime>

using namespace std;

#define LINEWIDTH 20
#define TOTAL 32
#define MAX_WORDS 32

void CheckDiff(int * cpu, int * gpu, int nwords) {
    int Correct = 0, Wrong = 0;
    for (int i=0; i<nwords; i++) {
        if ( cpu[i] == gpu[i] ) {
            Correct++;
        }
        else {
            Wrong++;
        }
    }
    if (Wrong == 0) {
        printf("Correctly Matched: True\n\n");
    }
    else {
        printf("Correctly Matched: False\n\n");
    }
}

void matchPattern_CPU(unsigned int *text, unsigned int *words, int *matches, int nwords, int length)
{
	unsigned int word;

	for (int l=0; l<length; l++)
	{
		for (int offset=0; offset<4; offset++)
		{
			if (offset==0) {
				word = text[l];
			}
			else
				word = (text[l]>>(8*offset)) + (text[l+1]<<(32-8*offset)); 

			for (int w=0; w<nwords; w++){
				matches[w] += (word==words[w]);
			} 
		}
	}
}

__global__ void matchPattern_GPU(unsigned int *text, const unsigned int *words, int *matches, int nwords, int length) {

    int col = threadIdx.x;
    int index = col + blockIdx.x*blockDim.x;

    if (index >= length) {
        return;
    }

    __shared__ unsigned int sm_text[TOTAL+1];
    __shared__ unsigned int sm_words[MAX_WORDS];

    // int xDist = threadIdx.x + blockIdx.x*blockDim.x;
    // int yDist = threadIdx.y*blockDim.x*gridDim.x + blockDim.y*blockIdx.y*blockDim.x*gridDim.x;
    // int index = xDist + yDist;
    // __shared__ int len;

    // if (threadIdx.x == 0) {
    //     len = length;
    // }

    unsigned int word;

    if (col < 32) {
        sm_words[col] = words[col];
    }

    // if (index < length) {
        sm_text[col] = text[index];
        // if (col == TOTAL-1) {
        sm_text[col+1] = text[index+1];
        // }
    // }
    __syncthreads();

    for (int offset=0; offset<4; offset++)
    {
        if (offset==0) {
            // word = text[index];
            word = sm_text[col];
        }
        else {
            // word = (text[index]>>(8*offset)) + (text[index+1]<<(32-8*offset)); 
            word = (sm_text[col]>>(8*offset)) + (sm_text[col+1]<<(32-8*offset)); 
        }
        for (int w=0; w<32; w++){
            if (word == sm_words[w]) {
            // if (word == words[w]) {
                atomicAdd(&matches[w], 1);
            }
        }        
    }
}

int main() {

    const char * fileData[3] = { "./data/small.txt", "./data/medium.txt", "./data/large.txt" };
    int wl;
    for (wl=0; wl<3; wl++) {

        int length, len, nwords=32, matches[nwords];
        char *ctext, keywords[nwords][LINEWIDTH], *line;
        line = (char*) malloc(sizeof(char)*LINEWIDTH);
        unsigned int  *text,  *words;
        memset(matches, 0, sizeof(matches));

        // char filename[1024];
        // memset(filename, '\0', sizeof(filename));

        // cin >> filename;
        // read in text and keywords for processing
        FILE *fp, *wfile;
        // wfile = fopen("./data/test.txt","r");
        wfile = fopen("./data/keywords.txt","r");
        if (!wfile)
        {	
            printf("keywords.txt: File not found.\n");	
            exit(0);
        }

        int k=0, cnt = nwords;
        size_t read, linelen = LINEWIDTH;
        while((read = getline(&line, &linelen, wfile)) != -1 && cnt--)
        {
            strncpy(keywords[k], line, sizeof(line));
            keywords[k][4] = '\0';
            k++;
        }
        fclose(wfile);

        // cout << "K: " << k << endl;
        fp = fopen(fileData[wl],"r");
        // fp = fopen("./data/small.txt","r");
        if (!fp) {	
            printf("Unable to open the file.\n");	
            exit(0);
        }

        length = 0;
        while (getc(fp) != EOF) length++;

        ctext = (char *) malloc(length+4);

        rewind(fp);

        for (int l=0; l<length; l++) ctext[l] = getc(fp);
        for (int l=length; l<length+4; l++) ctext[l] = ' ';

        fclose(fp);

        printf("Length : %d\n", length );
        // define number of words of text, and set pointers
        len  = length/4;
        text = (unsigned int *) ctext;

        // define words for matching
        words = (unsigned int *) malloc(nwords*sizeof(unsigned int));

        // cout << "Words: ";
        for (int w=0; w<nwords; w++)
        {
            words[w] = ((unsigned int) keywords[w][0])
                + ((unsigned int) keywords[w][1])*(1<<8)
                + ((unsigned int) keywords[w][2])*(1<<16)
                + ((unsigned int) keywords[w][3])*(1<<24);
            // cout << words[w] << "\t";
        }
        // cout << endl;

        // GPU Execution
        const dim3 block_size(TOTAL, 1);
        // const dim3 num_blocks(512, 512);
        const dim3 num_blocks(ceil(len/TOTAL), 1);

        cudaEvent_t start_kernel, stop_kernel, m_kernel_start, m_kernel_stop;
        cudaEventCreate(&start_kernel);
        cudaEventCreate(&stop_kernel);
        cudaEventCreate(&m_kernel_start);
        cudaEventCreate(&m_kernel_stop);


        unsigned int * d_text, * d_words;
        int * d_matches;
        int * mat;
        mat = (int* )malloc(sizeof(int)*nwords);

        cudaEventRecord(m_kernel_start);
        cudaMalloc((void**)&d_text, sizeof(unsigned int) * len);
        cudaMalloc((void**)&d_words, sizeof(unsigned int)*nwords);
        cudaMalloc((void**)&d_matches, sizeof(int)*nwords);

        cudaMemcpy(d_text, text, sizeof(unsigned int) * len, cudaMemcpyHostToDevice);
        cudaMemcpy(d_words, words, sizeof(unsigned int) * nwords, cudaMemcpyHostToDevice);

        cudaEventRecord(start_kernel);
        matchPattern_GPU<<<num_blocks, block_size>>>(d_text, d_words, d_matches, nwords, len);
        cudaEventRecord(stop_kernel);
        
        cudaEventSynchronize(stop_kernel);

        cudaMemcpy(mat, d_matches, sizeof(int) * nwords, cudaMemcpyDeviceToHost);
        cudaEventRecord(m_kernel_stop);
        cudaEventSynchronize(m_kernel_stop);

        float k_time, k2_time ;
        cudaEventElapsedTime(&k_time, start_kernel, stop_kernel);
        cudaEventElapsedTime(&k2_time, m_kernel_start, m_kernel_stop);
        cout  << "[" << wl << "] GPU-Kernel Time: " << k_time  << "ms" << endl;
        cout  << "[" << wl << "] GPU-Kernel + Memory Time: " << k2_time  << "ms" << endl;

        // CPU execution
        const clock_t begin_time = clock();
        matchPattern_CPU(text, words, matches, nwords, len);
        float runTime = (float)( clock() - begin_time ) /  CLOCKS_PER_SEC;
        // printf("CPU Time: %fs\n\n", runTime);
        cout  << "[" << wl << "] CPU-Time: " << runTime << "s" << endl;

        cout << "[" << wl << "] Speedup: " << (runTime*1000)/k_time << endl;
        cout << "[" << wl << "] Speedup with memory Transfer: " << (runTime*1000)/k2_time << endl;
        
        CheckDiff(matches, mat, nwords);

        // printf("[%d] Printing Matches:\n", wl);
        // printf("Word\t  |\tNumber of Matches\n===================================\n");
        // for (int i = 0; i < nwords; ++i)
            // printf("%s\t  |\t%d\n", keywords[i], mat[i]);

        free(ctext);
        free(words);
        cudaFree(d_text);
        cudaFree(d_words);
        cudaFree(d_matches);
    }

    return 0;
}
