//gcc -Wall -g -o bitmap bitmap.C -lstdc++

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>


#define WHITE 0xFF
#define BLACK 0x0

#define DELTA 100

typedef struct
{
	uint16_t 	ImageFileType ; 	/* Always 4D42h (''BM'')		*/
	uint32_t 	FileSize ;	        /* Physical file size in bytes 		*/
	uint16_t	Reserved1 ;
	uint16_t	Reserved2 ;
	uint32_t	ImageDataOffset ;	/* Start of image data offset in byte 	*/
}__attribute__((__packed__)) BITMAP_HEADER1 ;

typedef struct
{
	uint16_t 	HeaderSize ;		/* Size of this header 			*/
	uint16_t	Reserved1;
	uint16_t	ImageWidth ;		/* Image width in pixel			*/
	uint16_t	Reserved2;
	uint16_t	ImageHeight ;		/* Image height in pixel			*/
	uint16_t	Reserved3;
	uint16_t	NumberOfImagePlanes ;/* always 1				*/
	uint16_t	BitPerPixel ;		/* 1, 4, 8, 24				*/
	uint32_t	CompressionMethod ;	/* 0, 1, 2				*/
	uint32_t	SizeOfBitmap ;		/* Size of the bitmap in bytes		*/
	uint32_t	HorzResolution ;	/* Horiz. Resolution in pixel per meter	*/
	uint32_t	VertResolution ;	/* Vert. Resolution in pixel per meter	*/
	uint32_t	NumColorsUsed ;	    /* Number of the colors in the bitmap	*/
	uint32_t	NumSignificantColors ;	/* Number of important colors in palette	*/
}__attribute__((__packed__)) 	BITMAP_HEADER2 ;
typedef struct
{
	uint8_t 	Blue ;
	uint8_t		Green ;
	uint8_t		Red ;
}__attribute__((__packed__))	RGB ;

typedef struct 
{
	BITMAP_HEADER1	h1;
	BITMAP_HEADER2	h2;
	uint32_t         nb_byte_line;
	RGB 		*p_buffer;			
	RGB		*p_rgb;
        FILE            *pFile;
}	IMAGE_BMP;





static void          steganographyEncrypt (const char *pSrc, const char *pDst, const char *pHiddenSource);
static void          modifyPixel          (RGB  *p);
static void          steganographyDecrypt (const char *pOri, const char *pModified, const char *pFoundHiddenText);


int main(void)
{
    steganographyEncrypt ("img1.bmp", "img2.bmp", "hidden_text.bmp");
    steganographyDecrypt ("img1.bmp", "img2.bmp", "hidden_text2.bmp");
    return 0;
}



static void steganographyEncrypt (const char *pSrc, const char *pDst, const char *pHiddenSource)
{
FILE *pFileSource;
FILE *pFileDest;
FILE *pFileHiddenSource;
int         i;

struct {
	BITMAP_HEADER1	h1;
	BITMAP_HEADER2	h2;
	unsigned long   nb_byte_line;
	RGB 	      **p_buffer;			
	RGB    	      **p_row;
}			bitmap;
struct {
	BITMAP_HEADER1	h1;
	BITMAP_HEADER2	h2;
	unsigned long   nb_byte_line;
        RGB            *p_buffer;			
	RGB            *p_rgb;
}			hiddenText;

	/* Open the files */
        pFileSource = fopen(pSrc, "rb");
	pFileDest   = fopen(pDst, "wb");


	// Read the two headers
	fread  (&bitmap.h1, sizeof(bitmap.h1), 1, pFileSource);
	fwrite (&bitmap.h1, sizeof(bitmap.h1), 1, pFileDest);
	fread  (&bitmap.h2, sizeof(bitmap.h2), 1, pFileSource);
	fwrite (&bitmap.h2, sizeof(bitmap.h2), 1, pFileDest);

        // Reserve dynamiquement le 1er tableau de pointeurs
	bitmap.p_buffer = (RGB**)new unsigned char[bitmap.h2.ImageHeight*sizeof(RGB*)];
	memset (bitmap.p_buffer, 0, bitmap.h2.ImageHeight * sizeof(RGB*));


	// Reserve dynamiquement toutes les lignes
	bitmap.nb_byte_line = (bitmap.h2.ImageWidth * sizeof(RGB)) + (bitmap.h2.ImageWidth % 4);

	for (i=bitmap.h2.ImageHeight, bitmap.p_row = bitmap.p_buffer; i; i--, bitmap.p_row++)
	{
            *bitmap.p_row = (RGB*)new unsigned char[bitmap.nb_byte_line];
             memset (*bitmap.p_row, 0, bitmap.nb_byte_line);
	}


	// Copie toute l'image en memoire
	for (i=bitmap.h2.ImageHeight, bitmap.p_row = bitmap.p_buffer; i; i--, bitmap.p_row++)
	{
             fread (*bitmap.p_row, bitmap.nb_byte_line, 1, pFileSource);
	}



	// Traite le fichier cache
        pFileHiddenSource = fopen(pHiddenSource, "rb");
	fread  (&hiddenText.h1, sizeof(hiddenText.h1), 1, pFileHiddenSource);
	fread  (&hiddenText.h2, sizeof(hiddenText.h2), 1, pFileHiddenSource);
    
	hiddenText.nb_byte_line = (hiddenText.h2.ImageWidth * sizeof(RGB)) + (hiddenText.h2.ImageWidth % 4);
	hiddenText.p_buffer = (RGB*) new unsigned char[hiddenText.nb_byte_line];

	
	int heightLoop, widthLoop;
	if (hiddenText.h2.ImageHeight <= bitmap.h2.ImageHeight)
		heightLoop = hiddenText.h2.ImageHeight;
	else
		heightLoop = bitmap.h2.ImageHeight;

	if (hiddenText.h2.ImageWidth <= bitmap.h2.ImageWidth)
		widthLoop = hiddenText.h2.ImageWidth;
	else
		widthLoop = bitmap.h2.ImageWidth;



        bitmap.p_row = bitmap.p_buffer;
	for (i=heightLoop; i; i--, bitmap.p_row++)
	{
             fread  (hiddenText.p_buffer, hiddenText.nb_byte_line, 1, pFileHiddenSource);
	     hiddenText.p_rgb = (RGB*)hiddenText.p_buffer;


	     unsigned short j;
	     for (j=0; j<(widthLoop+2); j=j+1, hiddenText.p_rgb++)
             {
                 if ((hiddenText.p_rgb->Blue != WHITE) ||
                     (hiddenText.p_rgb->Green!= WHITE) ||
	             (hiddenText.p_rgb->Red  != WHITE))
                 {
                     modifyPixel ((*bitmap.p_row) + j); 
                 }
             }
	}
	delete [] hiddenText.p_buffer;
        fclose(pFileHiddenSource);



	// Copie l'image qui est en memoire dans un fichier
	for (i=bitmap.h2.ImageHeight, bitmap.p_row = bitmap.p_buffer; i; i--, bitmap.p_row++)
	{
		fwrite (*bitmap.p_row, bitmap.nb_byte_line, 1, pFileDest);
	}




	// Libere toutes les memoires
	for (i=bitmap.h2.ImageHeight, bitmap.p_row = bitmap.p_buffer; i; i--, bitmap.p_row++)
	{
            delete [] *bitmap.p_row;
	}
	fclose(pFileSource);
	fclose(pFileDest);
}




// pOri = Original bitmap, pModified = Modified bitmap (read only)
// pFoundHiddenText = TextDecrypted (write only)
static void steganographyDecrypt (const char *pOri, const char *pModified, const char *pFoundHiddenText)
{
IMAGE_BMP    bitmapOri;
IMAGE_BMP    bitmapModified;
IMAGE_BMP    bitmapFoundHiddenText;

	/* Open the files */
        bitmapOri.pFile             = fopen(pOri, "rb");
	bitmapModified.pFile        = fopen(pModified, "rb");
	bitmapFoundHiddenText.pFile = fopen(pFoundHiddenText, "wb");


	// Read the two headers
	fread  (&bitmapOri.h1, sizeof(bitmapOri.h1), 1, bitmapOri.pFile);
	fread  (&bitmapOri.h2, sizeof(bitmapOri.h2), 1, bitmapOri.pFile);
	fread  (&bitmapModified.h1, sizeof(bitmapModified.h1), 1, bitmapModified.pFile);
	fread  (&bitmapModified.h2, sizeof(bitmapModified.h2), 1, bitmapModified.pFile);
	
	// Write the text file
	fwrite (&bitmapOri.h1, sizeof(bitmapOri.h1), 1, bitmapFoundHiddenText.pFile);
	fwrite (&bitmapOri.h2, sizeof(bitmapOri.h2), 1, bitmapFoundHiddenText.pFile);


	//Initialize the nb byte per line and p_buffer
	bitmapOri.nb_byte_line = (bitmapOri.h2.ImageWidth * sizeof(RGB)) +
		                     (bitmapOri.h2.ImageWidth % 4);
	bitmapOri.p_buffer     = (RGB*) new unsigned char[bitmapOri.nb_byte_line];

	bitmapModified.nb_byte_line = (bitmapModified.h2.ImageWidth * sizeof(RGB)) +
		                          (bitmapModified.h2.ImageWidth % 4);
	bitmapModified.p_buffer     = (RGB*) new unsigned char[bitmapModified.nb_byte_line];

        bitmapFoundHiddenText.nb_byte_line = bitmapOri.nb_byte_line;
	bitmapFoundHiddenText.p_buffer     = (RGB*) new unsigned char[bitmapFoundHiddenText.nb_byte_line];


	unsigned short i;
	for (i=bitmapOri.h2.ImageHeight; i; i--)
	{
		
	    fread (bitmapOri.p_buffer, bitmapOri.nb_byte_line, 1, bitmapOri.pFile);
	    fread (bitmapModified.p_buffer, bitmapModified.nb_byte_line, 1, bitmapModified.pFile);
            memset (bitmapFoundHiddenText.p_buffer, WHITE, bitmapFoundHiddenText.nb_byte_line);

            bitmapOri.p_rgb             = (RGB*) bitmapOri.p_buffer;
            bitmapModified.p_rgb        = (RGB*) bitmapModified.p_buffer;
            bitmapFoundHiddenText.p_rgb = (RGB*) bitmapFoundHiddenText.p_buffer;
        
        
  
            // Check the line
	    unsigned short j;
	    for (j=bitmapOri.h2.ImageWidth; 
	         j; 
	         j--, bitmapOri.p_rgb++, bitmapModified.p_rgb++, bitmapFoundHiddenText.p_rgb++)
	    {
          
                // Control only one color (Red or Green or Blue)
                if (bitmapOri.p_rgb->Red != bitmapModified.p_rgb->Red)
                {
                    bitmapFoundHiddenText.p_rgb->Red   = BLACK;
                    bitmapFoundHiddenText.p_rgb->Green = BLACK;
                    bitmapFoundHiddenText.p_rgb->Blue  = BLACK;
                }
            }
	    fwrite (bitmapFoundHiddenText.p_buffer, bitmapFoundHiddenText.nb_byte_line, 1, bitmapFoundHiddenText.pFile);
	}

        delete [] bitmapOri.p_buffer;
        delete [] bitmapModified.p_buffer;
        delete [] bitmapFoundHiddenText.p_buffer;

	fclose(bitmapOri.pFile);
	fclose(bitmapModified.pFile);
	fclose(bitmapFoundHiddenText.pFile);

}


static void modifyPixel (RGB  *p)
{
    if (p->Blue >= DELTA)
        p->Blue -= DELTA;
    else
        p->Blue += DELTA;

    if (p->Green >= DELTA)
        p->Green -= DELTA;
    else
        p->Green += DELTA;

    if (p->Red >= DELTA)
        p->Red -= DELTA;
    else
        p->Red += DELTA;
}


