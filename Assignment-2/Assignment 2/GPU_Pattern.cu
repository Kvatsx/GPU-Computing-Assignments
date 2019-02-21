/*
 * @Author: Kaustav Vats 
 * @Roll-Number: 2016048 
 */

 #include <iostream>
 #include <stdio.h>

using namespace std;

#define LINEWIDTH 20
// #define TOTAL 1025

__global__ void matchPattern_GPU(unsigned int *text, unsigned int *words, int *matches, int nwords, int length) {
    // printf("Kernel Called\n");
    // __shared__ int sm_matches[nwords];
    // __shared__ unsigned int sm_text[blockDim.x+1][blockDim.y];

    int row = blockIdx.y*blockDim.y + threadIdx.y;
    int col = blockIdx.x*blockDim.x + threadIdx.x;

    int total_threads = gridDim.x*gridDim.y*blockDim.x*blockDim.y;

    // __shared__ unsigned int sm_text[1025];

    int xDist = threadIdx.x + blockIdx.x*blockDim.x;
    int yDist = threadIdx.y*blockDim.x*gridDim.x + blockDim.y*blockIdx.y*blockDim.x*gridDim.x;
    int index = xDist + yDist;

    int i=0;
    unsigned int word;
    while ( (index + i*total_threads) < length ) {
        // sm_text[index] = text[index + i*total_threads];
        // if ( threadIdx.x == (blockDim.x-1) && threadIdx.y == (blockDim.y-1)) {
            // sm_text[total_threads] = text[index + i*total_threads+1];
        // }
        // __syncthreads();

        for (int offset=0; offset<4; offset++)
        {
            if (offset==0) {
                word = text[index];
                // word = sm_text[index];
            }
            else {
                word = (text[index]>>(8*offset)) + (text[index+1]<<(32-8*offset)); 
                // word = (sm_text[index]>>(8*offset)) + (sm_text[index+1]<<(32-8*offset)); 
            }

            for (int w=0; w<nwords; w++){
                if (word == words[w]) {
                    atomicAdd(&matches[w], 1);
                }
            }        
        }
        i++;
        // index += total_threads;
    }
}

int main() {

    int length, len, nwords=20, matches[nwords];
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
	fp = fopen("./data/small.txt","r");
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
    const dim3 block_size(32, 32);
    const dim3 num_blocks(1024, 1024);

    unsigned int * d_text, * d_words;
    int * d_matches;
    int * mat;
    mat = (int* )malloc(sizeof(int)*nwords);

    cudaMalloc((void**)&d_text, sizeof(unsigned int) * len);
    cudaMalloc((void**)&d_words, sizeof(unsigned int)*nwords);
    cudaMalloc((void**)&d_matches, sizeof(int)*nwords);

    cudaMemcpy(d_text, text, sizeof(unsigned int) * len, cudaMemcpyHostToDevice);
    cudaMemcpy(d_words, words, sizeof(unsigned int) * nwords, cudaMemcpyHostToDevice);

    matchPattern_GPU<<<num_blocks, block_size>>>(d_text, d_words, d_matches, nwords, len);

    cudaMemcpy(mat, d_matches, sizeof(int) * nwords, cudaMemcpyDeviceToHost);


	// CPU execution
	// const clock_t begin_time = clock();
	// matchPattern_CPU(text, words, matches, nwords, len);
	// float runTime = (float)( clock() - begin_time ) /  CLOCKS_PER_SEC;
	// printf("Time for matching keywords: %fs\n\n", runTime);

	printf("Printing Matches:\n");
	printf("Word\t  |\tNumber of Matches\n===================================\n");
	for (int i = 0; i < nwords; ++i)
		printf("%s\t  |\t%d\n", keywords[i], mat[i]);

	free(ctext);
    free(words);
    cudaFree(d_text);
    cudaFree(d_words);
    cudaFree(d_matches);

}
