/*
 * @Author: Kaustav Vats 
 * @Roll-Number: 2016048 
 * @Date: 2019-01-22 23:03:14 
 */

#define STB_IMAGE_IMPLEMENTATION
#define STB_IMAGE_WRITE_IMPLEMENTATION

#include <iostream>
#include "stb_image.h"
#include "stb_image_write.h"
#include <stdio.h>

#define maskCols 3
#define maskRows 3
#define imgchannels 1

#define TILE_SIZE 32

using namespace std;

void sequentialConvolution(const unsigned char*inputImage,const float * kernel ,unsigned char * outputImageData, int kernelSizeX, int kernelSizeY, int dataSizeX, int dataSizeY, int channels)
{
    int i, j, m, n, mm, nn;
    int kCenterX, kCenterY;                         // center index of kernel
    float sum;                                      // accumulation variable
    int rowIndex, colIndex;                         // indice di riga e di colonna

    const unsigned char * inputImageData = inputImage;
    kCenterX = kernelSizeX / 2;
    kCenterY = kernelSizeY / 2;

    // cout << kCenterX << " " << kCenterY << endl;

    for (int k=0; k<channels; k++) {                    //cycle on channels
        for (i = 0; i < dataSizeY; ++i)                //cycle on image rows
        {
            for (j = 0; j < dataSizeX; ++j)            //cycle on image columns
            {
                sum = 0;
                for (m = 0; m < kernelSizeY; ++m)      //cycle kernel rows
                {
                    mm = kernelSizeY - 1 - m;       // row index of flipped kernel

                    for (n = 0; n < kernelSizeX; ++n)  //cycle on kernel columns
                    {
                        nn = kernelSizeX - 1 - n;   // column index of flipped kernel

                        // indexes used for checking boundary
                        rowIndex = i + m - kCenterY;
                        colIndex = j + n - kCenterX;

                        // ignore pixels which are out of bound
                        if (rowIndex >= 0 && rowIndex < dataSizeY && colIndex >= 0 && colIndex < dataSizeX)
                            sum += inputImageData[(dataSizeX * rowIndex + colIndex)*channels + k] * kernel[kernelSizeX * mm + nn];
                    }
                }
                outputImageData[(dataSizeX * i + j)*channels + k] = sum;

            }
        }
    }
}
__global__ void convKernel(unsigned char * inputImage, const float * kernel, unsigned char* outputImageData, int kernelSizeX, int kernelSizeY, int dataSizeX, int dataSizeY, int channels){

    int m, n, mm, nn;
    int kCenterX, kCenterY;                         // center index of kernel
    float sum;                                      // accumulation variable
    int rowIndex, colIndex;                         // indice di riga e di colonna

    const unsigned char * inputImageData = inputImage;
    kCenterX = kernelSizeX / 2;
    kCenterY = kernelSizeY / 2;

    int i = blockIdx.x*blockDim.x + threadIdx.x;
    int j = blockIdx.y*blockDim.y + threadIdx.y;

    __shared__ unsigned char s_ImageData[TILE_SIZE][TILE_SIZE];

    // // __shared__ float s_Kernel[kernelSizeY][kernelSizeX];

    s_ImageData[i][j] = inputImageData[i * dataSizeX + j];

    __syncthreads();

    sum = 0;
    for (m = 0; m < kernelSizeY; ++m)      //cycle kernel rows
    {
        mm = kernelSizeY - 1 - m;       // row index of flipped kernel

        for (n = 0; n < kernelSizeX; ++n)  //cycle on kernel columns
        {
            nn = kernelSizeX - 1 - n;   // column index of flipped kernel

            // indexes used for checking boundary
            rowIndex = i + m - kCenterY;
            colIndex = j + n - kCenterX;

            // ignore pixels which are out of bound
            if (rowIndex >= 0 && rowIndex < dataSizeY && colIndex >= 0 && colIndex < dataSizeX)
                // sum += inputImageData[dataSizeX * rowIndex + colIndex] * kernel[kernelSizeX * mm + nn];
                sum += s_ImageData[rowIndex][colIndex] * kernel[kernelSizeX * mm + nn];
        }
    }
    outputImageData[dataSizeX * i + j] = sum;
}

int main(){
    int width, height, bpp;
    unsigned char *image, *seq_img;

    image = stbi_load( "image64.png", &width, &height, &bpp, imgchannels );
    seq_img = (unsigned char*)malloc(width*height*sizeof(unsigned char));

    cout << "Height x Width " << height << "x" << width << endl; 
 
    float hostMaskData[maskRows*maskCols];
    for(int i=0; i< maskCols*maskCols; i++){
        hostMaskData[i] = 1.0/(maskRows*maskCols);
    }
    // sequentialConvolution(image, hostMaskData, seq_img, maskRows, maskCols, width, height, imgchannels);
    // stbi_write_png("mynew_seq.png", width, height, imgchannels, seq_img, 0);

    // cuda Program

    const dim3 block_size(16, 16);
    const dim3 num_blocks(width/block_size.x, height/block_size.y);

    cout << "Block Size " << block_size.x << "x" << block_size.y << endl;
    cout << "Num Block " << num_blocks.x << "x" << num_blocks.y << endl;

    unsigned char *d_image = 0, *d_seqimg = 0;
    float *d_hostmaskdata = 0;

    cudaMalloc((void**)&d_image, sizeof(unsigned char) * width * height);
    cudaMalloc((void**)&d_seqimg, sizeof(unsigned char) * width * height);
    cudaMalloc((void**)&d_hostmaskdata, sizeof(float) * maskCols * maskRows);

    cudaMemcpy(d_image, &image[0], sizeof(char) * width * height, cudaMemcpyHostToDevice);
    cudaMemcpy(d_hostmaskdata, &hostMaskData[0], sizeof(float) * maskCols * maskRows, cudaMemcpyHostToDevice);

    convKernel<<<num_blocks, block_size>>>(d_image, d_hostmaskdata, d_seqimg, maskRows, maskCols, width, height, imgchannels);

    cudaMemcpy(seq_img, d_seqimg, sizeof(char) * width * height, cudaMemcpyDeviceToHost);

    stbi_write_png("mynew_seq.png", width, height, imgchannels, seq_img, 0);    

    cudaFree(d_image);
    cudaFree(d_seqimg);
    cudaFree(d_hostmaskdata);

    free(image);
    free(seq_img);

    return 0;
}