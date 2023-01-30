CREATE TABLE [dbo].[CrushFTPLogins](
	[CrushFTPLoginID] [int] IDENTITY(1,1) NOT NULL,
	[CrushFTPLoginName] [varchar](50) NOT NULL,
    [HostName] [varchar](50) NOT NULL,
	[HostKeyFingerprint] [varchar](100) NULL,
	[AccountName] [varchar](50) NOT NULL,
	[Password] [varchar](50) NOT NULL,
	[PrivateKey] [varchar](400) NULL);

