/*****************************************************************************
*
* String Pattern Matching - Serial Implementation
* 
* Reference: http://people.maths.ox.ac.uk/~gilesm/cuda/
*
*****************************************************************************/

#include <iostream>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <math.h>
#include <ctime>

using namespace std;

#define LINEWIDTH 20

void matchPattern_CPU(unsigned int *text, unsigned int *words, int *matches, int nwords, int length)
{
	unsigned int word;

	for (int l=0; l<length; l++)
	{
		// cout << "Test[l] : " << (char)text[l] << endl;
		for (int offset=0; offset<4; offset++)
		{
			if (offset==0) {
				word = text[l];
				// cout << "wd:" << word << endl;
			}
			else
				word = (text[l]>>(8*offset)) + (text[l+1]<<(32-8*offset)); 

			for (int w=0; w<nwords; w++){
				matches[w] += (word==words[w]);

			} 
			// cout << "word : " << offset << word << endl;
				
		}
	}
}


int main(int argc, const char **argv)
{

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
	// fp = fopen("./data/large.txt","r");
	fp = fopen("./data/small.txt","r");
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

	// CPU execution
	const clock_t begin_time = clock();
	matchPattern_CPU(text, words, matches, nwords, len);
	float runTime = (float)( clock() - begin_time ) /  CLOCKS_PER_SEC;
	printf("Time for matching keywords: %fs\n\n", runTime);

	printf("Printing Matches:\n");
	printf("Word\t  |\tNumber of Matches\n===================================\n");
	for (int i = 0; i < nwords; ++i)
		printf("%s\t  |\t%d\n", keywords[i], matches[i]);

	free(ctext);
	free(words);
}
