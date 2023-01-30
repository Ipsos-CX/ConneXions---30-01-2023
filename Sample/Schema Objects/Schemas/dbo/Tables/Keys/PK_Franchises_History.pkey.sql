ALTER TABLE [dbo].[Franchises_History]
	ADD CONSTRAINT [PK_Franchises_History]
	PRIMARY KEY CLUSTERED ([ID] ASC, [DateStamp] ASC, [State] ASC)
