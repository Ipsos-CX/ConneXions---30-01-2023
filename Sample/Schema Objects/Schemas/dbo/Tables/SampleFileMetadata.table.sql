CREATE TABLE [dbo].[SampleFileMetadata] (
    [SampleFileID]               INT      IDENTITY(1,1)     NOT NULL,
    [SampleFileSource]			 VARCHAR (255) NOT NULL,
    [SampleFileDestination]   VARCHAR (255) NOT NULL,
    [SampleFileNamePrefix]             VARCHAR (50)  NOT NULL,
    [SampleFileExtension]              VARCHAR (50)  NOT NULL,
    NonSolSupplied_Email			INT, 
    NonSolSupplied_Postal			INT, 
    NonSolSupplied_Party			INT,
	NonSolUnsuppress_Active			INT
	
);

